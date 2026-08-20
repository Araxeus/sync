#!/bin/bash

sudo apt update
sudo apt install wget -y
set -euo pipefail

installpath="$HOME/.local/bin"
mkdir -p "$installpath"

tmpdir=$(mktemp -d)
# The trap removes the temp dir when this shell exits, even if a command fails.
# mktemp uses /tmp by default (or $TMPDIR if set)
trap 'rm -rf "$tmpdir"' EXIT

wget https://github.com/Araxeus/vendorfiles-rs/releases/download/v2.0.3/vendor_v2.0.3_linux.tar.gz -O "$tmpdir/vendor.tar.gz"
tar -xzf "$tmpdir/vendor.tar.gz" -C "$installpath" vendor

wget https://raw.githubusercontent.com/Araxeus/sync/refs/heads/main/linux-env-vendor-config.yml -O "$HOME/vendor.yml"

sed -i "0,/REPLACE_WITH_VENDOR_FOLDER/s|REPLACE_WITH_VENDOR_FOLDER|$installpath|" "$HOME/vendor.yml"

"$installpath/vendor" --config "$HOME/vendor.yml" sync

mkdir -p "$HOME/.config/micro"
echo '{ "clipboard": "terminal" }' > "$HOME/.config/micro/settings.json"

cat << 'EOF' >> "$HOME/.bashrc"
export PATH="$HOME/.local/bin:$PATH"

eval "$(fzf --bash)"
export FZF_DEFAULT_COMMAND="fd --type f"

lsi() { 
   local output 
   if output=$(ls-interactive "$@") && [[ $output ]] ; then 
     cd "$output" 
   fi 
}
EOF

apt autoremove -y
