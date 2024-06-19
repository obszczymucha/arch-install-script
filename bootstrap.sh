#!/usr/bin/env bash
set -e

CITY=Melbourne
COUNTRY=Australia
HOSTNAME=audio

# This is a state file this script utilises.
# It contains a log of steps that were performed, so they don't have to be
# repeated. If you need to repeate a step, remove the that corresponts to the
# step from this file.
STATE_FILE='.state'

function timed_info() {
  echo -e "\n"[$(date +"%Y-%m-%d %k:%M:%S")]: "$1" >&2
}

function info() {
  echo "$@" >&2
}

function check_configuration() {
  timed_info "Checking configuration..."

  if [ -z "$COUNTRY" ]; then
    info "COUNTRY is not defined."
    return 1
  else
    info "Found COUNTRY set to $COUNTRY"
  fi

  if [ -z "$CITY" ]; then
    info "CITY is not defined."
    return 1
  else
    info "Found CITY set to $CITY"
  fi

  info "Configuration OK."
}

function step_executed() {
  if [[ $# == 0 ]]; then return 1; fi

  if ! grep -Eq "^$@$" "$STATE_FILE" 2>&1 >/dev/null; then
    return 1
  else
    return 0
  fi
}

function mark_step_as_executed() {
  echo "$@" >> "$STATE_FILE"
}

function initialize_arch_keyring() {
  local step="initialize_arch_key_ring"
  if $(step_executed "$step"); then return; fi

  timed_info "Initializing Arch keyring..."
  pacman-key --init
  pacman-key --populate archlinux

  mark_step_as_executed "$step"
}

function find_the_fastest_mirror() {
  timed_info "Updating pacman's mirrorlist..."
  pacman -Sy --noconfirm reflector
  reflector --verbose --country "${COUNTRY}" -l 200 -p http --sort rate --save /etc/pacman.d/mirrorlist
}

function install_tools() {
  timed_info "Installing/updating tools..."
  source pacman.sh
}

function set_locale() {
  local step="set_locale"
  if $(step_executed "$step"); then return; fi

  timed_info "Setting locale to UTF-8..."
  sed -i "s/#en_US\.UTF-8 UTF-8/en_US\.UTF-8 UTF-8/g" /etc/locale.gen
  locale-gen
  echo LANG=en_US.UTF-8 > /etc/locale.conf
  export LANG=en_US.UTF-8

  mark_step_as_executed "$step"
}

function set_timezone_and_clock() {
  local step="set_timezone_and_clock"
  if $(step_executed "$step"); then return; fi

  timed_info "Setting timezone and clock..."
  ln -sf /usr/share/zoneinfo/${COUNTRY}/${CITY} /etc/localtime
  hwclock --systohc --utc

  mark_step_as_executed "$step"
}

function set_hostname() {
  local step="set_hostname"
  if $(step_executed "$step"); then return; fi

  timed_info "Setting hostname..."
  echo ${HOSTNAME} > /etc/hostname

  mark_step_as_executed "$step"
}

# Dunno if this is still needed.
function enable_wheel_group() {
  local step="enable_wheel_group"
  if $(step_executed "$step"); then return; fi

  timed_info "Enabling wheel group..."
  local sudoers_file='/etc/sudoers'

  if ! grep -q '%wheel ALL=(ALL) ALL' "$sudoers_file" 2> /dev/null; then
    echo '%wheel ALL=(ALL) ALL' >> "$sudoers_file"
  else
    sed -i '/%wheel ALL=(ALL) ALL/c\%wheel ALL=(ALL) ALL' "$sudoers_file"
  fi

  mark_step_as_executed "$step"
}

function add_root_user_to_sudoers() {
  local step="add_root_user_to_sudoers"
  if $(step_executed "$step"); then return; fi

  timed_info "Adding root user to sudoers..."
  local sudoers_file='/etc/sudoers'

  if ! grep -q 'root ALL=(ALL:ALL) ALL' "$sudoers_file" 2> /dev/null; then
    echo 'root ALL=(ALL:ALL) ALL' >> "$sudoers_file"
  fi

  mark_step_as_executed "$step"
}

function add_bootstrap_user_to_sudoers() {
  local step="add_bootstrap_user_to_sudoers"
  if $(step_executed "$step"); then return; fi

  timed_info "Adding bootstrap user to sudoers..."
  local sudoers_file='/etc/sudoers'

  if ! grep -q 'bootstrap ALL=(ALL) NOPASSWD: ALL' "$sudoers_file" 2> /dev/null; then
    echo 'bootstrap ALL=(ALL) NOPASSWD: ALL' >> "$sudoers_file"
  fi

  mark_step_as_executed "$step"
}

function create_bootstrap_user() {
  local step="create_bootstrap_user"
  if $(step_executed "$step"); then return; fi

  timed_info "Creating bootstrap user for Ansible bootstrapping..."
  local password
  password=$(/usr/bin/openssl passwd 'bootstrap')
  groupadd bootstrap
  useradd --password ${password} --comment 'Bootstrap User' --create-home --gid users --groups bootstrap bootstrap
  add_bootstrap_user_to_sudoers
  install --directory --owner=bootstrap --group=users --mode=0700 /home/bootstrap/.ssh
  ssh-keygen -P '' -f /home/bootstrap/.ssh/bootstrap
  chown bootstrap:users /home/bootstrap/.ssh/bootstrap
  chmod 0600 /home/bootstrap/.ssh/bootstrap
  chown bootstrap:users /home/bootstrap/.ssh/bootstrap.pub
  chmod 0600 /home/bootstrap/.ssh/bootstrap.pub
  cat /home/bootstrap/.ssh/bootstrap.pub > /home/bootstrap/.ssh/authorized_keys
  chown bootstrap:users /home/bootstrap/.ssh/authorized_keys
  chmod 0600 /home/bootstrap/.ssh/authorized_keys
  mkdir -p /root/.ssh
  chown root:root /root/.ssh
  chmod 0700 /root/.ssh
  cp /home/bootstrap/.ssh/bootstrap /root/.ssh/

  mark_step_as_executed "$step"
}

# TODO: check if we still need this.
function generate_sshd_keys() {
  timed_info "Generating sshd keys..."
  ssh-keygen -t rsa -f /etc/ssh/ssh_host_rsa_key -N ''
  ssh-keygen -t ecdsa -f /etc/ssh/ssh_host_ecdsa_key -N ''
  ssh-keygen -t ed25519 -f /etc/ssh/ssh_host_ed25519_key -N ''
}

# TODO: check if we still need this.
function enable_sshd() {
  local step="enable_sshd"
  if $(step_executed "$step"); then return; fi

  timed_info "Enabling sshd..."
  systemctl enable sshd.service
  systemctl start sshd

  mark_step_as_executed "$step"
}

function clone_dotfiles() {
  local step="clone_dotfiles"
  if $(step_executed "$step"); then return; fi

  timed_info "TODO: Cloning dotfiles..."

  # mark_step_as_executed "$step"
}

function clone_nvim_config() {
  local step="clone_nvim_config"
  if $(step_executed "$step"); then return; fi

  timed_info "TODO: Cloning dotfiles..."

  # mark_step_as_executed "$step"
}

function main() {
  check_configuration
  initialize_arch_keyring
  find_the_fastest_mirror
  install_tools
  set_locale
  set_timezone_and_clock
  set_hostname
  # add_root_to_sudoers
  # create_bootstrap_user
  # enable_sshd
  clone_dotfiles
  clone_nvim_config
}

main

if [ $? = 0 ]; then
  timed_info "Installation successful!"
else
  timed_info "ERROR: Something went wrong!"
fi

