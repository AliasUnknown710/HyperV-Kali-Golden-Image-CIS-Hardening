# Hyper-V Kali Golden Images (`hyperv-kali-golden-images`)

Standardized provisioning, CIS Debian/Linux Level 1 baseline hardening, and lifecycle management for Kali Linux Rolling penetration testing virtual machines on Windows Hyper-V.

## Why CIS Controls for an Offensive VM?

Penetration testing distributions prioritize tool availability over default OS security—shipping with open inbound firewall policies, permissive default `umask` values (`022`), unhardened SSH configurations, and disabled system auditing. Applying **CIS (Center for Internet Security) Debian/Linux Level 1 Benchmarks** (with documented offensive-tooling exceptions) provides three core benefits:

1. **Attack Surface Reduction on Hostile Networks:** Engagement VMs frequently bridge directly onto untrusted networks or run temporary listeners. Default-deny inbound firewall rules, hardened sysctl parameters, and locked-down SSH prevent lateral movement or opportunistic compromise of the assessment platform itself.
2. **Evidence Integrity & Non-Repudiation:** Enforcing `UMASK 027` prevents low-privilege local daemons from reading sensitive scan results or loot, while `auditd` maintains a local execution trail proving non-interference during engagements.
3. **Repeatable, Drift-Free Baselines:** Mapping hardening to an industry-recognized framework turns ad-hoc VM setup into an auditable, repeatable standard.

## Architecture & Workflow

This repository enforces a deterministic **Golden Image -> Engagement Clone** lifecycle to prevent configuration drift, cross-engagement data contamination, and duplicate DHCP/SSH network identities:

1. **Golden Image (`Kali-Golden-Master`)**: Built as a Hyper-V Generation 2 VM, configured with a dedicated non-root operator account, updated via `NetworkManager` (`nmcli`), hardened to CIS Debian/Linux Level 1 standards, stripped of machine-specific identifiers (`ssh_host_*`, `/etc/machine-id`, shell history), and sealed as a **Read-Only** VHDX.
2. **Engagement VMs (`Kali-Eng-<ID>`)**: Provisioned via differencing VHDX disks linked to `Kali-Golden-Master`, assigned unique hostnames, regenerated SSH host keys, distinct 128-bit `/etc/machine-id` DHCP client identifiers, and unique 14+ character complex operator passwords.

## Repository Structure

```text
hyperv-kali-golden-images/
├── README.md
├── docs/
│   ├── build-process.md
│   ├── network-design.md
│   ├── image-catalog.md
│   └── update-and-reset-policy.md
├── scripts/
│   ├── New-KaliGoldenImage.ps1
│   ├── New-EngagementVM.ps1
│   └── Invoke-KaliCISHardening.sh
├── configs/
│   └── core-pentest.txt
└── diagrams/
    └── architecture.mmd
```

## Quick Start

1. **Provision a New Golden Image VM:**
   ```powershell
   .\scripts\New-KaliGoldenImage.ps1 -VMName "Kali-Golden-Master" -ISOPath "D:\ISOs\kali-linux-installer-amd64.iso" -SwitchName "Dedicated-USB-External-Switch"
   ```
2. **Apply Automated CIS Hardening & Seal Inside Kali:**
   ```bash
   sudo bash scripts/Invoke-KaliCISHardening.sh --seal
   ```
3. **Spawn an Engagement VM:**
   ```powershell
   .\scripts\New-EngagementVM.ps1 -EngagementName "Kali-Eng-01" -GoldenVHDPath "C:\HyperV\VHDs\Kali-Golden-Master.vhdx" -SwitchName "Dedicated-USB-External-Switch"
   ```
