# Linux Setup

Instructions for setting up my custom Linux environment.

## Setting up SSH Key

If you don't have an SSH key pair, generate one using the following command:

```bash
ssh-keygen -t rsa
```

Copy the public key to the remote server:

```bash
ssh-copy-id user@remote-server
```

or if you want to manually copy the key, display it with:

```bash
cat ~/.ssh/id_rsa.pub
```

windows:

```batch
type %userprofile%\.ssh\id_rsa.pub
```

and paste it into the `~/.ssh/authorized_keys` file on the remote server.

full windows example:

```batch
ssh-keygen -t rsa
type %userprofile%\.ssh\id_rsa.pub | ssh root@10.0.0.69 "mkdir -p ~/.ssh && cat >> ~/.ssh/authorized_keys"
```

## first steps

<https://community-scripts.github.io/ProxmoxVE/scripts?id=post-pve-install>

* Update and upgrade the system packages:

````bash
apt update && apt upgrade -y
````

* Install essential tools:

````bash
apt install curl wget git unzip -y
````

if we are in a proxmox guest, install qemu-guest-agent for better integration

````bash
if [ -f /usr/sbin/qemu-ga ]; then
    apt install qemu-guest-agent -y
    systemctl enable qemu-guest-agent
    systemctl start qemu-guest-agent
fi
````

in proxmox host, make sure to enable the guest agent in the VM options.

```bash
qm set VMID --agent 1
```

* set timezone

Set the timezone to your desired location (example: America/New_York):

```bash
timedatectl set-timezone Israel/Jerusalem
```

* install tools

```bash
mkdir -p ~/path
echo 'export PATH=$HOME/path:$PATH' >> ~/.bashrc
source ~/.bashrc

apt install btop fd-find ripgrep bat fzf fastfetch -y

# install oh my posh
curl -s https://ohmyposh.dev/install.sh | bash -s -- -d ~/path

# create symlink for fd
ln -s $(which fdfind) ~/path/fd

# create symlink for bat
ln -s $(which batcat) ~/path/bat

# global install use update-alternatives to register micro as a system text editor
cd ~/path
curl https://getmic.ro/r | sh

echo '{ "clipboard": "terminal" }' > ~/.config/micro/settings.json

# The trap removes the temp dir when this shell exits, even if a command fails.
# mktemp uses /tmp by default (or $TMPDIR if set)
trap 'rm -rf "$tmpdir"' EXIT

tmpdir="$(mktemp -d)"

# get bitwarden cli (bw)
wget "https://bitwarden.com/download/?app=cli&platform=linux" -O $tmpdir/bw.zip
unzip $tmpdir/bw.zip -d $tmpdir
mv $tmpdir/bw ~/path/bw

# get ls-interactive
wget https://github.com/Araxeus/ls-interactive/releases/download/v1.7.0/lsi_v1.7.0_linux.tar.gz -O $tmpdir/lsi.tar.gz
tar -xzf $tmpdir/lsi.tar.gz -C ~/path ls-interactive

# get dysk (need to update version)
wget https://dystroy.org/dysk/download/dysk_3.5.0.zip -O "$tmpdir/dysk.zip"
unzip -j "$tmpdir/dysk.zip" "build/x86_64-unknown-linux-gnu/dysk" -d ~/path
# chmod +x ~/path/dysk

# get fastfetch (need to update version)
# wget https://github.com/fastfetch-cli/fastfetch/releases/latest/download/fastfetch-linux-amd64.zip -O "$tmpdir/fastfetch.zip"
# unzip -j "$tmpdir/fastfetch.zip" "fastfetch-linux-amd64/usr/bin/fastfetch" -d ~/path

# get atuin (shell/distro dependent)
curl --proto '=https' --tlsv1.2 -LsSf https://setup.atuin.sh | sh

# get bottom x86-64 (deb/ubuntu - need to update version)
curl -Lo $tmpdir/bottom.deb https://github.com/ClementTsang/bottom/releases/download/0.11.4/bottom_0.11.4-1_amd64.deb
dpkg -i $tmpdir/bottom.deb

# get mprocs (install tmux if need more)
wget https://github.com/pvolok/mprocs/releases/download/v0.8.0/mprocs-0.8.0-linux-x86_64-musl.tar.gz -O $tmpdir/mprocs.tar.gz
tar -xzf $tmpdir/mprocs.tar.gz -C ~/path mprocs

# multiplexers:
# Tmux, Zellij
# Terminals:
# Wezterm, Alacritty, Kitty, Ghostty

# get gdu
curl -L https://github.com/dundee/gdu/releases/latest/download/gdu_linux_amd64.tgz | tar xz
chmod +x gdu_linux_amd64
mv gdu_linux_amd64 /usr/bin/gdu

apt autoremove -y
````

## bashrc Configuration

````bash
# use nano if micro is not available
micro ~/.bashrc
````

Add the following aliases and functions to your `.bashrc` file:

```bash
# install ls-interactive
lsi() { 
   local output 
   if output=$(ls-interactive "$@") && [[ $output ]] ; then 
     cd "$output" 
   fi 
}

