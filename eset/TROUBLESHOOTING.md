# Ludus ESET Range Troubleshooting Guide

## WIN11-ESET Connection Timeout Issue

### Symptoms
- Deployment status shows ERROR
- `ludus range errors` shows: `UNREACHABLE! => timeout when waiting for 10.2.10.20:5986`
- RB-win11-eset shows in VM list as "On" with IP 10.2.10.20
- VM is completely unreachable (ping fails, all ports timeout)

### Root Cause
The WIN11 VM template uses `sysprep: True`, which causes Windows to generalize itself on first boot. During this process:
1. Windows reboots multiple times
2. Network services are restarted
3. WinRM may not be available for 5-10 minutes
4. In some cases, the VM may be in a hung state during sysprep

### Diagnostic Commands

Run comprehensive diagnostics:
```bash
make diagnose-win11
```

This will test:
- ICMP connectivity (ping)
- WinRM HTTP port (5985)
- WinRM HTTPS port (5986)  
- RDP port (3389)
- VM status from Proxmox

Expected output when VM is healthy:
```
Testing ICMP (ping)...
3 packets transmitted, 3 packets received, 0.0% packet loss

Testing WinRM HTTPS (5986)...
Connection to 10.2.10.20 port 5986 [tcp/*] succeeded!
```

Current output (unhealthy):
```
Testing ICMP (ping)...
3 packets transmitted, 0 packets received, 100.0% packet loss
```

### Solutions

#### Option 1: Wait and Retry (Recommended for sysprep timeout)
If the VM is powered on but unreachable, sysprep may still be running:

```bash
# Wait 5-10 minutes for sysprep to complete
sleep 600

# Check if connectivity has returned
make diagnose-win11

# If connectivity is restored, retry deployment
make retry-deploy
```

#### Option 2: Reboot the VM (For hung sysprep)
If waiting doesn't help, the VM may be hung during sysprep:

```bash
# Reboot the specific VM through Proxmox/Ludus
# Note: Need access to Proxmox console or Ludus VM reboot command
```

#### Option 3: Increase Timeout
The default WinRM timeout is 320 seconds (5.3 minutes). For slow sysprep processes, this may not be enough. Unfortunately, Ludus doesn't expose this timeout in config.yml, so this requires modifying Ludus internals.

#### Option 4: Disable Sysprep
If sysprep is not required, modify the VM config:

```yaml
- vm_name: "{{ range_id }}-win11-eset"
  hostname: WIN11-ESET
  template: win11-22h2-x64-enterprise-eset-template
  vlan: 10
  ip_last_octet: 20
  ram_gb: 4
  cpus: 2
  windows:
    sysprep: false  # Disable sysprep
  domain:
    fqdn: corp.local
    role: member
```

**Warning**: Disabling sysprep means the VM won't be generalized, which may cause issues with domain joining if the template already has a computer name/SID.

### Current Status

Latest diagnostics (2026-01-26 12:40):
- VM Status: Powered On
- IP Assignment: 10.2.10.20 (assigned by Proxmox)
- ICMP Ping: **FAILED** (100% packet loss)
- WinRM (5986): **TIMEOUT** (no response)
- RDP (3389): **TIMEOUT** (no response)

**Conclusion**: The VM is powered on but completely unresponsive to network traffic. This indicates the VM is either:
1. Still in the middle of sysprep process (waiting for reboot/initialization)
2. Hung during sysprep (requires reboot or intervention)
3. Network configuration issue (incorrect VLAN, gateway, etc.)

### Log Analysis

The failure occurs during the first "Gathering Facts" task when Ansible attempts initial WinRM connection:

```
TASK [Gathering Facts] *********************************************************
ok: [RB-ubuntu-eset-server]
ok: [RB-ad-dc-win2022]
ok: [RB-win-server-02]
ok: [RB-win-server-01]
ok: [RB-win-server-03]
ok: [RB-win-server-04]
fatal: [RB-win11-eset]: UNREACHABLE! => {
  "changed": false,
  "msg": "ssl: HTTPSConnectionPool(host='10.2.10.20', port=5986): 
          Max retries exceeded with url: /wsman 
          (Caused by ConnectTimeoutError(..., 
           'Connection to 10.2.10.20 timed out. (connect timeout=320)'))",
  "unreachable": true
}
```

Note that all other Windows VMs (DC01, SRV01-04) successfully connected, indicating this is specific to WIN11-ESET, not a general network or Ludus issue.

### Other Windows VMs Status

Successfully deployed:
- ✅ RB-ad-dc-win2022 (DC01) - 10.2.10.15 - **ok=76 changed=18**
- ✅ RB-win-server-01 (SRV01) - 10.2.10.21 - **ok=83 changed=13**
- ✅ RB-win-server-02 (SRV02) - 10.2.10.22 - **ok=81 changed=13**
- ✅ RB-win-server-03 (SRV03) - 10.2.10.23 - **ok=81 changed=13**
- ✅ RB-win-server-04 (SRV04) - 10.2.10.24 - **ok=81 changed=13**

Failed:
- ❌ RB-win11-eset (WIN11-ESET) - 10.2.10.20 - **ok=0 changed=0 unreachable=1**

### Next Steps

1. **Immediate**: Check if the VM is accessible via Proxmox console to see if sysprep is hung
2. **Short-term**: Wait 10-15 minutes and retry diagnostics to see if sysprep completes
3. **Long-term**: Consider using a non-sysprep template for Win11 if this continues to be an issue

### Monitoring Script

Use this one-liner to continuously monitor WIN11 connectivity:

```bash
while true; do 
  echo "$(date): Checking WIN11-ESET connectivity..."
  ping -c 1 -W 2 10.2.10.20 > /dev/null && echo "✓ PING SUCCESS" || echo "✗ Ping failed"
  nc -zv -w 2 10.2.10.20 5986 2>&1 | grep -q "succeeded" && echo "✓ WINRM SUCCESS" || echo "✗ WinRM failed"
  echo ""
  sleep 30
done
```

Press Ctrl+C to stop monitoring.
