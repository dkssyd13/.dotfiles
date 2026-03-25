#!/usr/bin/env bash
input=$(cat)
used_pct=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
model_full=$(echo "$input" | jq -r '.model.display_name // "Unknown Model"')
# Shorten model name: "Claude Opus 4.6" -> "Opus 4.6"
model_name="${model_full#Claude }"
cwd=$(echo "$input" | jq -r '.workspace.current_dir // .cwd // empty')
ide_name=$(echo "$input" | jq -r '.ide.name // empty')
# ANSI colors (using $'...' so variables contain actual escape characters)
RED=$'\033[0;31m'
GREEN=$'\033[38;5;34m'
YELLOW=$'\033[0;33m'
CYAN=$'\033[0;36m'
BOLD=$'\033[1m'
RESET=$'\033[0m'
# Terminal width (default 80 if not available)
term_width=${COLUMNS:-80}
# --- Line 1: Model name + git status ---
# Build git status string if inside a git repo
git_part=""
if [ -n "$cwd" ] && git -C "$cwd" rev-parse --git-dir > /dev/null 2>&1; then
    branch=$(git -C "$cwd" symbolic-ref --short HEAD 2>/dev/null || git -C "$cwd" rev-parse --short HEAD 2>/dev/null)
    staged=0
    unstaged=0
    untracked=0
    while IFS= read -r line; do
        x="${line:0:1}"
        y="${line:1:1}"
        if [ "$x" != " " ] && [ "$x" != "?" ] && [ "$x" != "!" ]; then
            staged=$(( staged + 1 ))
        fi
        if [ "$y" = "M" ] || [ "$y" = "D" ]; then
            unstaged=$(( unstaged + 1 ))
        fi
        if [ "$x" = "?" ] && [ "$y" = "?" ]; then
            untracked=$(( untracked + 1 ))
        fi
    done < <(git -C "$cwd" status --porcelain 2>/dev/null)
    dirty=$(( staged + unstaged + untracked ))
    if [ "$dirty" -eq 0 ]; then
        branch_color="$GREEN"
    else
        branch_color="$YELLOW"
    fi
    git_part="${branch_color}${branch}${RESET}"
    if [ "$staged" -gt 0 ]; then
        git_part="${git_part} ${GREEN}+${staged}${RESET}"
    fi
    if [ "$unstaged" -gt 0 ]; then
        git_part="${git_part} ${YELLOW}~${unstaged}${RESET}"
    fi
    if [ "$untracked" -gt 0 ]; then
        git_part="${git_part} ${RED}?${untracked}${RESET}"
    fi
    git_part=" ${git_part}"
fi
ide_part=""
if [ -n "$ide_name" ]; then
    ide_part=" ${RESET}| ${CYAN}${ide_name}"
fi
printf '%s%s%s%s%s%s\n' "$BOLD" "$CYAN" "$model_name" "$RESET" "$git_part" "${CYAN}${ide_part}${RESET}"
# --- Line 2: Context usage progress bar ---
if [ -n "$used_pct" ]; then
    used_int=$(printf "%.0f" "$used_pct")
else
    used_int=0
fi
# Choose bar color based on threshold
if [ "$used_int" -ge 90 ]; then
    bar_color="$RED"
elif [ "$used_int" -ge 70 ]; then
    bar_color="$YELLOW"
else
    bar_color="$GREEN"
fi
# Build bar: fixed width to match line 1 length
label="${used_int}%"
bar_width=40
filled=$(( used_int * bar_width / 100 ))
if [ "$used_int" -gt 0 ] && [ "$filled" -eq 0 ]; then
    filled=1
fi
empty=$(( bar_width - filled ))
filled_str=""
if [ "$filled" -gt 0 ]; then
    filled_str=$(printf '%0.s█' $(seq 1 $filled))
fi
empty_str=""
if [ "$empty" -gt 0 ]; then
    empty_str=$(printf '%0.s░' $(seq 1 $empty))
fi
printf '%s%s%s%s %s%s%s' "$bar_color" "$filled_str" "$RESET" "$empty_str" "$bar_color" "$label" "$RESET"
