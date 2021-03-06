 #!/bin/sh

# This installs the base instructions up to the point of joining / creating a cluster
DOMAIN_NAME=`hostname -d`

cat <<EOF | sudo tee -a /etc/hosts
192.168.254.10  master.${DOMAIN_NAME} master
192.168.254.11  worker01.${DOMAIN_NAME} worker01
192.168.254.12  worker02.${DOMAIN_NAME} worker02
192.168.254.13  worker03.${DOMAIN_NAME} worker03
EOF

cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF
sudo sysctl --system

sudo apt-get update
sudo apt-get -y install apt-transport-https ca-certificates curl gnupg-agent software-properties-common jq

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -

sudo add-apt-repository "deb [arch=arm64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"

sudo apt-get install -y docker-ce docker-ce-cli containerd.io
sudo usermod ubuntu -aG docker

cat <<EOF | sudo tee /etc/docker/daemon.json
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m"
  },
  "storage-driver": "overlay2"
}
EOF
sudo systemctl daemon-reload
sudo systemctl restart docker

sudo swapoff -a
sudo echo "vm.swappiness=0" | sudo tee -a /etc/sysctl.conf

sudo apt-get update
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
cat <<EOF | sudo tee /etc/apt/sources.list.d/kubernetes.list
deb https://apt.kubernetes.io/ kubernetes-xenial main
EOF
sudo apt-get update
sudo apt-get install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl

echo Adding " cgroup_enable=cpuset cgroup_memory=1 cgroup_enable=memory" to /boot/firmware/nobtcmd.txt
sudo cp  /boot/firmware/cmdline.txt /boot/firmware/cmdline.txt.backup
orig="$(head -n1 /boot/firmware/cmdline.txt ) ipv6.disable=1 cgroup_enable=cpuset cgroup_enable=memory cgroup_memory=1"
echo $orig | sudo tee /boot/firmware/cmdline.txt

cat <<EOF | tee ~/.bash_profile
# .bash_profile
if [ -f ~/.bashrc ]; then
. ~/.bashrc
fi
EOF

cat <<EOF | tee ~/.bashrc
# vim: ft=sh
alias ll='ls -al'
alias l='ls -l'
# No brainer, default to Vim
export EDITOR="vim"
# Color LS output to differentiate between directories and files
export LS_OPTIONS="--color=auto"
export CLICOLOR="Yes"
export LSCOLOR=""
export XAUTHORITY=~/.Xauthority
export DISPLAY=:1
EOF

echo Please reboot
