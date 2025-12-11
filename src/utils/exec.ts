// Shell command execution helpers

import { execSync } from 'node:child_process';

export interface ExecResult {
  success: boolean;
  stdout: string;
  stderr: string;
}

export function exec(command: string, options?: { inheritStdio?: boolean }): ExecResult {
  try {
    if (options?.inheritStdio) {
      execSync(command, {
        encoding: 'utf-8',
        stdio: 'inherit'
      });
      return { success: true, stdout: '', stderr: '' };
    }
    const stdout = execSync(command, {
      encoding: 'utf-8',
      stdio: ['pipe', 'pipe', 'pipe']
    });
    return { success: true, stdout: stdout.trim(), stderr: '' };
  } catch (err) {
    const error = err as { stdout?: Buffer | string; stderr?: Buffer | string };
    return {
      success: false,
      stdout: String(error.stdout || '').trim(),
      stderr: String(error.stderr || '').trim()
    };
  }
}

export function commandExists(command: string): boolean {
  const result = exec(`command -v ${command}`);
  return result.success && result.stdout.length > 0;
}

export function getCommandVersion(command: string, versionFlag = '--version'): string | null {
  const result = exec(`${command} ${versionFlag} 2>/dev/null`);
  if (result.success) {
    // Extract first line, often contains version
    return result.stdout.split('\n')[0];
  }
  return null;
}
