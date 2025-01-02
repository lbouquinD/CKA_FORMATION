#!/bin/bash

modprobe br_netfilter 

swapoff -a 

sudo sed -i 's/#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/g' /etc/sysctl.conf

sysctl --system