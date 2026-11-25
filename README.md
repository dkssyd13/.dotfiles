# Dotfiles

Portable personal configuration for macOS and Omarchy, managed with
[GNU Stow](https://www.gnu.org/software/stow/). Each top-level directory is a
package whose contents mirror paths under `$HOME`.

## New machine

```bash
git clone <this-repository-url> ~/.dotfiles
cd ~/.dotfiles
stow --no-folding -t ~ ghostty nvim tmux vimrc herdr claude   # pick packages
```

On Omarchy, check `AGENTS.md` first: it lists the Omarchy version these
dotfiles were last verified with and the integration points to recheck after
an Omarchy update.

Use `stow -n -v ...` for a dry run and `stow -D ...` to unlink a package.
`--no-folding` links individual files instead of whole directories, so
machine-local files never end up inside the repository. Stow refuses to
overwrite existing files; move them aside first.

Typical packages: macOS `aerospace bin cursor ghostty herdr ideavimrc nvim p10k
tmux vimrc`; Linux `bin claude cursor fcitx5 ghostty herdr hypr ideavimrc nvim
p10k tmux vimrc`.

### Extra steps

- **ghostty**: link the OS-specific config, which is not tracked:
  `ln -sfn linux.conf ~/.config/ghostty/os/current.conf` (or `macos.conf`).
  Machine-specific settings such as `font-size` go in an untracked
  `~/.config/ghostty/local.conf`, which is loaded last.
- **fcitx5** (Omarchy): `omarchy pkg add fcitx5-hangul`.
- **cursor**: the package targets Cursor's config dir, not `$HOME`:
  `stow --no-folding --ignore='extensions.txt|local-keys.sed' -t ~/.config/Cursor cursor`
  (macOS: `-t ~/Library/Application\ Support/Cursor`). Then register the git
  filter: `git config filter.cursor-local.clean 'sed -f cursor/local-keys.sed'`,
  and install extensions with
  `xargs -n1 cursor --install-extension < cursor/extensions.txt`.

The Herdr package tracks only its configuration. Runtime files such as Herdr
sessions, logs, and plugin locks are not tracked and remain machine-local.
Claude Code downloads skills from the claude.ai account into
`~/.claude/skills/synced/`; that directory is not tracked either.

The tracked Claude settings refer to the optional Herdr integration hook through
`$HOME`, so the same settings work on macOS and Omarchy without OS-specific
path changes. Install that hook separately with `herdr integration install
claude` on machines where the integration is wanted.

The `cursor` package links `settings.json` and `keybindings.json` into
`~/Library/Application Support/Cursor/User` on macOS and
`~/.config/Cursor/User` on Linux, then installs any extensions from
`cursor/extensions.txt` that are missing. After adding or removing extensions,
refresh the list with:

```bash
cursor --list-extensions | sort > ~/.dotfiles/cursor/extensions.txt
```

Machine-local Cursor settings (Remote-SSH host platforms, window zoom) stay on
disk but are stripped from commits by a git clean filter. The keys are listed
in `cursor/local-keys.sed`; the `git config` step above registers the filter
in this clone. If `git status` shows `settings.json` as modified while `git diff` is
empty, only local keys changed; `git add` clears it.

After installation on Omarchy, reload Hyprland and check the configuration:

```bash
hyprctl reload
hyprctl configerrors
```

On Omarchy, installing the `fcitx5` dotfiles package also installs
`fcitx5-hangul` with `omarchy pkg add`; its `libhangul` dependency is installed
automatically. The included Fcitx profile enables US and Hangul input; use
Right Alt to switch.

## Neovim

The `nvim` package is a hand-written lazy.nvim config (no LazyVim). The first
start clones the plugins and installs the Mason tools in the background
(pyrefly, ruff, marksman, taplo, lua-language-server, json-lsp, debugpy,
stylua, markdownlint-cli2); `:Lazy` and `:Mason` show progress.

On Omarchy, Neovim creates `~/.config/nvim/lua/plugins/theme.lua` at startup
as a symlink to the current Omarchy theme
(`~/.local/state/omarchy/current/theme/neovim.lua`, or the Omarchy 3 path).
lazy.nvim watches that file, so `omarchy theme set` reloads the colorscheme in
running editors. The link is machine-local and ignored by git. On macOS the
theme is catppuccin macchiato with a transparent background.
