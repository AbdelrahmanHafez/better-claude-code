# Better Claude Code - Project Guide

This file helps Claude Code understand the project structure and development workflow.

## Project Overview

Better Claude Code is an installer that fixes bugs and adds enhancements to Claude Code CLI. It addresses two main issues:

1. **Piped commands not auto-approved** ([#13340](https://github.com/anthropics/claude-code/issues/13340)) - Fixed via a PreToolUse hook
2. **Custom shell not respected** ([#7490](https://github.com/anthropics/claude-code/issues/7490)) - Fixed via settings.json env config

## Project Structure

```
better-claude-code/
├── install              # Generated single-file installer (DO NOT EDIT DIRECTLY)
├── README.md            # User documentation
├── CLAUDE.md            # This file
└── src/
    ├── bashly.yml       # Bashly CLI configuration (commands, flags, args)
    ├── lib/             # Shared helper functions
    │   ├── colors.sh    # Terminal output helpers (info, success, error, etc.)
    │   ├── deps.sh      # Dependency checking and installation
    │   ├── settings.sh  # Claude settings.json manipulation
    │   ├── hook_script.sh # Generates the allow-piped.sh hook
    │   └── permissions.sh # Default safe Bash permissions list
    └── *_command.sh     # Implementation for each CLI command
        ├── all_command.sh
        ├── dependencies_command.sh
        ├── shell_command.sh
        ├── hook_command.sh
        └── permissions_command.sh
```

## Development Workflow

### Building

This project uses [bashly](https://bashly.dev) to generate a single executable from modular source files.

```bash
# Generate the installer (requires Docker)
docker run --rm -v "$PWD:/app" dannyben/bashly generate

# Test the installer
./install --help
./install all
```

### Code Style

- **Step-down style**: All files use `main()` at the top, with helper functions defined below in order of abstraction
- **Section comments**: Use `# --- Section Name ---` to group related functions
- **Error handling**: Use `|| true` after arithmetic operations like `((count++))` to avoid exit code issues with `set -e`

### Key Design Decisions

1. **Single file output**: The `install` script is self-contained for easy `curl | bash` distribution
2. **Homebrew dependency**: We rely on Homebrew for macOS package management (prompts to install if missing)
3. **Configurable paths**: `--claude-dir` flag allows installation to custom directories (for dotfiles managers)
4. **Hook filename prefix**: `--hook-prefix` flag adds a prefix to the hook filename (e.g., `executable_` for chezmoi)
5. **Generated hook script**: The hook has the claude directory path baked in at install time via `generate_hook_script()`
6. **Separate file path vs settings path**: The hook file can have a prefix, but settings.json always references `$HOME/.claude/hooks/allow-piped.sh` (the runtime path after dotfiles are applied)

### Testing

**IMPORTANT:** Always test against a `/tmp/` directory, never against the real `~/.claude`. This prevents accidentally corrupting your actual Claude Code configuration.

#### Automated Tests (bats)

This project uses [bats-core](https://github.com/bats-core/bats-core) for automated testing. Tests are in the `test/` directory.

```bash
# Install bats-core (if not already installed)
brew install bats-core

# Run all tests
bats test/

# Run a specific test file
bats test/hook.bats

# Run tests with verbose output
bats --verbose-run test/

# Run tests in TAP format
bats --tap test/
```

Test files:
- `test/test_helper.bash` - Common helper functions (setup, assertions)
- `test/dependencies.bats` - Tests for `install dependencies`
- `test/shell.bats` - Tests for `install shell`
- `test/hook.bats` - Tests for `install hook`
- `test/permissions.bats` - Tests for `install permissions`
- `test/all.bats` - Tests for `install all`

Each test creates a fresh temp directory (`$TEST_DIR`) and cleans it up after, so tests are isolated and safe.

#### Manual Testing

```bash
# Test with custom directory (ALWAYS use /tmp for testing)
./install --claude-dir /tmp/test-claude all

# Test with chezmoi-style prefix
./install -d /tmp/test-claude -p executable_ all

# Test individual commands
./install -d /tmp/test-claude dependencies
./install -d /tmp/test-claude shell --shell /opt/homebrew/bin/fish
./install -d /tmp/test-claude hook
./install -d /tmp/test-claude permissions

# Clean up after testing
rm -rf /tmp/test-claude
```

### Adding New Permissions

Edit `src/lib/permissions.sh` and add entries to the `DEFAULT_PERMISSIONS` array:

```bash
DEFAULT_PERMISSIONS=(
  # ... existing permissions ...
  "Bash(new-command:*)"
)
```

Then regenerate with bashly.

### Adding New Commands

1. Add the command to `src/bashly.yml`
2. Run `docker run --rm -v "$PWD:/app" dannyben/bashly generate` (creates stub file)
3. Implement the command in the generated `src/<name>_command.sh`
4. Regenerate to bundle it into `./install`

## Dependencies

**Build time:**
- Docker (for running bashly)

**Runtime (installed automatically):**
- Homebrew
- bash 4.4+
- jq
- shfmt

## Code Migration Workflows

These workflows help you review changes more easily by leveraging git diffs.

### File Migration Workflow
**When moving code from one file to another, NEVER rewrite the code manually. Use `cp` command first, then modify.**

#### The Problem
When an LLM moves code from file A to file B by rewriting it, the user must review line-by-line to verify no unintended changes were made. This is time-consuming and error-prone because the entire file appears as "new" in git diff.

#### The Solution
Use a two-step workflow that leverages git as a verification tool:

**Step 1: Copy the file**
```bash
cp src/old-location/file.sh src/new-location/file.sh
```

**Step 2: Prompt user to stage so you can continue**
- Stop and inform the user the file has been copied
- Ask the user to stage the copied file with `git add` and let you know when to continue
- User verifies the copy is identical (git will show it as a new file with original content)
- User says "continue"

**Step 3: Modify the copied file**
- Now modify the new file to achieve the desired changes
- Git diff will show ONLY the modifications, not a complete rewrite
- User only needs to review the actual changes

### Code Snippet Migration Workflow
**When extracting/moving code snippets (>15 lines), NEVER manually copy the code. Use CLI tools for mechanical extraction.**

**Step 1: Extract using CLI tools**
```bash
# Append to end of existing file
sed -n '45,95p' src/old-file.sh >> src/target-file.sh

# Create brand new file with extracted code
sed -n '45,95p' src/old-file.sh > src/new-file.sh
```

**Step 2: Prompt user to stage so you can continue**
- Stop and inform the user the code has been extracted
- Ask the user to stage the changes with `git add` and let you know when to continue

**Step 3: Modify the extracted code**
- Now modify the extracted code (wrap in function, remove unwanted bits, etc.)
- Git diff shows only the actual modifications

#### Useful CLI Commands
```bash
# Extract specific line range
sed -n '10,50p' file.sh >> target.sh

# Extract from line to end of file
sed -n '100,$p' file.sh >> target.sh

# Extract last N lines
tail -n 20 file.sh >> target.sh

# Extract first N lines
head -n 20 file.sh > target.sh
```

#### When to Use These Approaches
- Moving code from one file to another
- Extracting functions (>15 lines)
- Refactoring large chunks of code
- Any code movement where verification is important

#### When NOT to Use These Approaches
- Writing completely new code (nothing to copy)
- Small extractions (<15 lines) - just use Edit tool
- Making small edits to existing files (use Edit tool)

## Related Issues

- [#13340](https://github.com/anthropics/claude-code/issues/13340) - Piped commands permission bug
- [#7490](https://github.com/anthropics/claude-code/issues/7490) - Custom shell not respected
