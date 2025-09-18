#!/usr/bin/env bash
source install.config
set -eu
trap 'log_progress "ERROR: Installation did not complete successfully!"' ERR

check_configuration() {
  log_progress "Checking configuration..."

  if [ -z "$DESTINATION_DEVICE" ]; then
    echo "DESTINATION_DEVICE is not defined."
    return 1
  else
    echo "Found DESTINATION_DEVICE set to $DESTINATION_DEVICE"
  fi

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

  if [ -f "parted.config" ]; then
    echo "Found parted configuration file."
  else
    echo "Cannot find parted configuration file."
    return 1
  fi

  echo "Configuration OK."
}

create_partitions() {
  log_progress "Creating partitions..."
  parted "${DESTINATION_DEVICE}" < parted.config
}

format_partitions() {
  log_progress "Formatting partitions..."
  mkfs.vfat -F32 "${DESTINATION_DEVICE}p1"
  mkfs.vfat -F32 "${DESTINATION_DEVICE}p2"
  mkswap "${DESTINATION_DEVICE}p3"
  swapon "${DESTINATION_DEVICE}p3"
  mkfs.ext4 -F "${DESTINATION_DEVICE}p4"
  mkfs.ext4 -F "${DESTINATION_DEVICE}p5"
  mkfs.ext4 -F "${DESTINATION_DEVICE}p6"
}

mount_partitions_for_installation() {
  log_progress "Mounting partitions for installation..."
  mount "${DESTINATION_DEVICE}p4" /mnt
  mkdir -p /mnt/efi
  mount "${DESTINATION_DEVICE}p1" /mnt/efi
  mkdir -p /mnt/boot
  mount "${DESTINATION_DEVICE}p2" /mnt/boot
  mkdir -p /mnt/home
  mount "${DESTINATION_DEVICE}p5" /mnt/home
}

find_the_fastest_mirror() {
  pacman -Sy --noconfirm reflector
  reflector --verbose --country "${COUNTRY}" -l 200 -p http --sort rate --save /etc/pacman.d/mirrorlist
}

install_the_base_system() {
  log_progress "Installing the base system..."
  pacstrap /mnt base base-devel linux linux-firmware
}

generate_fstab() {
  log_progress "Generating an fstab..."
  genfstab -U -p /mnt >> /mnt/etc/fstab
  cat /mnt/etc/fstab
}

chroot_install() {
  log_progress "Continuing installation in chroot..."
  cp chroot-install.sh /mnt
  cp install.config /mnt
  arch-chroot /mnt /bin/bash chroot-install.sh
  rm -f /mnt/chroot-install.sh /mnt/install.config
}

main() {
  check_configuration
  create_partitions
  format_partitions
  mount_partitions_for_installation
  find_the_fastest_mirror
  install_the_base_system
  generate_fstab
  chroot_install
  log_progress "Installation successful!"
}

main "$@"

