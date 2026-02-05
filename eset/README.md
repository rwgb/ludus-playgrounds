# ESET Protect On-Prem Ludus Range

A complete cybersecurity lab environment built on [Ludus](https://ludus.cloud) featuring ESET Protect On-Prem endpoint management and an Active Directory domain for testing security tools, configurations, and attack scenarios.

## 📋 Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [Quick Start](#quick-start)
- [Network Topology](#network-topology)
- [VM Specifications](#vm-specifications)
- [Features](#features)
- [Deployment](#deployment)
- [Access & Credentials](#access--credentials)
- [Custom Ansible Roles](#custom-ansible-roles)
- [Testing Mode](#testing-mode)
- [Troubleshooting](#troubleshooting)
- [Development](#development)

## Overview

This project deploys a fully functional corporate network simulation with:

- **ESET Protect On-Prem** server for centralized endpoint management
- **Active Directory** domain (eset.local) with domain-joined systems
- **5 Virtual Machines** (1 Ubuntu, 3 Windows Servers, 1 Windows 11 Workstation)
- **ESET Components**: Bridge, Rogue Detection Sensor, Inspector, ESA, EEE
- **Automated provisioning** via 7 custom Ansible roles
- **Domain-joined Ubuntu** server using realm/sssd
- **Testing mode** with 300+ ESET cloud service allowlists

**Deployment Time:** ~45-60 minutes (automated)

## Architecture

### Infrastructure Components

| Component | Purpose | Technology |
|-----------|---------|------------|
| **ESET Management Console** | Centralized endpoint security management | Ubuntu 24.04, MySQL 8.0, Apache Tomcat 9 |
| **Active Directory** | Domain services and authentication | Windows Server 2022 (eset.local) |
| **ESET Bridge** | Cloud connector for ESET services | Windows Server 2022 |
| **Rogue Detection Sensor** | Network device detection | Windows Server 2022 (requires WinPcap) |
| **ESET Inspector** | Advanced threat analysis | Windows Server 2022 |
| **Client Workstation** | Test endpoint for policies | Windows 11 Enterprise |

### Deployment Strategy

1. **Infrastructure Setup** - Ludus creates VMs from templates
2. **Domain Configuration** - Primary DC promotion, domain join
3. **Software Installation** - ESET Protect, Java, component installers
4. **Role Application** - Custom Ansible roles configure each system
5. **Verification** - Automated checks confirm successful deployment

## Quick Start

```bash
# 1. Navigate to ESET playground
cd eset

# 2. Upload custom Ansible roles to Ludus server
make upload-roles

# 3. Configure the range
make config

# 4. Deploy the range (creates VMs and runs provisioning)
make deploy

# 5. Monitor deployment progress
ludus range logs -f

# 6. Check deployment status
make status

# 7. Connect via WireGuard VPN
ludus user wireguard > ludus-range.conf
sudo wg-quick up ./ludus-range.conf  # Or import to GUI client
```

Access ESET Console: **https://10.2.10.10:8443/era**

## Network Topology

```
VLAN 10 (10.2.0.0/16)
├── Router: 10.2.10.254 (Debian 11 - Auto-provisioned by Ludus)
├── eset-server: 10.2.10.10 (Ubuntu 24.04 - ESET Protect Server - Domain Member)
├── SRV01: 10.2.10.21 (Windows Server 2022 - Primary DC)
├── SRV02: 10.2.10.22 (Windows Server 2022 - Domain Member - ESET Bridge/RDS)
├── SRV03: 10.2.10.23 (Windows Server 2022 - Domain Member - ESET Inspector)
└── WIN11: 10.2.10.30 (Windows 11 Enterprise - Domain Member)
```

**Network Details:**
- **Subnet:** 10.2.0.0/16
- **VLAN:** 10
- **DNS:** Managed by SRV01 (AD DNS)
- **WireGuard VPN:** Required for access from outside Ludus network

## VM Specifications

| VM Name | Hostname | IP | OS | RAM | vCPU | Role | Domain |
|---------|----------|----|----|-----|------|------|--------|
| ubuntu-eset-server | eset-server | 10.2.10.10 | Ubuntu 24.04 | 4 GB | 2 | ESET Protect Server | Member |
| eee-esa | SRV01 | 10.2.10.21 | Windows Server 2022 | 6 GB | 2 | Primary Domain Controller | DC |
| member-server | SRV02 | 10.2.10.22 | Windows Server 2022 | 4 GB | 2 | ESET Bridge/RDS Host | Member |
| inspector-server | SRV03 | 10.2.10.23 | Windows Server 2022 | 8 GB | 4 | ESET Inspector Host | Member |
| win11-workstation | WIN11 | 10.2.10.30 | Windows 11 22H2 Enterprise | 4 GB | 2 | Client Workstation | Member |

**Total Resources:** 26 GB RAM, 14 vCPUs

## Features

### ESET Protect On-Prem (eset-server)

✅ **Fully Automated Installation**
- MySQL 8.0 database backend
- Apache Tomcat 9 web server
- ESET Protect Server (latest version)
- Automated database initialization
- SSL certificate generation

🌐 **Web Console Access**
- URL: https://10.2.10.10:8443/era
- Username: `Administrator`
- Password: `EsetAdminPass!2024`

🔐 **Database Configuration**
- MySQL Root Password: `StrongRootPass!2024`
- ESET DB User: `era_user`
- ESET DB Password: `StrongDbPass!2024`

🏢 **Domain Integration**
- Joined to eset.local domain via realm
- SSSD configured for AD authentication
- Automatic home directory creation

### Active Directory Domain (eset.local)

**Primary Domain Controller (SRV01)**
- ✅ Fully automated DC promotion
- ✅ DNS server configuration
- ✅ Java 11 installed (for ESET Secure Authentication)
- ✅ Chocolatey package manager
- 📦 **Pre-downloaded Installers** (C:\ESET_Installers\):
  - ESET Secure Authentication (esa_nt32nt64_enu.exe)
  - ESET Endpoint Encryption (eees_nt32.msi)

**Default Domain Administrator**
- Username: `Administrator`
- Password: `password`

⚠️ **Security Note:** Default passwords are intentionally weak for lab use. Never use in production!

### ESET Components

**SRV02 - Bridge & Rogue Detection Sensor**
- ✅ ESET Bridge installer downloaded
- ✅ Rogue Detection Sensor installer downloaded
- ✅ ESET Bridge installed automatically
- ⚠️ **Manual Installation Required:**
  - WinPcap/Npcap (prerequisite for RDS)
  - Rogue Detection Sensor (after WinPcap)

**SRV03 - ESET Inspector**
- ✅ ESET Inspector Server installer downloaded (C:\ESET_Installers\ei_server_nt64.msi)
- 📝 Install manually after deployment
- 💡 Requires 8GB RAM for optimal performance

### Security Hardening Disabled (Lab Environment)

⚠️ **WARNING:** This environment intentionally disables security features for testing purposes. **NEVER** deploy to production networks!

All Windows VMs have:
- ❌ User Account Control (UAC) disabled
- ❌ Windows Defender disabled
- ❌ Windows Firewall disabled (Domain profile only)
- ✅ Software installation restrictions removed
- ✅ AlwaysInstallElevated policy enabled

## Deployment

### Prerequisites

1. **Ludus Server Access**
   ```bash
   ludus user apikey  # Verify authentication
   ```

2. **Required Ansible Collections**
   ```bash
   # Not needed - roles use PowerShell instead of ansible.windows
   ```

3. **System Requirements** (Proxmox/Ludus Server)
   - 26 GB RAM available
   - 14 CPU cores available
   - ~150 GB disk space

### Deployment Steps

#### 1. Initial Setup

```bash
# Clone repository
git clone https://github.com/rwgb/ludus-playgrounds.git
cd ludus-playgrounds/eset

# Upload custom Ansible roles to Ludus server
make upload-roles
```

#### 2. Configure Range

```bash
# Set range configuration
make config

# Verify configuration
ludus range config get
```

#### 3. Deploy Range

```bash
# Full deployment (VMs + provisioning)
make deploy

# Monitor deployment in real-time
ludus range logs -f  # Ctrl+C to exit

# Alternative: Check status periodically
make status
```

#### 4. Handle Expected Errors

**Domain Controller Reboots** (Normal Behavior)
```bash
# DC promotion requires reboot - deployment will pause
# Wait ~5 minutes, then retry
make retry-deploy
```

**WireGuard VPN Setup**
```bash
# Generate VPN configuration
ludus user wireguard > ludus-range.conf

# Connect (Linux/macOS)
sudo wg-quick up ./ludus-range.conf

# Disconnect
sudo wg-quick down ./ludus-range.conf

# Or import ludus-range.conf into WireGuard GUI client
```

### Deployment Timeline

| Phase | Duration | Description |
|-------|----------|-------------|
| VM Creation | 5-10 min | Proxmox creates VMs from templates |
| Windows Sysprep | 5-10 min | Windows generalization process |
| DC Promotion | 10-15 min | SRV01 becomes domain controller |
| Domain Joins | 5-10 min | Member systems join eset.local |
| ESET Installation | 15-20 min | Ubuntu server installs ESET Protect |
| Role Execution | 5-10 min | Ansible roles configure systems |
| **Total** | **45-75 min** | Full automated deployment |

### Makefile Targets

```bash
make upload-roles      # Upload all custom roles to Ludus
make config            # Set range configuration
make deploy            # Full deployment (VMs + provisioning)
make retry-deploy      # Retry after DC reboot or transient errors
make status            # Show range status
make errors            # Display deployment errors
make logs              # Show full deployment logs
make destroy           # Delete entire range
make all               # config + deploy (full workflow)
```

### Advanced Targets

```bash
make clean-old-roles   # Remove deprecated role names from Ludus
make refresh-roles     # Delete all roles and re-upload fresh copies
make eset-logs         # Filter logs for ESET installation progress
make domain-status     # Filter logs for AD domain operations
```

## Access & Credentials

### ESET Protect Console

**Web Interface:**
```
URL: https://10.2.10.10:8443/era
Username: Administrator
Password: EsetAdminPass!2024
```

**Database Access:**
```bash
# SSH to eset-server
ssh ludus@10.2.10.10  # Password: password

# MySQL root access
sudo mysql -u root -p  # Password: StrongRootPass!2024

# ESET database user
mysql -u era_user -p era_db  # Password: StrongDbPass!2024
```

### Active Directory Domain

**Domain:** eset.local

**Domain Administrator:**
```
Username: eset\Administrator (or Administrator@eset.local)
Password: password
```

**All Windows VMs:**
```
Local Admin: .\localuser
Password: password
```

**Ubuntu Server:**
```
SSH: ludus@10.2.10.10
Password: password (Ludus default)

# Domain users can also authenticate
ssh localuser@eset.local@10.2.10.10
```

### Remote Desktop Access

```bash
# Windows VMs (via WireGuard VPN)
rdesktop 10.2.10.21  # SRV01
rdesktop 10.2.10.22  # SRV02
rdesktop 10.2.10.23  # SRV03
rdesktop 10.2.10.30  # WIN11

# Or use any RDP client
# Username: eset\Administrator
# Password: password
```

### Verification Commands

```bash
# Check domain join status (Ubuntu)
ssh ludus@10.2.10.10 "realm list"

# Test domain user authentication (Ubuntu)
ssh ludus@10.2.10.10 "id Administrator@eset.local"

# Check ESET service status
ssh ludus@10.2.10.10 "sudo systemctl status eraserver"

# Verify DNS resolution
nslookup eset.local
nslookup SRV01.eset.local
```

## Custom Ansible Roles

### Role Inventory

| Role Name | Target OS | Purpose |
|-----------|-----------|---------|
| `linux-domain-join` | Ubuntu | Join Linux systems to AD domain using realm/sssd |
| `install-eset` | Ubuntu | Install ESET Protect Server with MySQL and Tomcat |
| `windows-setup` | Windows | Disable UAC/Defender/Firewall, install Chocolatey, reboot |
| `install-java` | Windows | Install Java 11, set JAVA_HOME, configure PATH |
| `download-eset-esa-eee` | Windows | Download ESA and EEE installers |
| `download-eset-inspector` | Windows | Download ESET Inspector server installer |
| `install-eset-bridge-rds` | Windows | Download and install ESET Bridge, download RDS installer |

### Role Details

#### linux-domain-join
**Purpose:** Join Ubuntu systems to eset.local Active Directory domain

**Features:**
- Installs realmd, sssd, krb5, adcli packages
- Configures systemd-resolved DNS to use domain controller
- Discovers and joins domain using realm
- Configures SSSD for domain authentication
- Enables automatic home directory creation
- Retry logic for DC availability

**Variables:** (defaults/main.yml)
```yaml
ad_domain: "eset.local"
ad_realm: "ESET.LOCAL"
ad_admin_user: "Administrator"
ad_admin_password: "password"
ad_dc_hostname: "SRV01.eset.local"
ad_dc_ip: "10.2.10.21"
```

#### install-eset
**Purpose:** Automated ESET Protect Server installation on Ubuntu

**Installation Includes:**
- MySQL 8.0 server
- Apache Tomcat 9
- ESET Protect Server (latest version)
- Database initialization
- Service configuration

**Variables:** (defaults/main.yml)
```yaml
mysql_root_password: "StrongRootPass!2024"
eset_admin_password: "EsetAdminPass!2024"
db_user_username: "era_user"
db_user_password: "StrongDbPass!2024"
```

**Installation Script:** https://github.com/rwgb/eset.epop.tools/blob/dev/scripts/linux/install-eset.sh

#### windows-setup
**Purpose:** Prepare Windows systems for software installation

**Tasks:**
1. Disable UAC via registry
2. Disable Windows Installer restrictions
3. Disable software restriction policies
4. Disable Windows Defender
5. Disable Windows Firewall (Domain profile)
6. Check if Chocolatey is installed
7. **Reboot if Chocolatey not installed** (allows security changes to take effect)
8. Install Chocolatey package manager
9. Install Git via Chocolatey

**Why the reboot?** Registry changes (UAC disable) don't take effect until reboot, causing Chocolatey installation to fail with access denied errors.

#### install-java
**Purpose:** Install Java 11 for ESET Secure Authentication

**Tasks:**
1. Install OpenJDK 11 via Chocolatey
2. Detect Java installation path
3. Set JAVA_HOME system environment variable
4. Add Java bin directory to system PATH
5. Verify installation

#### download-eset-esa-eee
**Purpose:** Download ESET Secure Authentication and Endpoint Encryption installers

**Downloads to:** `C:\ESET_Installers\`
- esa_nt32nt64_enu.exe
- eees_nt32.msi

**Note:** Installers are downloaded but not automatically installed. Manual installation required.

#### download-eset-inspector
**Purpose:** Download ESET Inspector server installer

**Downloads to:** `C:\ESET_Installers\ei_server_nt64.msi`

**Note:** Manual installation required after deployment.

#### install-eset-bridge-rds
**Purpose:** Download ESET Bridge and Rogue Detection Sensor, install Bridge

**Tasks:**
1. Create C:\ESET_Installers directory
2. Download ESET Bridge installer (esetbridge_nt64.msi)
3. Download Rogue Detection Sensor installer (rdsensor_x64.msi)
4. Install ESET Bridge automatically
5. Display manual installation instructions for RDS

**Manual Steps Required:**
1. Install WinPcap or Npcap (with WinPcap compatibility mode)
2. Install Rogue Detection Sensor
3. Configure RDS connection to ESET Protect server

### Role Upload and Management

```bash
# Upload all roles
make upload-roles

# Upload single role
ludus ansible role add -d roles/linux-domain-join

# Force re-upload (overwrite existing)
ludus ansible role rm linux-domain-join
ludus ansible role add -d roles/linux-domain-join

# List uploaded roles
ludus ansible role list

# Remove role
ludus ansible role rm role-name

# Clean up old/deprecated roles
make clean-old-roles
```

## Testing Mode

**⚠️ WARNING:** Testing mode is designed for controlled malware analysis in isolated lab environments. Use only in air-gapped networks or dedicated security lab infrastructure.

### Purpose

Block all outbound internet traffic except ESET cloud services, enabling safe malware testing while maintaining ESET updates and functionality.

### Features

- **300+ ESET Service Allow lists** (domains + IPs)
- **Firewall rule management** via Ludus CLI
- **Granular control** over allowed services
- **Quick enable/disable** testing mode

### Usage

```bash
# Block ALL outbound traffic
make testing-start

# Allow ESET cloud services (300+ domains/IPs)
make testing-allow-eset

# Check current firewall rules
make testing-status

# Restore full internet access
make testing-stop

# Add custom allowlist
ludus testing allow -d example.com
ludus testing allow -i 203.0.113.10
```

### Allowlist Files

- `eset-allowlist-domains.txt` - 300+ ESET service domains
- `eset-allowlist-ips.txt` - ESET cloud IP addresses

### Example Workflow

```bash
# 1. Enable testing mode
make testing-start

# 2. Allow ESET services
make testing-allow-eset

# 3. Run malware sample (all other traffic blocked)
# ... perform analysis ...

# 4. Disable testing mode
make testing-stop
```

## Troubleshooting

### Common Issues

#### 1. Deployment Stuck or Errors

**Symptom:** `ludus range errors` shows failures

**Solution:**
```bash
# Check specific errors
ludus range errors

# Retry deployment (idempotent)
make retry-deploy

# Check detailed logs
ludus range logs | tail -100
```

#### 2. Domain Controller Promotion Errors

**Symptom:** `DCPromo exited with 15: Role change is in progress`

**Why:** This is EXPECTED. Domain controller promotion requires a reboot.

**Solution:**
```bash
# Wait 3-5 minutes for reboot
sleep 300

# Retry deployment
make retry-deploy
```

#### 3. Windows 11 Sysprep Timeout

**Symptom:** `timeout when waiting for 10.2.10.30:5986`

**Why:** Windows 11 sysprep takes 5-10 minutes

**Solution:**
```bash
# Wait for sysprep to complete
sleep 600

# Retry deployment
make retry-deploy
```

#### 4. ESET Installation Failed

**Check if already installed:**
```bash
ssh ludus@10.2.10.10 "systemctl status eraserver"
```

**View installation logs:**
```bash
ssh ludus@10.2.10.10 "sudo journalctl -u eraserver -n 100"
```

**Manually re-run installer:**
```bash
ssh ludus@10.2.10.10
sudo /tmp/install-eset.sh
```

#### 5. Domain Join Failed (Ubuntu)

**Check realm status:**
```bash
ssh ludus@10.2.10.10 "realm list"
```

**Verify DNS resolution:**
```bash
ssh ludus@10.2.10.10 "nslookup eset.local"
ssh ludus@10.2.10.10 "nslookup SRV01.eset.local"
```

**Manual domain join:**
```bash
ssh ludus@10.2.10.10
echo "password" | sudo realm join --user=Administrator eset.local --verbose
```

#### 6. WinRM Connection Failures

**Symptom:** `timeout when waiting for <IP>:5986`

**Causes:**
- VM still booting
- Sysprep in progress
- Network not ready

**Solution:**
```bash
# Wait 5-10 minutes
sleep 600

# Check VM status in Proxmox
ludus range list

# Retry deployment
make retry-deploy
```

### Diagnostic Commands

```bash
# Range status
make status
ludus range list

# Deployment errors
make errors
ludus range errors

# Full logs
make logs
ludus range logs

# Filter logs for specific component
make eset-logs           # ESET installation
make domain-status       # AD domain operations

# Live log monitoring
ludus range logs -f      # Ctrl+C to exit

# Check specific VM
ludus range logs | grep -A 20 "RB-ubuntu-eset-server"

# Network connectivity
ping 10.2.10.10
ping 10.2.10.21

# SSH access
ssh ludus@10.2.10.10
ssh -o StrictHostKeyChecking=no ludus@10.2.10.10

# RDP access (requires WireGuard VPN)
rdesktop 10.2.10.21
```

### Getting Help

1. **Check existing documentation:**
   - [TROUBLESHOOTING.md](TROUBLESHOOTING.md) - Detailed diagnostic procedures
   - [AI-AGENT-TODO.md](AI-AGENT-TODO.md) - Known issues and future improvements

2. **Ludus Documentation:**
   - https://docs.ludus.cloud

3. **ESET Resources:**
   - https://help.eset.com/protect_admin/11.0/en-US/

## Development

### Project Structure

```
eset/
├── config.yml                      # Range VM definitions
├── Makefile                        # Deployment automation
├── README.md                       # This file
├── TROUBLESHOOTING.md             # Detailed diagnostics
├── AI-AGENT-TODO.md               # Development roadmap
├── eset-allowlist-domains.txt     # Testing mode allowlist
├── eset-allowlist-ips.txt         # Testing mode allowlist
└── roles/                         # Custom Ansible roles
    ├── linux-domain-join/
    ├── install-eset/
    ├── windows-setup/
    ├── install-java/
    ├── download-eset-esa-eee/
    ├── download-eset-inspector/
    └── install-eset-bridge-rds/
```

### Creating a New Role

```bash
# Create role directory structure
mkdir -p roles/my-new-role/{defaults,meta,tasks,templates,handlers}

# Create required files
touch roles/my-new-role/defaults/main.yml
touch roles/my-new-role/meta/main.yml
touch roles/my-new-role/tasks/main.yml

# Add role to config.yml
# roles:
#   - my-new-role

# Upload role
ludus ansible role add -d roles/my-new-role

# Test role
make retry-deploy
```

### Modifying Existing Roles

```bash
# Edit role tasks
vim roles/install-eset/tasks/main.yml

# Re-upload role (delete + add for clean upload)
ludus ansible role rm install-eset
ludus ansible role add -d roles/install-eset

# Test changes
make retry-deploy
```

### Best Practices

1. **Idempotency:** All roles should be safe to re-run
2. **Error Handling:** Use `failed_when`, `ignore_errors`, `retries`
3. **Conditionals:** Check if software already installed before installing
4. **Variables:** Use defaults/main.yml for configurable values
5. **Documentation:** Comment complex tasks, update README
6. **Testing:** Test roles individually before full deployment

### Git Workflow

```bash
# Create feature branch
git flow feature start my-feature

# Make changes
git add -A
git commit -m "feat: add new role for XYZ"

# Push changes
git flow feature publish my-feature

# Finish feature (merges to develop)
git flow feature finish my-feature
```

## License

MIT

## Contributing

Contributions welcome! Please:

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

## Credits

- **Ludus** - https://ludus.cloud
- **ESET** - https://www.eset.com
- **ESET Install Script** - https://github.com/rwgb/eset.epop.tools

---

**Last Updated:** February 2026
**Ludus Version:** Compatible with Ludus 1.x
**ESET Protect Version:** Latest (auto-downloaded during installation)
```

## Features

### ESET Protect On-Prem
- Full ESET management console
- MySQL 8.0 database backend
- Apache Tomcat 9 web server
- Web console: https://10.2.10.10:8443/era
- Automated installation via custom Ansible role

### Active Directory Domain
- Domain: eset.local
- Primary Domain Controller: SRV01 (10.2.10.21)
  - Java (OpenJDK) installed
  - ESET Secure Authentication installer (C:\ESET_Installers\esa_nt32nt64_enu.exe)
  - ESET Endpoint Encryption installer (C:\ESET_Installers\eees_nt32.msi)
  - Chocolatey package manager
  - Domain user: **localuser** (Password: password)
    - Member of Domain Admins
    - Member of Schema Admins
- Alternate Domain Controller: SRV02 (10.2.10.22)
  - ESET Bridge installed (esetbridge_nt64.msi)
  - Rogue Detection Sensor installed (rdsensor_x64.msi)
  - WinPcap installed (required for RD Sensor)
  - Chocolatey package manager
- Alternate Domain Controller: SRV03 (10.2.10.23)
  - ESET Inspector installer (C:\ESET_Installers\ei_server_nt64.msi)
  - Chocolatey package manager
- 1 Windows 11 Enterprise workstation (WIN11)
  - Chocolatey package manager
- All systems have security restrictions disabled for testing

### Security Configuration
- Software installation restrictions **disabled** on all Windows servers
- UAC disabled for easier testing
- Windows Firewall disabled
- Windows Defender disabled
- PowerShell execution policy: Unrestricted

**⚠️ Warning:** This range is intentionally insecure for testing purposes. Do not expose to production networks.

## Prerequisites

- [Ludus](https://ludus.cloud) server access
- Ludus CLI configured and authenticated
- WireGuard client for VPN access to the range
- Required Ludus templates:
  - `ubuntu-24.04-x64-server-template`
  - `win2022-server-x64-eset-template`

## Installation

### 1. Clone the Repository

```bash
git clone <repository-url>
cd "ludus playgrounds/eset"
```

### 2. Upload Custom Ansible Roles

```bash
make upload-roles
```

This uploads:
- `install-eset` - Installs ESET Protect On-Prem on Ubuntu
- `disable-software-restrictions` - Removes Windows security restrictions

### 3. Deploy the Range

```bash
# Set configuration and deploy
make all

# Or step by step:
make config    # Set the Ludus range configuration
make deploy    # Deploy all VMs and provision them
```

### 4. Monitor Deployment

Watch the deployment progress in real-time:

```bash
ludus range logs -f    # Press Ctrl+C to stop
```

Or check specific logs:

```bash
make eset-logs         # Show ESET installation logs
make domain-status     # Show domain controller logs
make errors            # Show any deployment errors
```

## Access

### WireGuard VPN

1. Get your WireGuard configuration:
   ```bash
   ludus user wireguard > ludus-range.conf
   ```

2. Connect using WireGuard client:
   - **GUI**: Import `ludus-range.conf` in WireGuard app
   - **CLI**: `sudo wg-quick up ./ludus-range.conf`

3. Once connected, you have direct access to all VMs on the 10.2.0.0/16 network

### Credentials

#### ESET Protect Console
- **URL**: https://10.2.10.10:8443/era
- **Username**: Administrator
- **Password**: EsetAdminPass!2024

#### ESET Database
- **Username**: era_user
- **Password**: StrongDbPass!2024
- **Root Password**: StrongRootPass!2024

#### Active Directory
- **Domain**: corp.local
- **Domain Admin**: `CORP\domainadmin` / `password`
- **Domain User**: `CORP\domainuser` / `password`

#### Windows Local Administrator
- **Username**: `.\Administrator` (use .\ prefix for local account)
- **Password**: (set by template - check Ludus template documentation)

#### Ubuntu Server
- **Username**: (default SSH user from template)
- **Access**: SSH to 10.2.10.10

### Remote Desktop (RDP)

Once connected via WireGuard VPN:

```bash
# Microsoft Remote Desktop
open rdp://10.2.10.15    # DC01
open rdp://10.2.10.21    # SRV01
open rdp://10.2.10.22    # SRV02
open rdp://10.2.10.23    # SRV03
open rdp://10.2.10.24    # SRV04
```

Or use any RDP client (Microsoft Remote Desktop, Remmina, etc.)

### SSH Access

```bash
ssh user@10.2.10.10    # Ubuntu ESET server
```

## Project Structure

```
eset/
├── config.yml                          # Main Ludus range configuration
├── Makefile                            # Automation commands
├── README.md                           # This file
├── AGENT_INSTRUCTIONS.md               # AI agent context documentation
├── TROUBLESHOOTING.md                  # Detailed troubleshooting guide
├── AI-AGENT-TODO.md                    # Future AI agent development roadmap
├── ludus-range.conf                    # WireGuard VPN configuration
├── roles/
│   ├── install-eset/                   # ESET installation role
│   │   ├── meta/main.yml
│   │   ├── defaults/main.yml
│   │   └── tasks/main.yml
│   └── disable-software-restrictions/  # Windows security removal role
│       ├── meta/main.yml
│       ├── defaults/main.yml
│       └── tasks/main.yml
└── eset-lab.yml                        # Standalone ESET playbook
```

## Usage

### Common Commands

```bash
# Deployment
make all              # Configure and deploy the range
make config           # Set the range configuration
make deploy           # Deploy all VMs
make retry-deploy     # Retry a failed deployment

# Monitoring
make status           # Show range status
make errors           # Show deployment errors
make eset-logs        # Show ESET installation logs
make domain-status    # Show domain controller status

# Diagnostics
make diagnose-winrm   # Test WinRM connectivity to all Windows hosts

# Maintenance
make upload-roles     # Upload custom Ansible roles
make list-roles       # List installed roles
make destroy          # Destroy the entire range
make clean            # Destroy and redeploy from scratch

# Help
make help             # Show all available commands
```

### Check Range Status

```bash
ludus range status
```

Expected output when healthy:
```
DEPLOYMENT STATUS: SUCCESS
NUMBER OF VMS: 7
```

### Deploying ESET Agents to Windows Machines

1. Access ESET Web Console: https://10.2.10.10:8443/era
2. Login with Administrator / EsetAdminPass!2024
3. Navigate to **Admin** → **Installation Packages**
4. Download Windows agent installer
5. Deploy to SRV01-04 via Group Policy or manual installation

Since software restrictions are disabled, you can install directly on any server.

## Troubleshooting

### Deployment Errors

Check for errors:
```bash
make errors
```

Common issues:
- **WinRM timeout**: Windows VMs may need time after sysprep (wait 10 min, retry)
- **Domain join failure**: DC may need more time to promote (retry deployment)
- **Network unreachable**: Ludus API timeout (wait and retry)

See [TROUBLESHOOTING.md](TROUBLESHOOTING.md) for detailed diagnostics.

### ESET Installation Failed

Check ESET-specific logs:
```bash
make eset-logs
```

Look for:
- MySQL installation errors
- Tomcat deployment issues
- ESET server service failures

### Domain Issues

Check domain logs:
```bash
make domain-status
```

### Can't Access VMs

1. Verify WireGuard VPN is connected:
   ```bash
   wg show    # Should show active connection
   ```

2. Test connectivity:
   ```bash
   ping 10.2.10.10
   ping 10.2.10.15
   ```

3. Check VM status:
   ```bash
   make status
   ```

### Software Installation Blocked on Windows

The `disable-software-restrictions` role should prevent this, but if it persists:

1. Verify role was applied:
   ```bash
   ludus range logs | grep disable-software-restrictions
   ```

2. Check registry settings on affected VM via RDP:
   ```powershell
   Get-ItemProperty HKLM:\SOFTWARE\Policies\Microsoft\Windows\Installer
   ```

3. Manually disable UAC:
   ```powershell
   Set-ItemProperty -Path HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System -Name EnableLUA -Value 0
   ```

## Configuration

### Modifying the Range

Edit [config.yml](config.yml) to:
- Add/remove VMs
- Change IP addresses
- Adjust resource allocation (RAM, CPUs)
- Add additional roles

After changes:
```bash
make config
make deploy
```

### Customizing ESET Installation

Edit [roles/install-eset/defaults/main.yml](roles/install-eset/defaults/main.yml) to change:
- MySQL root password
- ESET admin password (min 14 chars with uppercase + symbol)
- Database credentials

### Adding Custom Ansible Roles

1. Create role in `roles/` directory:
   ```bash
   mkdir -p roles/my-role/{tasks,meta,defaults}
   ```

2. Upload to Ludus:
   ```bash
   ludus ansible role add -d roles/my-role
   ```

3. Add to VM config in `config.yml`:
   ```yaml
   roles:
     - my-role
   ```

## Testing Scenarios

This range supports various security testing scenarios:

### Endpoint Protection Testing
- Deploy ESET agents to all Windows servers
- Test malware detection and prevention
- Configure ESET policies and exclusions

### Active Directory Testing
- Test multi-DC replication and failover
- Practice domain enumeration techniques
- Test lateral movement scenarios
- Practice Kerberos authentication
- Test Group Policy deployment across DCs
- Deploy ESET Secure Authentication for MFA testing
- Deploy ESET Endpoint Encryption for disk encryption testing

### Network Security
- Capture network traffic between VMs
- Test DNS configurations
- Analyze domain authentication traffic

### Software Deployment
- Test application installation methods
- Practice Group Policy software deployment
- Deploy custom scripts and tools

## Testing Mode (Firewall Control)

Ludus provides a testing mode that blocks all outbound internet traffic from your range. This is useful for:
- **Malware analysis**: Prevent malware from communicating with C2 servers
- **Controlled testing**: Ensure tools only communicate with known services
- **Compliance**: Meet security testing requirements for isolated environments

### Using Testing Mode

#### Enable Testing Mode

Block all outbound traffic:
```bash
make testing-start
```

This blocks all internet access from the range. VMs can still communicate with each other internally.

#### Allow ESET Services

To enable ESET cloud connectivity (updates, telemetry, LiveGrid):
```bash
make testing-allow-eset
```

This allowlists:
- **300+ ESET domains** - Update servers, LiveGrid, PROTECT, antispam, etc.
- **200+ IP addresses** - ESET infrastructure endpoints
- Source: [ESET KB332](https://support.eset.com/en/kb332)

Files used:
- [eset-allowlist-domains.txt](eset-allowlist-domains.txt) - All required ESET domains
- [eset-allowlist-ips.txt](eset-allowlist-ips.txt) - All required ESET IPs

#### Check Testing Mode Status

```bash
make testing-status
```

Shows:
- Whether testing mode is enabled
- Currently allowed domains
- Currently allowed IP addresses

#### Add Custom Domains or IPs

Allow a specific domain:
```bash
make testing-allow-domain
# Enter domain when prompted, e.g., example.com
```

Allow a specific IP:
```bash
make testing-allow-ip
# Enter IP when prompted, e.g., 1.2.3.4
```

Or use Ludus directly:
```bash
# Single domain
ludus testing allow -d example.com

# Multiple domains
ludus testing allow -d example.com,test.com

# Single IP
ludus testing allow -i 1.2.3.4

# From file (one entry per line)
ludus testing allow -f custom-allowlist.txt
```

#### Disable Testing Mode

Restore full internet access:
```bash
make testing-stop
```

### Testing Mode Examples

**Scenario 1: Malware Analysis**
```bash
# 1. Enable testing mode (block all traffic)
make testing-start

# 2. Allow only ESET services
make testing-allow-eset

# 3. Run malware sample - cannot reach C2 servers
# 4. Analyze ESET detection behavior safely

# 5. Restore internet when done
make testing-stop
```

**Scenario 2: Controlled Updates**
```bash
# 1. Block all traffic
make testing-start

# 2. Allow only specific update servers
ludus testing allow -d windowsupdate.microsoft.com,download.microsoft.com

# 3. Allow ESET updates
make testing-allow-eset

# 4. Perform controlled updates only from allowed sources
```

**Scenario 3: Custom Tool Testing**
```bash
# 1. Enable testing mode
make testing-start

# 2. Allow only your own infrastructure
ludus testing allow -d mycompany.com -i 203.0.113.10

# 3. Test custom tools with restricted internet
```

### Testing Mode Notes

- ⚠️ Testing mode is **optional** - ESET works fine without it
- ✅ Use it when you need **strict traffic control**
- 🔒 Internal VM-to-VM traffic is **always allowed**
- 🌐 Allowlisted domains are resolved on the **Ludus server** (not in VMs)
- 📝 Allowlists persist until testing mode is stopped
- 🚫 Blocking traffic does **not** affect VPN access to VMs



## Maintenance

### Updating Roles

After modifying Ansible roles:
```bash
make upload-roles    # Re-upload all roles
make deploy-roles    # Apply only user-defined roles
```

### Redeploying Individual VMs

Ludus doesn't support individual VM redeployment. To update a single VM:
1. Remove it from config.yml
2. Run `make config && make deploy`
3. Add it back to config.yml
4. Run `make config && make deploy` again

### Backing Up Configuration

```bash
# Backup current config
cp config.yml config.yml.backup

# Save WireGuard config
ludus user wireguard > ludus-range-backup.conf
```

## Performance Notes

- **Deployment time**: 20-40 minutes (depending on sysprep)
- **ESET installation**: 10-15 minutes
- **Total range size**: 5 VMs (4 Windows + 1 Ubuntu)
- **Minimum RAM**: 20 GB (4 GB per VM)

## Security Considerations

⚠️ **This range is intentionally vulnerable for testing purposes:**

- Software restrictions disabled
- UAC disabled
- Windows Firewall disabled
- Windows Defender disabled
- Weak passwords used for demonstration

**Do not**:
- Expose this range to the internet
- Use production credentials
- Store sensitive data
- Connect to production networks

## License

[Specify your license here]

## Contributing

[Specify contribution guidelines]

## Support

For issues:
1. Check [TROUBLESHOOTING.md](TROUBLESHOOTING.md)
2. Review Ludus logs: `ludus range logs`
3. Check Ludus documentation: https://docs.ludus.cloud

## Acknowledgments

- [Ludus](https://ludus.cloud) - Cyber range platform
- [ESET](https://www.eset.com) - Endpoint protection software
- Ansible community for automation tools

## Version History

- **v1.0** - Initial release
  - ESET Protect On-Prem automated installation
  - Active Directory domain with 5 Windows servers
  - Software restriction removal for easy testing
  - Comprehensive documentation and troubleshooting
