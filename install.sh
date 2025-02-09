#!/bin/bash -eu

cd "$(dirname ${BASH_SOURCE[0]})"
DOTFILES_DIR=$(readlink -f .)
COMMON_DIR=$(readlink -f ./common)
HOST_DIR=$(readlink -f ./hosts/$(hostname))
echo ${HOST_DIR}
mkdir -p ${HOST_DIR}

# ~/.bash_profile
COMMON_BASH_PROFILE=${COMMON_DIR}/bash_profile
HOST_BASH_PROFILE=${HOST_DIR}/bash_profile
if [ ! -f ${HOST_BASH_PROFILE} ]; then
    cp ${HOME}/.bash_profile ${HOST_BASH_PROFILE} || echo "source ${COMMON_BASH_PROFILE}" >${HOST_BASH_PROFILE}
fi
ln -snf ${HOST_BASH_PROFILE} ${HOME}/.bash_profile

# ~/.bashrc
COMMON_BASHRC=${COMMON_DIR}/bashrc
HOST_BASHRC=${HOST_DIR}/bashrc
if [ ! -f ${HOST_BASHRC} ]; then
    cp ${HOME}/.bashrc ${HOST_BASHRC} || echo "source ${COMMON_BASHRC}" >${HOST_BASHRC}
fi
ln -snf ${HOST_BASHRC} ${HOME}/.bashrc

ln -snf ${COMMON_DIR}/vimrc ~/.vimrc
ln -snf ${COMMON_DIR}/tmux.conf ~/.tmux.conf

ls --color=always -lah ${HOME} | grep ${DOTFILES_DIR}

# nvim
PATH_REAL_LOCAL_NVIM_INIT=${HOST_DIR}/init.lua
if [ ! -f $PATH_REAL_LOCAL_NVIM_INIT ]; then
    if [ -f ~/.config/nvim/init.lua ]; then
        cp ~/.config/nvim/init.lua $PATH_REAL_LOCAL_NVIM_INIT
    elif [ -f ~/.vimrc ]; then
        cp ~/.vimrc $PATH_REAL_LOCAL_NVIM_INIT
    else
        touch $PATH_REAL_LOCAL_NVIM_INIT
    fi
fi
mkdir -p "${HOME}/.config/nvim/"
ln -snf $PATH_REAL_LOCAL_NVIM_INIT ~/.config/nvim/init.lua
ls -la ~/.config/nvim/init.lua

echo "Dotfiles successfully installed!"
