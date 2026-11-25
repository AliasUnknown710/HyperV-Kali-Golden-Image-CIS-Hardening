# Golden Image & Engagement VM Catalog

This catalog tracks the master golden template and active engagement clones provisioned from it. All instances share a consistent non-root operator username for script compatibility while enforcing unique 14+ character complex passwords, distinct `/etc/machine-id` values, and unique SSH host keys per instance.

| VM Name | Guest Hostname | Role | Operator Account | Hardening Baseline | Disk Configuration | Network Switch | Status |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **`Kali-Golden-Master`** | `kali` (sealed) | Master Golden Image | Dedicated Operator (Unique PW) | CIS Debian L1 + Kali Exceptions | Read-Only Master VHDX | Disconnected (Sealed) | **Active Master** |
| **`Kali-Eng-01`** | `kali-eng-01` | Engagement VM 01 | Dedicated Operator (Unique PW) | CIS Debian L1 + Unique Keys/Machine-ID | Differencing VHDX | `Dedicated-USB-External-Switch` | **Active** |
| **`Kali-Eng-02`** | `kali-eng-02` | Engagement VM 02 | Dedicated Operator (Unique PW) | CIS Debian L1 + Unique Keys/Machine-ID | Differencing VHDX | `Dedicated-USB-External-Switch` | **Active** |
