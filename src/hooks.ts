// Hook file generation and configuration

import * as fs from 'node:fs';
import * as path from 'node:path';
import { fileURLToPath } from 'node:url';
import { getClaudeDir, getHookPrefix, trackChezmoiFile } from './utils/chezmoi.js';
import { info, success, file } from './utils/colors.js';
import { addHook, hasHook } from './settings.js';

const HOOK_FILENAME = 'auto-approve-allowed-commands.sh';

export function getHookFilepath(): string {
  const prefix = getHookPrefix();
  return path.join(getClaudeDir(), 'hooks', `${prefix}${HOOK_FILENAME}`);
}

export function ensureHooksDir(): void {
  const hooksDir = path.join(getClaudeDir(), 'hooks');
  if (!fs.existsSync(hooksDir)) {
    fs.mkdirSync(hooksDir, { recursive: true });
    info(`Created ${file(hooksDir)}`);
  }
}

export function getHookScriptContent(): string {
  // Get the path to the assets directory relative to this file
  const currentFile = fileURLToPath(import.meta.url);
  const currentDir = path.dirname(currentFile);

  // In dist/, go up one level then into assets/
  // In development, assets is at project root
  let assetsPath = path.join(currentDir, '..', 'assets', HOOK_FILENAME);

  if (!fs.existsSync(assetsPath)) {
    // Try development path (from src/)
    assetsPath = path.join(currentDir, '..', '..', 'assets', HOOK_FILENAME);
  }

  if (!fs.existsSync(assetsPath)) {
    throw new Error(`Hook script not found at ${assetsPath}`);
  }

  return fs.readFileSync(assetsPath, 'utf-8');
}

export function installHook(): void {
  ensureHooksDir();

  const hookPath = getHookFilepath();
  const hookExists = fs.existsSync(hookPath);

  if (hookExists) {
    info('Hook already exists, updating...');
  }

  const content = getHookScriptContent();
  fs.writeFileSync(hookPath, content, { mode: 0o755 });
  trackChezmoiFile(hookPath);

  success('Hook installed');
}

export function configureHookInSettings(): void {
  const hookPathForSettings = `$HOME/.claude/hooks/${HOOK_FILENAME}`;

  if (hasHook(hookPathForSettings)) {
    info('Hook already configured in settings');
    return;
  }

  addHook({
    matcher: 'Bash',
    hooks: [{
      type: 'command',
      command: hookPathForSettings
    }]
  });
}
