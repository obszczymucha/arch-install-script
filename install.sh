#!/bin/bash

source install.config

set -e

function check_configuration {
  log_progress "Checking configuration..."

  if [ -z "$DESTINATION_DEVICE" ]; then
    echo "DESTINATION_DEVICE is not defined."
    return 1
  else
    echo "Found DESTINATION_DEVICE set to $DESTINATION_DEVICE"
  fi

  if [ -f "parted.config" ]; then
    echo "Found parted configuration file."
  else
    echo "Cannot find parted configuration file."
    return 1
  fi

  echo "Configuration OK."
}

function create_partitions {
  log_progress "Creating partitions..."
  parted ${DESTINATION_DEVICE} < parted.config
}

function format_partitions {
  log_progress "Formatting partitions..."
  mkfs.vfat -F32 ${DESTINATION_DEVICE}1
  mkfs.ext4 -F ${DESTINATION_DEVICE}2
  mkswap ${DESTINATION_DEVICE}3
  swapon ${DESTINATION_DEVICE}3
  mkfs.ext4 -F ${DESTINATION_DEVICE}4
}

function mount_partitions_for_installation {
  log_progress "Mounting partitions for installation..."
  mount ${DESTINATION_DEVICE}2 /mnt
  mkdir -p /mnt/boot
  mount ${DESTINATION_DEVICE}1 /mnt/boot
  mkdir -p /mnt/home
  mount ${DESTINATION_DEVICE}4 /mnt/home
}

function install_the_base_system {
  log_progress "Installing the base system..."
  pacstrap /mnt base base-devel
}

function generate_fstab {
  log_progress "Generating an fstab..."
  genfstab -U -p /mnt >> /mnt/etc/fstab
  cat /mnt/etc/fstab
}

function chroot_install {
  log_progress "Continuing installation in chroot..."
  cp chroot-install.sh /mnt
  cp install.config /mnt
  arch-chroot /mnt /bin/bash chroot-install.sh
  rm -f /mnt/chroot-install.sh /mnt/install.config
}

function run {
  check_configuration
  create_partitions
  format_partitions
  mount_partitions_for_installation
  install_the_base_system
  generate_fstab
  chroot_install
}

run

if [ $? = 0 ]; then
  log_progress "Installation successful!"
else
  log_progress "ERROR: Installation did not complete successfully!"
fi