eval "$(fzf --bash)"

### Smart completions
# keeps 100,000 commands in memory
HISTSIZE=100000
# keeps 200,000 commands in history file.
HISTFILESIZE=200000
# skips duplicate sequential commands and cleans old duplicates
HISTCONTROL=ignoredups:erasedups
# appends to the history file instead of overwriting it when closing
shopt -s histappend
# writes and reloads history after every single command so all open windows stay synced
PROMPT_COMMAND="history -a; history -n"
## Arrow controls are configured in ~/.inputrc

export PATH=$PATH:~/.local/bin

eval "$(oh-my-posh init bash --config powerlevel10k_rainbow)"
```

## custom dns

```bash
# edit resolv to use quad9 dns (9.9.9.9)
nano /etc/resolv.conf

# edit proxmox network config
nano /etc/network/interfaces

# edit hostfile to point to proxmox host (10.0.0.69)
nano /etc/hosts
```

## SFTP windows setup

```batch
winget install SSHFS-Win.SSHFS-Win

setx PATH "%PATH%;C:\Program Files\SSHFS-Win\bin"

ssh-keygen -t rsa
```

if root:

```batch
type %userprofile%/.ssh/id_rsa.pub | ssh root@10.0.0.69 "mkdir -p ~/.ssh && cat >> ~/.ssh/authorized_keys"

sshfs-win cmd root@10.0.0.69:/srv/torrents X: -o idmap=user -o reconnect -o Ciphers=arcfour -o allow_other
```

else user:

```batch
type %userprofile%/.ssh/id_rsa.pub | ssh root@proxmox-ip "
mkdir -p /srv/torrents/.ssh && \
cat >> /srv/torrents/.ssh/authorized_keys && \
chown -R torrentuser:torrentuser /srv/torrents/.ssh && \
chmod 700 /srv/torrents/.ssh && \
chmod 600 /srv/torrents/.ssh/authorized_keys
"
```

save the following as `%userprofile%/mount-sftp.bat`

```batch
@echo off
REM ================================
REM Auto-mount SFTP torrent folder
REM ================================

REM Set variables
SET DRIVE=X:
SET USER=torrentuser
SET HOST=10.0.0.69
SET REMOTE=/srv/torrents

REM Wait for network to initialize
timeout /t 5 /nobreak >nul

REM Unmount drive if it exists (avoids conflicts)
net use %DRIVE% /delete /y >nul 2>&1

REM Mount SFTP folder via SSHFS-Win
sshfs-win cmd %USER%@%HOST%:%REMOTE% %DRIVE% -o idmap=user -o reconnect -o allow_other

REM Check result
if errorlevel 1 (
    echo Mount failed. Check network and credentials.
) else (
    echo Mount successful: %DRIVE% mapped to %REMOTE%
)
```

### Make it run automatically at login

Option A — Startup folder (simplest)

1. Press Win + R → type shell:startup → Enter

2. Copy mount_torrents.bat into the folder

3. It will run every time you log in

Option B — Task Scheduler (silent + robust)

1. Open Task Scheduler

2. Click Create Task

3. General → Name: Mount Torrent Drive
   * Check Run only when user is logged on
   * Check Run with highest privileges

4. Triggers → New → At log on → OK

5. Actions → New → Action: Start a program → Program/script: "%userprofile%/mount-sftp.bat"
   * Check Hidden

6. Conditions → optionally uncheck Start the task only if the computer is on AC power

7. Settings → Check Run task as soon as possible after a scheduled start is missed

This will run silently, reconnect if needed, and avoid a command window popping up (if you choose “Hidden” in Actions).

## Fully automated powershell script

[register-sftp-scheduler](./register-sftp-scheduler.ps1)

[register-sftp-service](./register-sftp-service.ps1)
