#!/usr/bin/env bats
# Tests for Categories 1-4: Basic Pipes, Command Chaining, Comments, Multi-line

load hook_test_helper

# =============================================================================
# Category 1: Basic Pipes
# =============================================================================

# --- Simple pipes ---

@test "parse: simple two-command pipe" {
  run_parse_commands 'ls | grep foo'
  assert_commands "ls" "grep foo"
}

@test "parse: pipe with arguments" {
  run_parse_commands 'cat file.txt | head -5'
  assert_commands "cat file.txt" "head -5"
}

@test "parse: three-command pipe" {
  run_parse_commands 'ls -la | grep foo | head -5'
  assert_commands "ls -la" "grep foo" "head -5"
}

@test "parse: four-command pipe" {
  run_parse_commands "ps aux | grep node | grep -v grep | awk '{print \$2}'"
  assert_commands "ps aux" "grep node" "grep -v grep" "awk '{print \$2}'"
}

@test "parse: simple echo pipe" {
  run_parse_commands 'echo hello | cat'
  assert_commands "echo hello" "cat"
}

# --- Pipes with spaces in arguments ---

@test "parse: pipe with double-quoted string containing space" {
  run_parse_commands 'grep "hello world" | head'
  assert_commands 'grep "hello world"' "head"
}

@test "parse: pipe with single-quoted string containing space" {
  run_parse_commands "grep 'hello world' | head"
  assert_commands "grep 'hello world'" "head"
}

@test "parse: pipe with path containing space" {
  run_parse_commands 'ls "my folder" | wc -l'
  assert_commands 'ls "my folder"' "wc -l"
}

# --- Permission validation for pipes ---

@test "permission: allow pipe when all commands permitted" {
  run_hook_allow 'ls | grep foo' '["Bash(ls:*)", "Bash(grep:*)"]'
  assert_allowed
}

@test "permission: block pipe when one command not permitted" {
  run_hook_block 'ls | grep foo' '["Bash(ls:*)"]'
  assert_blocked
}

@test "permission: block pipe when no commands permitted" {
  run_hook_block 'ls | grep foo' '["Bash(cat:*)"]'
  assert_blocked
}

# =============================================================================
# Category 2: Command Chaining Operators
# =============================================================================

# --- AND operator (&&) ---

@test "parse: basic AND chain" {
  run_parse_commands 'git status && git diff'
  assert_commands "git status" "git diff"
}

@test "parse: triple AND chain" {
  run_parse_commands 'mkdir foo && cd foo && touch file'
  assert_commands "mkdir foo" "cd foo" "touch file"
}

@test "parse: conditional AND execution" {
  run_parse_commands 'test -f file && cat file'
  assert_commands "test -f file" "cat file"
}

# --- OR operator (||) ---

@test "parse: basic OR chain" {
  run_parse_commands 'git fetch || echo "fetch failed"'
  assert_commands "git fetch" 'echo "fetch failed"'
}

@test "parse: triple OR chain" {
  run_parse_commands 'command1 || command2 || command3'
  assert_commands "command1" "command2" "command3"
}

# --- Semicolon separator ---

@test "parse: basic semicolon" {
  run_parse_commands 'cmd1; cmd2'
  assert_commands "cmd1" "cmd2"
}

@test "parse: triple semicolon" {
  run_parse_commands 'cmd1; cmd2; cmd3'
  assert_commands "cmd1" "cmd2" "cmd3"
}

@test "parse: common info commands with semicolon" {
  run_parse_commands 'ls; pwd; whoami'
  assert_commands "ls" "pwd" "whoami"
}

@test "parse: sequential with sleep" {
  run_parse_commands 'echo start; sleep 1; echo end'
  assert_commands "echo start" "sleep 1" "echo end"
}

# --- Mixed operators ---

@test "parse: AND then OR" {
  run_parse_commands 'cmd1 && cmd2 || cmd3'
  assert_commands "cmd1" "cmd2" "cmd3"
}

@test "parse: OR then AND" {
  run_parse_commands 'cmd1 || cmd2 && cmd3'
  assert_commands "cmd1" "cmd2" "cmd3"
}

@test "parse: semicolon then AND" {
  run_parse_commands 'cmd1; cmd2 && cmd3'
  assert_commands "cmd1" "cmd2" "cmd3"
}

@test "parse: AND with pipe" {
  run_parse_commands 'git status && git diff | head'
  assert_commands "git status" "git diff" "head"
}

@test "parse: pipe then AND" {
  run_parse_commands 'ls | grep foo && echo found'
  assert_commands "ls" "grep foo" "echo found"
}

