#!/usr/bin/env bash

function main() {
  pacman -Syyu --noconfirm \
    base \
    base-devel \
    ansible \
    aria2 \
    at \
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
    git-lfs \
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
