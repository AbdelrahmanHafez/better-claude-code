// Claude Code settings.json manipulation

import * as fs from 'node:fs';
import * as path from 'node:path';
import { getClaudeDir, trackChezmoiFile } from './utils/chezmoi.js';
import { info, file } from './utils/colors.js';

export interface HookEntry {
  type: 'command';
  command: string;
}

export interface MatcherHook {
  matcher: string;
  hooks: HookEntry[];
}

export interface ClaudeSettings {
  env?: {
    SHELL?: string;
    [key: string]: string | undefined;
  };
  hooks?: {
    PreToolUse?: MatcherHook[];
    [key: string]: unknown;
  };
  permissions?: {
    allow?: string[];
    deny?: string[];
  };
  [key: string]: unknown;
}

function getSettingsPath(): string {
  return path.join(getClaudeDir(), 'settings.json');
}

export function ensureClaudeDir(): void {
  const claudeDir = getClaudeDir();
  if (!fs.existsSync(claudeDir)) {
    fs.mkdirSync(claudeDir, { recursive: true });
    info(`Created ${file(claudeDir)}`);
  }
}

export function getSettings(): ClaudeSettings {
  const settingsPath = getSettingsPath();
  if (!fs.existsSync(settingsPath)) {
    return {};
  }
  const content = fs.readFileSync(settingsPath, 'utf-8');
  return JSON.parse(content) as ClaudeSettings;
}

export function saveSettings(settings: ClaudeSettings): void {
  ensureClaudeDir();
  const settingsPath = getSettingsPath();
  fs.writeFileSync(settingsPath, `${JSON.stringify(settings, null, 2)}\n`);
  trackChezmoiFile(settingsPath);
}

export function setEnvVar(name: string, value: string): void {
  const settings = getSettings();
  if (!settings.env) {
    settings.env = {};
  }
  settings.env[name] = value;
  saveSettings(settings);
}

export function addPermission(permission: string): boolean {
  const settings = getSettings();
  if (!settings.permissions) {
    settings.permissions = {};
  }
  if (!settings.permissions.allow) {
    settings.permissions.allow = [];
  }
  if (settings.permissions.allow.includes(permission)) {
    return false; // Already exists
  }
  settings.permissions.allow.push(permission);
  saveSettings(settings);
  return true;
}

export function hasPermission(permission: string): boolean {
  const settings = getSettings();
  return settings.permissions?.allow?.includes(permission) ?? false;
}

export function addPermissions(permissions: string[]): number {
  const settings = getSettings();
  if (!settings.permissions) {
    settings.permissions = {};
  }
  if (!settings.permissions.allow) {
    settings.permissions.allow = [];
  }

  let added = 0;
  for (const permission of permissions) {
    if (!settings.permissions.allow.includes(permission)) {
      settings.permissions.allow.push(permission);
      added++;
    }
  }

  if (added > 0) {
    saveSettings(settings);
  }
  return added;
}

export interface HookConfig {
  matcher: string;
  hooks: HookEntry[];
}

export function addHook(hookConfig: HookConfig): boolean {
  const settings = getSettings();
  if (!settings.hooks) {
    settings.hooks = {};
  }
  if (!settings.hooks.PreToolUse) {
    settings.hooks.PreToolUse = [];
  }

  // Check if hook already exists with same matcher
  const existingIndex = settings.hooks.PreToolUse.findIndex(
    (matcherHook) => matcherHook.matcher === hookConfig.matcher
  );

  if (existingIndex >= 0) {
    // Merge hooks arrays (check by command path)
    const existing = settings.hooks.PreToolUse[existingIndex];
    for (const hookEntry of hookConfig.hooks) {
      const alreadyExists = existing.hooks.some(
        (existingHook) => existingHook.command === hookEntry.command
      );
      if (!alreadyExists) {
        existing.hooks.push(hookEntry);
      }
    }
  } else {
    settings.hooks.PreToolUse.push(hookConfig);
  }

  saveSettings(settings);
  return true;
}

export function hasHook(hookPath: string): boolean {
  const settings = getSettings();
  if (!settings.hooks?.PreToolUse) {
    return false;
  }
  return settings.hooks.PreToolUse.some((matcherHook) =>
    matcherHook.hooks.some((hookEntry) => hookEntry.command === hookPath)
  );
}
