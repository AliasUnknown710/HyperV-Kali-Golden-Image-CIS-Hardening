# Hyper-V Virtual Network Design

## Single-Switch Dedicated External NIC Architecture

On a mobile assessment workstation (Windows laptop), network traffic is physically and logically separated between the host OS and penetration testing VMs using a single **External Virtual Switch** bound to a secondary **USB wireless adapter**:

* **Host Isolation (`AllowManagementOS $false` or dedicated USB NIC):** The laptop's built-in network adapter handles normal host OS traffic, while the secondary USB wireless adapter is dedicated to the Hyper-V External Virtual Switch (`Dedicated-USB-External-Switch`) for assessment traffic and package updates.
* **Shared Virtual Switch Across VMs:** Because Hyper-V enforces a strict 1-to-1 binding between an External Virtual Switch and a physical network adapter, the Golden Image (during staging updates) and all engagement clones attach to the same External Virtual Switch.

## Identity & DHCP Collision Prevention

Multiple VMs safely share `Dedicated-USB-External-Switch` without IP address or SSH key collisions because every engagement clone undergoes identity regeneration (`scripts/Invoke-KaliCISHardening.sh --clone <Hostname>`) on first boot:

1. **Unique Virtual MAC Address:** Hyper-V dynamically assigns a distinct MAC address (`00-15-5D-*`) to each VM's virtual network adapter.
2. **Unique DHCP Client Identifier (`DUID` / `machine-id`):** Modern Linux (`NetworkManager` / `systemd`) derives its DHCP Client ID from `/etc/machine-id`. Truncating and regenerating `/etc/machine-id` ensures the upstream router or access point issues a separate DHCP lease to each clone.
3. **Unique Hostname & SSH Host Keys:** Regenerating `/etc/ssh/ssh_host_*` (RSA, ECDSA, ED25519, MLDSA44-ED25519) and setting a distinct hostname prevents man-in-the-middle warnings and DNS/mDNS name collisions.
