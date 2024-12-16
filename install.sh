#!/bin/bash

# dotfilesのディレクトリ
DOTFILES_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/dotfiles"
BACKUP_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/backup"

# バックアップ関数
backup_and_link() {
    local source_file="$1"
    local target_file="$2"

    # すでにシンボリックリンクが存在する場合は何もしない
    if [ -L "$target_file" ]; then
        return
    fi

    # 既存のファイルが存在する場合はバックアップ
    if [ -f "$target_file" ] || [ -d "$target_file" ]; then
        mkdir -p "$BACKUP_DIR/$(dirname "${target_file#$HOME/}")"
        mv "$target_file" "$BACKUP_DIR/$(dirname "${target_file#$HOME/}")"
    fi

    # シンボリックリンクの作成
    ln -sf "$source_file" "$target_file"
}

# シンボリックリンクの作成
backup_and_link "$DOTFILES_DIR/zshrc" "$HOME/.zshrc"
backup_and_link "$DOTFILES_DIR/zprofile" "$HOME/.zprofile"
backup_and_link "$DOTFILES_DIR/bash/bashrc" "$HOME/.bashrc"
backup_and_link "$DOTFILES_DIR/bash/bash_profile" "$HOME/.bash_profile"
backup_and_link "$DOTFILES_DIR/commit_template" "$HOME/.commit_template"
backup_and_link "$DOTFILES_DIR/gitignore_global" "$HOME/.gitignore_global"

# Neovimの設定
mkdir -p "$HOME/.config/nvim"
backup_and_link "$DOTFILES_DIR/config/nvim/init.vim" "$HOME/.config/nvim/init.vim"

echo "Dotfiles successfully installed!"