@test "parse: grouped AND piped" {
  run_parse_commands '(cmd1 && cmd2) | cmd3'
  assert_commands "cmd1" "cmd2" "cmd3"
}

# --- Permission validation for chaining ---

@test "permission: allow AND chain when all permitted" {
  run_hook_allow 'git status && git diff' '["Bash(git status:*)", "Bash(git diff:*)"]'
  assert_allowed
}

@test "permission: block AND chain when one not permitted" {
  run_hook_block 'git status && rm file' '["Bash(git status:*)"]'
  assert_blocked
}

# =============================================================================
# Category 3: Comments
# =============================================================================

# --- End-of-line comments ---

@test "parse: simple trailing comment" {
  run_parse_commands 'ls # list files'
  assert_commands "ls"
}

@test "parse: comment after flags" {
  run_parse_commands 'ls -la # long listing'
  assert_commands "ls -la"
}

@test "parse: comment after argument" {
  run_parse_commands 'grep foo # find foo'
  assert_commands "grep foo"
}

@test "parse: comment after pipe" {
  run_parse_commands 'ls | head # first 10'
  assert_commands "ls" "head"
}

@test "parse: comment after chain" {
  run_parse_commands 'cmd1 && cmd2 # both commands'
  assert_commands "cmd1" "cmd2"
}

# --- Standalone comments ---

@test "parse: only comment returns no commands" {
  run_parse_commands '# just a comment'
  assert_no_commands
}

@test "parse: indented comment returns no commands" {
  run_parse_commands '  # indented comment'
  assert_no_commands
}

# --- Comments in multi-line ---

@test "parse: comment between lines" {
  run_parse_commands $'ls # comment\ngrep foo'
  assert_commands "ls" "grep foo"
}

@test "parse: comments around command" {
  run_parse_commands $'# header\nls\n# footer'
  assert_commands "ls"
}

# --- Hash in strings (NOT comments) ---

@test "parse: hash inside double quotes is not comment" {
  run_parse_commands 'echo "foo # bar"'
  assert_commands 'echo "foo # bar"'
}

@test "parse: hash inside single quotes is not comment" {
  run_parse_commands "echo 'foo # bar'"
  assert_commands "echo 'foo # bar'"
}

@test "parse: hash in argument (quoted)" {
  run_parse_commands "grep '#include'"
  assert_commands "grep '#include'"
}

@test "parse: unquoted hash IS comment" {
  run_parse_commands 'echo #hashtag'
  assert_commands "echo"
}

# =============================================================================
# Category 4: Multi-line Commands
# =============================================================================

# --- Backslash line continuation ---

@test "parse: backslash before pipe" {
  run_parse_commands $'ls -la \\\n  | grep foo'
  assert_commands "ls -la" "grep foo"
}

@test "parse: backslash before argument" {
  run_parse_commands $'grep -E \\\n  "pattern"'
  assert_commands 'grep -E "pattern"'
}

@test "parse: multiple backslash continuations" {
  run_parse_commands $'cmd \\\n  --flag \\\n  --other'
  assert_commands "cmd --flag --other"
}

# --- Pipe at end of line (implicit continuation) ---

@test "parse: pipe at EOL continues" {
  run_parse_commands $'ls |\ngrep foo'
  assert_commands "ls" "grep foo"
}

@test "parse: multiple pipe continuations" {
  run_parse_commands $'cat file |\nhead -5 |\ntail -1'
  assert_commands "cat file" "head -5" "tail -1"
}

# --- AND/OR at end of line ---

@test "parse: AND at EOL continues" {
  run_parse_commands $'cmd1 &&\ncmd2'
  assert_commands "cmd1" "cmd2"
}

@test "parse: OR at EOL continues" {
  run_parse_commands $'cmd1 ||\ncmd2'
  assert_commands "cmd1" "cmd2"
}

# --- Plain newlines (separate statements) ---

@test "parse: two separate commands on newlines" {
  run_parse_commands $'ls\npwd'
  assert_commands "ls" "pwd"
}

@test "parse: blank line between commands" {
  run_parse_commands $'ls\n\npwd'
  assert_commands "ls" "pwd"
}

@test "parse: whitespace-only line between commands" {
  run_parse_commands $'ls\n   \npwd'
  assert_commands "ls" "pwd"
}

# --- Permission validation for multi-line ---

@test "permission: allow multi-line pipe when all permitted" {
  run_hook_allow $'ls |\ngrep foo' '["Bash(ls:*)", "Bash(grep:*)"]'
  assert_allowed
}

@test "permission: block multi-line when one not permitted" {
  run_hook_block $'ls\nrm file' '["Bash(ls:*)"]'
  assert_blocked
}
