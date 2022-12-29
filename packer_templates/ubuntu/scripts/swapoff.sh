#!/bin/sh -eux

swapoff -a
sed -i '/swap/d' /etc/fstab
reboot
