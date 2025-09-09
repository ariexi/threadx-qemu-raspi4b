#!/bin/bash
IMAGE=disk.img    # Image
CPU_CORES=4       # CPU-Kerne (bis zu 8)
RAM_SIZE=4G       # Größe des Arbeitsspeichers
SSH_PORT=2223     # Lokaler Port für den SSH-Zugriff
MONITOR_PORT=5555 # Lokaler Port für die QEMU Monitor Konsole
ARGS=             # Zusätzliche Argument (-nographic um ohne grafisches Fenster zu starten)

qemu-system-aarch64 \
  -machine raspi4b \
  -cpu cortex-a72 \
  -m ${RAM_SIZE} \
  -smp ${CPU_CORES} \
  -dtb bcm2711-rpi-4-b.dtb \
  -drive format=raw,file=${IMAGE},if=none,id=hd0,cache=writeback \
  -kernel kernel \
  -append "console=ttyAMA0 root=/dev/mmcblk0p2 rw rootwait" \
  -device usb-net,netdev=mynet \
  -netdev user,id=mynet,hostfwd=tcp::${SSH_PORT}-:22 \
  -device usb-mouse \
  -device usb-kbd
  -monitor telnet:127.0.0.1:${MONITOR_PORT},server,nowait \
  $ARGS