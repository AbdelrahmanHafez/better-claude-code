import { exec, commandExists, getCommandVersion } from './exec.js';

describe('exec', function() {
  describe('exec()', function() {
    it('returns success: true and stdout for successful commands', function() {
      // Arrange
      const command = 'echo "hello world"';

      // Act
      const result = exec(command);

      // Assert
      expect(result.success).toBe(true);
      expect(result.stdout).toBe('hello world');
      expect(result.stderr).toBe('');
    });

    it('returns success: false for failing commands', function() {
      // Arrange
      const command = 'exit 1';

      // Act
      const result = exec(command);

      // Assert
      expect(result.success).toBe(false);
    });

    it('returns success: false for non-existent commands', function() {
      // Arrange
      const command = 'nonexistent_command_12345';

      // Act
      const result = exec(command);

      // Assert
      expect(result.success).toBe(false);
    });

    it('trims stdout output', function() {
      // Arrange
      const command = 'echo "  spaced  "';

      // Act
      const result = exec(command);

      // Assert
      expect(result.stdout).toBe('spaced');
    });

    it('captures stderr on failure', function() {
      // Arrange
      const command = 'ls /nonexistent_directory_12345';

      // Act
      const result = exec(command);

      // Assert
      expect(result.success).toBe(false);
      expect(result.stderr).toContain('No such file or directory');
    });
  });

  describe('commandExists()', function() {
    it('returns true for existing commands', function() {
      // Arrange
      const command = 'ls';

      // Act
      const result = commandExists(command);

      // Assert
      expect(result).toBe(true);
    });

    it('returns false for non-existent commands', function() {
      // Arrange
      const command = 'nonexistent_command_xyz_12345';

      // Act
      const result = commandExists(command);

      // Assert
      expect(result).toBe(false);
    });

    it('returns true for bash', function() {
      // Arrange
      const command = 'bash';

      // Act
      const result = commandExists(command);

      // Assert
      expect(result).toBe(true);
    });
  });

  describe('getCommandVersion()', function() {
    it('returns version string for valid commands', function() {
      // Arrange
      const command = 'node';

      // Act
      const result = getCommandVersion(command);

      // Assert
      expect(result).not.toBeNull();
      expect(result).toMatch(/v?\d+\.\d+/);
    });

    it('returns null for non-existent commands', function() {
      // Arrange
      const command = 'nonexistent_command_xyz_12345';

      // Act
      const result = getCommandVersion(command);

      // Assert
      expect(result).toBeNull();
    });

    it('uses custom version flag when provided', function() {
      // Arrange
      const command = 'node';
      const versionFlag = '-v';

      // Act
      const result = getCommandVersion(command, versionFlag);

      // Assert
      expect(result).not.toBeNull();
      expect(result).toMatch(/v?\d+\.\d+/);
    });
  });
});
