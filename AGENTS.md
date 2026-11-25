# Agent instructions

## Before installing on Omarchy

Last verified with Omarchy **4.5.0-3**.

Run `omarchy version` first. If it differs, do not stow right away: use the
Omarchy skill to check that these dotfiles still integrate with the installed
Omarchy (theme, fonts, hooks, Hyprland), report what changed to the user, and
only then install. Afterwards, update the version above.

## Where these dotfiles differ from Omarchy defaults

- Files are stow symlinks. Omarchy commands that rewrite a config in place
  (`sed -i`, `jq` + `mv`) replace the link with a plain file; check links after.
- Ghostty's font is in `os/linux.conf`, not `config`. The font-set hook
  `hypr/.config/omarchy/hooks/font-set.d/ghostty-dotfiles` handles it.
- Neovim's `lua/plugins/omarchy.lua` loads on every OS and must declare every
  plugin used by Omarchy's theme `neovim.lua` files, so `lazy-lock.json` stays
  the same on macOS and Linux.
