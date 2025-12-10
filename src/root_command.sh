main() {
  local claude_dir="${args['--claude-dir']:-}"
  local hook_prefix="${args['--hook-prefix']:-}"

  init_claude_paths "$claude_dir" "$hook_prefix"

  _all_print_banner
  _all_print_overview

  _all_step_deps
  _all_step_shell
  _all_step_hook
  _all_step_permissions

  _all_print_completion
}

# --- Steps (quiet versions for bundled install) ---

_all_step_deps() {
  step "Step 1/4: Dependencies"

  if check_all_deps; then
    success "All dependencies present"
    return 0
  fi

  warn "Some dependencies missing"
  read -p "Install missing dependencies? [Y/n] " -n 1 -r
  echo ""

  if [[ $REPLY =~ ^[Nn]$ ]]; then
    error "Cannot continue without dependencies"
    exit 1
  fi

  install_missing_deps || exit 1
}

_all_step_shell() {
  step "Step 2/4: Shell configuration"

  local shell_path="${args['--shell']:-}"

  # Default to modern bash if not specified
  if [[ -z "$shell_path" ]]; then
    if ! shell_path=$(find_modern_bash); then
      error "Modern bash (4.4+) not found"
      info "Install with: brew install bash"
      info "Or specify a shell with: --shell /path/to/shell"
      exit 1
    fi
  fi

  local shell_name
  shell_name=$(basename "$shell_path")

  if [[ ! -x "$shell_path" ]]; then
    error "Shell not found or not executable: $shell_path"
    info "Use --shell to specify a valid shell path"
    exit 1
  fi

  local current_shell
  current_shell=$(get_setting '.env.SHELL')

  if [[ "$current_shell" == "$shell_path" ]]; then
    success "Shell already set to $shell_name"
    return 0
  fi

  info "Configuring Claude to use $shell_name ($shell_path)"
  set_setting '.env.SHELL' "\"$shell_path\""
  success "Shell configured"
}

_all_step_hook() {
  step "Step 3/4: Installing allow-piped hook"

  local hook_file
  hook_file=$(get_hook_filepath)

  ensure_hooks_dir

  if [[ -f "$hook_file" ]]; then
    info "Hook already exists, updating..."
  fi

  generate_hook_script "$CLAUDE_DIR" > "$hook_file"
  chmod +x "$hook_file"
  success "Hook installed"

  configure_hook_in_settings
}

_all_step_permissions() {
  step "Step 4/4: Adding safe permissions"

  local added=0

  for perm in "${DEFAULT_PERMISSIONS[@]}"; do
    if ! array_contains '.permissions.allow' "\"$perm\""; then
      array_add '.permissions.allow' "\"$perm\""
      ((added++)) || true
    fi
  done

  if [[ $added -eq 0 ]]; then
    success "All permissions already configured"
  else
    success "Added $added safe command permissions"
  fi
}

# --- Output ---

_all_print_banner() {
  echo ""
  echo "╔════════════════════════════════════════════╗"
  echo "║       Better Claude Code Installer         ║"
  echo "╚════════════════════════════════════════════╝"
  echo ""
}

_all_print_overview() {
  info "This installer will:"
  echo "  1. Check/install dependencies (bash 4.4+, shfmt, jq)"
  echo "  2. Configure your preferred shell"
  echo "  3. Install the allow-piped hook"
  echo "  4. Add safe command permissions"
  echo ""
}

_all_print_completion() {
  echo ""
  echo "╔════════════════════════════════════════════╗"
  echo "║            Installation Complete!          ║"
  echo "╚════════════════════════════════════════════╝"
  echo ""
  success "Better Claude Code is now configured!"
  echo ""
  info "Changes made to: $CLAUDE_SETTINGS"
  info "Hook installed to: $(get_hook_filepath)"
  echo ""
  info "Start a new Claude Code session to apply changes."
}

main
