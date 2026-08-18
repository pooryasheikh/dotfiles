# dotfiles

macOS configuration managed with [yadm](https://yadm.io/), whose worktree is `$HOME`.

## Fresh machine

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/pooryasheikh/dotfiles/main/.config/yadm/init.sh)"
```

`init.sh` installs Xcode CLT, Homebrew and yadm, clones this repo, asks whether the
machine is `work` or `personal`, then runs `yadm bootstrap`.

## What bootstrap does

| Step | Action |
|------|--------|
| `brew.sh` | Installs Homebrew, trusts the third-party taps, runs `brew bundle install` |
| `10-oh-my-zsh.sh` | oh-my-zsh, powerlevel10k, `zsh-lazyload`, `zsh-vi-mode` |
| `20-scripts.sh` | Symlinks `~/.config/scripts/*` into `~/.local/bin` |
| `30-tmux.sh` | Clones tpm and installs the plugins declared in `tmux.conf` |
| `40-alacritty-themes.sh` | Clones `alacritty-theme` |
| `50-kubernetes.sh` | krew plus the `ctx`, `ns`, `node-shell` plugins |
| `60-tfenv.sh` | Installs the Terraform version pinned in `.config/tfenv/version` |
| `70-nvim.sh` | `nvim --headless +Lazy! restore` against the tracked `lazy-lock.json` |
| `80-macos.sh` | macOS `defaults` (keyboard, Finder, Dock, screenshots) |
| `90-local.sh` | Creates the machine-local files below and generates this machine's SSH key |

## Work vs personal separation

**This repository is public.** No credential, private key, API token or internal
hostname is tracked. Each machine keeps its own:

| Machine-local file | Purpose | Created by |
|--------------------|---------|-----------|
| `~/.config/git/config.local` | git `user.name` / `user.email`, per-client `includeIf` | `90-local.sh` |
| `~/.config/zsh/local.zsh` | employer-specific PATH, exports, aliases | `90-local.sh` |
| `~/.ssh/conf.d/*.conf` | hosts, jumphosts, identities | `90-local.sh` |
| `~/.ssh/id_ed25519` | a fresh key per machine, never synced | `90-local.sh` |
| `~/.config/k9s/config.yaml` | cluster contexts (k9s writes it itself) | k9s |
| `~/.config/yadm/config` | `local.class`, so the class is not shared | `init.sh` |

`~/.gitignore` is **deny-by-default**: everything is ignored unless explicitly
allowlisted, so a stray `yadm add -A` cannot publish `~/.aws/credentials`,
`~/.ssh/id_*`, `~/.kube/config` or shell history. To track something new:

```bash
yadm add -f <path>       # then add a matching ! rule to ~/.gitignore
```

## Homebrew

`~/.config/brewfile/Brewfile` is hand-curated and installed with native
`brew bundle`. It lists top-level packages only.

> **Do not regenerate it with `brew bundle dump`.** Homebrew 6 will not load
> formulae from untrusted taps, so `dump` and `brew leaves` silently omit every
> third-party-tap entry — `sketchybar` and `borders` included. `brew.sh` runs
> `brew trust --tap` for each of them; edit the Brewfile by hand.

```bash
brew bundle check   --file=~/.config/brewfile/Brewfile --verbose   # what's missing
brew bundle cleanup --file=~/.config/brewfile/Brewfile             # what's extra (dry run)
```

## Layout

```
.config/
├── aerospace/     tiling WM            ├── k9s/          keys/plugins/skins
├── alacritty/     terminal             ├── lazygit/      git TUI
├── aliases/       shell aliases        ├── lf/           file manager
├── brewfile/      Brewfile             ├── neofetch/
├── finicky/       URL router           ├── nvim/         AstroNvim
├── git/           git (+ config.local) ├── presenterm/   terminal slides
├── glab-cli/      aliases only         ├── scripts/      -> ~/.local/bin
├── htop/                               ├── sketchybar/   status bar
├── yadm/          bootstrap            ├── tmux/         (plugins via tpm)
└── zsh/           local.zsh
```

## Notes

- Terminal: Alacritty + tmux. Editor: AstroNvim. WM: AeroSpace + SketchyBar + borders.
- tmux plugins are owned by tpm, not by this repo. They were once broken git
  submodules with no `.gitmodules`, which produced 13 empty directories on clone.
- `git-delta` is wired up as git's pager in `.config/git/config`.
- Terraform comes from `tfenv`, not Homebrew directly.

## References

- [FelixKratz/dotfiles](https://github.com/FelixKratz/dotfiles)
- [ZhongXiLu/dotfiles](https://github.com/ZhongXiLu/dotfiles)
