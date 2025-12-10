# Dependency checking and installation helpers

# Minimum bash version required (for mapfile -d, nameref, etc.)
MIN_BASH_MAJOR=4
MIN_BASH_MINOR=4

# --- Public API ---

check_all_deps() {
  local all_ok=true

  check_homebrew_status || all_ok=false
  check_bash_status || all_ok=false
  check_jq_status || all_ok=false
  check_shfmt_status || all_ok=false

  $all_ok
}

install_missing_deps() {
  require_homebrew || return 1

  install_bash_if_needed || return 1
  install_if_missing jq || return 1
  install_if_missing shfmt || return 1

  success "All dependencies installed"
}

# --- Status checks ---

check_homebrew_status() {
  if has_homebrew; then
    success "Homebrew $(brew --version 2>/dev/null | head -1 | sed 's/Homebrew //')"
    return 0
  else
    error "Homebrew not found"
    return 1
  fi
}

check_bash_status() {
  if bash_version_ok; then
    success "bash $(get_bash_version) (>= $MIN_BASH_MAJOR.$MIN_BASH_MINOR required)"
    return 0
  fi

  local modern_bash
  if modern_bash=$(find_modern_bash); then
    success "bash $MIN_BASH_MAJOR.$MIN_BASH_MINOR+ found at $modern_bash"
    return 0
  fi

  error "bash $(get_bash_version) (need >= $MIN_BASH_MAJOR.$MIN_BASH_MINOR)"
  return 1
}

check_jq_status() {
  if command_exists jq; then
    success "jq $(jq --version 2>/dev/null | sed 's/jq-//')"
    return 0
  else
    error "jq not found"
    return 1
  fi
}

check_shfmt_status() {
  if command_exists shfmt; then
    success "shfmt $(shfmt --version 2>/dev/null)"
    return 0
  else
    error "shfmt not found"
    return 1
  fi
}

# --- Homebrew installation ---

require_homebrew() {
  if has_homebrew; then
    return 0
  fi

  prompt_homebrew_install
}

prompt_homebrew_install() {
  error "Homebrew is required but not installed"
  echo ""
  info "Homebrew is the package manager we'll use to install dependencies."
  info "Installation may take several minutes."
  echo ""

  read -p "Install Homebrew now? [Y/n] " -n 1 -r
  echo ""

  if [[ $REPLY =~ ^[Nn]$ ]]; then
    print_manual_homebrew_instructions
    return 1
  fi

  install_homebrew
}

install_homebrew() {
  info "Installing Homebrew (this may take a few minutes)..."
  echo ""

  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

  if ! has_homebrew; then
    error "Homebrew installation failed"
    print_manual_homebrew_instructions
    return 1
  fi

  success "Homebrew installed successfully"
}

print_manual_homebrew_instructions() {
  echo ""
  echo "To install Homebrew manually, run:"
  # shellcheck disable=SC2016
  echo '  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"'
  echo ""
  echo "Then run this installer again."
}

# --- Package installation ---

install_bash_if_needed() {
  if bash_version_ok || find_modern_bash &>/dev/null; then
    return 0
  fi
  brew_install bash
}

install_if_missing() {
  local package="$1"
  if command_exists "$package"; then
    return 0
  fi
  brew_install "$package"
}

brew_install() {
  local package="$1"
  info "Installing $package via Homebrew..."
  brew install "$package"
}

# --- Bash version helpers ---

bash_version_ok() {
  local bash_path="${1:-bash}"
  local version major minor

  # shellcheck disable=SC2016
  version=$("$bash_path" -c 'echo "${BASH_VERSINFO[0]}.${BASH_VERSINFO[1]}"' 2>/dev/null) || return 1
  major="${version%%.*}"
  minor="${version#*.}"

  ((major > MIN_BASH_MAJOR)) || ((major == MIN_BASH_MAJOR && minor >= MIN_BASH_MINOR))
}

get_bash_version() {
  local bash_path="${1:-bash}"
  # shellcheck disable=SC2016
  "$bash_path" -c 'echo "${BASH_VERSINFO[0]}.${BASH_VERSINFO[1]}"' 2>/dev/null
}

find_modern_bash() {
  local candidates=(
    "/opt/homebrew/bin/bash"
    "/usr/local/bin/bash"
    "/bin/bash"
  )

  for bash_path in "${candidates[@]}"; do
    if [[ -x "$bash_path" ]] && bash_version_ok "$bash_path"; then
      echo "$bash_path"
      return 0
    fi
  done

  return 1
}

# --- Low-level utilities ---

has_homebrew() {
  command_exists brew
}

command_exists() {
  command -v "$1" &>/dev/null
}
