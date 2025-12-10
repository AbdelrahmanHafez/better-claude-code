# Configure the shell Claude uses for Bash commands
# Usage: action_install_shell <claude_dir> <hook_prefix> [shell_path]
action_install_shell() {
  local claude_dir="${1:-}"
  local hook_prefix="${2:-}"
  local shell_path="${3:-}"

  # Default to modern bash if not specified
  if [[ -z "$shell_path" ]]; then
    if ! shell_path=$(find_modern_bash); then
      error "Modern bash (4.4+) not found"
      info "Install with: brew install bash"
      info "Or specify a shell with: --shell /path/to/shell"
      exit 1
    fi
  fi

  init_claude_paths "$claude_dir" "$hook_prefix"

  step "Configuring Claude shell"

  _shell_validate "$shell_path"
  _shell_configure "$shell_path"
}

_shell_validate() {
  local shell_path="$1"

  if [[ ! -x "$shell_path" ]]; then
    error "Shell not found or not executable: $shell_path"
    exit 1
  fi
}

_shell_configure() {
  local shell_path="$1"
  local shell_name
  shell_name=$(basename "$shell_path")

  info "Using shell: $shell_path ($shell_name)"

  local current_shell
  current_shell=$(get_setting '.env.SHELL')

  if [[ "$current_shell" == "$shell_path" ]]; then
    success "Shell already configured to $shell_path"
    return 0
  fi

  if [[ -n "$current_shell" ]]; then
    info "Updating shell from $current_shell to $shell_path"
  else
    info "Setting shell to $shell_path"
  fi

  set_setting '.env.SHELL' "\"$shell_path\""

  success "Claude will now use $shell_name ($shell_path)"
  _shell_print_footer
}

_shell_print_footer() {
  echo ""
  info "This sets the SHELL environment variable in Claude's settings."
  info "Claude will use this shell for all Bash tool executions."
}
