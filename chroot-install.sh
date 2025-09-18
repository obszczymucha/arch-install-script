#!/usr/bin/env bash
source install.config
set -e
trap 'log_progress "ERROR: Installation did not complete successfully!"' ERR

PASSWORD=$(/usr/bin/openssl passwd -1 "bootstrap")

set_locale() {
  log_progress "Setting locale to UTF-8..."
  sed -i "s/#en_US\.UTF-8 UTF-8/en_US\.UTF-8 UTF-8/g" /etc/locale.gen
  locale-gen
  echo LANG=en_US.UTF-8 > /etc/locale.conf
  export LANG=en_US.UTF-8
}

set_timezone_and_clock() {
  log_progress "Setting timezone and clock..."
  ln -sf "/usr/share/zoneinfo/${COUNTRY}/${CITY}" /etc/localtime
  hwclock --systohc --utc
}

set_hostname() {
  log_progress "Setting hostname..."
  echo ${HOSTNAME} > /etc/hostname
}

get_network_interface() {
  ip link | grep "state UP" | cut -d: -f2 | tr -d ' '
}

enable_dhcp() {
  log_progress "Enabling DHCP..."
  local network_interface
  network_interface=$(get_network_interface)

  if [ -z "$network_interface" ]; then
    echo "Could not find an active network interface!"
    return 1
  else
    echo "Found active network interface: ${network_interface}"
  fi

  systemctl enable dhcpcd@${network_interface}.service
}

install_grub_bootloader() {
  log_progress "Installing bootloader..."
  pacman -S --noconfirm grub os-prober
  grub-install --recheck "${DESTINATION_DEVICE}"
  grub-mkconfig -o /boot/grub/grub.cfg
}

get_partuuid() {
  local disk="$1"
  local regex="\"(.*)\""
  local blkid_output
  blkid_output=$(blkid "$disk" -s PARTUUID)

  [[ $blkid_output =~ $regex ]]

  if [ -z "${BASH_REMATCH[1]}" ]; then
    echo "Unable to extract PARTUUID for ${disk}!"
    exit 1
  fi

  echo "${BASH_REMATCH[1]}"
}

install_uefi_bootloader() {
  log_progress "Installing bootloader..."
  local partuuid
  partuuid=$(get_partuuid "${DESTINATION_DEVICE}p4")

  mkdir -p /boot/loader/entries

  pacman -S --noconfirm dosfstools intel-ucode
  bootctl --esp-path=/efi --boot-path=/boot install
  {
    echo "title       Arch Linux"
    echo "linux       /vmlinuz-linux"
    echo "initrd      /intel-ucode.img"
    echo "initrd      /initramfs-linux.img"
    echo "options     root=PARTUUID=${partuuid} quiet loglevel=3 systemd.show_status=0 rd.udev.log_priority=3 vga=current vt.global_cursor_default=0 rw ipv6.disable=1"
  } > /boot/loader/entries/arch.conf
  {
    echo "timeout 0"
    echo "default arch"
  } > /boot/loader/loader.conf
}

# install_and_enable_sshd() {
#   log_progress "Installing and enabling sshd..."
#   pacman -S --noconfirm openssh
#   systemctl enable sshd.service
#   systemctl start sshd
# }

create_bootstrap_user_for_bootstrapping() {
  log_progress "Creating bootstrap user for bootstrapping..."
  groupadd bootstrap
  useradd --password "${PASSWORD}" --comment "Bootstrap User" --create-home --gid users --groups bootstrap bootstrap
  echo 'Defaults env_keep += "SSH_AUTH_SOCK"' > /etc/sudoers.d/10_bootstrap
  echo "bootstrap ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers.d/10_bootstrap
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
  mkdir -p /root/.ssh
  chmod 0700 /root/.ssh
  cp /home/bootstrap/.ssh/bootstrap /root/.ssh/
}

install_and_enable_sshd() {
  log_progress "Installing and enabling sshd..."
  pacman -S --noconfirm openssh
  systemctl enable sshd.service
  systemctl start sshd
}

install_tools() {
  log_progress "Installing tools..."
  pacman -S --noconfirm ansible git-crypt
}

main() {
  log_progress "Starting installation in chroot..."
  set_locale
  set_timezone_and_clock
  set_hostname
#  enable_dhcp
  install_uefi_bootloader
  install_and_enable_sshd
  create_bootstrap_user_for_bootstrapping
  install_tools

  log_progress "Installation successful! Type 'reboot' and enjoy your Arch Linux!"
}

main "$@"

