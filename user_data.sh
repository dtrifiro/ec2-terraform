#!/bin/bash
set -x

HOSTNAME="dtrifiro-gpu"
echo "Starting user data setup"

echo "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICz3u/Z5kCBcSPSZdyNoDBEqDWwmTnBWPeFQ93jgRijX dtrifiro-red" >/root/.ssh/authorized_keys

hostname $HOSTNAME
echo "127.0.0.1 $HOSTNAME" >>/etc/hosts

user=admin
HOME=/mnt/data/home
function as_user() {
	# runs the given command as $user
	sudo -u $user $@
}

# block devices
mkdir /mnt/scratch && mkfs.ext4 /dev/nvme1n1 && mount /dev/nvme1n1 /mnt/scratch && chown $user /mnt/scratch
ebs_volume_dev=/dev/nvme2n1
(
	mkdir /mnt/data $HOME &&
		mount $ebs_volume_dev /mnt/data/
) || (
	mkfs.ext4 $ebs_volume_dev &&
		mount $ebs_volume_dev /mnt/data
)
chown -R $user /mnt/data
usermod -d $HOME $user

cat >>/etc/apt/sources.list <<EOF
deb http://deb.debian.org/debian bookworm main contrib non-free-firmware non-free
deb http://deb.debian.org/debian bookworm-updates main contrib non-free-firmware non-free
deb http://security.debian.org/debian-security bookworm-security main contrib non-free-firmware non-free
EOF

export DEBIAN_FRONTEND=noninteractive DEBCONF_NONINTERACTIVE_SEEN=true
apt-get update && apt-get install -y --no-install-recommends \
	systemd-oomd \
	build-essential ccache ninja-build cmake \
	docker.io docker-compose \
	zsh bat bmon htop httpie git gpg tmux fzf grc tree ripgrep \
	python-is-python3 python3-dev python3-pip python3-virtualenv \
	dkms linux-headers-$(uname -r)

systemctl enable --now systemd-oomd

# nvidia repos and drivers
curl -fSsL https://developer.download.nvidia.com/compute/cuda/repos/debian12/x86_64/3bf863cc.pub | gpg --dearmor | tee /usr/share/keyrings/nvidia-drivers.gpg >/dev/null 2>&1
echo 'deb [signed-by=/usr/share/keyrings/nvidia-drivers.gpg] https://developer.download.nvidia.com/compute/cuda/repos/debian12/x86_64/ /' | tee /etc/apt/sources.list.d/nvidia-drivers.list
apt-get update && apt-get install -y --no-install-recommends nvidia-driver cuda-toolkit-12

# docker+gpu related tools
curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg &&
	curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list |
	sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' |
		tee /etc/apt/sources.list.d/nvidia-container-toolkit.list
apt-get update && apt-get install --no-install-recommends -y nvidia-container-toolkit
usermod --append --groups=docker $user
systemctl restart docker

# misc user stuff
chsh -s /usr/bin/zsh $user
as_user git clone https://git.decapod.one/brethil/dotfiles ~/.dotfiles

as_user ln -s $HOME/.dotfiles/tmux.conf $HOME/.tmux.conf
as_user ln -s $HOME/.dotfiles/pdbrc.py $HOME/.pdbrc.py
as_user ln -s $HOME/.dotfiles/vim/vimrc $HOME/.vimrc
as_user ln -s $HOME/.dotfiles/extras/zprofile $HOME/.zprofile

if ! grep DOTFILES $HOME/.zshrc >/dev/null; then
	cat >>$HOME/.zshrc <<EOF
    export DOTFILES=\$HOME/.dotfiles
    source \$DOTFILES/brethil_dotfile.sh
    # dotfiles end
EOF
fi

if ! grep CUDA_HOME $HOME/.zshrc >/dev/null; then
	cat >>$HOME/.zshrc <<EOF
    export CUDA_HOME=/usr/local/cuda
    export PATH=\$CUDA_HOME/bin:]$PATH
EOF
fi

echo -e "\nssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICz3u/Z5kCBcSPSZdyNoDBEqDWwmTnBWPeFQ93jgRijX dtrifiro-red" >>$HOME/.ssh/authorized_keys

# misc development tools
sudo apt install -y python-is-python3 python3-pip python3-virtualenv