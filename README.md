# threadx-qemu-raspi4b

Repo for bringing ThreadX on a Raspi4, starting with QEMU

## Steps to be successful

I am using WSL2 w/ ubuntut 22.04, so this tutorial is excactly for that combination and worked for me.

## Update qemu verion to 10 / latest version  ([see also](https://www.qemu.org/download/))

To install QEMU v10.1.0 on Ubuntu 22.04, you'll need to compile it from source since this version is not available in the default Ubuntu repositories. Here's a step-by-step guide:

1. First, remove any existing QEMU installation:
```bash
sudo apt remove --purge qemu*
sudo apt autoremove
```

2. Install required build dependencies:
```bash
sudo apt update
sudo apt install -y build-essential git \
    libglib2.0-dev libfdt-dev libpixman-1-dev zlib1g-dev \
    ninja-build meson \
    libaio-dev libbluetooth-dev libcapstone-dev libbrlapi-dev libbz2-dev \
    libcap-ng-dev libcurl4-gnutls-dev libgtk-3-dev \
    libibverbs-dev libjpeg8-dev libncurses5-dev libnuma-dev \
    librbd-dev librdmacm-dev \
    libsasl2-dev libsdl2-dev libseccomp-dev libsnappy-dev libssh-dev \
    libvde-dev libvdeplug-dev libvte-2.91-dev libxen-dev liblzo2-dev \
    valgrind xfslibs-dev  \
    libopus-dev \ 
    linux-image-generic 
```

3. Download Spice support for QEMU:

