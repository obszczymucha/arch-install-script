#!/usr/bin/env bash

function main() {
  pacman -Syyu --noconfirm \
    ansible \
    aria2 \
    at \
    base \
    base-devel \
    binutils \
    cmus \
    diffutils \
    dos2unix \
    dosfstools \
    encfs \
    expac \
    fastfetch \
    fd \
    ffmpeg \
    fzf \
    git \
    git-crypt \
    git-lfs \
    go \
    gocryptfs \
    icoutils \
    inetutils \
    inotify-tools \
    jq \
    less \
    lsof \
    man \
    mc \
    mkvtoolnix-gui \
    ncdu \
    neovim \
    net-tools \
    nodejs \
    npm \
    openssh \
    pacman-contrib \
    pkg-config \
    python \
    python-pip \
    python-pipx \
    rclone \
    reflector \
    ripgrep \
    rsync \
    rust-src \
    rustup \
    stow \
    svn \
    the_silver_searcher \
    tig \
    tmux \
    tree \
    unzip \
    wget \
    xdg-utils \
    yt-dlp \
    zip \
    zoxide \
    zsh
}

main 
