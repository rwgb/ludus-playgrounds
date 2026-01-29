# Ludus Playgrounds

A collection of [Ludus](https://ludus.cloud) cyber range configurations for building automated security testing and training environments.

## Overview

This repository contains pre-configured Ludus range definitions with custom Ansible roles for rapid deployment of enterprise security lab environments. Each playground is a self-contained project with complete documentation, automation, and infrastructure-as-code configurations.

## Available Playgrounds

### [ESET Protect On-Prem](eset/)

A comprehensive ESET endpoint security lab environment featuring:
- **ESET Protect On-Prem** centralized management console
- **Active Directory** domain with 3 domain controllers (eset.local)
- **ESET Bridge**, **Rogue Detection Sensor**, and **ESET Inspector** server
- **Windows Server 2022** infrastructure (1 primary DC, 2 alternate DCs)
- **Windows 11 Enterprise** workstation
- **10 custom Ansible roles** for automated deployment
- **Testing mode support** with 300+ ESET cloud service allowlists

**Quick Start:**
```bash
cd eset
make upload-roles
make config
make deploy
```

**Key Features:**
- Fully automated deployment (30-60 minutes)
- Pre-configured domain user with admin privileges
- ESET tools pre-downloaded and ready to install
- Chocolatey package manager on all Windows systems
- Comprehensive troubleshooting documentation

[→ Full Documentation](eset/README.md)

## Prerequisites

- [Ludus](https://ludus.cloud) server access and authentication
- Ludus CLI installed and configured
- WireGuard VPN client (for range access)
- Required Ansible collections:
  ```bash
  ludus ansible collection add ansible.windows
  ```

## Repository Structure

```
ludus-playgrounds/
├── eset/                           # ESET Protect On-Prem playground
│   ├── config.yml                  # Range definition
│   ├── Makefile                    # Deployment automation
│   ├── README.md                   # Complete documentation
│   ├── AGENT_INSTRUCTIONS.md       # Development guidelines
│   ├── TROUBLESHOOTING.md          # Diagnostic procedures
│   ├── roles/                      # Custom Ansible roles (10)
│   ├── eset-allowlist-domains.txt  # Testing mode allowlist
│   └── eset-allowlist-ips.txt      # Testing mode allowlist
└── README.md                       # This file
```

## Common Workflows

### Deploying a Playground

1. Navigate to the playground directory:
   ```bash
   cd eset
   ```

2. Upload custom Ansible roles:
   ```bash
   make upload-roles
   ```

3. Set the range configuration:
   ```bash
   make config
   ```

4. Deploy the range:
   ```bash
   make deploy
   ```

5. Monitor deployment:
   ```bash
   ludus range logs -f
   ```

### Accessing Your Range

1. Generate WireGuard VPN configuration:
   ```bash
   ludus user wireguard > ludus-range.conf
   ```

2. Import into WireGuard client and connect

3. Access systems via RDP or SSH:
   ```bash
   # Windows systems via RDP
   # Ubuntu systems via SSH
   ```

### Destroying a Range

```bash
cd eset
make destroy
```

## Development

### Adding a New Playground

1. Create a new directory for the playground
2. Add `config.yml` with VM definitions
3. Create custom Ansible roles in `roles/`
4. Add `README.md` with documentation
5. Add `Makefile` for automation
6. Update this README with the new playground

### Contributing

- Keep playgrounds self-contained and well-documented
- Include comprehensive troubleshooting guides
- Use Makefiles for common operations
- Test deployments before committing
- Update documentation with any manual steps

## Troubleshooting

### Role Not Found Errors
```bash
# Re-upload all roles
make upload-roles

# Verify roles are uploaded
ludus ansible role list
```

### Ansible Module Not Found
```bash
# Install required collection
ludus ansible collection add ansible.windows
```

### Deployment Failures
```bash
# Check errors
ludus range errors

# View full logs
ludus range logs

# Retry deployment
make retry-deploy
```

### Domain Controller Reboot Required
```bash
# This is expected for alternate DCs
# Simply retry the deployment
make retry-deploy
```

## Resources

- [Ludus Documentation](https://docs.ludus.cloud)
- [Ludus GitHub](https://github.com/badsectorlabs/ludus)
- [ESET Business Products](https://www.eset.com/us/business/)
- [Ansible Windows Automation](https://docs.ansible.com/ansible/latest/collections/ansible/windows/)

## License

[Specify your license here]

## Support

For issues specific to:
- **Ludus platform**: See [Ludus documentation](https://docs.ludus.cloud)
- **ESET playground**: See [eset/README.md](eset/README.md) and [eset/TROUBLESHOOTING.md](eset/TROUBLESHOOTING.md)
- **This repository**: Open an issue on GitHub

## Version History

- **v1.0** - Initial release with ESET Protect On-Prem playground
  - 6-VM enterprise lab environment
  - 10 custom Ansible roles
  - Active Directory domain with 3 DCs
  - Complete ESET tool ecosystem
  - Testing mode with cloud service allowlists
