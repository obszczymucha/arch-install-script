#!/bin/bash

source install.config
PASSWORD=$(/usr/bin/openssl passwd -crypt 'vagrant')

function set_locale {
  log_progress "Setting locale to UTF-8..."
  sed -i "s/#en_US\.UTF-8 UTF-8/en_US\.UTF-8 UTF-8/g" /etc/locale.gen && \
  locale-gen && \
  echo LANG=en_US.UTF-8 > /etc/locale.conf && \
  export LANG=en_US.UTF-8
}

function set_timezone_and_clock {
  log_progress "Setting timezone and clock..."
  ln -sf /usr/share/zoneinfo/Europe/Dublin /etc/localtime
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

function install_bootloader {
  log_progress "Installing bootloader..."
  pacman -S --noconfirm grub os-prober
  grub-install --recheck ${DESTINATION_DEVICE}
  grub-mkconfig -o /boot/grub/grub.cfg
}

function create_vagrant_user_for_bootstrapping {
  log_progress "Creating vagrant user for bootstrapping..."
  groupadd vagrant && \
  useradd --password ${PASSWORD} --comment 'Vagrant User' --create-home --gid users --groups vagrant vagrant && \
  echo 'Defaults env_keep += "SSH_AUTH_SOCK"' > /etc/sudoers.d/10_vagrant && \
  echo 'vagrant ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers.d/10_vagrant && \
  chmod 0440 /etc/sudoers.d/10_vagrant && \
  install --directory --owner=vagrant --group=users --mode=0700 /home/vagrant/.ssh && \
  curl --output /home/vagrant/.ssh/authorized_keys --location https://raw.github.com/mitchellh/vagrant/master/keys/vagrant.pub && \
  chown vagrant:users /home/vagrant/.ssh/authorized_keys && \
  chmod 0600 /home/vagrant/.ssh/authorized_keys
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

function run {
  set_locale && \
  set_timezone_and_clock && \
  set_hostname && \
  enable_dhcp && \
  install_bootloader && \
  create_vagrant_user_for_bootstrapping && \
  install_and_enable_sshd && \
  install_python2_for_ansible_bootstrapping
}

run

if [ $? = 0 ]; then
  log_progress "Installation successful! Type 'reboot' and enjoy your Arch Linux!"
else
  log_progress "ERROR: Installation did not complete successfully!"
fi

