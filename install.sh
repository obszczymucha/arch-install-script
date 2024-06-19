#!/usr/bin/env bash
set -e

HOSTNAME=audio
CITY=Melbourne
COUNTRY=Australia

function log_progress() {
  echo -e "\n"[$(date +"%Y-%m-%d %k:%M:%S")]: "$1" >&2
}

function check_configuration() {
  log_progress "Checking configuration..."

  if [ -z "$COUNTRY" ]; then
    echo "COUNTRY is not defined."
    return 1
  else
    echo "Found COUNTRY set to $COUNTRY"
  fi

  if [ -z "$CITY" ]; then
    echo "CITY is not defined."
    return 1
  else
    echo "Found CITY set to $CITY"
  fi

  echo "Configuration OK."
}

function find_the_fastest_mirror() {
  log_progress "Updating pacman's mirrorlist..."
  pacman -Sy --noconfirm reflector
  eval $(echo "reflector --verbose --country '${COUNTRY}' -l 200 -p http --sort rate --save /etc/pacman.d/mirrorlist")
}

function install_tools() {
  log_progress "Installing the base system..."
  pacman -Sy --noconfirm base base-devel openssh
}

function set_locale() {
  log_progress "Setting locale to UTF-8..."
  sed -i "s/#en_US\.UTF-8 UTF-8/en_US\.UTF-8 UTF-8/g" /etc/locale.gen
  locale-gen
  echo LANG=en_US.UTF-8 > /etc/locale.conf
  export LANG=en_US.UTF-8
}

function set_timezone_and_clock() {
  log_progress "Setting timezone and clock..."
  ln -sf /usr/share/zoneinfo/${COUNTRY}/${CITY} /etc/localtime
  hwclock --systohc --utc
}

function set_hostname() {
  log_progress "Setting hostname..."
  echo ${HOSTNAME} > /etc/hostname
}

function enable_wheel_group() {
  log_progress "Enabling wheel group..."
  local sudoers_file='/etc/sudoers'

  if ! grep -q '%wheel ALL=(ALL) ALL' "$sudoers_file" 2> /dev/null; then
    echo '%wheel ALL=(ALL) ALL' >> "$sudoers_file"
  else
    sed -i '/%wheel ALL=(ALL) ALL/c\%wheel ALL=(ALL) ALL' "$sudoers_file"
  fi
}

function enable_passwordless_sudo_for_bootstrap() {
  log_progress "Adding bootstrap user to sudoers..."
  local sudoers_file='/etc/sudoers'

  if ! grep -q 'bootstrap ALL=(ALL) NOPASSWD: ALL' "$sudoers_file" 2> /dev/null; then
    echo 'bootstrap ALL=(ALL) NOPASSWD: ALL' >> "$sudoers_file"
  fi
}

function create_bootstrap_user() {
  log_progress "Creating bootstrap user for bootstrapping..."
  local password
  password=$(/usr/bin/openssl passwd 'bootstrap')
  groupadd bootstrap
  useradd --password ${password} --comment 'Bootstrap User' --create-home --gid users --groups bootstrap bootstrap
  enable_passwordless_sudo_for_bootstrap
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
}

function install_daemonize() {
  log_progress "Installing daemonize..."
  local aur_dir='/home/bootstrap/.projects/ops/aur'
  local package_dir="$aur_dir/daemonize"
  su bootstrap -c "mkdir -p $aur_dir"
  su bootstrap -c "git clone https://aur.archlinux.org/daemonize.git $package_dir"
  su bootstrap -c "cd $package_dir && makepkg -s --noconfirm"
  rm "$package_dir/"daemonize-debug*.tar.zst
  mv "$package_dir/"*.tar.zst "$package_dir/"daemonize.tar.zst
  pacman -U --noconfirm "$package_dir/daemonize.tar.zst"
}

function add_root_to_sudoers() {
  log_progress "Adding root user to sudoers..."
  local sudoers_file='/etc/sudoers'

  if ! grep -q 'root ALL=(ALL:ALL) ALL' "$sudoers_file" 2> /dev/null; then
    echo 'root ALL=(ALL:ALL) ALL' >> "$sudoers_file"
  fi
}

function enable_systemd() {
  log_progress "Enabling systemd..."
  cp etc/profile.d/00-wsl2-systemd.sh /etc/profile.d/
  chmod +x /etc/profile.d/00-wsl2-systemd.sh
}

function setup_wsl() {
  log_progress "Copying wsl config..."
  cp etc/wsl.conf /etc/
}

function generate_sshd_keys() {
  log_progress "Generating sshd keys..."
  ssh-keygen -t rsa -f /etc/ssh/ssh_host_rsa_key -N ''
  ssh-keygen -t ecdsa -f /etc/ssh/ssh_host_ecdsa_key -N ''
  ssh-keygen -t ed25519 -f /etc/ssh/ssh_host_ed25519_key -N ''
}

function enable_sshd() {
  log_progress "Enabling sshd..."
  systemctl enable sshd.service
  # systemctl start sshd
}

function main() {
  check_configuration
  find_the_fastest_mirror
  install_tools
  set_locale
  set_timezone_and_clock
  set_hostname
  add_root_to_sudoers
  create_bootstrap_user
  # install_daemonize
  setup_wsl
  # enable_systemd
  # enable_sshd
}

main

if [ $? = 0 ]; then
  log_progress "Installation successful!"
else
  log_progress "ERROR: Installation did not complete successfully!"
fi

