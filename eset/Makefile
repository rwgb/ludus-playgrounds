.PHONY: all config deploy deploy-roles provision destroy status clean help errors logs testing-start testing-allow-eset testing-status testing-stop testing-allow-domain testing-allow-ip

# Deploy and provision the complete ESET range
all: config deploy

# Set the Ludus range configuration
config:
	@echo "Setting Ludus range configuration..."
	ludus range config set -f config.yml

# Deploy the range (full deployment)
deploy:
	@echo "Deploying Ludus range..."
	ludus range deploy
	@echo "Waiting for deployment to complete..."
	@while ! ludus range list | grep -q "READY\|SUCCESS"; do \
		echo "Waiting for range to be ready..."; \
		sleep 10; \
	done
	@echo "Range deployed successfully!"

# Deploy only user-defined roles (after initial deployment)
deploy-roles:
	@echo "Running user-defined roles..."
	ludus range deploy -t user-defined-roles

# Show range status
status:
	ludus range list

# Show deployment errors
errors:
	ludus range errors

# Show full deployment logs
logs:
	ludus range logs

# Show ESET installation logs
eset-logs:
	ludus range logs | grep -E "(install-eset|eset-server|ESET|mysql|tomcat)" || echo "No ESET installation logs found"

# Check DC and domain status
domain-status:
	ludus range logs | grep -E "(DC01|WIN11|domain|join|Active Directory)" || echo "No domain logs found"

# Diagnose WinRM connectivity on all Windows hosts
diagnose-winrm:
	@echo "Testing WinRM connectivity to all Windows hosts..."
	@echo "Testing DC01 (10.2.10.15)..."
	@nc -zv -w 5 10.2.10.15 5986 2>&1 | grep -E "succeeded|timed out|refused" || echo "Connection check failed"
	@echo "Testing WIN11-ESET (10.2.10.20)..."
	@nc -zv -w 5 10.2.10.20 5986 2>&1 | grep -E "succeeded|timed out|refused" || echo "Connection check failed"
	@echo "Testing SRV01 (10.2.10.21)..."
	@nc -zv -w 5 10.2.10.21 5986 2>&1 | grep -E "succeeded|timed out|refused" || echo "Connection check failed"
	@echo "Testing SRV02-04..."
	@for i in 22 23 24; do nc -zv -w 5 10.2.10.$$i 5986 2>&1 | grep -E "succeeded|timed out|refused" || echo "10.2.10.$$i: Connection check failed"; done

# Diagnose WinRM connectivity on WIN11 specifically  
diagnose-win11:
	@echo "=== WIN11-ESET (10.2.10.20) Diagnostics ==="
	@echo "Testing ICMP (ping)..."
	@ping -c 3 -W 2 10.2.10.20 2>&1 | tail -2
	@echo ""
	@echo "Testing WinRM HTTP (5985)..."
	@nc -zv -w 5 10.2.10.20 5985 2>&1 || echo "Port 5985 not accessible"
	@echo ""
	@echo "Testing WinRM HTTPS (5986)..."
	@nc -zv -w 5 10.2.10.20 5986 2>&1 || echo "Port 5986 not accessible"
	@echo ""
	@echo "Testing RDP (3389)..."
	@nc -zv -w 5 10.2.10.20 3389 2>&1 || echo "Port 3389 not accessible"
	@echo ""
	@echo "Getting VM status from Proxmox..."
	@ludus range list | grep "win11-eset" || echo "VM not found in range"

# Retry deployment (useful after waiting for services to stabilize)
retry-deploy:
	@echo "Retrying deployment..."
	ludus range deploy

# Destroy the range
destroy:
	@echo "Destroying range..."
	ludus range rm

# Upload the ansible role to Ludus server
upload-role:
	@echo "Uploading install-eset role to Ludus server..."
	ludus ansible role add -d roles/install-eset

