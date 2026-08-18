#!/usr/bin/env bash
# tpm plus the plugins tmux.conf declares.
#
# These used to be git submodules, which pinned an exact commit per plugin.
# tpm has no pin syntax and always clones the default branch tip, so without
# the PINS list below a new machine gets a different plugin version than an
# existing one -- tmux-tokyo-night is at v7.x upstream while this config is
# written against v1.10.0's option names (@theme_disable_plugins etc.), so an
# unpinned install silently renders a different status bar.
set -euo pipefail

PLUGINS="${XDG_CONFIG_HOME:-$HOME/.config}/tmux/plugins"
TPM="$PLUGINS/tpm"

# "<plugin-dir-name> <tag>" per line. Bash 3.2 safe -- no associative arrays,
# because macOS ships bash 3.2 and this may not run under Homebrew's bash.
PINS="
tmux-tokyo-night v1.10.0
"

if [[ ! -f "$TPM/tpm" ]]; then
    rm -rf "$TPM"
    git clone --depth=1 https://github.com/tmux-plugins/tpm "$TPM"
fi
[[ -f "$TPM/tpm" ]] || { echo "tpm install failed" >&2; exit 1; }

# Installs every `set -g @plugin` from tmux.conf. Needs no running server.
"$TPM/bin/install_plugins" || echo "tpm reported errors; run prefix+I inside tmux" >&2

# Apply version pins.
while read -r name tag; do
    [[ -z "${name:-}" ]] && continue
    dir="$PLUGINS/$name"
    if [[ ! -d "$dir/.git" ]]; then
        echo "  pin: $name not installed, skipping" >&2
        continue
    fi
    current="$(git -C "$dir" describe --tags --exact-match 2>/dev/null || true)"
    if [[ "$current" == "$tag" ]]; then
        echo "  pin: $name already at $tag"
        continue
    fi
    git -C "$dir" fetch --tags --quiet 2>/dev/null || true
    if git -C "$dir" checkout --quiet "$tag" 2>/dev/null; then
        echo "  pin: $name -> $tag"
    else
        echo "  pin: could not check out $tag for $name" >&2
    fi
done <<< "$(printf '%s\n' "$PINS" | sed '/^[[:space:]]*$/d')"

echo "tmux plugins ✅"
