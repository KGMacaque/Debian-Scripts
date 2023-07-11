#!/bin/bash

#   @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
#   @@@ This script will install both ZRAM & ZSWAP, then config them using the default settings.  @@@
#   @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
#   _____________________________________________________________  Created By: KGMacaque  _________

# Check if script is run as root
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root"
  exit
fi

# Function to modify or append lines in a file
modify_line() {
  if grep -q -E "$1" "$2"; then
    sudo sed -i "s|$1|$3|" "$2"
    echo "Line modified successfully in $2."
  elif ! grep -q -F "$3" "$2"; then
    echo "$3" | sudo tee -a "$2" > /dev/null
    echo "Line added successfully to $2."
  fi
}

# Update repositories and install necessary packages for ZRAM
sudo apt-get update && sudo apt-get install -y zram-tools

# Enable ZRAM swap
modify_line '^ENABLED=' '/etc/default/zramswap' 'ENABLED=1'

# Modify or append lines in /etc/modprobe.d/zram.conf
modify_line 'options zram num_devices=' '/etc/modprobe.d/zram.conf' 'options zram num_devices=2'
modify_line 'options zram disksize=' '/etc/modprobe.d/zram.conf' 'options zram disksize=1G'

# Set the desired value for GRUB_CMDLINE_LINUX_DEFAULT
grub_cmdline="quiet splash zswap.enabled=1 zswap.compressor=lz4 zswap.max_pool_percent=25 zswap.zpool=z3fold"

# Update GRUB_CMDLINE_LINUX_DEFAULT line in /etc/default/grub
sudo sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT=.*/GRUB_CMDLINE_LINUX_DEFAULT="'$grub_cmdline'"/' /etc/default/grub

# Update GRUB configuration
sudo update-grub

# Reboot the system
echo "The system will reboot in 30 seconds to apply changes..."
sleep 30
sudo reboot

