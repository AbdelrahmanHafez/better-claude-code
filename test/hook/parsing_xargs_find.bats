#!/usr/bin/env bats
# Tests for Category 16: xargs and find -exec Edge Cases
# SECURITY: These commands can execute arbitrary commands with user-controlled data

load hook_test_helper

# =============================================================================
# xargs basic parsing
# =============================================================================

@test "parse: simple xargs" {
  run_parse_commands 'echo foo | xargs ls'
  assert_commands "echo foo" "xargs ls"
}

@test "parse: xargs without argument" {
  run_parse_commands 'cat files.txt | xargs'
  assert_commands "cat files.txt" "xargs"
}

@test "parse: xargs with -I placeholder" {
  run_parse_commands 'echo foo | xargs -I {} cp {} /tmp/'
  assert_commands "echo foo" "xargs -I {} cp {} /tmp/"
}

@test "parse: xargs with -n" {
  run_parse_commands 'cat list | xargs -n 1 echo'
  assert_commands "cat list" "xargs -n 1 echo"
}

@test "parse: xargs with -0" {
  run_parse_commands 'find . -print0 | xargs -0 ls'
  assert_commands "find . -print0" "xargs -0 ls"
}

@test "parse: xargs with long options" {
  run_parse_commands 'cat list | xargs --max-args=1 echo'
  assert_commands "cat list" "xargs --max-args=1 echo"
}

# =============================================================================
# xargs with dangerous commands
# =============================================================================

@test "parse: xargs rm extracts full command" {
  run_parse_commands 'cat list | xargs rm'
  assert_commands "cat list" "xargs rm"
}

@test "parse: xargs rm -rf extracts full command" {
  run_parse_commands 'find /tmp -name "*.tmp" | xargs rm -rf'
  assert_commands 'find /tmp -name "*.tmp"' "xargs rm -rf"
}

@test "parse: xargs chmod extracts full command" {
  run_parse_commands 'find . -type f | xargs chmod 644'
  assert_commands "find . -type f" "xargs chmod 644"
}

# =============================================================================
# find -exec parsing
# =============================================================================

@test "parse: find -exec simple" {
  run_parse_commands 'find . -name "*.txt" -exec cat {} \;'
  assert_commands 'find . -name "*.txt" -exec cat {} \;'
}

@test "parse: find -exec with plus terminator" {
  run_parse_commands 'find . -type f -exec ls {} +'
  assert_commands "find . -type f -exec ls {} +"
}

@test "parse: find with multiple -exec" {
  run_parse_commands 'find . -exec echo {} \; -exec ls {} \;'
  assert_commands 'find . -exec echo {} \; -exec ls {} \;'
}

@test "parse: find -execdir" {
  run_parse_commands 'find . -name "*.sh" -execdir chmod +x {} \;'
  assert_commands 'find . -name "*.sh" -execdir chmod +x {} \;'
}

@test "parse: find -ok (interactive exec)" {
  run_parse_commands 'find . -name "*.bak" -ok rm {} \;'
  assert_commands 'find . -name "*.bak" -ok rm {} \;'
}

# =============================================================================
# find -exec with dangerous commands
# =============================================================================

@test "parse: find -exec rm" {
  run_parse_commands 'find /tmp -name "*.tmp" -exec rm {} \;'
  assert_commands 'find /tmp -name "*.tmp" -exec rm {} \;'
}

@test "parse: find -exec rm -rf" {
  run_parse_commands 'find . -type d -empty -exec rm -rf {} \;'
  assert_commands 'find . -type d -empty -exec rm -rf {} \;'
}

@test "parse: find -exec chmod" {
  run_parse_commands 'find . -type f -exec chmod 755 {} \;'
  assert_commands 'find . -type f -exec chmod 755 {} \;'
}

# =============================================================================
# xargs permission validation
# SECURITY: Bash(xargs:*) allows ANY command via xargs!
# =============================================================================

@test "permission: xargs blocked without permission" {
  run_hook_block 'cat list | xargs ls' '["Bash(cat:*)"]'
  assert_blocked
}

