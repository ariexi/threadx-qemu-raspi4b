# threadx-qemu-raspi4b

Repo for bringing ThreadX on a Raspi4, starting with QEMU

## Steps

1. using WSL2 w/ ubuntut 22.04
2. update qemu verion to 10 / latest version

`git clone https://gitlab.com/qemu-project/qemu.git`
`cd qemu`
`./configure`
`make`

3. Install the required packages on your host system:

#### Cross compilers for arm64
`sudo apt install gcc-aarch64-linux-gnu g++-aarch64-linux-gnu`

#### Qemu itself
`sudo apt install qemu qemubuilder qemu-system-gui qemu-system-arm qemu-utils qemu-system-data qemu-system`
`sudo apt install gcc-aarch64-linux-gnu g++-aarch64-linux-gnu \
  qemubuilder qemu-system-gui qemu-system-arm qemu-utils qemu-system-data qemu-system \
  bison flex guestfs-tools libssl-dev telnet xz-utils`

#### shows available supported machines
`qemu-system-aarch64 -machine help`

#### shows qemu version
`qemu-system-aarch64 -version`
