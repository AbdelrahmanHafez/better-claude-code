#!/usr/bin/env bats
# Tests for Category 18: Complex Real-World Commands
# These test commands commonly used by Claude Code

load hook_test_helper

# =============================================================================
# Git commands (very common in Claude Code)
# =============================================================================

@test "real: git log with formatting" {
  run_parse_commands 'git log --oneline -n 10'
  assert_commands "git log --oneline -n 10"
}

@test "real: git log with format string" {
  run_parse_commands 'git log --format="%H %s" -n 5'
  assert_commands 'git log --format="%H %s" -n 5'
}

@test "real: git diff with options" {
  run_parse_commands 'git diff --staged --name-only'
  assert_commands "git diff --staged --name-only"
}

@test "real: git status piped to grep" {
  run_parse_commands 'git status --porcelain | grep "^M"'
  assert_commands "git status --porcelain" 'grep "^M"'
}

@test "real: git branch with filter" {
  run_parse_commands 'git branch -a | grep feature'
  assert_commands "git branch -a" "grep feature"
}

@test "real: git add and commit chain" {
  run_parse_commands 'git add . && git commit -m "feat: add feature"'
  assert_commands "git add ." 'git commit -m "feat: add feature"'
}

@test "real: git fetch and pull chain" {
  run_parse_commands 'git fetch origin && git pull --rebase'
  assert_commands "git fetch origin" "git pull --rebase"
}

@test "real: git stash operations" {
  run_parse_commands 'git stash && git checkout main && git stash pop'
  assert_commands "git stash" "git checkout main" "git stash pop"
}

# =============================================================================
# Node.js / npm / package manager commands
# =============================================================================

@test "real: npm install" {
  run_parse_commands 'npm install'
  assert_commands "npm install"
}

@test "real: npm install with package" {
  run_parse_commands 'npm install --save-dev typescript'
  assert_commands "npm install --save-dev typescript"
}

@test "real: npm run script" {
  run_parse_commands 'npm run build'
  assert_commands "npm run build"
}

@test "real: npm test with coverage" {
  run_parse_commands 'npm test -- --coverage'
  assert_commands "npm test -- --coverage"
}

@test "real: yarn commands" {
  run_parse_commands 'yarn install && yarn build'
  assert_commands "yarn install" "yarn build"
}

@test "real: pnpm commands" {
  run_parse_commands 'pnpm install && pnpm test'
  assert_commands "pnpm install" "pnpm test"
}

@test "real: node execution" {
  run_parse_commands 'node script.js'
  assert_commands "node script.js"
}

@test "real: node with flags" {
  run_parse_commands 'node --inspect-brk app.js'
  assert_commands "node --inspect-brk app.js"
}

@test "real: npx command" {
  run_parse_commands 'npx tsc --init'
  assert_commands "npx tsc --init"
}

# =============================================================================
# Python commands
# =============================================================================

@test "real: python script" {
  run_parse_commands 'python3 script.py'
  assert_commands "python3 script.py"
}

@test "real: python with arguments" {
  run_parse_commands 'python3 manage.py migrate'
  assert_commands "python3 manage.py migrate"
}

@test "real: pip install" {
  run_parse_commands 'pip install -r requirements.txt'
  assert_commands "pip install -r requirements.txt"
}

@test "real: pytest with options" {
  run_parse_commands 'pytest -v --cov=src tests/'
  assert_commands "pytest -v --cov=src tests/"
}

@test "real: python -m module" {
  run_parse_commands 'python3 -m venv .venv'
  assert_commands "python3 -m venv .venv"
}

@test "real: uv pip install" {
  run_parse_commands 'uv pip install flask'
  assert_commands "uv pip install flask"
}

# =============================================================================
# Docker commands
# =============================================================================

@test "real: docker build" {
  run_parse_commands 'docker build -t myapp:latest .'
  assert_commands "docker build -t myapp:latest ."
}

@test "real: docker run" {
  run_parse_commands 'docker run -d -p 8080:80 nginx'
  assert_commands "docker run -d -p 8080:80 nginx"
}

@test "real: docker compose" {
  run_parse_commands 'docker compose up -d'
  assert_commands "docker compose up -d"
}

@test "real: docker ps piped" {
  run_parse_commands 'docker ps -a | grep exited'
  assert_commands "docker ps -a" "grep exited"
}

@test "real: docker exec" {
  run_parse_commands 'docker exec -it container_name bash'
  assert_commands "docker exec -it container_name bash"
}

# =============================================================================
# Search and text processing (common Claude Code patterns)
# =============================================================================

@test "real: grep recursive search" {
  run_parse_commands 'grep -r "TODO" --include="*.js" .'
  assert_commands 'grep -r "TODO" --include="*.js" .'
}

@test "real: ripgrep search" {
  run_parse_commands 'rg "function" --type ts'
  assert_commands 'rg "function" --type ts'
}

@test "real: fd find files" {
  run_parse_commands 'fd -e py -x wc -l'
  assert_commands "fd -e py -x wc -l"
}

