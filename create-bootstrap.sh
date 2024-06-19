#!/usr/bin/env bash
set -e

function check_for_root() {
  if [[ $(whoami) != "root" ]]; then
    echo "This script MUST be run as root." >&2
    exit 1
  fi
}

function main() {
  local working_dir="/tmp/arch-bootstrap"
  rm -rf "$working_dir"
  mkdir -p "$working_dir"

  wget https://mirror.aarnet.edu.au/pub/archlinux/iso/latest/archlinux-bootstrap-x86_64.tar.zst -O "${working_dir}/bootstrap.tar.zst"
  tar --use-compress-program=unzstd -xvf "${working_dir}/bootstrap.tar.zst" -C "${working_dir}"

  local root_dir="${working_dir}/root.x86_64"
  cp etc/wsl.conf "${root_dir}/etc/"
  cp $HOME/.ssh/* "${root_dir}/root/.ssh/"

  sed -Ei '/aarnet\.edu\.au/c\Server = https:\/\/mirror\.aarnet\.edu\.au\/pub\/archlinux\/$repo\/os\/$arch' "${root_dir}/etc/pacman.d/mirrorlist"

  local repo_dir="${root_dir}/root/arch-install-script"
  git clone git@github.com:obszczymucha/arch-install-script.git "${repo_dir}"
  git -C "${repo_dir}" checkout wsl2

  local filename
  filename="Arch-Bootstrap-$(date +%Y%m)01.tar.gz"

  cd "${root_dir}"
  tar -czvf "$filename" *
  mv "$filename" /mnt/i/iNsTaLL

  echo
  echo "$filename was generated successfully at /mnt/i/iNsTaLL." >&2
}

check_for_root
main
