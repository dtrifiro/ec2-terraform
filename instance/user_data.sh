#!/bin/bash
set -x

HOSTNAME="dtrifiro-gpu"
echo "Starting user data setup"

hostname $HOSTNAME
echo "127.0.0.1 $HOSTNAME" >>/etc/hosts

user=admin
HOME=/home/admin
function as_user() {
	# runs the given command as $user
	sudo -u $user $@
}

cat >>/etc/apt/sources.list <<EOF
deb http://deb.debian.org/debian bookworm main contrib non-free-firmware non-free
deb http://deb.debian.org/debian bookworm-updates main contrib non-free-firmware non-free
deb http://security.debian.org/debian-security bookworm-security main contrib non-free-firmware non-free
EOF

export DEBIAN_FRONTEND=noninteractive DEBCONF_NONINTERACTIVE_SEEN=true
apt-get update && apt-get install -y --no-install-recommends \
	build-essential \
	docker.io docker-compose \
	zsh bat bmon htop httpie git gpg tmux fzf grc tree ripgrep \
	linux-headers-$(uname -r) \
	nvidia-smi nvidia-driver nvidia-cuda-dev nvidia-cuda-toolkit

chsh -s /usr/bin/zsh $user
usermod --append --groups=docker $user

# docker+gpu related tools
curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg &&
	curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list |
	sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' |
		tee /etc/apt/sources.list.d/nvidia-container-toolkit.list
apt-get update
apt-get install -y nvidia-container-toolkit

echo -e "\nssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICz3u/Z5kCBcSPSZdyNoDBEqDWwmTnBWPeFQ93jgRijX dtrifiro-redhat" >>$HOME/.ssh/authorized_keys

# block devices
mkdir /mnt/scratch && mkfs.ext4 /dev/nvme1n1 && mount /dev/nvme1n1 /mnt/scratch && chown $user /mnt/scratch
ebs_volume_dev=/dev/nvme2n1
(mkdir /mnt/data && mount $ebs_volume_dev /mnt/data/) || (mkfs.ext4 $ebs_volume_dev && mount $ebs_volume_dev /mnt/data)
chown -R $user /mnt/data

# misc development tools
sudo apt install -y python-is-python3 python3-pip python3-virtualenv
