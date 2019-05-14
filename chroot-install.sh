#!/bin/bash

source install.config

set -e

PASSWORD=$(/usr/bin/openssl passwd -crypt 'bootstrap')

function set_locale {
  log_progress "Setting locale to UTF-8..."
  sed -i "s/#en_US\.UTF-8 UTF-8/en_US\.UTF-8 UTF-8/g" /etc/locale.gen
  locale-gen
  echo LANG=en_US.UTF-8 > /etc/locale.conf
  export LANG=en_US.UTF-8
}

function set_timezone_and_clock {
  log_progress "Setting timezone and clock..."
  ln -sf /usr/share/zoneinfo/${COUNTRY}/${CITY} /etc/localtime
  hwclock --systohc --utc
}

function set_hostname {
  log_progress "Setting hostname..."
  echo ${HOSTNAME} > /etc/hostname
}

function get_network_interface {
  IFS=': ' read -a TOKENS <<< `ip link | grep "state UP"`; echo "${TOKENS[1]}"
}

function enable_dhcp {
  log_progress "Enabling DHCP..."
  local NETWORK_INTERFACE=$(get_network_interface)

  if [ -z "$NETWORK_INTERFACE" ]; then
    echo "Could not find an active network interface!"
    return 1
  else
    echo "Found active network interface: ${NETWORK_INTERFACE}"
  fi

  systemctl enable dhcpcd@${NETWORK_INTERFACE}.service
}

function install_grub_bootloader {
  log_progress "Installing bootloader..."
  pacman -S --noconfirm grub os-prober
  grub-install --recheck ${DESTINATION_DEVICE}
  grub-mkconfig -o /boot/grub/grub.cfg
}

function get_partuuid {
  DISK=$1
  REGEX="\"(.*)\""
  BLKID_OUTPUT=$(blkid $DISK -s PARTUUID)

  [[ $BLKID_OUTPUT =~ $REGEX ]]

  if [ -z "$BASH_REMATCH" ]; then
    echo "Unable to extract PARTUUID for ${DISK}!"
    exit 1
  fi

  echo ${BASH_REMATCH[1]}
}

function install_uefi_bootloader {
  log_progress "Installing bootloader..."
  local PARTUUID=$(get_partuuid ${DESTINATION_DEVICE}2)

  pacman -S --noconfirm dosfstools intel-ucode
  bootctl --path=/boot install
  echo "title       Arch Linux" > /boot/loader/entries/arch.conf
  echo "linux       /vmlinuz-linux" >> /boot/loader/entries/arch.conf
  echo "initrd      /intel-ucode.img" >> /boot/loader/entries/arch.conf
  echo "initrd      /initramfs-linux.img" >> /boot/loader/entries/arch.conf
  echo "options     root=PARTUUID=${PARTUUID} quiet loglevel=0 systemd.show_status=0 rd.udev.log_priority=0 vga=current rw ipv6.disable=1" >> /boot/loader/entries/arch.conf
  echo "timeout 0" > /boot/loader/loader.conf
  echo "default arch" >> /boot/loader/loader.conf
}

function install_and_enable_sshd {
  log_progress "Installing and enabling sshd..."
  pacman -S --noconfirm openssh
  systemctl enable sshd.service
  systemctl start sshd
}

function create_bootstrap_user_for_bootstrapping {
  log_progress "Creating bootstrap user for bootstrapping..."
  groupadd bootstrap
  useradd --password ${PASSWORD} --comment 'Bootstrap User' --create-home --gid users --groups bootstrap bootstrap
  echo 'Defaults env_keep += "SSH_AUTH_SOCK"' > /etc/sudoers.d/10_bootstrap
  echo 'bootstrap ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers.d/10_bootstrap
  chmod 0440 /etc/sudoers.d/10_bootstrap
  install --directory --owner=bootstrap --group=users --mode=0700 /home/bootstrap/.ssh
  ssh-keygen -P '' -f /home/bootstrap/.ssh/bootstrap
  chown bootstrap:users /home/bootstrap/.ssh/bootstrap
  chmod 0600 /home/bootstrap/.ssh/bootstrap
  chown bootstrap:users /home/bootstrap/.ssh/bootstrap.pub
  chmod 0600 /home/bootstrap/.ssh/bootstrap.pub
  cat /home/bootstrap/.ssh/bootstrap.pub > /home/bootstrap/.ssh/authorized_keys
  chown bootstrap:users /home/bootstrap/.ssh/authorized_keys
  chmod 0600 /home/bootstrap/.ssh/authorized_keys
  mkdir /root/.ssh
  chmod 0700 /root/.ssh
  cp /home/bootstrap/.ssh/bootstrap /root/.ssh/
}

function install_and_enable_sshd {
  log_progress "Installing and enabling sshd..."
  pacman -S --noconfirm openssh
  systemctl enable sshd.service
  systemctl start sshd
}

function install_python2_for_ansible_bootstrapping {
  log_progress "Installing python2 for ansible bootstrapping..."
  pacman -S --noconfirm python2
}

function install_ansible {
  log_progress "Installing ansible..."
  pacman -S --noconfirm ansible
}

function install_wifi_essentials {
  log_progress "Installing wifi essentials..."
  pacman -S --noconfirm dialog wpa_supplicant
}

function run {
  set_locale
  set_timezone_and_clock
  set_hostname
  enable_dhcp
  install_uefi_bootloader
  install_and_enable_sshd
  create_bootstrap_user_for_bootstrapping
  install_python2_for_ansible_bootstrapping
  install_wifi_essentials
  install_ansible
}

run

if [ $? = 0 ]; then
  log_progress "Installation successful! Type 'reboot' and enjoy your Arch Linux!"
else
  log_progress "ERROR: Installation did not complete successfully!"
fi

