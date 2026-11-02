#!/bin/bash

sudo apt update
sudo apt install wget -y
set -euo pipefail

installpath="$HOME/.local/bin"
mkdir -p "$installpath"
vendoryml="$installpath/vendor.yml"

# mktemp uses /tmp by default (or $TMPDIR if set)
tmpdir=$(mktemp -d)
# The trap removes the temp dir when this shell exits, even if a command fails.
trap 'rm -rf "$tmpdir"' EXIT

# get vendorfiles
wget https://github.com/Araxeus/vendorfiles-rs/releases/download/v2.4.0/vendor_v2.4.0_linux.tar.gz -O "$tmpdir/vendor.tar.gz"
tar -xzf "$tmpdir/vendor.tar.gz" -C "$installpath" vendor
# get vendor config
wget https://raw.githubusercontent.com/Araxeus/sync/refs/heads/main/linux-env-vendor-config.yml -O "$vendoryml"
# replace the placeholder in the vendor config with the actual install path
sed -i "0,/REPLACE_WITH_VENDOR_FOLDER/s|REPLACE_WITH_VENDOR_FOLDER|$installpath|" "$vendoryml"
# run vendor to get the rest of the tools
"$installpath/vendor" --config "$vendoryml" add vendorfiles ls-interactive micro ttt fd ripgrep bat fzf tmux gum

# make micro copy to terminal clipboard (works over ssh
# might be bugged in RDM or other unconventional terminals)
mkdir -p "$HOME/.config/micro"
echo '{ "clipboard": "terminal" }' > "$HOME/.config/micro/settings.json"
# disable paging in bat
batconfig=$("$installpath/bat" --config-file)
mkdir -p "$(dirname "$batconfig")"

# appends $1 to $2 (default $WRITE_PATH) unless it is already there (multi-line safe)
write() {
    local text="$1" path="${2:-$WRITE_PATH}"
    touch "$path"
    if [[ "$(<"$path")" != *"$text"* ]]; then
        printf '%s\n' "$text" >> "$path"
    fi
}

write "--paging=never" "$batconfig"

# add to bashrc:
# 1. add installpath to PATH
# 2. add fzf bash completion & fd as default command
# 3. add fd as the default command for fzf
# 4. point vendor to its global config file
# 5. enable lsi - file and directory explorer
WRITE_PATH="$HOME/.bashrc"
write "export PATH=\"$installpath:\$PATH\""
write 'eval "$(fzf --bash)"'
write 'export FZF_DEFAULT_COMMAND="fd --type f"'
write "export DEFAULT_VENDOR_CONFIG=\"$vendoryml\""

shell_funcs=$(cat << 'EOF'
lsi() { 
    local output 
    if output=$(ls-interactive "$@" -x) && [[ $output ]]; then 
        if [ -f "$output" ]; then 
            ttt "$output" 
        else 
            cd "$output" 
        fi 
    fi 
}

TA9_COMPOSE="/home/ta9/compose_files/ta9_development_platform/compose.yml"

logs() {
    local containers
    if [ $# -gt 0 ]; then
        containers="$*"
    else
        containers="$(printf "%s\n" \
            "extensionsapi" \
            "databaseapi" \
            "extensionsgateway" \
            "devportal" \
            "servicesapi" \
            "scmapi" \
            "etlapi" \
            | gum filter --no-limit)"
    fi
    
    tmux new "docker compose -f $TA9_COMPOSE logs -f --tail 100 $containers"
}
EOF
)
write "$shell_funcs"

if command -v apt >/dev/null 2>&1; then
    sudo apt autoremove -y
fi
echo "Setup complete. Please restart your terminal or run 'source ~/.bashrc' to apply changes."
