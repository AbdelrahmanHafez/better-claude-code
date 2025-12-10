#!/usr/bin/env bats
# Tests for Category 17: Prefix Matching Edge Cases
# These test the permission validation logic, not parsing

load hook_test_helper

# =============================================================================
# Space boundaries - command name vs similar commands
# =============================================================================

# Given permission Bash(python3:*)

@test "permission: python3 with argument allowed" {
  run_hook_allow 'python3 script.py' '["Bash(python3:*)"]'
  assert_allowed
}

@test "permission: python3 alone allowed" {
  run_hook_allow 'python3' '["Bash(python3:*)"]'
  assert_allowed
}

@test "permission: python3-pip NOT allowed by python3 permission" {
  # Different binary - hyphen is part of command name
  run_hook_block 'python3-pip install x' '["Bash(python3:*)"]'
  assert_blocked
}

@test "permission: python3.11 NOT allowed by python3 permission" {
  # Different binary - dot is part of command name
  run_hook_block 'python3.11 script.py' '["Bash(python3:*)"]'
  assert_blocked
}

@test "permission: python36 NOT allowed by python3 permission" {
  # Different binary - no separator
  run_hook_block 'python36 script.py' '["Bash(python3:*)"]'
  assert_blocked
}

# =============================================================================
# Path-based permissions - directory allowlisting
# =============================================================================

# Given permission Bash(python3 .claude/skills:*)

@test "permission: path - direct child allowed" {
  run_hook_allow 'python3 .claude/skills/foo.py' '["Bash(python3 .claude/skills:*)"]'
  assert_allowed
}

@test "permission: path - nested child allowed" {
  run_hook_allow 'python3 .claude/skills/sub/bar.py' '["Bash(python3 .claude/skills:*)"]'
  assert_allowed
}

@test "permission: path - exact match allowed" {
  run_hook_allow 'python3 .claude/skills' '["Bash(python3 .claude/skills:*)"]'
  assert_allowed
}

@test "permission: path - different directory blocked" {
  run_hook_block 'python3 .claude/other/bad.py' '["Bash(python3 .claude/skills:*)"]'
  assert_blocked
}

@test "permission: path - prefix attack blocked (skillsmalicious)" {
  # .claude/skillsmalicious.py is NOT .claude/skills/
  run_hook_block 'python3 .claude/skillsmalicious.py' '["Bash(python3 .claude/skills:*)"]'
  assert_blocked
}

# =============================================================================
# Multi-word command prefixes
# =============================================================================

# Given permission Bash(git log:*)

@test "permission: multi-word - exact match" {
  run_hook_allow 'git log' '["Bash(git log:*)"]'
  assert_allowed
}

@test "permission: multi-word - with flags" {
  run_hook_allow 'git log --oneline' '["Bash(git log:*)"]'
  assert_allowed
}

@test "permission: multi-word - with args" {
  run_hook_allow 'git log -p file.txt' '["Bash(git log:*)"]'
  assert_allowed
}

@test "permission: multi-word - different subcommand (git logs) blocked" {
  run_hook_block 'git logs' '["Bash(git log:*)"]'
  assert_blocked
}

@test "permission: multi-word - different subcommand (git logger) blocked" {
  run_hook_block 'git logger' '["Bash(git log:*)"]'
  assert_blocked
}

@test "permission: multi-word - different subcommand (git status) blocked" {
  run_hook_block 'git status' '["Bash(git log:*)"]'
  assert_blocked
}

# =============================================================================
# Multiple permissions
# =============================================================================

@test "permission: multiple - first matches" {
  run_hook_allow 'ls' '["Bash(ls:*)", "Bash(grep:*)"]'
  assert_allowed
}

@test "permission: multiple - second matches" {
  run_hook_allow 'grep foo' '["Bash(ls:*)", "Bash(grep:*)"]'
  assert_allowed
}

@test "permission: multiple - neither matches" {
  run_hook_block 'rm file' '["Bash(ls:*)", "Bash(grep:*)"]'
  assert_blocked
}

@test "permission: pipe - all commands match different permissions" {
  run_hook_allow 'ls | grep foo | head' '["Bash(ls:*)", "Bash(grep:*)", "Bash(head:*)"]'
  assert_allowed
}

@test "permission: pipe - one command not permitted" {
  run_hook_block 'ls | grep foo | rm file' '["Bash(ls:*)", "Bash(grep:*)"]'
  assert_blocked
}

# =============================================================================
# Edge cases and special patterns
# =============================================================================

@test "permission: empty command string" {
  # Empty input exits early (neither allow nor block - falls through)
  run_hook '' '["Bash(ls:*)"]'
  # No explicit allow output for empty commands
  [[ "$output" != *'"permissionDecision":"allow"'* ]]
}

@test "permission: whitespace-only command" {
  run_hook_allow '   ' '["Bash(ls:*)"]'
  assert_allowed
}

@test "permission: comment-only command" {
  run_hook_allow '# just a comment' '["Bash(ls:*)"]'
  assert_allowed
}

@test "permission: command with leading whitespace" {
  run_hook_allow '  ls' '["Bash(ls:*)"]'
  assert_allowed
}

@test "permission: no permissions configured" {
  # With empty permission array, nothing should be auto-allowed
  run_hook_block 'ls' '[]'
  assert_blocked
}

# =============================================================================
# Case sensitivity
# =============================================================================

@test "permission: case sensitive - lowercase allowed" {
  run_hook_allow 'ls' '["Bash(ls:*)"]'
  assert_allowed
}

@test "permission: case sensitive - uppercase blocked" {
  run_hook_block 'LS' '["Bash(ls:*)"]'
  assert_blocked
}

@test "permission: case sensitive - mixed case blocked" {
  run_hook_block 'Ls' '["Bash(ls:*)"]'
  assert_blocked
}
