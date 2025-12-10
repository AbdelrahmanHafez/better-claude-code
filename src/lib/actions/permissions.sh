# Add safe command permissions to Claude settings
# Usage: action_install_permissions <claude_dir> [hook_prefix]
action_install_permissions() {
  local claude_dir="${1:-}"
  local hook_prefix="${2:-}"

  init_claude_paths "$claude_dir" "$hook_prefix"

  step "Adding safe command permissions"
  _permissions_print_overview
  _permissions_add
  _permissions_print_footer
}

_permissions_print_overview() {
  info "This adds read-only and safe commands to your allowed permissions."
  info "These commands will auto-approve without prompting."
  echo ""
}

_permissions_add() {
  local added=0
  local skipped=0

  for perm in "${DEFAULT_PERMISSIONS[@]}"; do
    if array_contains '.permissions.allow' "\"$perm\""; then
      ((skipped++)) || true
    else
      array_add '.permissions.allow' "\"$perm\""
      ((added++)) || true
    fi
  done

  if [[ $added -eq 0 ]]; then
    success "All ${#DEFAULT_PERMISSIONS[@]} permissions already configured"
  else
    success "Added $added new permissions ($skipped already existed)"
  fi
}

_permissions_print_footer() {
  echo ""
  info "Permissions are stored in: $CLAUDE_SETTINGS"
}