@test "real: ag search" {
  run_parse_commands 'ag "import.*from" --ts'
  assert_commands 'ag "import.*from" --ts'
}

@test "real: grep pipe to head" {
  run_parse_commands 'grep -r "error" logs/ | head -20'
  assert_commands 'grep -r "error" logs/' "head -20"
}

@test "real: complex grep pipeline" {
  run_parse_commands 'cat access.log | grep "POST" | cut -d" " -f7 | sort | uniq -c | sort -rn | head'
  assert_commands "cat access.log" 'grep "POST"' 'cut -d" " -f7' "sort" "uniq -c" "sort -rn" "head"
}

# =============================================================================
# Build and test commands
# =============================================================================

@test "real: make commands" {
  run_parse_commands 'make clean && make build'
  assert_commands "make clean" "make build"
}

@test "real: cargo build" {
  run_parse_commands 'cargo build --release'
  assert_commands "cargo build --release"
}

@test "real: cargo test" {
  run_parse_commands 'cargo test -- --nocapture'
  assert_commands "cargo test -- --nocapture"
}

@test "real: go build" {
  run_parse_commands 'go build -o bin/app ./cmd/app'
  assert_commands "go build -o bin/app ./cmd/app"
}

@test "real: go test" {
  run_parse_commands 'go test -v ./...'
  assert_commands "go test -v ./..."
}

@test "real: gradle build" {
  run_parse_commands './gradlew build'
  assert_commands "./gradlew build"
}

@test "real: maven commands" {
  run_parse_commands 'mvn clean install -DskipTests'
  assert_commands "mvn clean install -DskipTests"
}

# =============================================================================
# Shell utilities and system commands
# =============================================================================

@test "real: ls with options" {
  run_parse_commands 'ls -la --color=auto'
  assert_commands "ls -la --color=auto"
}

@test "real: cat file with line numbers" {
  run_parse_commands 'cat -n src/main.rs | head -50'
  assert_commands "cat -n src/main.rs" "head -50"
}

@test "real: wc word count" {
  run_parse_commands 'wc -l src/**/*.py'
  assert_commands "wc -l src/**/*.py"
}

@test "real: tree command" {
  run_parse_commands 'tree -L 2 --dirsfirst'
  assert_commands "tree -L 2 --dirsfirst"
}

@test "real: curl API request" {
  run_parse_commands 'curl -s https://api.example.com/health | jq .'
  assert_commands "curl -s https://api.example.com/health" "jq ."
}

@test "real: curl POST with data" {
  run_parse_commands 'curl -X POST -H "Content-Type: application/json" -d '\''{"key":"value"}'\'' http://localhost:8080/api'
  # Note: The shell parses the single quotes, output has preserved quoting
  assert_commands "curl -X POST -H \"Content-Type: application/json\" -d '{\"key\":\"value\"}' http://localhost:8080/api"
}

@test "real: jq complex query" {
  run_parse_commands 'cat data.json | jq ".items[] | select(.active == true) | .name"'
  assert_commands "cat data.json" 'jq ".items[] | select(.active == true) | .name"'
}

# =============================================================================
# Permission validation for real-world commands
# =============================================================================

@test "permission: git operations with git permission" {
  run_hook_allow 'git status && git diff' '["Bash(git status:*)", "Bash(git diff:*)"]'
  assert_allowed
}

@test "permission: npm operations with npm permission" {
  run_hook_allow 'npm install && npm test' '["Bash(npm:*)"]'
  assert_allowed
}

@test "permission: python script with python3 permission" {
  run_hook_allow 'python3 script.py arg1 arg2' '["Bash(python3:*)"]'
  assert_allowed
}

@test "permission: docker build needs docker permission" {
  run_hook_allow 'docker build -t app .' '["Bash(docker:*)"]'
  assert_allowed
}

@test "permission: complex pipeline needs all permissions" {
  run_hook_allow 'cat file | grep pattern | head -10' '["Bash(cat:*)", "Bash(grep:*)", "Bash(head:*)"]'
  assert_allowed
}

@test "permission: pipeline blocked when one command not permitted" {
  run_hook_block 'cat file | grep pattern | head -10' '["Bash(cat:*)", "Bash(grep:*)"]'
  assert_blocked
}

# =============================================================================
# Complex multi-command scenarios
# =============================================================================

@test "real: check and build pattern" {
  run_parse_commands 'npm run lint && npm test && npm run build'
  assert_commands "npm run lint" "npm test" "npm run build"
}

@test "real: conditional execution" {
  run_parse_commands 'test -f config.json && cat config.json || echo "Not found"'
  assert_commands "test -f config.json" "cat config.json" 'echo "Not found"'
}

@test "real: subshell for directory change" {
  run_parse_commands '(cd /tmp && ls -la)'
  assert_commands "cd /tmp" "ls -la"
}

@test "real: environment setup" {
  run_parse_commands 'export NODE_ENV=test && npm test'
  assert_commands "npm test"
}

