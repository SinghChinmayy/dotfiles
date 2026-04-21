#!/usr/bin/env bash
# install.sh — set up or update dotfiles on this machine
#
# Fresh install:
#   git clone https://github.com/SinghChinmayy/dotfiles.git ~/dotfiles
#   bash ~/dotfiles/install.sh
#
# Already installed — just run it again to pull updates and re-link.

set -euo pipefail

DOTFILES="$HOME/dotfiles"
BACKUP_DIR="$HOME/.dotfiles-backup/$(date +%Y%m%d_%H%M%S)"

# ── Helpers ────────────────────────────────────────────────────────────────

info()    { echo "  $*"; }
ok()      { echo "  [ok] $*"; }
warn()    { echo "  [!!] $*"; }

backup_and_remove() {
    local target="$1"
    # skip if it's already one of our own symlinks
    if [ -L "$target" ] && [[ "$(readlink "$target")" == "$DOTFILES"* ]]; then
        return
    fi
    if [ -e "$target" ] || [ -L "$target" ]; then
        mkdir -p "$BACKUP_DIR"
        cp -r "$target" "$BACKUP_DIR/"
        rm -rf "$target"
        info "Backed up: $target"
    fi
}

link() {
    local src="$1" dst="$2"
    backup_and_remove "$dst"
    ln -sf "$src" "$dst"
    ok "$(basename "$dst") -> $src"
}

# ── Already installed? Pull updates first ──────────────────────────────────

if [ -d "$DOTFILES/.git" ]; then
    # check if any managed symlink already points into ~/dotfiles
    already_linked=false
    [ -L "$HOME/.gitconfig" ] && [[ "$(readlink "$HOME/.gitconfig")" == "$DOTFILES"* ]] && already_linked=true

    if $already_linked; then
        echo ""
        echo "Dotfiles already set up on this machine."
        read -p "Pull latest changes from origin and re-link? (Y/n): " update
        case $update in
            "" | [Yy]*)
                echo ""
                echo "[update]"
                cd "$DOTFILES"
                git fetch origin
                BRANCH=$(git rev-parse --abbrev-ref HEAD)
                BEHIND=$(git rev-list --count HEAD..origin/"$BRANCH" 2>/dev/null || echo 0)
                if [ "$BEHIND" -gt 0 ]; then
                    info "Pulling $BEHIND new commit(s)..."
                    git pull --rebase origin "$BRANCH"
                else
                    info "Already up to date."
                fi
                ;;
            [Nn]*)
                echo "Skipping update, re-linking only."
                ;;
            *)
                echo "Invalid input, skipping update."
                ;;
        esac
    fi
fi

echo ""
echo "Linking dotfiles"
echo "================"

# ── Git ────────────────────────────────────────────────────────────────────
if [ -f "$DOTFILES/git/gitconfig" ]; then
    echo "[git]"
    link "$DOTFILES/git/gitconfig" "$HOME/.gitconfig"
fi

# ── Shell ──────────────────────────────────────────────────────────────────
if [ -f "$DOTFILES/shell/bashrc" ]; then
    echo "[shell]"
    link "$DOTFILES/shell/bashrc"  "$HOME/.bashrc"
    link "$DOTFILES/shell/profile" "$HOME/.profile"
fi

# ── Vim ────────────────────────────────────────────────────────────────────
if [ -f "$DOTFILES/vim/vimrc" ]; then
    echo "[vim]"
    link "$DOTFILES/vim/vimrc" "$HOME/.vimrc"
fi

# ── Neovim ─────────────────────────────────────────────────────────────────
if [ -d "$DOTFILES/nvim" ]; then
    echo "[nvim]"
    mkdir -p "$HOME/.config"
    link "$DOTFILES/nvim" "$HOME/.config/nvim"
fi

# ── Tmux ───────────────────────────────────────────────────────────────────
if [ -f "$DOTFILES/tmux/tmux.conf" ]; then
    echo "[tmux]"
    link "$DOTFILES/tmux/tmux.conf" "$HOME/.tmux.conf"
    if [ ! -d "$HOME/.tmux/plugins/tpm" ]; then
        info "Installing tmux plugin manager..."
        git clone https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"
        info "Open tmux and press prefix + I to install plugins."
    fi
fi

# ── Claude ─────────────────────────────────────────────────────────────────
if [ -f "$DOTFILES/claude/settings.json" ]; then
    echo "[claude]"
    mkdir -p "$HOME/.claude"
    link "$DOTFILES/claude/settings.json" "$HOME/.claude/settings.json"
fi

# ── Bin scripts ────────────────────────────────────────────────────────────
if [ -d "$DOTFILES/bin" ] && [ -n "$(ls -A "$DOTFILES/bin")" ]; then
    echo "[bin]"
    mkdir -p "$HOME/bin"
    for script in "$DOTFILES/bin/"*; do
        chmod +x "$script"
        link "$script" "$HOME/bin/$(basename "$script")"
    done
fi

echo ""
echo "Done!"
if [ -d "$BACKUP_DIR" ]; then
    echo "Previous configs backed up to: $BACKUP_DIR"
fi
echo ""
echo "Next steps:"
echo "  source ~/.bashrc"
echo ""
