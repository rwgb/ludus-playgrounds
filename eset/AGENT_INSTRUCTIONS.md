# Agent Instructions

## Purpose
Deploy a Ludus range containing:
- Ubuntu 24.04 server provisioned with the custom `install-eset` Ansible role
- Windows 11 Enterprise ESET template VM

## Key Files
- config.yml: Range definition (VLAN 10, Ubuntu at .10, Win11 at .20, Ubuntu uses role `install-eset`).
- roles/install-eset/: Custom role uploaded to Ludus (meta/main.yml exists).
- install-eset.yml: Standalone playbook equivalent (uses host `eset-server`).
- Makefile: Automation helpers for config/deploy/provision/role upload.

## Commands
- Set config: `ludus range config set -f config.yml`
- Deploy range: `ludus range deploy`
- Upload role: `ludus ansible role add -d roles/install-eset`
- List roles: `ludus ansible role list`
- Make targets: `make all` (config+deploy+provision), `make deploy`, `make provision`, `make upload-role`, `make status`, `make destroy`, `make clean`.

## Provisioning Notes
- Role name: `install-eset`; must exist on Ludus server (add via `ludus ansible role add -d roles/install-eset`).
- Role installs ESET via curl/bash: https://raw.githubusercontent.com/rwgb/eset.epop.tools/dev/scripts/linux/install-eset.sh
- VM hostnames/IPs: `eset-server` (10.x.x.10), `WIN11-ESET` (10.x.x.20) on VLAN 10.

## Troubleshooting
- If role not found: re-run `ludus ansible role add -d roles/install-eset` and confirm with `ludus ansible role list`.
- If provisioning fails: check deploy logs `ludus range logs` or errors `ludus range errors`.
- The Ludus CLI does not run arbitrary playbooks directly; provisioning occurs via roles during deploy.

## Expectations
- Keep edits minimal; preserve YAML formatting.
- Default to ASCII.
- Do not revert user changes; avoid destructive git commands.
