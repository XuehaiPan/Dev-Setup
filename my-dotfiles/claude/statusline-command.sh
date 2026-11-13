#!/usr/bin/env bash
# Claude Code status line — two-line session overview.
# Layout (sections separated by dim │):
#   Line 1: (env) project@branch(:cwd_rel@cwd_branch) │ model [effort] │ HH:MM:SS
#   Line 2: diff:+N/-M │ ctx:N% │ 5h:N%/♻TTL 7d:N%/♻TTL │ in:X out:Y cache:Z

# Guard: require bash (not sh/dash/zsh)
# shellcheck disable=SC2292
[ -n "${BASH_VERSION:-}" ] || exit 0

set -euo pipefail

# Resolve command paths — empty means unavailable
JQ="$(command -v jq 2>/dev/null || true)"
GIT="$(command -v git 2>/dev/null || true)"
PYTHON="$(command -v python3 2>/dev/null || true)"
BC="$(command -v bc 2>/dev/null || true)"

# Guard: jq is required to parse the input JSON
[[ -n "${JQ}" ]] || exit 0

input="$(cat)"

# ---------------------------------------------------------------------------
# Helper: format a raw token/number into K or M suffix, one decimal place.
# ---------------------------------------------------------------------------
fmt_tokens() {
    local n="${1}"
    # Strip any decimal part jq may emit (e.g. 12300.0 → 12300)
    n="$(printf '%.0f' "${n}" 2>/dev/null || echo "${n}")"
    if [[ -z "${BC}" ]]; then
        printf '%s' "${n}"
        return
    fi
    if [[ "${n}" -ge 1000000 ]] 2>/dev/null; then
        local m
        m="$(echo "scale=1; ${n} / 1000000" | "${BC}")"
        printf '%.1fM' "${m}"
    elif [[ "${n}" -ge 1000 ]] 2>/dev/null; then
        local k
        k="$(echo "scale=1; ${n} / 1000" | "${BC}")"
        printf '%.1fK' "${k}"
    else
        printf '%s' "${n}"
    fi
}

# ANSI helpers
DIM='\033[2m'
RESET='\033[0m'
RED='\033[31m'
GREEN='\033[32m'
YELLOW='\033[33m'
BLUE='\033[34m'
MAGENTA='\033[35m'
CYAN='\033[36m'
WHITE='\033[37m'
BLINK='\033[5m'
SEP="${DIM}│${RESET}"

# ---------------------------------------------------------------------------
# Helper: format seconds into a compact countdown (e.g. 3.5d, 1d5h, 5.4h, 2h13m, 45m).
# ---------------------------------------------------------------------------
fmt_countdown() {
    local secs="${1}"
    if [[ "${secs}" -le 0 ]] 2>/dev/null; then
        printf 'now'
        return
    fi
    local d="$((secs / 86400))"
    local h="$(((secs % 86400) / 3600))"
    local m="$(((secs % 3600) / 60))"
    if [[ "${d}" -ge 3 ]]; then
        printf '%d.%dd' "${d}" "$((h * 10 / 24))"
    elif [[ "${d}" -gt 0 ]]; then
        printf '%dd%dh' "${d}" "${h}"
    elif [[ "${h}" -ge 5 ]]; then
        printf '%d.%dh' "${h}" "$((m * 10 / 60))"
    elif [[ "${h}" -gt 0 ]]; then
        printf '%dh%dm' "${h}" "${m}"
    else
        printf '%dm' "${m}"
    fi
}

# ---------------------------------------------------------------------------
# Helper: format a single rate-limit entry — e.g. "5h:64%/♻45m"
# Args: <label> <used_pct> <resets_at>
# Prints the colored+countdown string; empty if used_pct is empty.
# ---------------------------------------------------------------------------
fmt_rate_section() {
    local label="${1}" used="${2}" resets="${3}"
    [[ -n "${used}" ]] || return 0
    local rem="$((100 - "$(printf '%.0f' "${used}")"))"
    local color="${WHITE}"
    if [[ "${rem}" -le 15 ]]; then
        color="${BLINK}${RED}"
    elif [[ "${rem}" -le 25 ]]; then
        color="${RED}"
    elif [[ "${rem}" -le 50 ]]; then
        color="${YELLOW}"
    fi
    local countdown=""
    if [[ -n "${resets}" ]]; then
        local ttl="$((resets - now_epoch))"
        if [[ "${ttl}" -gt 0 ]] 2>/dev/null; then
            countdown="${RESET}${DIM}/♻$(fmt_countdown "${ttl}")${RESET}"
        fi
    fi
    printf '%b' "${color}${label}:${rem}%${countdown}${RESET}"
}

