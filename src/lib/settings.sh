# Claude Code settings.json manipulation helpers

# These get initialized by init_claude_paths()
CLAUDE_DIR=""
CLAUDE_SETTINGS=""
CLAUDE_HOOKS_DIR=""
HOOK_FILE_PREFIX=""

# Track files modified that are managed by chezmoi (used by shell_alias.sh too)
CHEZMOI_MODIFIED_FILES=()

# Check if any chezmoi files were modified
has_chezmoi_modifications() {
  [[ ${#CHEZMOI_MODIFIED_FILES[@]} -gt 0 ]]
}

# --- Initialization (must be called before using other functions) ---

init_claude_paths() {
  # CLAUDE_DIR_OVERRIDE is for testing only (not exposed as CLI flag)
  local custom_dir="${CLAUDE_DIR_OVERRIDE:-}"

  # Check if chezmoi manages ~/.claude
  if [[ -z "$custom_dir" ]] && is_claude_managed_by_chezmoi; then
    CLAUDE_DIR="$(chezmoi source-path)/dot_claude"
    HOOK_FILE_PREFIX="executable_"
    # Track that ~/.claude is managed by chezmoi
    CHEZMOI_MODIFIED_FILES+=("$HOME/.claude")
    info "Detected chezmoi managing ~/.claude"
    info "Installing to: $CLAUDE_DIR"
  else
    CLAUDE_DIR="${custom_dir:-$HOME/.claude}"
    HOOK_FILE_PREFIX=""
  fi

  CLAUDE_SETTINGS="$CLAUDE_DIR/settings.json"
  CLAUDE_HOOKS_DIR="$CLAUDE_DIR/hooks"
}

is_claude_managed_by_chezmoi() {
  # Check if chezmoi is installed
  if ! command -v chezmoi &>/dev/null; then
    return 1
  fi

  # Check if ~/.claude is managed by chezmoi
  chezmoi source-path ~/.claude &>/dev/null
}

get_hook_filename() {
  echo "${HOOK_FILE_PREFIX}auto-approve-allowed-commands.sh"
}

get_hook_filepath() {
  echo "$CLAUDE_HOOKS_DIR/$(get_hook_filename)"
}

# --- Public API (step-down: high-level functions first) ---

set_setting() {
  local jq_path="$1"  # e.g., '.env.SHELL'
  local value="$2"    # JSON value, e.g., '"string"' or '123' or 'true'
  local current new

  current=$(get_settings)
  new=$(echo "$current" | jq "$jq_path = $value")
  write_settings "$new"
}

get_setting() {
  local jq_path="$1"  # e.g., '.env.SHELL'
  get_settings | jq -r "$jq_path // empty"
}

array_contains() {
  local jq_path="$1"  # e.g., '.permissions.allow'
  local value="$2"    # JSON value to check for, e.g., '"Bash(ls:*)"'

  get_settings | jq -e "$jq_path | index($value) != null" &>/dev/null
}

array_add() {
  local jq_path="$1"  # e.g., '.permissions.allow'
  local value="$2"    # JSON value to add, e.g., '"Bash(ls:*)"'
  local current new

  if array_contains "$jq_path" "$value"; then
    return 0
  fi

  current=$(get_settings)
  # First ensure the path exists, then add the value
  new=$(echo "$current" | jq "
    if $jq_path == null then
      $jq_path = []
    else
      .
    end
    | $jq_path += [$value]
    | $jq_path = ($jq_path | unique)
  ")
  write_settings "$new"
}

merge_setting() {
  local jq_path="$1"  # e.g., '.hooks'
  local obj="$2"      # JSON object to merge, e.g., '{"PreToolUse": [...]}'
  local current new

  current=$(get_settings)
  new=$(echo "$current" | jq "$jq_path = (($jq_path // {}) * $obj)")
  write_settings "$new"
}

# --- Directory management ---

ensure_claude_dir() {
  if [[ ! -d "$CLAUDE_DIR" ]]; then
    mkdir -p "$CLAUDE_DIR"
    info "Created $CLAUDE_DIR"
  fi
}

ensure_hooks_dir() {
  ensure_claude_dir
  if [[ ! -d "$CLAUDE_HOOKS_DIR" ]]; then
    mkdir -p "$CLAUDE_HOOKS_DIR"
    info "Created $CLAUDE_HOOKS_DIR"
  fi
}

# --- Low-level settings I/O ---

get_settings() {
  if [[ -f "$CLAUDE_SETTINGS" ]]; then
    cat "$CLAUDE_SETTINGS"
  else
    echo '{}'
  fi
}

write_settings() {
  local json="$1"
  ensure_claude_dir
  echo "$json" | jq '.' > "$CLAUDE_SETTINGS"
}

# --- Hook configuration ---

configure_hook_in_settings() {
  if hook_already_configured; then
    return 0
  fi
  add_hook_to_settings
}

add_hook_to_settings() {
  # Settings always reference the non-prefixed filename at $HOME/.claude
  # (prefix is only for dotfiles managers like chezmoi)
  # shellcheck disable=SC2016
  local new_hook='{"type": "command", "command": "$HOME/.claude/hooks/auto-approve-allowed-commands.sh"}'

  local current new
  current=$(get_settings)

  # Check if a Bash matcher already exists in PreToolUse
  if echo "$current" | jq -e '.hooks.PreToolUse[]? | select(.matcher == "Bash")' &>/dev/null; then
    # Append our hook to the existing Bash matcher's hooks array
    new=$(echo "$current" | jq --argjson hook "$new_hook" '
      .hooks.PreToolUse = [
        .hooks.PreToolUse[] |
        if .matcher == "Bash" then
          .hooks += [$hook]
        else
          .
        end
      ]
    ')
  else
    # No Bash matcher exists, create a new entry
    local hook_entry
    hook_entry=$(jq -n --argjson hook "$new_hook" '{
      "matcher": "Bash",
      "hooks": [$hook]
    }')
    new=$(echo "$current" | jq --argjson entry "$hook_entry" '
      .hooks.PreToolUse = ((.hooks.PreToolUse // []) + [$entry])
    ')
  fi

  write_settings "$new"
}

hook_already_configured() {
  # Check if PreToolUse has a Bash matcher with auto-approve-allowed-commands.sh command
  get_settings | jq -e '
    .hooks.PreToolUse[]?
    | select(.matcher == "Bash")
    | .hooks[]?
    | select(.command | endswith("auto-approve-allowed-commands.sh"))
  ' &>/dev/null
}
