# Default safe Bash permissions to add

# These are read-only or safe commands that Claude can run without user approval
# shellcheck disable=SC2034  # Used by permissions_command.sh and all_command.sh
DEFAULT_PERMISSIONS=(
  # Basic file operations (read-only)
  "Bash(cat:*)"
  "Bash(head:*)"
  "Bash(tail:*)"
  "Bash(less:*)"
  "Bash(more:*)"

  # File info
  "Bash(ls:*)"
  "Bash(file:*)"
  "Bash(stat:*)"
  "Bash(wc:*)"
  "Bash(du:*)"
  "Bash(df:*)"

  # Search and find
  "Bash(find:*)"
  "Bash(fd:*)"
  "Bash(grep:*)"
  "Bash(rg:*)"
  "Bash(awk:*)"
  "Bash(sed:*)"

  # Text processing
  "Bash(sort:*)"
  "Bash(uniq:*)"
  "Bash(cut:*)"
  "Bash(tr:*)"
  "Bash(column:*)"
  "Bash(fold:*)"
  "Bash(nl:*)"
  "Bash(paste:*)"
  "Bash(rev:*)"
  "Bash(tee:*)"

  # Path utilities
  "Bash(pwd:*)"
  "Bash(dirname:*)"
  "Bash(basename:*)"
  "Bash(realpath:*)"
  "Bash(readlink:*)"
  "Bash(which:*)"
  "Bash(type:*)"

  # System info
  "Bash(echo:*)"
  "Bash(date:*)"
  "Bash(cal:*)"
  "Bash(uname:*)"
  "Bash(hostname:*)"
  "Bash(whoami:*)"
  "Bash(id:*)"
  "Bash(env:*)"
  "Bash(printenv:*)"
  "Bash(locale:*)"
  "Bash(uptime:*)"

  # Git (read-only operations)
  "Bash(git status:*)"
  "Bash(git diff:*)"
  "Bash(git log:*)"
  "Bash(git show:*)"
  "Bash(git branch:*)"
  "Bash(git tag:*)"
  "Bash(git remote:*)"
  "Bash(git ls-files:*)"
  "Bash(git ls-tree:*)"
  "Bash(git blame:*)"
  "Bash(git rev-parse:*)"
  "Bash(git rev-list:*)"
  "Bash(git describe:*)"
  "Bash(git config --get:*)"
  "Bash(git config --list:*)"
  "Bash(git stash list:*)"
  "Bash(git fetch:*)"

  # JSON/data processing
  "Bash(jq:*)"

  # Checksums
  "Bash(md5:*)"
  "Bash(md5sum:*)"
  "Bash(shasum:*)"

  # Binary inspection
  "Bash(hexdump:*)"
  "Bash(xxd:*)"
  "Bash(od:*)"
  "Bash(strings:*)"

  # Process info (read-only)
  "Bash(ps:*)"
  "Bash(top -l 1:*)"

  # Other tools
  "Bash(tree:*)"
  "Bash(bat:*)"
  "Bash(eza:*)"
  "Bash(exa:*)"
  "Bash(fzf:*)"
  "Bash(seq:*)"
  "Bash(expr:*)"
  "Bash(test:*)"
  "Bash(xargs:*)"
  "Bash(man:*)"
  "Bash(tldr:*)"
  "Bash(shfmt:*)"
)