# ---------------------------------------------------------------------------
# Helper: resolve git branch for a directory
# ---------------------------------------------------------------------------
git_branch() {
    [[ -n "${GIT}" ]] || return 0
    local dir="${1}"
    if "${GIT}" -C "${dir}" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        "${GIT}" -C "${dir}" --no-optional-locks symbolic-ref --short HEAD 2>/dev/null ||
            "${GIT}" -C "${dir}" --no-optional-locks rev-parse --short HEAD 2>/dev/null ||
            true
    fi
}
git_toplevel() {
    [[ -n "${GIT}" ]] || return 0
    "${GIT}" -C "${1}" --no-optional-locks rev-parse --show-toplevel 2>/dev/null || true
}
relpath() {
    [[ -n "${PYTHON}" ]] || return 1
    "${PYTHON}" -c "import os, sys; print(os.path.relpath(sys.argv[1], sys.argv[2]))" \
        "${1}" "${2}" 2>/dev/null
}

# ===========================================================================
# Data extraction (ordered to match assembly)
# ===========================================================================

read -r now_epoch now_time < <(date '+%s %H:%M:%S')
home_dir="${HOME:-$(eval echo ~)}"

# --- Line 1 --------------------------------------------------------------

# 1a. Python virtual environment / conda environment
env_display=""
if [[ -n "${CONDA_DEFAULT_ENV:-}" ]]; then
    env_display="${CONDA_DEFAULT_ENV}"
elif [[ -n "${VIRTUAL_ENV_PROMPT:-}" ]]; then
    env_display="${VIRTUAL_ENV_PROMPT}"
elif [[ -n "${VIRTUAL_ENV:-}" ]]; then
    env_display="$(basename "${VIRTUAL_ENV}")"
fi