# Upload all roles
upload-roles:
	@echo "Uploading all custom roles to Ludus server..."
	ludus ansible role add -d roles/install-eset
	ludus ansible role add -d roles/disable-software-restrictions
	ludus ansible role add -d roles/download-eset-tools
	ludus ansible role add -d roles/install-chocolatey
	ludus ansible role add -d roles/install-java
	ludus ansible role add -d roles/install-eset-bridge-rds
	ludus ansible role add -d roles/download-eset-inspector
	ludus ansible role add -d roles/configure-domain-user
	ludus ansible role add -d roles/modify-eset-uuid

# List installed ansible roles
list-roles:
	ludus ansible role list

# Clean and redeploy
clean: destroy
	@echo "Waiting for cleanup..."
	@sleep 5
	$(MAKE) all

# Enable testing mode (blocks all outbound traffic)
testing-start:
	@echo "Starting Ludus testing mode (blocks all outbound traffic)..."
	ludus testing start
	@echo "Testing mode enabled. Use 'make testing-allow-eset' to allow ESET services."

# Allow ESET domains and IPs through testing mode
testing-allow-eset:
	@echo "Allowing ESET domains through firewall..."
	ludus testing allow -f eset-allowlist-domains.txt
	@echo "Allowing ESET IP addresses through firewall..."
	ludus testing allow -f eset-allowlist-ips.txt
	@echo "ESET allowlist applied successfully!"

# Show testing mode status and allowed domains/IPs
testing-status:
	@echo "Testing mode status:"
	ludus testing status

# Stop testing mode (restore full internet access)
testing-stop:
	@echo "Stopping testing mode (restoring full internet access)..."
	ludus testing stop
	@echo "Testing mode disabled. All traffic now allowed."

# Add custom domain to allowlist
testing-allow-domain:
	@read -p "Enter domain to allow: " domain; \
	ludus testing allow -d $$domain

# Add custom IP to allowlist
testing-allow-ip:
	@read -p "Enter IP address to allow: " ip; \
	ludus testing allow -i $$ip

# Show help
help:
	@echo "Available targets:"
	@echo ""
	@echo "Deployment:"
	@echo "  all              - Configure and deploy the range"
	@echo "  config           - Set the range configuration"
	@echo "  deploy           - Deploy the range VMs (full deployment)"
	@echo "  deploy-roles     - Run only custom roles (after initial deploy)"
	@echo "  retry-deploy     - Retry failed deployment"
	@echo "  destroy          - Destroy the range"
	@echo "  clean            - Destroy and redeploy the range"
	@echo ""
	@echo "Monitoring:"
	@echo "  status           - Show range status"
	@echo "  errors           - Show deployment errors"
	@echo "  logs             - Show full deployment logs"
	@echo "  eset-logs        - Show ESET installation logs"
	@echo "  domain-status    - Show DC and domain join status"
	@echo ""
	@echo "Diagnostics:"
	@echo "  diagnose-winrm   - Run WinRM diagnostics on all Windows hosts"
	@echo "  diagnose-win11   - Run diagnostics specifically on WIN11-ESET"
	@echo ""
	@echo "Ansible Roles:"
	@echo "  upload-role      - Upload the install-eset role to Ludus server"
	@echo "  upload-roles     - Upload all custom roles to Ludus server"
	@echo "  list-roles       - List installed Ansible roles"
	@echo ""
	@echo "Testing Mode (Firewall Control):"
	@echo "  testing-start          - Enable testing mode (blocks all outbound traffic)"
	@echo "  testing-allow-eset     - Allow ESET services through firewall"
	@echo "  testing-status         - Show current testing mode status"
	@echo "  testing-stop           - Disable testing mode (restore full internet)"
	@echo "  testing-allow-domain   - Interactively add custom domain to allowlist"
	@echo "  testing-allow-ip       - Interactively add custom IP to allowlist"
	@echo ""
	@echo "  help             - Show this help message"
