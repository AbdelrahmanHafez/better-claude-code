# Hook test helper functions
#
# Provides helpers for testing the auto-approve hook system:
# - Command parsing (parse_commands)
# - Permission validation (full hook with --permissions)

# Get the project root directory
get_project_root() {
  cd "$(dirname "$BATS_TEST_FILENAME")/../.." && pwd
}

# Get the hook script path
get_hook_script() {
  echo "$(get_project_root)/assets/auto-approve-allowed-commands.sh"
}

# --- Command Parsing Tests ---

# Run the parse_commands function and capture output
# Usage: run_parse_commands 'ls | grep foo'
# Result: $output contains newline-separated commands, $status is exit code
run_parse_commands() {
  local input="$1"
  local hook_script
  hook_script=$(get_hook_script)
  run "$hook_script" parse_commands "$input"
}

# Assert that the parsed commands match expected (order matters)
# Usage: assert_commands "ls" "grep foo" "head -5"
# Compares against $output from run_parse_commands
assert_commands() {
  local expected=("$@")
  local actual_array

  # Split output into array (newline-delimited)
  IFS=$'\n' read -r -d '' -a actual_array <<< "$output" || true

  # Compare counts
  if [[ ${#actual_array[@]} -ne ${#expected[@]} ]]; then
    echo "Command count mismatch"
    echo "Expected ${#expected[@]} commands: ${expected[*]}"
    echo "Got ${#actual_array[@]} commands: ${actual_array[*]}"
    echo "Raw output:"
    echo "$output"
    return 1
  fi

  # Compare each command
  for i in "${!expected[@]}"; do
    if [[ "${actual_array[$i]}" != "${expected[$i]}" ]]; then
      echo "Command $i mismatch"
      echo "Expected: '${expected[$i]}'"
      echo "Got: '${actual_array[$i]}'"
      echo "All expected: ${expected[*]}"
      echo "All actual: ${actual_array[*]}"
      return 1
    fi
  done
}

# Assert no commands were parsed (empty input, only comments, etc.)
assert_no_commands() {
  if [[ -n "$output" && "$output" != "" ]]; then
    echo "Expected no commands, but got:"
    echo "$output"
    return 1
  fi
}

# Assert parsing failed (non-zero exit)
assert_parse_error() {
  if [[ "$status" -eq 0 ]]; then
    echo "Expected parse error, but parsing succeeded with output:"
    echo "$output"
    return 1
  fi
}

# --- Permission Validation Tests ---

# Run the full hook with custom permissions
# Usage: run_hook 'ls | grep foo' '["Bash(ls:*)", "Bash(grep:*)"]'
# Result: $output contains hook response JSON, $status is exit code
run_hook() {
  local command="$1"
  local permissions="$2"
  local hook_script
  hook_script=$(get_hook_script)

  # Create JSON and run hook, capturing output
  # Use a subshell and process substitution to avoid quoting issues
  run bash -c 'jq -n --arg cmd "$1" "{\"tool_input\": {\"command\": \$cmd}}" | "$2" --permissions "$3"' _ "$command" "$hook_script" "$permissions"
}

# Run hook and expect ALLOW decision
# Usage: run_hook_allow 'ls | grep foo' '["Bash(ls:*)", "Bash(grep:*)"]'
run_hook_allow() {
  run_hook "$1" "$2"
}

# Run hook and expect BLOCK decision (fall through, no output)
# Usage: run_hook_block 'ls | grep foo' '["Bash(cat:*)"]'
run_hook_block() {
  run_hook "$1" "$2"
}

# Assert the hook returned ALLOW decision
assert_allowed() {
  if [[ "$output" != *'"permissionDecision":"allow"'* ]]; then
    echo "Expected ALLOW decision"
    echo "Got output: $output"
    echo "Status: $status"
    return 1
  fi
}

# Assert the hook returned BLOCK decision (no allow output = fall through)
assert_blocked() {
  if [[ "$output" == *'"permissionDecision":"allow"'* ]]; then
    echo "Expected BLOCK decision (no allow output)"
    echo "Got output: $output"
    return 1
  fi
}

# --- Debug Helpers ---

# Run hook with debug output for troubleshooting
run_hook_debug() {
  local command="$1"
  local permissions="$2"
  local hook_script
  hook_script=$(get_hook_script)

  local json_input
  json_input=$(jq -n --arg cmd "$command" '{"tool_input": {"command": $cmd}}')

  run bash -c "echo '$json_input' | '$hook_script' --debug --permissions '$permissions'" 2>&1
}

# Run parse_commands with debug output
run_parse_commands_debug() {
  local input="$1"
  local hook_script
  hook_script=$(get_hook_script)
  run "$hook_script" parse_commands --debug "$input" 2>&1
}
