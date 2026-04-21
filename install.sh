#!/usr/bin/env bash
# install.sh — bootstrap a new machine from this dotfiles repo
#
# Usage:
#   git clone https://github.com/SinghChinmayy/dotfiles.git ~/dotfiles
#   cd ~/dotfiles && bash install.sh

set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="$HOME/.dotfiles-backup/$(date +%Y%m%d_%H%M%S)"

log()    { echo "  $*"; }
success(){ echo "  [ok] $*"; }

# Back up an existing file/dir, then remove it so we can symlink cleanly.
backup_and_remove() {
    local target="$1"
    if [ -e "$target" ] || [ -L "$target" ]; then
        mkdir -p "$BACKUP_DIR"
        cp -r "$target" "$BACKUP_DIR/"
        rm -rf "$target"
        log "Backed up: $target -> $BACKUP_DIR/"
    fi
}

# Create a symlink, backing up whatever was there first.
link() {
    local src="$1" dst="$2"
    backup_and_remove "$dst"
    ln -sf "$src" "$dst"
    success "Linked: $dst -> $src"
}

echo ""
echo "Dotfiles installer"
echo "=================="
echo ""

# ── Shell ──────────────────────────────────────────────────────────────────
echo "[shell]"
link "$DOTFILES/shell/bashrc"  "$HOME/.bashrc"
link "$DOTFILES/shell/profile" "$HOME/.profile"

# ── Git ────────────────────────────────────────────────────────────────────
echo "[git]"
link "$DOTFILES/git/gitconfig" "$HOME/.gitconfig"

# ── Vim ────────────────────────────────────────────────────────────────────
echo "[vim]"
link "$DOTFILES/vim/vimrc" "$HOME/.vimrc"

# ── Tmux ───────────────────────────────────────────────────────────────────
echo "[tmux]"
link "$DOTFILES/tmux/tmux.conf" "$HOME/.tmux.conf"

# ── Neovim ─────────────────────────────────────────────────────────────────
echo "[nvim]"
mkdir -p "$HOME/.config"
link "$DOTFILES/nvim" "$HOME/.config/nvim"

# ── Claude ─────────────────────────────────────────────────────────────────
echo "[claude]"
mkdir -p "$HOME/.claude"
link "$DOTFILES/claude/settings.json" "$HOME/.claude/settings.json"

# ── Bin scripts ────────────────────────────────────────────────────────────
echo "[bin]"
mkdir -p "$HOME/bin"
for script in "$DOTFILES/bin/"*; do
    chmod +x "$script"
    link "$script" "$HOME/bin/$(basename "$script")"
done

# ── tmux plugin manager ────────────────────────────────────────────────────
if [ ! -d "$HOME/.tmux/plugins/tpm" ]; then
    echo "[tpm]"
    git clone https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"
    success "Cloned tmux plugin manager. Open tmux and press prefix + I to install plugins."
fi

echo ""
echo "Done!"
if [ -d "$BACKUP_DIR" ]; then
    echo "Previous configs backed up to: $BACKUP_DIR"
fi
echo ""
echo "Next steps:"
echo "  1. Restart your shell (or: source ~/.bashrc)"
echo "  2. Open nvim — plugins will auto-install via lazy.nvim"
echo "  3. Open tmux and press prefix + I to install tmux plugins"
echo ""
