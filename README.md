# Dotfiles

Portable personal configuration for macOS and Omarchy. Packages mirror paths
under `$HOME`; `install.sh` creates symlinks and backs up conflicting files.

## New machine

```bash
git clone <this-repository-url> ~/.dotfiles
cd ~/.dotfiles
./install.sh --dry-run
./install.sh
```

The default package set is chosen for macOS or Linux. To install selected
packages, pass their directory names, for example:

```bash
./install.sh ghostty nvim tmux
```

On Linux, the defaults also install the tracked Claude and Herdr configuration.
Runtime files such as Herdr sessions, logs, and plugin locks are not tracked and
remain machine-local.

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
in `cursor/local-keys.sed`; `install.sh cursor` registers the filter in this
clone. If `git status` shows `settings.json` as modified while `git diff` is
empty, only local keys changed; `git add` clears it.

Use `--all` only when you really want packages for every operating system.
Conflicting files are moved to `~/.local/state/dotfiles-backups/<timestamp>/`.

After installation on Omarchy, reload Hyprland and check the configuration:

```bash
hyprctl reload
hyprctl configerrors
```

On Omarchy, installing the `fcitx5` dotfiles package also installs
`fcitx5-hangul` with `omarchy pkg add`; its `libhangul` dependency is installed
automatically. The included Fcitx profile enables US and Hangul input; use
Right Alt to switch.
