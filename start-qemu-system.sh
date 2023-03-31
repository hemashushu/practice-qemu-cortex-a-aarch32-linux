#!/bin/bash
qemu-system-arm -machine virt -cpu cortex-a7 -m 2G \
    -kernel build/vmlinuz-5.10.0-21-armmp-lpae \
    -initrd build/initrd.img-5.10.0-21-armmp-lpae \
    -append "root=/dev/vda2 console=ttyAMA0" \
    -drive if=none,file=build/hda.qcow2,format=qcow2,id=hd \
    -device virtio-blk-device,drive=hd \
    -netdev user,hostfwd=tcp::3222-:22,id=mynet \
    -device virtio-net-device,netdev=mynet \
    -nographic
