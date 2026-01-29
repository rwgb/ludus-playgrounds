# Ludus Playgrounds - AI Coding Agent Instructions

## Project Overview

This repository contains Infrastructure-as-Code (IaC) for deploying cybersecurity lab environments using [Ludus](https://ludus.cloud), a platform for building reproducible cyber ranges. Each "playground" is a complete, self-contained lab environment with automated provisioning via Ansible.

**Current Playgrounds:**
- `eset/` - ESET Protect On-Prem endpoint security lab with Active Directory (fully operational)
- `game of active directory (GOAD)/` - Planned GOAD implementation (empty)
- `pentesting/` - Planned pentesting lab (empty)

## Architecture: Ludus + Ansible Pattern

### Core Workflow
1. **Define** infrastructure in `config.yml` (VM specifications, network topology)
2. **Upload** custom Ansible roles to Ludus server: `ludus ansible role add -d roles/<role-name>`
3. **Configure** range: `ludus range config set -f config.yml`
4. **Deploy** VMs and run provisioning: `ludus range deploy`
5. **Monitor** with `ludus range logs -f`
6. **Access** via WireGuard VPN: `ludus user wireguard > ludus-range.conf`

### VM Configuration Schema (config.yml)
```yaml
ludus:
  - vm_name: "{{ range_id }}-hostname"  # Automatically prefixed with user's range ID
    hostname: "SHORT-NAME"               # Windows hostname or Linux hostname
    template: ubuntu-24.04-x64-server-template  # Ludus template name
    vlan: 10                             # VLAN number (10 = primary network)
    ip_last_octet: 10                    # VM gets 10.{vlan}.{ip_last_octet}.{user_octet}
    ram_gb: 4
    cpus: 2
    linux: true                          # OR windows: {sysprep: true}
    domain:                              # Windows-only: AD domain settings
      fqdn: eset.local
      role: primary-dc                   # primary-dc, alt-dc, or member
    roles:                               # Custom Ansible roles to apply
      - role-name-1
      - role-name-2
```

### Ansible Role Structure
All custom roles follow standard Ansible Galaxy structure:
```
roles/<role-name>/
├── defaults/
│   └── main.yml          # Default variables
├── meta/
│   └── main.yml          # Role metadata
└── tasks/
    └── main.yml          # Tasks to execute
```

**Critical:** Windows roles REQUIRE the `ansible.windows` collection:
```bash
ludus ansible collection add ansible.windows
```

## ESET Playground Specifics

### Network Topology
- **VLAN 10** (10.2.0.0/16) - All systems on same network
- **Router:** 10.2.10.254 (Debian 11, auto-provisioned by Ludus)
- Network addressing: `10.{vlan}.{ip_last_octet}.{user_range_id}`

### Role Application Strategy
Roles are applied in the order listed in `config.yml`. Dependencies are handled through role ordering:
1. `disable-software-restrictions` - FIRST on Windows (disables UAC, Defender, firewall)
2. `install-chocolatey` - Package manager for Windows
3. Domain-specific roles (e.g., `install-java`, `download-eset-tools`)

### Makefile Targets (eset/)
```bash
make upload-roles   # Upload ALL custom roles (run after modifying any role)
make config         # Set range configuration (idempotent)
make deploy         # Full deployment (VMs + provisioning)
make retry-deploy   # Retry after transient failures (DC reboots, WinRM timeouts)
make status         # Show range state
make errors         # Show deployment errors
make logs           # Full deployment logs
make eset-logs      # Filter for ESET-specific logs
make domain-status  # Filter for Active Directory logs
make destroy        # Delete the entire range
```

**Note:** `make all` = `make config && make deploy`

### Testing Mode (Firewall Control)
⚠️ **Security Note:** Testing mode is designed for controlled malware analysis. Use only in isolated lab environments.

ESET playground includes 300+ ESET cloud service allowlists for air-gapped testing:
```bash
make testing-start          # Block ALL outbound traffic
make testing-allow-eset     # Allow ESET cloud services (from allowlist files)
make testing-status         # Show current firewall rules
make testing-stop           # Restore full internet
ludus testing allow -d example.com -i 203.0.113.10  # Add custom allowlist
```

**Use case:** Safely run malware samples while maintaining ESET updates.

## Game of Active Directory (GOAD) Playground

🚧 **Status:** Planned - Not yet implemented

**Purpose:** Multi-domain Active Directory environment for penetration testing and attack simulation.

**Planned Features:**
- Multiple AD forests and domains
- Cross-domain trusts
- Vulnerable configurations for red team training
- Automated user/group provisioning

**Directory:** `game of active directory (GOAD)/`

See [GOAD project](https://github.com/Orange-Cyberdefense/GOAD) for architecture reference.

## Pentesting Playground

🚧 **Status:** Planned - Not yet implemented

**Purpose:** General-purpose penetration testing lab with vulnerable applications and services.

**Planned Features:**
- Kali Linux attack platform
- Vulnerable web applications (DVWA, WebGoat, etc.)
- Misconfigured services for exploitation practice
- Network segmentation for attack/defense scenarios

**Directory:** `pentesting/`

## Common Issues & Solutions

### 1. Module Not Found Errors
**Symptom:** `couldn't resolve module/action 'ansible.windows.win_chocolatey'`  
**Fix:** Install Windows collection BEFORE deploying:
```bash
ludus ansible collection add ansible.windows
make retry-deploy
```

### 2. Domain Controller Promotion Failures
**Symptom:** `DCPromo exited with 15: Role change is in progress or this computer needs to be restarted`  
**Why:** Alternate DCs (`alt-dc`) require a reboot after primary DC promotion  
**Fix:** This is expected. Just retry:
```bash
make retry-deploy  # Deployment is idempotent
```

### 3. Windows 11 Sysprep Timeout
**Symptom:** `UNREACHABLE! => timeout when waiting for 10.2.10.30:5986`  
**Why:** Windows 11 with `sysprep: true` takes 5-10 minutes to complete generalization  
**Fix:** Wait and retry:
```bash
sleep 600  # Wait 10 minutes
make retry-deploy
```

See [eset/TROUBLESHOOTING.md](eset/TROUBLESHOOTING.md) for detailed diagnostics.

### 4. Roles Not Applied
**Symptom:** Roles don't execute during deployment  
**Fix:** Ensure roles are uploaded AND referenced in config.yml:
```bash
ludus ansible role list  # Verify uploaded roles
make upload-roles        # Re-upload if missing
```

## Development Conventions

⚠️ **CRITICAL SECURITY WARNING:**
All playgrounds intentionally disable security features (UAC, Windows Defender, firewalls) for testing purposes. These configurations are UNSAFE for production environments. Never deploy these ranges on networks with access to sensitive data or production systems. Always use isolated, air-gapped networks or dedicated lab infrastructure.

### Adding a New Playground
1. Create directory: `mkdir new-playground/`
2. Copy ESET structure as template: `cp eset/{Makefile,README.md} new-playground/`
3. Create `config.yml` defining VMs
4. Create `roles/` directory for custom provisioning
5. Update root README.md with playground details

### Modifying Existing Roles
1. Edit role in `roles/<role-name>/tasks/main.yml`
2. Re-upload: `make upload-roles` (uploads ALL roles)
3. Redeploy: `make deploy` (runs ALL roles, idempotent)

**Idempotency:** Ansible tasks should be idempotent. Use conditionals to skip already-completed work:
```yaml
- name: Check if software is installed
  ansible.builtin.stat:
    path: /opt/software/binary
  register: software_check

- name: Install software
  ansible.builtin.shell: /tmp/install.sh
  when: not software_check.stat.exists
```

### Windows Role Patterns
⚠️ **Security:** The `disable-software-restrictions` role MUST be applied first on Windows VMs to allow software installation. This disables UAC, Defender, and firewall - acceptable ONLY in isolated lab environments.

Always use `ansible.windows.*` modules (requires `ansible.windows` collection):
- `ansible.windows.win_chocolatey` - Install Chocolatey packages
- `ansible.windows.win_regedit` - Modify registry
- `ansible.windows.win_shell` - Run PowerShell commands
- `ansible.windows.win_get_url` - Download files
- `ansible.windows.win_package` - Install MSI/EXE installers

**Example:** Downloading and installing Windows software:
```yaml
- name: Download installer
  ansible.windows.win_get_url:
    url: https://example.com/installer.msi
    dest: C:\Installers\installer.msi

- name: Install software
  ansible.windows.win_package:
    path: C:\Installers\installer.msi
    arguments: /quiet /norestart
    state: present
```

### Documentation Standards
Each playground MUST have:
- `README.md` - Full deployment guide, architecture, credentials, access instructions
- `config.yml` - VM definitions with inline comments
- `Makefile` - Automation targets with helpful comments
- `TROUBLESHOOTING.md` - Known issues and diagnostics (if complex)
- `AGENT_INSTRUCTIONS.md` - Developer/agent guide (optional, for AI assistance)

## Key Files to Reference

- [eset/config.yml](eset/config.yml) - Example multi-VM range with AD domain
- [eset/roles/install-eset/](eset/roles/install-eset/) - Linux role example (Ubuntu ESET installation)
- [eset/roles/disable-software-restrictions/](eset/roles/disable-software-restrictions/) - Windows role example (registry/firewall config)
- [eset/Makefile](eset/Makefile) - Comprehensive automation examples
- [eset/README.md](eset/README.md) - Complete ESET playground documentation
- [eset/AI-AGENT-TODO.md](eset/AI-AGENT-TODO.md) - Future AI behavior agent development roadmap

## Credentials & Access

### ESET Playground
- **ESET Console:** https://10.2.10.10:8443/era (Administrator / EsetAdminPass!2024)
- **Domain Admin:** eset.local\localuser / password (Domain Admins + Schema Admins)
- **MySQL Root:** StrongRootPass!2024
- **ESET DB User:** era_user / StrongDbPass!2024

### WireGuard VPN
```bash
ludus user wireguard > ludus-range.conf
sudo wg-quick up ./ludus-range.conf  # Or import in GUI client
```

Once connected, access VMs directly via their IP addresses (10.2.x.x).

## Testing & Validation

### Pre-Deployment Checks
```bash
ludus ansible collection list    # Verify required collections
ludus ansible role list          # Verify uploaded roles
ludus range list                 # Check no existing range (or destroy first)
```

### Post-Deployment Validation
```bash
ludus range list                 # Should show "READY" or "SUCCESS"
make status                      # Same as above
make errors                      # Should be empty or show expected reboot errors
ping 10.2.10.10                  # Test connectivity (requires VPN)
```

### Active Monitoring
```bash
ludus range logs -f              # Follow logs in real-time (Ctrl+C to stop)
make eset-logs                   # Filter for ESET installation progress
make domain-status               # Check DC promotion and domain join status
```

## AI Agent Notes

- **Deployment time:** 30-60 minutes for ESET playground (3 DCs + provisioning)
- **Idempotency:** All Ansible roles should be safe to re-run. Always use stat/check tasks before making changes.
- **Windows timing:** Domain controllers reboot during promotion. Expect "Role change is in progress" errors on first run.
- **Credentials:** Never commit credentials to git. All credentials in documentation are for isolated lab use only.
- **ESET installers:** Some ESET tools are downloaded but NOT auto-installed (ESA, EEE, Inspector). See [eset/README.md](eset/README.md) for manual installation paths.
