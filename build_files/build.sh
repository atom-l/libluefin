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

# Use a COPR Example:
#
# dnf5 -y copr enable ublue-os/staging
# dnf5 -y install package
# Disable COPRs so they don't end up enabled on the final image:
# dnf5 -y copr disable ublue-os/staging

#### Example for enabling a System Unit File

systemctl enable podman.socket

#### Myself modifycations

# 替换flathub源
flatpak remote-delete flathub
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo

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
