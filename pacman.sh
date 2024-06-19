#!/usr/bin/env bash

function main() {
  pacman -Syyu --noconfirm \
    base \
    base-devel \
    openssh \

    less
}

main
