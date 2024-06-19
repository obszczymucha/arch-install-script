# arch-install-script (WSL2)

## Overview
This is a set of bash scripts that perform all necessary steps to install and
maintain Arch Linux on WSL2.


## Installation

### Prepare bootstrap archive
Run:
```bash
sudo ./create-bootstrap.sh
```

### Add the distro in WSL2
In PowerShell, run:
```PowerShell
wsl --import Archlinux I:\wsl2\Archlinux-20240601 I:\iNsTaLL\Arch-Bootstrap-20240601.tar.gz
```

### Launch the distro
In PowerShell, run:
```PowerShell
wsl -d Archlinux ~
```


### Run the bootstrap script
```bash
cd arch-install-script
./bootstrap.sh
```


## Maintenance
To refresh pacman packages, run:
```bash
./pacman.sh
```

