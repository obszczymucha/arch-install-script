#!/bin/bash

source install.config

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

function run {
  set_locale && \
  set_timezone_and_clock && \
  set_hostname && \
  enable_dhcp && \
  install_bootloader
}

run

if [ $? = 0 ]; then
  log_progress "Installation successful!"
else
  log_progress "ERROR: Installation did not complete successfully!"
fi

