# Check and optionally install dependencies
# Usage: action_check_deps
action_check_deps() {
  step "Checking dependencies"

  if check_all_deps; then
    _deps_print_success
    return 0
  fi

  _deps_prompt_install
}

_deps_print_success() {
  echo ""
  success "All dependencies are installed"
}

_deps_prompt_install() {
  echo ""
  warn "Some dependencies are missing"
  echo ""
  read -p "Install missing dependencies? [Y/n] " -n 1 -r
  echo ""

  if [[ $REPLY =~ ^[Nn]$ ]]; then
    error "Cannot continue without dependencies"
    exit 1
  fi

  install_missing_deps
}
