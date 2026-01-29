# Agent Instructions

## Purpose
Deploy a Ludus range containing:
- Ubuntu 24.04 server with ESET Protect On-Prem (centralized endpoint management)
- Active Directory domain (eset.local) with 3 Windows Server 2022 domain controllers
- Windows 11 Enterprise workstation
- ESET ecosystem tools: Bridge, Rogue Detection Sensor, Inspector, Secure Authentication, Endpoint Encryption
- Automated provisioning via custom Ansible roles

## Network Topology
- VLAN 10 (10.2.0.0/16)
- Router: 10.2.10.254 (Debian 11)
- eset-server: 10.2.10.10 (Ubuntu 24.04 - ESET Protect Server)
- SRV01: 10.2.10.21 (Primary DC - eset.local)
- SRV02: 10.2.10.22 (Alternate DC - eset.local)
- SRV03: 10.2.10.23 (Alternate DC - eset.local)
- WIN11: 10.2.10.30 (Windows 11 Enterprise Workstation)

## Key Files
- **config.yml**: Range definition with 5 VMs (1 Ubuntu, 3 Windows Servers, 1 Win11)
- **Makefile**: Automation targets for deployment, role upload, testing mode
- **roles/**: 10 custom Ansible roles
- **eset-allowlist-domains.txt**: 300+ ESET cloud service domains for testing mode
- **eset-allowlist-ips.txt**: 200+ ESET infrastructure IPs for testing mode
- **README.md**: Comprehensive documentation
- **TROUBLESHOOTING.md**: Diagnostic procedures

## Ansible Roles
1. **install-eset**: Installs ESET Protect On-Prem on Ubuntu (MySQL, Tomcat, web console)
2. **disable-software-restrictions**: Disables UAC, firewall, Defender, Windows Installer restrictions
3. **install-chocolatey**: Installs Chocolatey package manager on Windows systems
4. **install-java**: Installs OpenJDK via Chocolatey (SRV01)
5. **download-eset-tools**: Downloads ESA and EEE installers (SRV01)
6. **install-eset-bridge-rds**: Installs ESET Bridge, Rogue Detection Sensor, WinPcap (SRV02)
7. **download-eset-inspector**: Downloads ESET Inspector server installer (SRV03)
8. **configure-domain-user**: Creates domain user 'localuser' with Domain Admin and Schema Admin privileges
9. **create-domain-users**: (if exists) Additional domain user provisioning
10. **download-eset-installers**: (if exists) Additional ESET installer downloads

## Role Application (config.yml)
- **eset-server**: install-eset
- **SRV01** (Primary DC): disable-software-restrictions, install-chocolatey, install-java, download-eset-tools, configure-domain-user
- **SRV02** (Alt DC): disable-software-restrictions, install-chocolatey, install-eset-bridge-rds
- **SRV03** (Alt DC): disable-software-restrictions, install-chocolatey, download-eset-inspector
- **WIN11**: disable-software-restrictions, install-chocolatey

## Templates Used
- Ubuntu: ubuntu-24.04-x64-server-template
- Servers: win2022-server-x64-template
- Workstation: win11-22h2-x64-enterprise-template

## Credentials
- **ESET Web Console**: https://10.2.10.10:8443/era
  - Username: Administrator
  - Password: EsetAdminPass!2024
- **MySQL Root**: StrongRootPass!2024
- **ESET Database**: era_user / StrongDbPass!2024
- **Domain User**: eset.local\localuser / password
  - Member of Domain Admins and Schema Admins

## Commands

### Deployment
```bash
make upload-roles    # Upload all 10 custom roles to Ludus
make config          # Set range configuration
make deploy          # Deploy full range
make retry-deploy    # Retry after domain controller reboot errors
make status          # Check deployment status
make errors          # View deployment errors
make logs            # View full deployment logs
make eset-logs       # View ESET-specific logs
make domain-status   # View domain controller status
```

### Testing Mode (Firewall Control)
```bash
make testing-start         # Block all outbound traffic
make testing-allow-eset    # Allow ESET cloud services
make testing-status        # Show allowed domains/IPs
make testing-stop          # Restore full internet
make testing-allow-domain  # Interactively add custom domain
make testing-allow-ip      # Interactively add custom IP
```

### Cleanup
```bash
make destroy    # Destroy the range
make clean      # Destroy and redeploy from scratch
```

## Prerequisites
- **Ansible collection required**: `ludus ansible collection add ansible.windows`
  - Provides: win_chocolatey, win_get_url, win_package, win_domain_user, win_domain_group_membership, win_regedit
  - Without this collection, all Windows roles will fail with module not found errors

## Common Issues & Solutions

### 1. Ansible Module Not Found
**Error**: `couldn't resolve module/action 'ansible.windows.win_chocolatey'`
**Solution**: Install the Windows collection
```bash
ludus ansible collection add ansible.windows
make retry-deploy
```

### 2. Domain Controller Promotion Failed
**Error**: `DCPromo exited with 15: Role change is in progress or this computer needs to be restarted`
**Solution**: This is expected for alternate DCs. Retry deployment:
```bash
make retry-deploy
```

### 3. WinRM Timeout on Windows VMs
**Issue**: Windows VMs may timeout during sysprep (especially Win11)
**Solution**: Wait 10-15 minutes and retry deployment

### 4. Domain Join Failures
**Issue**: "Unable to find Active Directory Web Services"
**Solution**: DC promotion takes time. Wait and retry:
```bash
make retry-deploy
```

### 5. Role Not Found During Deployment
**Solution**: Ensure roles are uploaded
```bash
make upload-roles
ludus ansible role list  # Verify all 10 roles present
```

## ESET Software Locations

### Pre-downloaded Installers (Manual Installation Required)
- **SRV01**: C:\ESET_Installers\
  - esa_nt32nt64_enu.exe (ESET Secure Authentication)
  - eees_nt32.msi (ESET Endpoint Encryption)
- **SRV03**: C:\ESET_Installers\
  - ei_server_nt64.msi (ESET Inspector Server)

### Auto-installed Components
- **eset-server**: ESET Protect On-Prem (full installation)
- **SRV02**: ESET Bridge, Rogue Detection Sensor, WinPcap

## Testing Mode Use Cases

### Malware Analysis
```bash
make testing-start          # Block all outbound
make testing-allow-eset     # Allow ESET services only
# Run malware samples safely - cannot reach C2 servers
make testing-stop           # Restore when done
```

### Controlled Updates
```bash
make testing-start
ludus testing allow -d windowsupdate.microsoft.com,download.microsoft.com
make testing-allow-eset
# Only allowed services can communicate
```

### Custom Tool Testing
```bash
make testing-start
ludus testing allow -d mycompany.com -i 203.0.113.10
# Test tools with restricted internet
```

## Development Workflow

### Adding a New Role
1. Create role structure in `roles/new-role-name/`
2. Add role to appropriate VM in config.yml
3. Update Makefile upload-roles target
4. Upload and deploy:
```bash
make upload-roles
make config
make deploy
```

### Modifying Existing Configuration
1. Edit config.yml
2. Set new config and redeploy:
```bash
make config
make deploy
```

### Testing Changes
1. Make changes to roles
2. Re-upload and run roles:
```bash
make upload-roles
make deploy-roles  # Runs only user-defined roles
```

## Performance Notes
- **Deployment time**: 30-60 minutes (includes domain promotion, ESET installation)
- **Total VMs**: 6 (1 router, 1 Ubuntu, 3 Windows Servers, 1 Win11)
- **Minimum RAM**: 24 GB (4 GB per VM)
- **Storage**: ~150 GB (including templates)

## Security Warnings
⚠️ **This range is intentionally vulnerable for testing:**
- All Windows security features disabled (UAC, Firewall, Defender)
- Weak passwords used for demonstration
- Software installation restrictions removed
- **Do not** expose to production networks or internet
- **Do not** use production credentials
- **Do not** store sensitive data

## Expectations
- Keep edits minimal; preserve YAML formatting
- Default to ASCII for compatibility
- Do not revert user changes without explicit instruction
- Avoid destructive git commands (force push, hard reset)
- Always test role changes in development before production deployment
- Document any manual configuration steps in README.md
- Update this file when adding new roles or changing architecture