# 1b. Project dir + current dir + git branches
cwd="$(echo "${input}" | "${JQ}" -r '.workspace.current_dir // .cwd // empty')"
cwd="${cwd:-$(pwd)}"
project_dir="$(echo "${input}" | "${JQ}" -r '.workspace.project_dir // empty')"
project_dir="${project_dir:-${cwd}}"
dir_display="${project_dir/#${home_dir}/'~'}"
cwd_suffix=""
if [[ "${cwd}" != "${project_dir}" ]]; then
    cwd_rel="$(relpath "${cwd}" "${project_dir}" || echo "${cwd/#${home_dir}/'~'}")"
    cwd_suffix="${RESET}${WHITE}:${RESET}${CYAN}${cwd_rel}"
fi
branch="$(git_branch "${project_dir}")"
if [[ "${cwd}" != "${project_dir}" ]]; then
    proj_repo="$(git_toplevel "${project_dir}")"
    cwd_repo="$(git_toplevel "${cwd}")"
    if [[ "${cwd_repo}" != "${proj_repo}" ]]; then
        cwd_branch="$(git_branch "${cwd}")"
        if [[ -n "${cwd_branch}" ]]; then
            cwd_suffix="${cwd_suffix}${RESET}${WHITE}@${RESET}${YELLOW}${cwd_branch}"
        fi
    fi
fi

# 1c. Model display name + optional reasoning effort
model="$(echo "${input}" | "${JQ}" -r '.model.display_name // empty')"
effort="$(echo "${input}" | "${JQ}" -r '.effortLevel // .effort_level // empty')"
effort="${effort:-${CLAUDE_CODE_EFFORT_LEVEL:-}}"
model_display=""
if [[ -n "${model}" ]]; then
    if [[ -n "${effort}" ]]; then
        model_display="${model} ${RESET}[${effort}]"
    else
        model_display="${model}"
    fi
fi

# --- Line 2 --------------------------------------------------------------

# 2a. Git diff stats
diff_add=""
diff_del=""
if [[ -n "${GIT}" ]] && "${GIT}" -C "${project_dir}" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    diff_stat="$("${GIT}" -C "${project_dir}" --no-optional-locks diff --shortstat 2>/dev/null || true)"
    if [[ -n "${diff_stat}" ]]; then
        diff_add="$(echo "${diff_stat}" | sed -n 's/.* \([0-9]*\) insertion.*/\1/p')"
        diff_del="$(echo "${diff_stat}" | sed -n 's/.* \([0-9]*\) deletion.*/\1/p')"
    fi
fi

# 2b. Context used %
used_pct="$(echo "${input}" | "${JQ}" -r '.context_window.used_percentage // empty')"

# 2c. Rate limits (5-hour and 7-day) — shown as remaining
five_used="$(echo "${input}" | "${JQ}" -r '.rate_limits.five_hour.used_percentage // empty')"
five_resets="$(echo "${input}" | "${JQ}" -r '.rate_limits.five_hour.resets_at // empty')"
week_used="$(echo "${input}" | "${JQ}" -r '.rate_limits.seven_day.used_percentage // empty')"
week_resets="$(echo "${input}" | "${JQ}" -r '.rate_limits.seven_day.resets_at // empty')"

# 2d. Token totals (in / out / cache)
total_in="$(echo "${input}" | "${JQ}" -r '.context_window.total_input_tokens // empty')"
total_out="$(echo "${input}" | "${JQ}" -r '.context_window.total_output_tokens // empty')"
in_fmt=""
out_fmt=""
if [[ -n "${total_in}" ]] && [[ "${total_in}" != "0" ]]; then
    in_fmt="$(fmt_tokens "${total_in}")"
fi
if [[ -n "${total_out}" ]] && [[ "${total_out}" != "0" ]]; then
    out_fmt="$(fmt_tokens "${total_out}")"
fi
cache_create="$(echo "${input}" | "${JQ}" -r '.context_window.current_usage.cache_creation_input_tokens // 0')"
cache_read="$(echo "${input}" | "${JQ}" -r '.context_window.current_usage.cache_read_input_tokens // 0')"
cache_total="$(("$(printf '%.0f' "${cache_create}" 2>/dev/null || echo 0)" + "$(printf '%.0f' "${cache_read}" 2>/dev/null || echo 0)"))"
cache_fmt=""
if [[ "${cache_total}" -gt 0 ]]; then
    cache_fmt="$(fmt_tokens "${cache_total}")"
fi

# ===========================================================================
# Assembly — print each section only when it has content, separated by │
# ===========================================================================
first=1
print_section() {
    local color="${1}"
    local text="${2}"
    if [[ ${first} -eq 0 ]]; then
        printf ' %b ' "${SEP}"
    fi
    printf "${RESET}${color}%b${RESET}" "${text}"
    first=0
}

# --- Line 1: identity & session -------------------------------------------

# 1a: (env) project_dir@branch(:cwd_rel@cwd_branch)
dir_section=""
if [[ -n "${env_display}" ]]; then
    dir_section="${GREEN}(${env_display})${RESET} "
fi
dir_section="${dir_section}${CYAN}${dir_display}"
if [[ -n "${branch}" ]]; then
    dir_section="${dir_section}${RESET}${WHITE}@${RESET}${YELLOW}${branch}"
fi
dir_section="${dir_section}${cwd_suffix}"
print_section "" "${dir_section}"

# 1b: model [effort]
if [[ -n "${model_display}" ]]; then
    print_section "${GREEN}" "${model_display}"
fi

# 1c: local time
print_section "${DIM}" "${now_time}"

# --- Line 2: metrics -----------------------------------------------------
printf '\n'
first=1

# 2a: git diff stats (+N/-M)
diff_section=""
if [[ -n "${diff_add}" ]]; then
    diff_section="${GREEN}+${diff_add}${RESET}"
fi
if [[ -n "${diff_del}" ]]; then
    diff_section="${diff_section}${diff_section:+/}${RED}-${diff_del}${RESET}"
fi
if [[ -n "${diff_section}" ]]; then
    print_section "${WHITE}" "diff:${diff_section}"
fi

# 2b: context used %
ctx_section=""
if [[ -n "${used_pct}" ]]; then
    ctx_section="ctx:$(printf '%.0f' "${used_pct}")%"
fi
if [[ -n "${ctx_section}" ]]; then
    print_section "${MAGENTA}" "${ctx_section}"
fi

# 2c: rate limits (remaining % + countdown to reset)
five_fmt="$(fmt_rate_section '5h' "${five_used}" "${five_resets}")"
week_fmt="$(fmt_rate_section '7d' "${week_used}" "${week_resets}")"
rate_section="${five_fmt}${week_fmt:+${five_fmt:+ }${week_fmt}}"
if [[ -n "${rate_section}" ]]; then
    print_section "" "${rate_section}"
fi

# 2d: token totals (in / out / cache)
tok_parts=""
if [[ -n "${in_fmt}" ]] || [[ -n "${out_fmt}" ]]; then
    tok_parts="in:${in_fmt:-0} out:${out_fmt:-0}"
fi
if [[ -n "${cache_fmt}" ]]; then
    if [[ -n "${tok_parts}" ]]; then
        tok_parts="${tok_parts} ${RESET}cache:${cache_fmt}"
    else
        tok_parts="${RESET}cache:${cache_fmt}"
    fi
fi
if [[ -n "${tok_parts}" ]]; then
    print_section "${BLUE}" "${tok_parts}"
fi
