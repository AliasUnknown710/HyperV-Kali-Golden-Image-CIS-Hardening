# Golden Image Build & CIS Hardening Process (Kali Rolling / Debian Base)

## Phase 1: Base OS Installation (Hyper-V Generation 2)
1. Execute `scripts/New-KaliGoldenImage.ps1` on the Hyper-V host to provision a Generation 2 VM with Secure Boot disabled (`Off`) and Dynamic Memory configured.
2. Install Kali Linux Rolling (Zsh default shell) and create a dedicated non-root administrative operator account (removing or avoiding the default `kali` username).
3. Attach the VM to `Dedicated-USB-External-Switch` for package installation. Verify interface status using `nmcli device status`.

## Phase 2: Standardized Tooling Manifest
Update the base OS and install the curated offensive toolset defined in `configs/core-pentest.txt`:
```bash
sudo apt update && sudo apt full-upgrade -y
xargs -a configs/core-pentest.txt sudo apt install -y
```

## Phase 3: CIS Level 1 Hardening & Modern Kali Adjustments
Each control below balances host defense with offensive testing requirements and accounts for modern Kali Rolling defaults:

### 1. Filesystem & Legacy Kernel Module Hardening (CIS 1.1.1 / 1.1.2)
* **What:** Mounts `/dev/shm` with `noexec,nodev,nosuid` in `/etc/fstab` (using a leading newline to avoid parse errors on files lacking a trailing newline) and blacklists unused filesystem drivers (`cramfs`, `freevxfs`, `jffs2`, `hfs`, `hfsplus`, `udf`) in `/etc/modprobe.d/cis-filesystems.conf`.
* **Why:** Prevents untrusted payloads from executing directly out of world-writable shared memory and eliminates kernel privilege-escalation attack surface in unmaintained filesystem drivers.

### 2. Kernel & Network Stack Sysctl Hardening (CIS 1.5 / 3.1–3.3)
* **What:** Deploys `/etc/sysctl.d/99-cis-hardening.conf` to disable IP source routing and ICMP redirects, enforce strict Reverse Path Filtering (`rp_filter=1`, overriding Kali's default loose mode `2`), enable TCP SYN cookies, restrict kernel pointer leaks (`kptr_restrict=2`), enforce full ASLR (`randomize_va_space=2`), and disable SUID core dumps (`fs.suid_dumpable=0`).
* **Why:** Protects the assessment box from routing-table poisoning, IP spoofing, and kernel memory disclosure on shared networks. *Offensive Exception:* Temporarily set `rp_filter=0` on an engagement clone during active LLMNR/NBT-NS spoofing (`responder` or `mitm6`).

### 3. Host Firewall Configuration (CIS 3.5.1)
* **What:** Installs and enables `ufw` with a `default deny incoming` and `default allow outgoing` policy.
* **Why:** Kali defaults to accepting all inbound traffic. A default-deny inbound firewall prevents unsolicited network scans or lateral movement attempts from reaching temporary engagement listeners unless explicitly permitted.

### 4. SSH Server Hardening (CIS 5.2)
* **What:** Configures `/etc/ssh/sshd_config.d/99-cis-ssh.conf` to enforce key-only authentication (`PasswordAuthentication no`), block direct root login (`PermitRootLogin no`), cap authentication retries (`MaxAuthTries 3`), set idle session timeouts (`ClientAliveInterval 300`), and disable X11/agent/TCP forwarding.
* **Why:** Ensures that if the SSH service is started temporarily during an engagement for file transfers, it cannot be brute-forced or abused for pivot forwarding.

### 5. Password Complexity, `UMASK 027`, & File Permissions (CIS 1.4.2, 5.1, 5.4, 5.5)
* **What:** Configures `libpam-pwquality` in `/etc/security/pwquality.conf.d/99-cis-pwquality.conf` (`minlen=14`, `minclass=4`, `maxrepeat=3`), locks down `/boot/grub/grub.cfg` (`600`) and `/etc/cron*` (`600`/`700`), and enforces `UMASK 027`. Because modern Debian/Kali removed the `UMASK` line from `/etc/login.defs`, `UMASK 027` is explicitly appended to `/etc/login.defs`, `pam_umask.so` is enabled in `/etc/pam.d/common-session`, and `umask 027` is enforced in `/etc/profile`, `/etc/bash.bashrc`, and `/etc/zsh/zshrc`.
* **Why:** Ensures newly created scan results and loot files are not world-readable (`640` instead of `644`) and enforces strong unique authenticators across all clones.

### 6. System Auditing (`auditd`) (CIS 4.1.1 / 4.1.3)
* **What:** Enables `auditd` and loads `/etc/audit/rules.d/99-cis-audit.rules` to watch `/etc/sudoers`, `/etc/passwd`, `/etc/shadow`, and kernel module syscalls (`init_module`, `finit_module`, `delete_module`).
* **Why:** Maintains a local audit trail of privilege escalation and system modifications for engagement accountability.

## Phase 4: Generalization & Sealing (`Kali-Golden-Master`)
Before marking the Golden Image VHDX as **Read-Only**, strip machine-specific identities and purge Zsh history without writing back to disk:
```bash
sudo rm -f /etc/ssh/ssh_host_*
sudo truncate -s 0 /etc/machine-id
sudo rm -f /var/lib/dbus/machine-id
sudo apt clean
unset HISTFILE && rm -f ~/.zsh_history ~/.bash_history
sudo shutdown -h now
```
Once powered off in Hyper-V Manager, lock the VHDX on the Windows host:
```powershell
\$GI_VHD = (Get-VMHardDiskDrive -VMName "Kali-Golden-Master").Path
Set-ItemProperty -Path \(GI_VHD -Name IsReadOnly -Value\)true
```
