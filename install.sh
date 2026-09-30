#!/usr/bin/env bash
set -euo pipefail

repo_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
dry_run=false
backup_root="${XDG_STATE_HOME:-$HOME/.local/state}/dotfiles-backups/$(date +%Y%m%d-%H%M%S)"

case "${OSTYPE:-}" in
  darwin*) default_packages=(aerospace bin cursor ghostty herdr ideavimrc nvim p10k tmux vimrc) ;;
  linux*) default_packages=(bin claude cursor fcitx5 ghostty herdr hypr ideavimrc nvim p10k tmux vimrc) ;;
  *) default_packages=(bin ghostty ideavimrc nvim p10k tmux vimrc) ;;
esac

usage() {
  printf 'Usage: %s [--dry-run] [--all | PACKAGE ...]\n' "${0##*/}"
  printf 'Default packages for this OS: %s\n' "${default_packages[*]}"
}

packages=()
while (($#)); do
  case "$1" in
    --dry-run) dry_run=true ;;
    --all)
      mapfile -t packages < <(find "$repo_dir" -mindepth 1 -maxdepth 1 -type d \
        ! -name .git ! -name .agents ! -name .codex ! -name skills ! -name wallpapers -printf '%f\n' | sort)
      ;;
    -h|--help) usage; exit 0 ;;
    --*) printf 'Unknown option: %s\n' "$1" >&2; usage >&2; exit 2 ;;
    *) packages+=("$1") ;;
  esac
  shift
done
((${#packages[@]})) || packages=("${default_packages[@]}")

run() {
  if $dry_run; then printf '+ '; printf '%q ' "$@"; printf '\n'; else "$@"; fi
}

# Most packages mirror $HOME; Cursor keeps its user config in an OS-specific place.
target_root() {
  case "$1:${OSTYPE:-}" in
    cursor:darwin*) printf '%s\n' "$HOME/Library/Application Support/Cursor" ;;
    cursor:*) printf '%s\n' "${XDG_CONFIG_HOME:-$HOME/.config}/Cursor" ;;
    *) printf '%s\n' "$HOME" ;;
  esac
}

if [[ "${OSTYPE:-}" == linux* ]]; then
  for package in "${packages[@]}"; do
    if [[ "$package" == fcitx5 ]]; then
      command -v omarchy >/dev/null || {
        printf 'The fcitx5 package requires Omarchy on Linux.\n' >&2
        exit 1
      }
      run omarchy pkg add fcitx5-hangul
      break
    fi
  done
fi

for package in "${packages[@]}"; do
  package_dir="$repo_dir/$package"
  [[ -d "$package_dir" ]] || { printf 'Unknown package: %s\n' "$package" >&2; exit 2; }
  root=$(target_root "$package")

  while IFS= read -r -d '' source; do
    relative=${source#"$package_dir"/}
    target="$root/$relative"
    target_dir=${target%/*}

    run mkdir -p "$target_dir"
    if [[ -L "$target" && "$(readlink -f -- "$target")" == "$source" ]]; then
      printf 'ok      %s\n' "$target"
      continue
    fi
    if [[ -e "$target" || -L "$target" ]]; then
      backup="$backup_root/$relative"
      run mkdir -p "${backup%/*}"
      run mv -- "$target" "$backup"
      printf 'backup  %s -> %s\n' "$target" "$backup"
    fi
    run ln -s -- "$source" "$target"
    printf 'link    %s -> %s\n' "$target" "$source"
  done < <(find "$package_dir" -type f ! -name '.DS_Store' ! -name '*.bak' ! -name '*.bak.*' \
    ! -path "$repo_dir/cursor/extensions.txt" ! -path "$repo_dir/cursor/local-keys.sed" -print0)

  if [[ "$package" == cursor ]]; then
    run git -C "$repo_dir" config filter.cursor-local.clean 'sed -f cursor/local-keys.sed'
    printf 'ok      git filter cursor-local\n'
    if command -v cursor >/dev/null; then
      while IFS= read -r extension; do
        [[ -n "$extension" ]] && run cursor --install-extension "$extension" >/dev/null
      done < <(comm -23 <(sort "$package_dir/extensions.txt") <(cursor --list-extensions | sort))
      printf 'ok      Cursor extensions\n'
    else
      printf 'skip    Cursor extensions (cursor CLI not found)\n'
    fi
  fi
done

printf '\nInstalled: %s\n' "${packages[*]}"
$dry_run || printf 'Backups (if any): %s\n' "$backup_root"
