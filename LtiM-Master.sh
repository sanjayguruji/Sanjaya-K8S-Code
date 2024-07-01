#!/bin/bash

swapon -s
     cat <<EOF | sudo tee /etc/modules-load.d/crio.conf
overlay
br_netfilter
EOF

     sudo modprobe overlay
     sudo modprobe br_netfilter
     sudo sysctl --system
  
     export OS=xUbuntu_22.04
     export VERSION=1.28
     sudo apt update
     sudo apt-get install -y apt-transport-https ca-certificates curl
     cat <<EOF | sudo tee /etc/apt/sources.list.d/devel:kubic:libcontainers:stable.list
deb https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/$OS/ /
EOF

     cat <<EOF | sudo tee /etc/apt/sources.list.d/devel:kubic:libcontainers:stable:cri-o:$VERSION.list
deb http://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable:/cri-o:/$VERSION/$OS/ /
EOF

     curl -L https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/$OS/Release.key | sudo apt-key --keyring /etc/apt/trusted.gpg.d/libcontainers.gpg add -
     curl -L https://download.opensuse.org/repositories/devel:kubic:libcontainers:stable:cri-o:$VERSION/$OS/Release.key |sudo apt-key --keyring /etc/apt/trusted.gpg.d/libcontainers-cri-o.gpg add -
     sudo apt-get update
     sudo apt-get install cri-o cri-o-runc
     systemctl daemon-reload
     systemctl enable crio --now
     cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF

     echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.28/deb/ /" | sudo tee /etc/apt/sources.list.d/kubernetes.list
     curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.28/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
     apt-get update
     apt-get install -y kubelet="1.28.0-*" kubectl="1.28.0-*" kubeadm="1.28.0-*"
     apt-get update -y
     apt-get install -y jq
     systemctl enable --now kubelet
     systemctl start kubelet
     kubeadm config images pull
     kubeadm init --ignore-preflight-errors=all
     sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
    sudo chown $(id -u):$(id -g) $HOME/.kube/config
    kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.26.0/manifests/calico.yaml
