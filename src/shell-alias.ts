// Shell alias configuration for bash/zsh/fish

import * as fs from 'node:fs';
import * as path from 'node:path';
import { info, success, file } from './utils/colors.js';
import { exec } from './utils/exec.js';
import { trackChezmoiFile } from './utils/chezmoi.js';

const ALIAS_MARKER = '# Added by claude-code-plus for shell alias';

interface ShellConfig {
  name: string;
  configPaths: string[];
  aliasTemplate: (shellPath: string) => string;
}

const SHELL_CONFIGS: ShellConfig[] = [
  {
    name: 'Bash',
    configPaths: ['.bashrc', '.bash_profile'],
    aliasTemplate: (shellPath: string) =>
      `${ALIAS_MARKER}\nclaude() {\n  SHELL="${shellPath}" command claude "$@"\n}\n`
  },
  {
    name: 'Zsh',
    configPaths: ['.zshrc'],
    aliasTemplate: (shellPath: string) =>
      `${ALIAS_MARKER}\nclaude() {\n  SHELL="${shellPath}" command claude "$@"\n}\n`
  },
  {
    name: 'Fish',
    configPaths: ['.config/fish/config.fish'],
    aliasTemplate: (shellPath: string) =>
      `${ALIAS_MARKER}\nfunction claude\n  SHELL="${shellPath}" command claude $argv\nend\n`
  }
];

function hasExistingAlias(content: string): boolean {
  return content.includes(ALIAS_MARKER);
}

/**
 * Get the chezmoi source path for a file if it's managed by chezmoi.
 * Returns the source path if managed, or null if not managed.
 */
function getChezmoiSourcePath(targetPath: string): string | null {
  const result = exec(`chezmoi source-path "${targetPath}" 2>/dev/null`);
  if (result.success && result.stdout.trim()) {
    return result.stdout.trim();
  }
  return null;
}

/**
 * Get the target file to write to, resolving chezmoi source if applicable.
 * Returns { targetPath, isChezmoiManaged }
 */
function resolveConfigTarget(configPath: string): { targetPath: string; isChezmoiManaged: boolean } {
  const chezmoiSource = getChezmoiSourcePath(configPath);
  if (chezmoiSource) {
    return { targetPath: chezmoiSource, isChezmoiManaged: true };
  }
  return { targetPath: configPath, isChezmoiManaged: false };
}

export function configureShellAlias(shellPath: string): void {
  const home = process.env.HOME;
  if (!home) {
    throw new Error('HOME environment variable not set');
  }

  for (const shellConfig of SHELL_CONFIGS) {
    for (const configPath of shellConfig.configPaths) {
      const fullPath = path.join(home, configPath);

      // Only modify existing config files
      if (!fs.existsSync(fullPath)) {
        continue;
      }

      // Resolve to chezmoi source if managed
      const { targetPath, isChezmoiManaged } = resolveConfigTarget(fullPath);

      // Read from the resolved target (chezmoi source or original)
      const content = fs.readFileSync(targetPath, 'utf-8');

      if (hasExistingAlias(content)) {
        info(`${shellConfig.name} alias already configured`);
        continue;
      }

      // Only add newline prefix if file doesn't end with one
      const prefix = content.endsWith('\n') ? '\n' : '\n\n';
      const alias = prefix + shellConfig.aliasTemplate(shellPath);
      fs.appendFileSync(targetPath, alias);

      // Track chezmoi-managed files for later apply
      if (isChezmoiManaged) {
        trackChezmoiFile(fullPath);
      }

      success(`Added claude alias to ${file(configPath)}`);
    }
  }
}

export function getSourceCommand(): string {
  const shell = process.env.SHELL || '/bin/bash';
  const shellName = path.basename(shell);

  switch (shellName) {
    case 'fish':
      return 'source ~/.config/fish/config.fish';
    case 'zsh':
      return 'source ~/.zshrc';
    default:
      return 'source ~/.bashrc';
  }
}