@test "permission: xargs allowed with xargs permission" {
  # WARNING: This allows ANY command to be run via xargs
  run_hook_allow 'cat list | xargs ls' '["Bash(cat:*)", "Bash(xargs:*)"]'
  assert_allowed
}

@test "permission: xargs rm allowed with xargs permission (DANGEROUS)" {
  # SECURITY WARNING: Bash(xargs:*) allows xargs rm!
  # This documents the dangerous behavior - not a bug, just dangerous permission
  run_hook_allow 'cat list | xargs rm' '["Bash(cat:*)", "Bash(xargs:*)"]'
  assert_allowed
}

@test "permission: xargs rm blocked without xargs permission" {
  # Even though cat is allowed, xargs rm is blocked
  run_hook_block 'cat list | xargs rm' '["Bash(cat:*)"]'
  assert_blocked
}

# =============================================================================
# find -exec permission validation
# SECURITY: find commands execute external commands
# =============================================================================

@test "permission: find with -exec blocked without permission" {
  run_hook_block 'find . -exec cat {} \;' '["Bash(ls:*)"]'
  assert_blocked
}

@test "permission: find with -exec allowed with find permission" {
  run_hook_allow 'find . -exec cat {} \;' '["Bash(find:*)"]'
  assert_allowed
}

@test "permission: find -exec rm allowed with find permission (DANGEROUS)" {
  # SECURITY WARNING: Bash(find:*) allows find -exec rm!
  # This documents the dangerous behavior
  run_hook_allow 'find . -exec rm {} \;' '["Bash(find:*)"]'
  assert_allowed
}

@test "permission: find -exec rm blocked without find permission" {
  run_hook_block 'find . -exec rm {} \;' '["Bash(ls:*)"]'
  assert_blocked
}

# =============================================================================
# Nested/complex xargs scenarios
# =============================================================================

@test "parse: multiple xargs in pipeline" {
  run_parse_commands 'cat list | xargs echo | xargs ls'
  assert_commands "cat list" "xargs echo" "xargs ls"
}

@test "parse: xargs with subshell command" {
  # xargs running bash -c - very dangerous pattern
  run_parse_commands 'cat list | xargs bash -c "echo {}"'
  # The xargs command includes the bash -c part
  assert_commands "cat list" 'xargs bash -c "echo {}"'
}

@test "permission: xargs bash -c needs xargs permission" {
  run_hook_block 'cat list | xargs bash -c "rm file"' '["Bash(cat:*)"]'
  assert_blocked
}

@test "permission: xargs bash -c allowed with xargs permission (DANGEROUS)" {
  # SECURITY: This is extremely dangerous - allows arbitrary code execution
  run_hook_allow 'cat list | xargs bash -c "rm file"' '["Bash(cat:*)", "Bash(xargs:*)"]'
  assert_allowed
}

# =============================================================================
# Edge cases
# =============================================================================

@test "parse: xargs with parallel (-P)" {
  run_parse_commands 'cat urls | xargs -P 4 -n 1 curl'
  assert_commands "cat urls" "xargs -P 4 -n 1 curl"
}

@test "parse: find with complex expression" {
  run_parse_commands 'find . \( -name "*.log" -o -name "*.tmp" \) -exec rm {} \;'
  assert_commands 'find . \( -name "*.log" -o -name "*.tmp" \) -exec rm {} \;'
}

@test "parse: find piped to xargs" {
  run_parse_commands 'find . -name "*.txt" | xargs grep "pattern"'
  assert_commands 'find . -name "*.txt"' 'xargs grep "pattern"'
}

@test "permission: find piped to xargs both need permission" {
  run_hook_block 'find . -name "*.txt" | xargs grep "pattern"' '["Bash(find:*)"]'
  assert_blocked
}

@test "permission: find piped to xargs allowed with both permissions" {
  run_hook_allow 'find . -name "*.txt" | xargs grep "pattern"' '["Bash(find:*)", "Bash(xargs:*)"]'
  assert_allowed
}

