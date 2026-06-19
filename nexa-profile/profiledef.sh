#!/usr/bin/env bash
# Nexa OS Profile definition for archiso

iso_name="NexaOS-Installer"
iso_label="NEXAOS_$(date +%Y%m)"
iso_publisher="Nexa Solutions <https://github.com/NexaSolutions>"
iso_application="Nexa OS Live/Installer Image"
iso_version="1.0-alpha"
install_dir="arch"
buildmodes=('iso')
bootmodes=(
    'bios.syslinux.mbr'
    'bios.syslinux.eltorito'
    'uefi-x64.systemd-boot.esp'
    'uefi-x64.systemd-boot.eltorito'
)
arch="x86_64"
pacman_conf="pacman.conf"
airootfs_image_type="squashfs"
airootfs_image_tool_options=('-comp' 'xz' '-Xbcj' 'x86')
file_permissions=(
  ["/etc/shadow"]="0:0:0400"
  ["/etc/gshadow"]="0:0:0400"
  ["/root"]="0:0:0750"
  ["/root/.automated_script.sh"]="0:0:0755"
  ["/root/.gnupg"]="0:0:0700"
  ["/usr/local/bin/choose-mirror"]="0:0:0755"
  ["/usr/local/bin/livecd-sound"]="0:0:0755"
)
