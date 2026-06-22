# vim: set ft=make :
# This file should only contain bluefin specific stuff

# Configure Bluefin-CLI Terminal Experience with Brew
[group('System')]
[no-exit-message]
bluefin-cli:
    @ublue-bling
    brew bundle --file=/usr/share/ublue-os/homebrew/cli.Brewfile

# Rush B!!!
[group('System')]
gamemode:
    #!/usr/bin/env bash
    set -e
    if [[ "$(jq '."os-category"' /usr/share/ublue-os/image-info.json)" == "gamespace" ]] ; then
        echo "Already in gamemode."
        exit 0
    else
        gum confirm "Would you like to disable game mode?" || exit 0
    fi
    proxy_args=()
    proxy_http="${HTTP_PROXY:-${http_proxy:-}}"
    [[ -n "$proxy_http" ]] && proxy_args+=("HTTP_PROXY=$proxy_http" "http_proxy=$proxy_http")
    proxy_https="${HTTPS_PROXY:-${https_proxy:-}}"
    [[ -n "$proxy_https" ]] && proxy_args+=("HTTPS_PROXY=$proxy_https" "https_proxy=$proxy_https")
    proxy_no="${NO_PROXY:-${no_proxy:-}}"
    [[ -n "$proxy_no" ]] && proxy_args+=("NO_PROXY=$proxy_no" "no_proxy=$proxy_no")
    set +e
    if [[ ${#proxy_args[@]} -eq 0 ]]; then
        pkexec bootc switch ghcr.io/ublue-os/bazzite-nvidia-open:stable --apply
    else
        pkexec env "${proxy_args[@]}" bootc switch ghcr.io/ublue-os/bazzite-nvidia-open:stable --apply
    fi

# Configure docker,incus-admin,libvirt, container manager, serial permissions
[group('System')]
dx-group:
    #!/usr/bin/pkexec bash
    append_group() {
        local group_name="$1"
        if ! grep -q "^$group_name:" /etc/group; then
            echo "Appending $group_name to /etc/group"
            grep "^$group_name:" /usr/lib/group | sudo tee -a /etc/group > /dev/null
        fi
    }

    GROUPS_ADD=("docker" "incus-admin" "libvirt" "dialout")

    for GROUP_ADD in "${GROUPS_ADD[@]}" ; do
        append_group $GROUP_ADD
        usermod -aG $GROUP_ADD {{ `id -un` }}
    done

    echo "Reboot system and log back in to use docker, libvirt, incus, and serial connections."

# Install system flatpaks for rebasers
[group('System')]
install-system-flatpaks:
    #!/usr/bin/env bash
    gum confirm "Install development flatpaks?" || exit 0
    brew bundle --file="${TARGET_FLATPAK_FILE:-/usr/share/ublue-os/homebrew/system-dx-flatpaks.Brewfile}"
    gum confirm "Install system flatpaks?" || exit 0
    brew bundle --file="${TARGET_FLATPAK_FILE:-/usr/share/ublue-os/homebrew/system-flatpaks.Brewfile}"
    if gum confirm "Do you want to install extra monospace fonts?" ; then
        brew bundle install --file=/usr/share/ublue-os/homebrew/fonts.Brewfile
    fi

# Install default system flatpaks (alias for install-system-flatpaks)

# For additional applications, use: ujust bbrew
[group('System')]
bluefin-apps:
    echo "Installing default system flatpaks..."
    @ujust install-system-flatpaks

alias switch-stream := rebase-helper
alias switch-streams := rebase-helper
alias rollback-helper := rebase-helper

# Rebase assistant
[group('System')]
rebase-helper:
    @/usr/bin/ublue-rollback-helper
