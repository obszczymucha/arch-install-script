# arch-install-script

# Overview
This is a set of bash scripts that perform basic steps to install Arch Linux.

The script sets ``en_US.UTF-8`` locale and ``Europe/Dublin`` timezone.
It also enables DHCP on the first active interface it finds.

# WARNING
This set of scripts was created to automate **my** Arch Linux installation. If you aren't an advanced Arch Linux user, don't use these. Instead, follow the steps at https://wiki.archlinux.org/index.php/Beginners'_guide and learn how stuff works.
I take no responsibility for any damage that might be caused by using these scripts.

# Usage
* Copy everything onto your Arch Linux media CD/USB.
* Edit ``install.config`` and define ``DESTINATION_DEVICE`` (**CAREFUL: this device will be cleared and partitioned!** See next step.)
* Edit ``parted.config`` for your desirable partitioning configuration.
* Edit ``install.config`` and change your ``HOSTNAME`` (optional).
* Make sure you're connected to the internet and run ``install.sh``.
