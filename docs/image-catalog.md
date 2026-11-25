# CIS Hardening Verification Screenshot Catalog & Image Baseline

## Verification Screenshots (`docs/screenshots/`)

The 8 sanitized screenshots in `docs/screenshots/` document the end-to-end CIS Debian/Linux Level 1 baseline hardening and clone identity regeneration sequence applied to Kali Linux Rolling:

| Screenshot File | Hardening Phase | CIS Control Mapping | Commands & Verified Outcome |
| :--- | :--- | :--- | :--- |
| **`CIS_Hardening_Step_1.png`** | Phase 1: Filesystem & Kernel Modules | CIS 1.1.1.1–1.1.1.6, CIS 1.1.2.2 | Configures `/dev/shm` with `noexec,nodev,nosuid` in `/etc/fstab` (verified via `findmnt -n /dev/shm`) and blacklists `cramfs`, `freevxfs`, `jffs2`, `hfs`, `hfsplus`, and `udf` in `/etc/modprobe.d/cis-filesystems.conf`. |
| **`CIS_Hardening_Step_2_P1.png`** | Phase 2 (Part 1): Kernel & Network Stack Sysctl | CIS 1.5.1, 1.5.3, 3.1.2, 3.2.1–3.2.8 | Writes `/etc/sysctl.d/99-cis-hardening.conf` and applies all kernel network and memory parameters via `sysctl --system` (disabling redirects/source routing, enabling `rp_filter=1`, `tcp_syncookies=1`, `kptr_restrict=2`, ASLR `2`, and `fs.suid_dumpable=0`). |
| **`CIS_Hardening_Step_2_P2.png`** | Phase 2 (Part 2): Kernel Parameter Validation | CIS 1.5.1, 3.2.7, 3.2.8 | Confirms active kernel values via `sudo sysctl` (`net.ipv4.tcp_syncookies = 1`, `net.ipv4.conf.all.rp_filter = 1`, `kernel.kptr_restrict = 2`). |
| **`CIS_Hardening_Step_3.png`** | Phase 3: Host Firewall Configuration | CIS 3.5.1.1, 3.5.1.3, 3.5.1.6 | Installs `ufw`, enforces `default deny incoming` and `default allow outgoing`, enables the service, and verifies `Status: active` via `sudo ufw status verbose`. |
| **`CIS_Hardening_Step_4.png`** | Phase 4: SSH Server Configuration | CIS 5.2.4–5.2.5, 5.2.8, 5.2.10, 5.2.12, 5.2.16–5.2.17 | Deploys `/etc/ssh/sshd_config.d/99-cis-ssh.conf` (disabling root login, password auth, empty passwords, and forwarding; setting `MaxAuthTries 3`, `ClientAliveInterval 300`, `LoginGraceTime 60`) and validates syntax with `sudo sshd -t`. |
| **`CIS_Hardening_Step_5.png`** | Phase 5: PAM Password Quality, `UMASK 027`, & Permissions | CIS 1.4.2, 5.1.2–5.1.7, 5.4.1, 5.5.4 | Configures `libpam-pwquality` (`minlen=14`, `minclass=4`, `maxrepeat=3`), restricts `/boot/grub/grub.cfg` (`600`), `/etc/crontab` (`600`), and `/etc/cron.*` (`700`), enforces `UMASK 027` across `/etc/login.defs`, `pam_umask.so`, `/etc/profile`, `/etc/bash.bashrc`, and `/etc/zsh/zshrc`, and confirms `027` in a login shell. |
| **`CIS_Hardening_Step_6.png`** | Phase 6: System & Kernel Auditing | CIS 4.1.1.1–4.1.1.2, 4.1.3.1–4.1.3.2, 4.1.3.8, 4.1.3.19 | Installs and enables `auditd`, writes `/etc/audit/rules.d/99-cis-audit.rules` monitoring `sudoers`, `/etc/passwd`, `/etc/shadow`, `/etc/group`, `/etc/gshadow`, and module syscalls (`init_module`, `finit_module`, `delete_module`), and loads rules via `augenrules --load` and `auditctl -l`. |
| **`CIS_Hardening_Step_7.png`** | Phase 7: Clone Identity Regeneration & Hygiene | CIS 5.2.1–5.2.3 & Image Hygiene | Regenerates unique SSH host keys (`RSA`, `ECDSA`, `ED25519`, `MLDSA44-ED25519`), resets `/etc/machine-id` via `systemd-machine-id-setup`, sets a unique hostname via `hostnamectl`, cleans APT caches, and purges shell history. |

---

## Golden Image & Engagement VM Baseline

| VM Name | Guest Hostname | Role | Operator Account | Hardening Baseline | Disk Configuration | Network Switch | Status |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **`Kali-Golden-Master`** | `kali` (sealed) | Master Golden Image | Dedicated Operator (Unique PW) | CIS Debian L1 + Kali Exceptions | Read-Only Master VHDX | Disconnected (Sealed) | **Active Master** |
| **`Kali-Eng-01`** | `kali-eng-01` | Engagement VM 01 | Dedicated Operator (Unique PW) | CIS Debian L1 + Unique Keys/Machine-ID | Differencing VHDX | `Dedicated-USB-External-Switch` | **Active** |
| **`Kali-Eng-02`** | `kali-eng-02` | Engagement VM 02 | Dedicated Operator (Unique PW) | CIS Debian L1 + Unique Keys/Machine-ID | Differencing VHDX | `Dedicated-USB-External-Switch` | **Active** |
