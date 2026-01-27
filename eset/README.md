# ESET Protect On-Prem Ludus Range

A complete cyber security lab environment built on [Ludus](https://ludus.cloud) featuring ESET Protect On-Prem endpoint management and an Active Directory domain for testing security tools, configurations, and attack scenarios.

## Overview

This project deploys a fully functional corporate network simulation with:
- **ESET Protect On-Prem** server for centralized endpoint management
- **Active Directory** domain (corp.local) with domain controller
- **Windows Server 2022** infrastructure with ESET templates
- **Ubuntu 24.04 LTS** ESET management server
- Automated provisioning and configuration via Ansible

## Network Topology

```
VLAN 10 (10.2.0.0/16)
├── Router: 10.2.10.254 (Debian 11)
├── DC01: 10.2.10.15 (Windows Server 2022 - Domain Controller)
├── eset-server: 10.2.10.10 (Ubuntu 24.04 - ESET Protect Server)
├── SRV01: 10.2.10.21 (Windows Server 2022 - Domain Member)
├── SRV02: 10.2.10.22 (Windows Server 2022 - Domain Member)
├── SRV03: 10.2.10.23 (Windows Server 2022 - Domain Member)
└── SRV04: 10.2.10.24 (Windows Server 2022 - Domain Member)
```

## Features

### ESET Protect On-Prem
- Full ESET management console
- MySQL 8.0 database backend
- Apache Tomcat 9 web server
- Web console: https://10.2.10.10:8443/era
- Automated installation via custom Ansible role

### Active Directory Domain
- Domain: corp.local
- Organizational Units: Workstations, Servers
- Domain Admin and standard user accounts
- DNS and DHCP services

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
- Test Group Policy deployment
- Practice domain enumeration techniques
- Test lateral movement scenarios

### Network Security
- Capture network traffic between VMs
- Test DNS configurations
- Analyze domain authentication traffic

### Software Deployment
- Test application installation methods
- Practice Group Policy software deployment
- Deploy custom scripts and tools

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

- **Deployment time**: 30-60 minutes (depending on sysprep and domain operations)
- **ESET installation**: 10-15 minutes
- **Total range size**: ~7 VMs (6 Windows + 1 Ubuntu)
- **Minimum RAM**: 28 GB (4 GB per VM)

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
