#!/bin/bash

set -ouex pipefail

# Copy the contents of system_files/ of the git repo to /
cp -avf "/ctx/system_files"/. /

### Install packages

# Packages can be installed from any enabled yum repo on the image.
# RPMfusion repos are available by default in ublue main images
# List of rpmfusion packages can be found here:
# https://mirrors.rpmfusion.org/mirrorlist?path=free/fedora/updates/43/x86_64/repoview/index.html&protocol=https&redirect=1

# this installs a package from fedora repos
dnf5 install -y tmux
dnf5 install -y jq
dnf5 install -y yq
dnf5 install -y papirus-icon-theme
dnf5 install -y butane

# Use a COPR Example:
#
# dnf5 -y copr enable ublue-os/staging
# dnf5 -y install package
# Disable COPRs so they don't end up enabled on the final image:
# dnf5 -y copr disable ublue-os/staging

#### Example for enabling a System Unit File

systemctl enable podman.socket

#### Myself modifycations

# 将图标主题设置为Papirus
cat <<'EOF' >> /usr/share/glib-2.0/schemas/zz0-bluefin-modifications.gschema.override
# Set default icon theme
[org.gnome.desktop.interface]
icon-theme='Papirus'
EOF

# 替换flathub源
flatpak remote-delete flathub
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
flatpak remote-modify flathub --url=https://mirrors.cernet.edu.cn/flathub
flatpak remote-add --title "Fedora Flatpaks" fedora oci+https://registry.fedoraproject.org

# 替换Homebrew源
cat <<'EOF' > /etc/profile.d/homebrew-mirror.sh
export HOMEBREW_BREW_GIT_REMOTE="https://mirrors.tuna.tsinghua.edu.cn/git/homebrew/brew.git"
export HOMEBREW_CORE_GIT_REMOTE="https://mirrors.tuna.tsinghua.edu.cn/git/homebrew/homebrew-core.git"
export HOMEBREW_API_DOMAIN="https://mirrors.tuna.tsinghua.edu.cn/homebrew-bottles/api"
export HOMEBREW_BOTTLE_DOMAIN="https://mirrors.tuna.tsinghua.edu.cn/homebrew-bottles"
export HOMEBREW_INSTALL_FROM_API=1
EOF
chmod 644 /etc/profile.d/homebrew-mirror.sh

# 修改镜像信息
IMAGE_INFO=$(cat /usr/share/ublue-os/image-info.json | jq '
    ."image-name" = "libluefin"
    | ."image-vendor" = "atom-l"
    | ."image-ref" = "ostree-image-signed:docker://ghcr.io/atom-l/libluefin"
    | ."image-tag" = "latest"
    | ."os-category" = "workspace"
')
echo "$IMAGE_INFO" > /usr/share/ublue-os/image-info.json

# 安装k8s相关的管理工具
cat <<EOF >> /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://pkgs.k8s.io/core:/stable:/v1.36/rpm/
enabled=1
gpgcheck=1
gpgkey=https://pkgs.k8s.io/core:/stable:/v1.36/rpm/repodata/repomd.xml.key
exclude=kubelet kubeadm kubectl cri-tools kubernetes-cni
EOF

yum install -y kubeadm kubectl
