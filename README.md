# arch-install-script

# Overview
This is a set of bash scripts that perform basic steps and install Arch Linux.

The script sets ``en_US.UTF-8`` locale and ``Europe/Dublin`` timezone.
It also enables DHCP on the first active interface it finds.

# Usage
* Copy everything onto your Arch Linux media CD/USB.
* Edit ``install.config`` and define ``DESTINATION_DEVICE`` (**CAREFUL: this device will be cleared and partitioned!** See next step.)
* Edit ``parted.config`` for your desirable partitioning configuration.
* Edit ``install.config`` and change your ``HOSTNAME`` (optional).
* Make sure you're connected to the internet and run ``install.sh``.
