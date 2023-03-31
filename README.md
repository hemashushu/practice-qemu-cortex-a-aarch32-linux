# QEMU Cortex-A AArch32 - Linux

Build a Cortex-A AArch32 development virtual machine with QEMU.

Machine config:

- machine: virt
- cpu: Cortex-A7
- memory: 2GiB

OS config:

Debian _armhf_, ARM 32 bit with hardware floating point support.

- - -

Table of Content

<!-- @import "[TOC]" {cmd="toc" depthFrom=2 depthTo=4 orderedList=false} -->

<!-- code_chunk_output -->

- [Setup the virtual machine](#-setup-the-virtual-machine)
- [Boot into guest OS](#-boot-into-guest-os)
- [Configuration after first boot](#-configuration-after-first-boot)
- [Login through SSH](#-login-through-ssh)
- [Check your `sudo` privilegs](#-check-your-sudo-privilegs)
- [Write a `Hello World!` program](#-write-a-hello-world-program)
- [Upgrade the kernel](#-upgrade-the-kernel)

<!-- /code_chunk_output -->

## Setup the virtual machine

1. Create a new folder named "aarch32-debian" or any other name you like, and then enter this folder.

```bash
$ mkdir aarch32-debian
$ cd aarch32-debian
```

2. Download [vmlinuz](https://deb.debian.org/debian/dists/bullseye/main/installer-armhf/current/images/netboot/vmlinuz) and [initrd.gz](https://deb.debian.org/debian/dists/bullseye/main/installer-armhf/current/images/netboot/initrd.gz) from Debian web site.

```bash
$ wget https://deb.debian.org/debian/dists/bullseye/main/installer-armhf/current/images/netboot/vmlinuz
$ wget https://deb.debian.org/debian/dists/bullseye/main/installer-armhf/current/images/netboot/initrd.gz
```

**For information how to find these two files**

```text
1. https://www.debian.org/download
   click "Other Installers - Getting Debian"
2. https://www.debian.org/distrib
   click "Download an installation image - small installation image"
3. https://www.debian.org/distrib/netinst
   click "Network boot - armhf"
4. https://deb.debian.org/debian/dists/bullseye/main/installer-armhf/current/images/
   click "netboot"
```

3. Create the `build` folder.

This folder will be used to store the hard disk image of the virtual machine and the kernel files.

```bash
$ mkdir build
```

Just create this folder, don't change into it.

4. Create a disk image.

Use the `QCOW2` as image file format. Since this virtual system will only install base softwares and development tools, 32GiB would be a resonable size.

```bash
$ qemu-img create -f qcow2 build/hda.qcow2 32G
```

5. Start the installer.

Here's how to install Debian.

Note that this system is for development only, not for our daily use, so it should be kept as simple as possible. Just use the default settings for most of the steps.

```bash
$ qemu-system-arm -M virt -cpu cortex-a7 -m 2G \
  -kernel vmlinuz \
  -initrd initrd.gz \
  -drive if=none,file=build/hda.qcow2,format=qcow2,id=hd \
  -device virtio-blk-device,drive=hd \
  -netdev user,id=mynet \
  -device virtio-net-device,netdev=mynet \
  -nographic \
  -no-reboot
```

Here are some key steps:

- Language: "English"
- Location: Select a location that matches your time zone, as the installation wizard does not provide a separate step for us to select a time zone.
- Keyboard: "American English"
- Hostname: "aarch32debian" or other name you like. Don't enter special characters, only [a-z], [0-9] and "-" (hyphen) are allowed.
- Domain name: "localdomain"
- Mirror: Select the mirror closest to your location.
- Proxy: Leave blank (means no proxy).
- Root password: Root user password, can be 123456 because it's easy to type, note this is a virtual machine and the password doesn't matter.
- New user full name: The display name of your new user, this user will be the default non-privileged user.
- New user login name: Can be the same as your host login name.
- New user password: New user password, can be "123456", it doesn't matter.

The following are the steps for partitioning:

- Partitioning method: "Guided - use entire disk"
- Select disk: "Virtual disk 1 (vda)"
- Partitioning scheme: "All files in one partition"
- Finish partitioning and write changes to disk.
- Write the changes to disks: "Yes"

Almost done:

- Statistics submission: "No"
- Choose software to install: **Only** select the "SSH Server" and "standard system utilities"

- Install the GRUB boot loader: This step will be failed, just ignore and continue.
- Debian installer main menu: "Continue without boot loader"
- Installation complete: "Continue"

The QEMU program will exit because instead of reboot the virtual machine, because the parameter "-no-reboot" was added to QEMU.

6. Check the disk image.

```bash
$ ls -lh build
total 1.7G
-rw-r--r-- 1 yang yang 1.7G Mar 31 11:18 hda.qcow2
```

It seems to be Ok.

7. Copy the kernel files from the disk image out to the host filesystem.

Your need a tool called [libguestfs](https://libguestfs.org/), which you can install through your system's package manager.

Let's list the disk image:

```bash
$ virt-ls -v -a build/hda.qcow2 /boot
```

You may see quite a lot of output messages, scroll up slightly and you should see text looks like this:

```text
command: mount '-o' 'ro' '/dev/sda1' '/sysroot//boot'
guestfsd: => mount_ro (0x49) took 0.02 secs
guestfsd: <= ls0 (0x15b) request length 52 bytes
guestfsd: => ls0 (0x15b) took 0.00 secs
System.map-5.10.0-20-armmp-lpae
System.map-5.10.0-21-armmp-lpae
config-5.10.0-20-armmp-lpae
config-5.10.0-21-armmp-lpae
initrd.img
initrd.img-5.10.0-20-armmp-lpae
initrd.img-5.10.0-21-armmp-lpae
initrd.img.old
lost+found
vmlinuz
vmlinuz-5.10.0-20-armmp-lpae
vmlinuz-5.10.0-21-armmp-lpae
vmlinuz.old
libguestfs: closing guestfs handle 0x564410c905c0 (state 2)
```

File "initrd.img-5.10.0-21-armmp-lpae" and "vmlinuz-5.10.0-21-armmp-lpae" are the files we need. Note that you may see different version number, just select the latest one.

Now copy them out to the host:

```bash
$ virt-copy-out -a build/hda.qcow2 /boot/initrd.img-5.10.0-21-armmp-lpae build
$ virt-copy-out -a build/hda.qcow2 /boot/vmlinuz-5.10.0-21-armmp-lpae build
```

Check again:

```bash
$ ls -lh build
total 1.8G
-rw-r--r-- 1 yang yang 1.7G Mar 31 11:18 hda.qcow2
-rw-r--r-- 1 yang yang  22M Mar 31 11:37 initrd.img-5.10.0-21-armmp-lpae
-rw-r--r-- 1 yang yang 4.9M Mar 31 11:38 vmlinuz-5.10.0-21-armmp-lpae
```

## Boot into guest OS

```bash
qemu-system-arm -machine virt -cpu cortex-a7 -m 2G \
    -kernel build/vmlinuz-5.10.0-21-armmp-lpae \
    -initrd build/initrd.img-5.10.0-21-armmp-lpae \
    -append "root=/dev/vda2 console=ttyAMA0" \
    -drive if=none,file=build/hda.qcow2,format=qcow2,id=hd \
    -device virtio-blk-device,drive=hd \
    -netdev user,hostfwd=tcp::3222-:22,id=mynet \
    -device virtio-net-device,netdev=mynet \
    -nographic
```

You will see the login messgae if there is no exception:

```text
Debian GNU/Linux 11 aarch32debian ttyAMA0

aarch32debian login:
```

## Configuration after first boot

After the first boot, there are some essential configurations that need to be done before it can become a normal development enviroment.

Login in as root user and install "sudo", "vim" and "build-essential" softwares:

```bash
# apt install sudo vim build-essential
```

Add the default non-privileged user (which you create in the installation wizard) to "sudo" group:

```bash
# usermod -a -G sudo yang
```

Note that you need to replace "yang" above with your new non-privileged user name.

## Login through SSH

It's recommended to use our development environment by logging in to the virtual machine via SSH, as QEMU terminal sometimes has text display issue.

```bash
$ ssh yang@localhost -p 3222
```

Replace "yang" above with your new non-privileged user name. The port `3222` is specified by the parameter `hostfwd=tcp::3222-:22` when you started QEMU, you can change it to another port. The purpose of this parameter is to redirect the host port `3222` to guest port `22`.

## Check your `sudo` privilegs

```bash
$ id
```

Make sure `groups=...27(sudo)...` is shown, now perform a privileged operation:

```bash
$ sudo apt update
```

If there is no exception, you may see the text:

```text
Reading package lists... Done
Building dependency tree... Done
Reading state information... Done
All packages are up to date.
```

Remember that even in a virtual machine, you should avoid using the root user directly.

> Use unprivileged user for most operations and use `sudo` command to promote permission only when privileged is needed, this rule always true in the Linux world.

## Write a `Hello World!` program

In the virtual machine, create a text file named `main.c`, and write down the following text:

```c
#include <stdio.h>

int main(void){
    printf("Hello World!\n");
    return 0;
}
```

Try to compile it and run the output executable file:

```bash
$ gcc -g -Wall -o main.elf main.c
$ ./main.elf
Hello World!
```

Everything is Ok.

## Upgrade the kernel

When you upgrade the guest OS and the kernel is updated, you will need to copy the new kernel from the guest OS out to the host filesystem. Which can be done by using `libguestfs` as described in the section above, but also by using `scp` utility.
