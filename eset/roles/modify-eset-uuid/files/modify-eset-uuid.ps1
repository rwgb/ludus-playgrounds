# PowerShell script to modify ESET Agent ProductInstanceID UUID
# This script can be run standalone or via Ansible

# Registry path and value name
$registryPath = "HKLM:\SOFTWARE\ESET\RemoteAdministrator\Agent\CurrentVersion\Info"
$valueName = "ProductInstanceID"

# Function to generate a new UUID
function New-RandomUUID {
    $hex = "0123456789abcdef"
    $uuid = ""
    
    # Generate UUID format: xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
    for ($i = 0; $i -lt 8; $i++) { $uuid += $hex[(Get-Random -Minimum 0 -Maximum 16)] }
    $uuid += "-"
    for ($i = 0; $i -lt 4; $i++) { $uuid += $hex[(Get-Random -Minimum 0 -Maximum 16)] }
    $uuid += "-"
    for ($i = 0; $i -lt 4; $i++) { $uuid += $hex[(Get-Random -Minimum 0 -Maximum 16)] }
    $uuid += "-"
    for ($i = 0; $i -lt 4; $i++) { $uuid += $hex[(Get-Random -Minimum 0 -Maximum 16)] }
    $uuid += "-"
    for ($i = 0; $i -lt 12; $i++) { $uuid += $hex[(Get-Random -Minimum 0 -Maximum 16)] }
    
    return $uuid
}

# Check if registry key exists
if (Test-Path $registryPath) {
    # Get current value
    $currentValue = Get-ItemProperty -Path $registryPath -Name $valueName -ErrorAction SilentlyContinue
    
    if ($currentValue) {
        Write-Host "Current ProductInstanceID: $($currentValue.$valueName)"
        
        # Generate new UUID
        $newUUID = New-RandomUUID
        
        # Set new value
        Set-ItemProperty -Path $registryPath -Name $valueName -Value $newUUID
        
        Write-Host "New ProductInstanceID: $newUUID"
        Write-Host "UUID successfully changed!"
    } else {
        Write-Host "ProductInstanceID value not found in registry."
    }
} else {
    Write-Host "ESET Agent registry key not found at: $registryPath"
    Write-Host "Please ensure ESET Agent is installed."
}
