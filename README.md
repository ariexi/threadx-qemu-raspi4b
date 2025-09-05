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
    libopus-dev
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

## Emulate a Raspberry 4B

See also this [tutorial (German only)](https://crycode.de/raspberry-pi-4-emulieren-mit-qemu/
)
### Preparation

1. Download a Raspberry Pi OS image (32- or 64-bit) from the official [download site](https://www.raspberrypi.com/software/operating-systems/).

> Please pay attention to the kernel version specified there, as we must compile the kernel ourselve.
I took Kernel 6.12 with the verion below.

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

At first, a compatible kernel is needed. In this case, we use kernel 6.12 or 6.12.45

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


```bash

```