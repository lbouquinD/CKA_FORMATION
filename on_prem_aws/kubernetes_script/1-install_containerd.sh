#!/bin/bash

###  Récupération du binaaire containerd 
wget https://github.com/containerd/containerd/releases/download/v2.0.1/containerd-2.0.1-linux-amd64.tar.gz -O  containerd.tar.gz


# Extraction des bnaires
tar Cxzvf /usr/local containerd.tar.gz


# Installation du service  containerd
wget https://raw.githubusercontent.com/containerd/containerd/main/containerd.service -O /etc/systemd/system/containerd.service



# Activation du service containerd
systemctl daemon-reload
systemctl enable --now containerd


wget  https://github.com/opencontainers/runc/releases/download/v1.2.3/runc.amd64 -O runc.amd64

#installation de containerd
install -m 755 runc.amd64 /usr/local/sbin/runc


##  Install  CNI plugins 
wget https://github.com/containernetworking/plugins/releases/download/v1.6.2/cni-plugins-linux-amd64-v1.6.2.tgz -O cni-plugins-linux-amd64-v1.6.2.tgz
mkdir -p /opt/cni/bin
tar Cxzvf /opt/cni/bin cni-plugins-linux-amd64-v1.6.2.tgz
