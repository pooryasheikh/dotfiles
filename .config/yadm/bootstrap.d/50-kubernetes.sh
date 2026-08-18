#!/usr/bin/env bash
# krew and the kubectl plugins referenced by .zshrc / .aliases (alias ctx).
set -euo pipefail

command -v kubectl >/dev/null 2>&1 || { echo "kubectl missing, skipping krew"; exit 0; }

KREW_ROOT="${KREW_ROOT:-$HOME/.krew}"
export PATH="$KREW_ROOT/bin:$PATH"

if ! command -v kubectl-krew >/dev/null 2>&1; then
    tmp="$(mktemp -d)"
    trap 'rm -rf "$tmp"' EXIT
    OS="$(uname | tr '[:upper:]' '[:lower:]')"
    ARCH="$(uname -m | sed -e 's/x86_64/amd64/' -e 's/\(arm\)\(64\)\?.*/arm64/')"
    KREW="krew-${OS}_${ARCH}"
    curl -fsSLo "$tmp/$KREW.tar.gz" \
        "https://github.com/kubernetes-sigs/krew/releases/latest/download/$KREW.tar.gz"
    tar zxvf "$tmp/$KREW.tar.gz" -C "$tmp"
    "$tmp/$KREW" install krew
fi

for plugin in ctx ns node-shell; do
    kubectl krew list 2>/dev/null | grep -qx "$plugin" || kubectl krew install "$plugin"
done

echo "krew + kubectl plugins ✅"
