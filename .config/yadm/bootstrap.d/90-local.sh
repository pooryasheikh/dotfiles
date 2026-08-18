#!/usr/bin/env bash
# Creates the machine-local, deliberately-untracked files that keep the work
# and personal laptops separate, and generates this machine's own SSH key.
set -euo pipefail

CFG="${XDG_CONFIG_HOME:-$HOME/.config}"
CLASS="$(yadm config --get local.class 2>/dev/null || echo unknown)"

# --- git identity -----------------------------------------------------------
# .config/git/config includes this file; it never enters the repo.
GIT_LOCAL="$CFG/git/config.local"
if [[ ! -f "$GIT_LOCAL" ]]; then
    mkdir -p "$(dirname "$GIT_LOCAL")"
    printf 'Full name for git commits on this machine: '
    read -r git_name
    printf 'Email for git commits on this machine: '
    read -r git_email
    cat > "$GIT_LOCAL" <<GITEOF
# Machine-local git identity for the '$CLASS' machine. Not tracked by yadm.
[user]
	name = ${git_name}
	email = ${git_email}
GITEOF
    echo "  wrote $GIT_LOCAL"
fi

# --- shell overrides --------------------------------------------------------
ZSH_LOCAL="$CFG/zsh/local.zsh"
if [[ ! -f "$ZSH_LOCAL" ]]; then
    mkdir -p "$(dirname "$ZSH_LOCAL")"
    cat > "$ZSH_LOCAL" <<'ZSHEOF'
# Machine-local shell config, sourced last by .zshrc. Not tracked by yadm.
# Put employer-specific PATH entries, exports and aliases here.
ZSHEOF
    echo "  wrote $ZSH_LOCAL"
fi

# --- ssh --------------------------------------------------------------------
# .ssh/config Includes this directory; host topology stays off the public repo.
mkdir -p "$HOME/.ssh/conf.d"
chmod 700 "$HOME/.ssh" "$HOME/.ssh/conf.d"
if ! compgen -G "$HOME/.ssh/conf.d/*.conf" >/dev/null; then
    cat > "$HOME/.ssh/conf.d/00-local.conf" <<'SSHEOF'
# Machine-local SSH hosts. Not tracked by yadm.
# Example:
# Host jumphost
#     HostName 10.0.0.1
#     User me
#     IdentityFile ~/.ssh/id_ed25519
SSHEOF
    chmod 600 "$HOME/.ssh/conf.d/00-local.conf"
    echo "  wrote ~/.ssh/conf.d/00-local.conf"
fi

# Each machine gets its own key -- keys are never synced between laptops.
KEY="$HOME/.ssh/id_ed25519"
if [[ ! -f "$KEY" ]]; then
    ssh-keygen -t ed25519 -C "${CLASS}-$(hostname -s)-$(date +%Y%m)" -f "$KEY" -N ""
    echo "  generated $KEY -- add this public key to GitHub/GitLab:"
    cat "$KEY.pub"
fi

echo "Machine-local config ✅"
