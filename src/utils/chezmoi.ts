// Chezmoi detection and path resolution

import { exec, commandExists } from './exec.js';

// Cache for ~/.claude chezmoi status
const claudeDirCache: { checked: boolean; managed: boolean; sourcePath: string | null } = {
  checked: false,
  managed: false,
  sourcePath: null
};

/**
 * Check if chezmoi is available on the system
 */
export function isChezmoiAvailable(): boolean {
  return commandExists('chezmoi');
}

/**
 * Check if ~/.claude is managed by chezmoi
 */
export function isChezmoiManaged(): boolean {
  // Never report chezmoi when using override directory
  if (isOverrideDir()) {
    return false;
  }

  if (claudeDirCache.checked) {
    return claudeDirCache.managed;
  }

  claudeDirCache.checked = true;

  if (!isChezmoiAvailable()) {
    claudeDirCache.managed = false;
    return false;
  }

  const result = exec('chezmoi source-path ~/.claude');
  if (result.success && result.stdout.length > 0) {
    claudeDirCache.managed = true;
    claudeDirCache.sourcePath = result.stdout;
    return true;
  }

  claudeDirCache.managed = false;
  return false;
}

/**
 * Get the chezmoi source path for ~/.claude
 */
export function getChezmoiSourcePath(): string | null {
  if (!claudeDirCache.checked) {
    isChezmoiManaged();
  }
  return claudeDirCache.sourcePath;
}

/**
 * Get the prefix for hook files (executable_ for chezmoi, empty otherwise)
 */
export function getHookPrefix(): string {
  return isChezmoiManaged() ? 'executable_' : '';
}

/**
 * Check if we're using an override directory (for testing)
 */
export function isOverrideDir(): boolean {
  return !!process.env.CLAUDE_DIR_OVERRIDE;
}

/**
 * Get the actual directory to write files to
 * Returns chezmoi source path if managed, otherwise ~/.claude
 */
export function getClaudeDir(): string {
  const envOverride = process.env.CLAUDE_DIR_OVERRIDE;
  if (envOverride) {
    return envOverride;
  }

  if (isChezmoiManaged()) {
    return claudeDirCache.sourcePath!;
  }

  return `${process.env.HOME}/.claude`;
}

/**
 * Track files modified in chezmoi source directory.
 * These are the target paths (e.g., ~/.bashrc) that will need `chezmoi apply`.
 */
const modifiedChezmoiFiles: string[] = [];

/**
 * Get the target path from a chezmoi source path.
 * Returns null if not a chezmoi source path.
 */
export function getChezmoiTargetPath(sourcePath: string): string | null {
  const result = exec(`chezmoi target-path "${sourcePath}" 2>/dev/null`);
  if (result.success && result.stdout.trim()) {
    return result.stdout.trim();
  }
  return null;
}

/**
 * Track a file that was modified in chezmoi source.
 * Accepts either source or target path - will resolve to target path automatically.
 */
export function trackChezmoiFile(filePath: string): void {
  // If it looks like a chezmoi source path, resolve to target
  let targetPath = filePath;
  const chezmoiTarget = getChezmoiTargetPath(filePath);
  if (chezmoiTarget) {
    targetPath = chezmoiTarget;
  }

  if (!modifiedChezmoiFiles.includes(targetPath)) {
    modifiedChezmoiFiles.push(targetPath);
  }
}

export function getModifiedChezmoiFiles(): string[] {
  return [...modifiedChezmoiFiles];
}

export function hasChezmoiModifications(): boolean {
  return modifiedChezmoiFiles.length > 0;
}

/**
 * Apply chezmoi changes for all modified files
 */
export function applyChezmoiChanges(): boolean {
  if (!hasChezmoiModifications()) {
    return true;
  }

  // Apply each modified file with inherited stdio to allow any prompts
  for (const targetPath of modifiedChezmoiFiles) {
    const result = exec(`chezmoi apply "${targetPath}"`, { inheritStdio: true });
    if (!result.success) {
      return false;
    }
  }

  return true;
}
