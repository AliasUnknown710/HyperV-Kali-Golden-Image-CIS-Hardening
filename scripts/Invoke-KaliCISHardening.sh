#!/usr/bin/env bash
# Applies CIS Debian/Linux Level 1 baseline hardening tailored for modern Kali Rolling (Debian Trixie/Sid).
# Usage:
#   sudo bash Invoke-KaliCISHardening.sh --seal                 (Apply CIS & generalize Golden Image)
#   sudo bash Invoke-KaliCISHardening.sh --clone kali-eng-01    (Apply CIS & regenerate unique clone identity)

set -euo pipefail

MODE="${1:-}"
NEW_HOSTNAME="${2:-}"

if [[ $EUID -ne 0 ]]; then
    echo "[!] Run as root: sudo bash $0 [--seal | --clone <HOSTNAME>]"
    exit 1
fi

echo "[+] Step 1: Hardening /dev/shm and disabling legacy filesystems (CIS 1.1)..."
cp -n /etc/fstab /etc/fstab.bak
grep -q "/dev/shm" /etc/fstab || printf "\ntmpfs /dev/shm tmpfs defaults,noexec,nodev,nosuid 0 0\n" >> /etc/fstab
systemctl daemon-reload
mount -o remount,noexec,nodev,nosuid /dev/shm

printf "install cramfs /bin/true\ninstall freevxfs /bin/true\ninstall jffs2 /bin/true\ninstall hfs /bin/true\ninstall hfsplus /bin/true\ninstall udf /bin/true\n" > /etc/modprobe.d/cis-filesystems.conf

echo "[+] Step 2: Applying kernel and network stack sysctl hardening (CIS 3.1-3.3, 1.5)..."
printf "net.ipv4.conf.all.accept_source_route = 0\nnet.ipv4.conf.default.accept_source_route = 0\nnet.ipv4.conf.all.accept_redirects = 0\nnet.ipv4.conf.default.accept_redirects = 0\nnet.ipv4.conf.all.secure_redirects = 0\nnet.ipv4.conf.default.secure_redirects = 0\nnet.ipv4.conf.all.send_redirects = 0\nnet.ipv4.conf.default.send_redirects = 0\nnet.ipv4.conf.all.rp_filter = 1\nnet.ipv4.conf.default.rp_filter = 1\nnet.ipv4.tcp_syncookies = 1\nnet.ipv4.icmp_echo_ignore_broadcasts = 1\nnet.ipv4.icmp_ignore_bogus_error_responses = 1\nnet.ipv4.conf.all.log_martians = 1\nnet.ipv4.conf.default.log_martians = 1\nkernel.kptr_restrict = 2\nkernel.randomize_va_space = 2\nfs.suid_dumpable = 0\n" > /etc/sysctl.d/99-cis-hardening.conf
sysctl --system > /dev/null

echo "[+] Step 3: Configuring UFW host firewall (CIS 3.5)..."
apt-get update -qq && apt-get install -y -qq ufw libpam-pwquality auditd audispd-plugins
ufw default deny incoming
ufw default allow outgoing
ufw --force enable

echo "[+] Step 4: Hardening SSH daemon configuration (CIS 5.2)..."
printf "PermitRootLogin no\nPasswordAuthentication no\nPermitEmptyPasswords no\nPubkeyAuthentication yes\nMaxAuthTries 3\nClientAliveInterval 300\nClientAliveCountMax 2\nX11Forwarding no\nAllowAgentForwarding no\nAllowTcpForwarding no\nLoginGraceTime 60\n" > /etc/ssh/sshd_config.d/99-cis-ssh.conf
sshd -t
systemctl is-active --quiet ssh && systemctl reload ssh || true

echo "[+] Step 5: Configuring PAM password quality, UMASK 027, GRUB, and Cron permissions (CIS 5.4, 5.5, 1.4, 5.1)..."
mkdir -p /etc/security/pwquality.conf.d
printf "minlen = 14\nminclass = 4\nmaxrepeat = 3\n" > /etc/security/pwquality.conf.d/99-cis-pwquality.conf

sed -i 's/^#* *UMASK.*/UMASK\t\t027/' /etc/login.defs
grep -q "^UMASK" /etc/login.defs || printf "\nUMASK\t\t027\n" >> /etc/login.defs
grep -q "pam_umask.so" /etc/pam.d/common-session || echo "session optional pam_umask.so" >> /etc/pam.d/common-session
grep -q "umask 027" /etc/profile || printf "\numask 027\n" >> /etc/profile
grep -q "umask 027" /etc/bash.bashrc || printf "\numask 027\n" >> /etc/bash.bashrc
grep -q "umask 027" /etc/zsh/zshrc || printf "\numask 027\n" >> /etc/zsh/zshrc

chmod 600 /boot/grub/grub.cfg /etc/crontab
chmod 700 /etc/cron.d /etc/cron.daily /etc/cron.hourly /etc/cron.monthly /etc/cron.weekly

echo "[+] Step 6: Configuring auditd rules (CIS 4.1)..."
systemctl enable --now auditd
printf "%s\n" \
  "-w /etc/sudoers -p wa -k scope" \
  "-w /etc/sudoers.d -p wa -k scope" \
  "-w /etc/passwd -p wa -k identity" \
  "-w /etc/group -p wa -k identity" \
  "-w /etc/shadow -p wa -k identity" \
  "-w /etc/gshadow -p wa -k identity" \
  "-a always,exit -F arch=b64 -S init_module,finit_module,delete_module -k modules" > /etc/audit/rules.d/99-cis-audit.rules
augenrules --load

if [[ "$MODE" == "--seal" ]]; then
    echo "[+] Step 7 (SEAL): Stripping SSH host keys, machine-id, and caches for Golden Image..."
    rm -f /etc/ssh/ssh_host_*
    truncate -s 0 /etc/machine-id
    rm -f /var/lib/dbus/machine-id
    apt-get clean
    rm -f /home/*/.zsh_history /home/*/.bash_history /root/.zsh_history /root/.bash_history
    echo "[!] Golden Image sealed. Run 'unset HISTFILE && rm -f ~/.zsh_history ~/.bash_history && sudo shutdown -h now' and mark VHDX Read-Only."
elif [[ "$MODE" == "--clone" ]]; then
    if [[ -z "$NEW_HOSTNAME" ]]; then
        echo "[!] Error: Provide a hostname with --clone (e.g., --clone kali-eng-01)"
        exit 1
    fi
    echo "[+] Step 7 (CLONE): Regenerating unique SSH keys, machine-id, and hostname ($NEW_HOSTNAME)..."
    rm -f /etc/ssh/ssh_host_*
    dpkg-reconfigure -f noninteractive openssh-server
    truncate -s 0 /etc/machine-id
    rm -f /var/lib/dbus/machine-id
    systemd-machine-id-setup
    hostnamectl set-hostname "$NEW_HOSTNAME"
    apt-get clean
    rm -f /home/*/.zsh_history /home/*/.bash_history /root/.zsh_history /root/.bash_history
    echo "[!] Clone '$NEW_HOSTNAME' configured. Run 'passwd <operator>' to set a unique 14+ char complex password."
else
    echo "[+] CIS hardening steps 1-6 complete. Use --seal or --clone <HOSTNAME> for Step 7."
fi