You need to install `spice-protocol` first. (see also [spice download section](https://www.spice-space.org/download.html))  
(How to run meson you can find [here](https://mesonbuild.com/Running-Meson.html ))

Unfortunately it is not available in the main repositories, so you will have to download and compile it:
```bash
wget https://www.spice-space.org/download/releases/spice-protocol-0.14.5.tar.xz
tar -xf spice-protocol-0.14.5.tar.xz
cd spice-protocol-0.14.5
meson setup build
sudo meson install -C build
```

Then the `spice-server`

```bash
wget https://spice-space.org/download/releases/spice-server/spice-0.16.0.tar.bz2
tar -xjf spice-0.16.0.tar.bz2
cd spice-0.16.0
./configure
make
sudo make install
```
4. Download QEMU 10.1.0 source code:

```bash
cd /tmp
wget https://download.qemu.org/qemu-10.1.0.tar.xz
tar xvJf qemu-10.1.0.tar.xz
cd qemu-10.1.0
```

5. Configure the build:
```bash
./configure --enable-kvm \
    --enable-system \
    --enable-virtfs \
    --enable-sdl \
    --enable-gtk \
    --enable-vte \
    --enable-spice \
    --enable-slirp \
    --enable-user \
    --enable-system \
    --prefix=/usr/local \
    --localstatedir=/var \
    --sysconfdir=/etc
```

6. Build and install QEMU:
```bash
make
sudo make install
```

7. Update the system's library cache:
```bash
sudo ldconfig
```

8. Verify the installation:
```bash
qemu-system-aarch64 --version

# Have a look, if the machine raspi4b appears
# Output: 
# raspi4b              Raspberry Pi 4B (revision 1.5)
qemu-system-aarch64 -machine help
```

9. If you want to make QEMU accessible to your user:
```bash
sudo usermod -aG kvm $USER
sudo usermod -aG libvirt $USER
```

10. You might need to log out and log back in for group changes to take effect.

Optional: If you want to create a symbolic link to make QEMU commands available system-wide:
```bash
sudo ln -s /usr/local/bin/qemu-system-aarch64 /usr/bin/qemu-system-aarch64
```

Troubleshooting:
1. If you encounter any missing dependencies during configure:
```bash
# The configure script will tell you what's missing
# Install the missing packages using:
sudo apt install package-name-dev
```

2. If you get permission errors:
```bash
# Check if KVM is available
ls -l /dev/kvm
# Set correct permissions if needed
sudo chmod 666 /dev/kvm
```

3. If you need to uninstall the compiled version:
```bash
cd /tmp/qemu-10.1.0
sudo make uninstall
```

4. To clean the build directory:
```bash
make clean
```

After installation, you can use QEMU as described in the previous response, with all the commands and options remaining the same. The only difference is that you'll be using version 10.1.0 instead of the distribution's default version.

Remember to keep the source code directory if you want to uninstall QEMU later. If you need to remove it, you can use the make uninstall command from the source directory.

# Emulate a Raspberry 4B

See also this [tutorial (German only)](https://crycode.de/raspberry-pi-4-emulieren-mit-qemu/
)
## Preparation

1. Download a Raspberry Pi OS image (32- or 64-bit) from the official [download site](https://www.raspberrypi.com/software/operating-systems/).

> Please pay attention to the kernel version specified there, as you must compile the kernel by yourselve.
I took Kernel `6.12` with the verion below.

```bash
wget https://downloads.raspberrypi.com/raspios_arm64/images/raspios_arm64
-2025-05-13/2025-05-13-raspios-bookworm-arm64.img.xz
```

2. Install required software packages

```bash
sudo apt install gcc-aarch64-linux-gnu g++-aarch64-linux-gnu \
  bison flex guestfs-tools libssl-dev telnet xz-utils \
  bc libc6-dev libncurses5-dev crossbuild-essential-arm64
```

3. The downloaded image `2025-05-13-raspios-bookworm-arm64.img.xz` and all other files will be copied to `~/rpi-emu/` ab.
```bash
mkdir ~/rpi-emu
cd ~/rpi-emu
cp ~/2025-05-13-raspios-bookworm-arm64.img.xz ./
unxz 2025-05-13-raspios-bookworm-arm64.img.xz
```

4. Compile the kernel

At first, a compatible kernel is needed. In this case, use kernel `6.12` or `6.12.45`

To have it real simple, please creat a file `build-qemu-kernel.sh` with following content:

```bash
#!/bin/bash
VERSION=6.12.45

wget https://cdn.kernel.org/pub/linux/kernel/v${VERSION//.*/.x}/linux-${VERSION}.tar.xz
tar -xvJf linux-${VERSION}.tar.xz

cd linux-${VERSION}

ARCH=arm64 CROSS_COMPILE=/bin/aarch64-linux-gnu- make defconfig
ARCH=arm64 CROSS_COMPILE=/bin/aarch64-linux-gnu- make kvm_guest.config
ARCH=arm64 CROSS_COMPILE=/bin/aarch64-linux-gnu- make -j$(nproc)

cp arch/arm64/boot/Image ../kernel
cd ..
```

Download and compile the kernel via the script
```bash
chmod +x build-qemu-kernel.sh
./build-qemu-kernel.sh
```

The builded kernel is available in the folder `kernel` now.

5. Re-size the Raspberry Pi OS image

So that you can use the Raspberry Pi OS image with QEMU, you first need to adapt it.

### Enlarge the image

A standard Raspberry Pi enlarges the file system to the available space automatically when it is first started.
As this will not happen automatically here, you have to do it manually.
Save it also to a new file at the same time.

In the following, save the new image as disk.img and increase it by 60Gb

```bash
cp 2025-05-13-raspios-bookworm-arm64.img disk.img
truncate -s +60G disk.img
sudo virt-resize --expand /dev/sda2 2025-05-13-raspios-bookworm-arm64.img disk.img
```

### Configuration of user and password and activation of SSH

There is no longer a standard user for the newer Raspberry Pi OS images. This is why you have to edit the image to create it.

To do this, just first display the partitions in the image.

```bash
fdisk -l disk.img
```

```bash
Output: 
Disk disk.img: 65.73 GiB, 70581747712 bytes, 137854976 sectors
Units: sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 512 bytes
I/O size (minimum/optimal): 512 bytes / 512 bytes
Disklabel type: dos
Disk identifier: 0xd1876ee1

Device     Boot   Start       End   Sectors  Size Id Type
disk.img1         16384   1064959   1048576  512M  c W95 FAT32 (LBA)
disk.img2       1064960 137854591 136789632 65.2G 83 Linux
```

From the output, you need the start of disk.img1 (here 16384) and the sector size (here 512).
Multiply these two values to obtain the offset for integrating the partition.
16384 * 512 = 8388608


Then create a directory and mount the partition from the image, specifying the offset just calculated in this.

**Caution**

> **Please ensure that the offset is entered correctly!!**

```bash
mkdir mnt
sudo mount -o loop,offset=8388608 disk.img ./mnt
```

Create a file userconf.txt in the mounted partition. This file contains the user name and password for the login.

The password is queried interactively.

```bash
PW=$(openssl passwd -6)
echo "pi:$PW" | sudo tee mnt/userconf.txt
```

To ensure that SSH is also activated in the emulated system, you also have to  create a `ssh` file.

```bash
sudo touch mnt/ssh
```

Unmount the partition of the image again.

```bash
sudo umount mnt
```

### Start the emulated system

Everything is prepared now to start the emulated Raspberry Pi OS.

To have it real simple, please create a starting script `rpi-emu-start.sh` with following content:

```bash
#!/bin/bash
IMAGE=disk.img    # Image
CPU_CORES=4       # CPU-Kerne (bis zu 8)
RAM_SIZE=4G       # Größe des Arbeitsspeichers (8G led to a failure)
SSH_PORT=2223     # Lokaler Port für den SSH-Zugriff
MONITOR_PORT=5555 # Lokaler Port für die QEMU Monitor Konsole
ARGS=             # Zusätzliche Argument (-nographic um ohne grafisches Fenster zu starten)

qemu-system-aarch64 -machine raspi4b -cpu cortex-a72 \
  -smp ${CPU_CORES} -m ${RAM_SIZE} \
  -kernel kernel \
  -append "root=/dev/vda2 rootfstype=ext4 rw panic=0 console=ttyAMA0" \
  -drive format=raw,file=${IMAGE},if=none,id=hd0,cache=writeback \
  -device virtio-blk,drive=hd0,bootindex=0 \
  -netdev user,id=mynet,hostfwd=tcp::${SSH_PORT}-:22 \
  -device virtio-net-pci,netdev=mynet \
  -monitor telnet:127.0.0.1:${MONITOR_PORT},server,nowait \
  $ARGS
```

With the follwoing commands the script will be executable and will be started.

```bash
chmod +x rpi-emu-start.sh
./rpi-emu-start.sh
```

First start of Raspi on QEMU can take a while...

![Raspi on QEMU starting picture](/images/Raspi_on_QEMU.png)


### Login to the system

Since the SSH server is activated and passed on the SSH port, you can access the emulated system via SSH as following:

```bash
ssh -p 2223 pi@localhost
```

After login, you kann work like with a real Raspberry Pi

```bash
Linux raspberrypi 6.12.45 #1 SMP PREEMPT Fri Sep  5 16:29:45 CEST 2025 aarch64

The programs included with the Debian GNU/Linux system are free software;
the exact distribution terms for each program are described in the
individual files in /usr/share/doc/*/copyright.

Debian GNU/Linux comes with ABSOLUTELY NO WARRANTY, to the extent
permitted by applicable law.
Last login: Tue Sep  9 14:33:06 2025
pi@raspberrypi:~ $ 
```

### Stop the emulated system

It is the same mechanism, than in a real system.

```bash
sudo shutdown -h now
```

### Add graphical support

1. install XFCE4 Desktop Environment:

```bash
sudo apt install xfce4
```

2. Configure display export in WSL

Add following lines to `~/.bashrc`

```bash
export DISPLAY=$(cat /etc/resolv.conf | grep nameserver | awk '{print $2}'):0
export LIBGL_ALWAYS_INDIRECT=1
```

Start Raspberry Pi 4 on QEMU with following command:

```bash
qemu-system-aarch64 \
  -machine raspi3b \
  -cpu cortex-a72 \
  -m 4G \
  -smp 4 \
  -dtb bcm2711-rpi-4-b.dtb \
  -sd raspbian.img \
  -kernel kernel8.img \
  -append "console=ttyAMA0 root=/dev/mmcblk0p2 rw rootwait" \
  -device usb-net,netdev=net0 \
  -netdev user,id=net0 \
  -device usb-mouse \
  -device usb-kbd
```

```bash
Try this one ... ;-) in second script

qemu-system-aarch64 \
  -machine raspi4b \
  -cpu cortex-a72 \
  -m ${RAM_SIZE} \
  -smp ${CPU_CORES} \
  -dtb bcm2711-rpi-4-b.dtb \
  -drive format=raw,file=${IMAGE},if=none,id=hd0,cache=writeback \
  -kernel kernel \
  -append "root=/dev/vda2 rootfstype=ext4 rw panic=0 console=ttyAMA0" \ -> vom virt

  -append "console=ttyAMA0 root=/dev/mmcblk0p2 rw rootwait" \
  -device usb-net,netdev=net0 \
  -netdev user,id=net0 \
  -device usb-mouse \
  -device usb-kbd

  -device virtio-blk,drive=hd0,bootindex=0 \
  -netdev user,id=mynet,hostfwd=tcp::${SSH_PORT}-:22 \
  -device virtio-net-pci,netdev=mynet \
  -monitor telnet:127.0.0.1:${MONITOR_PORT},server,nowait \
  $ARGS
```




```bash

```
```bash

```
