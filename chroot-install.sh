PASSWORD=$(/usr/bin/openssl passwd -crypt 'bootstrap')

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

