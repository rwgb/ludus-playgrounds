# MySQL Service Health Check and Startup Script
# Checks if MySQL service is running, starts it if not, and debugs failures

param(
    [string]$LogFile = "C:\mysql-service-debug.log"
)

function Write-Log {
    param([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] $Message"
    Write-Host $logMessage
    Add-Content -Path $LogFile -Value $logMessage
}

# Initialize log
Write-Log "=== MySQL Service Health Check Started ==="

# Define possible MySQL service names
$possibleServiceNames = @("MySQL", "MySQL80", "MySQL57", "MYSQL", "mysqld")
$mysqlService = $null

# Find the MySQL service
foreach ($serviceName in $possibleServiceNames) {
    $service = Get-Service -Name $serviceName -ErrorAction SilentlyContinue
    if ($service) {
        $mysqlService = $service
        Write-Log "Found MySQL service: $serviceName"
        break
    }
}

if (-not $mysqlService) {
    Write-Log "ERROR: MySQL service not found. Checked service names: $($possibleServiceNames -join ', ')"
    Write-Log "Available services matching 'mysql': "
    Get-Service | Where-Object { $_.Name -like "*mysql*" } | ForEach-Object {
        Write-Log "  - $($_.Name) ($($_.Status))"
    }
    exit 1
}

$serviceName = $mysqlService.Name
Write-Log "MySQL Service Name: $serviceName"
Write-Log "Current Status: $($mysqlService.Status)"
Write-Log "Startup Type: $($mysqlService.StartType)"

# Check if service is running
if ($mysqlService.Status -eq 'Running') {
    Write-Log "SUCCESS: MySQL service is already running"
    exit 0
}

# Service is not running - attempt to start it
Write-Log "WARNING: MySQL service is not running (Status: $($mysqlService.Status))"
Write-Log "Attempting to start MySQL service..."

try {
    Start-Service -Name $serviceName -ErrorAction Stop
    Start-Sleep -Seconds 5
    
    # Refresh service status
    $mysqlService.Refresh()
    
    if ($mysqlService.Status -eq 'Running') {
        Write-Log "SUCCESS: MySQL service started successfully"
        exit 0
    } else {
        Write-Log "WARNING: Service start command completed but service status is: $($mysqlService.Status)"
    }
} catch {
    Write-Log "ERROR: Failed to start MySQL service"
    Write-Log "Error Message: $($_.Exception.Message)"
}

# If we get here, the service failed to start - begin debugging
Write-Log ""
Write-Log "=== DEBUGGING MySQL SERVICE FAILURE ==="
Write-Log ""

# Check Windows Event Logs for MySQL errors
Write-Log "--- Windows Event Log Entries (Last 10 MySQL-related errors) ---"
try {
    $events = Get-WinEvent -FilterHashtable @{
        LogName = 'Application'
        ProviderName = '*MySQL*'
    } -MaxEvents 10 -ErrorAction SilentlyContinue
    
    if ($events) {
        foreach ($event in $events) {
            Write-Log "Event ID: $($event.Id) | Level: $($event.LevelDisplayName) | Time: $($event.TimeCreated)"
            Write-Log "Message: $($event.Message)"
            Write-Log "---"
        }
    } else {
        Write-Log "No MySQL events found in Application log"
    }
} catch {
    Write-Log "Could not retrieve event log entries: $($_.Exception.Message)"
}

# Check System Event Log for service control errors
Write-Log ""
Write-Log "--- System Event Log (Service Control Manager) ---"
try {
    $sysEvents = Get-WinEvent -FilterHashtable @{
        LogName = 'System'
        ProviderName = 'Service Control Manager'
    } -MaxEvents 5 -ErrorAction SilentlyContinue | Where-Object { $_.Message -like "*MySQL*" }
    
    if ($sysEvents) {
        foreach ($event in $sysEvents) {
            Write-Log "Event ID: $($event.Id) | Time: $($event.TimeCreated)"
            Write-Log "Message: $($event.Message)"
            Write-Log "---"
        }
    }
} catch {
    Write-Log "Could not retrieve System event log entries: $($_.Exception.Message)"
}

# Check MySQL error log file
Write-Log ""
Write-Log "--- MySQL Error Log ---"
$possibleLogPaths = @(
    "C:\ProgramData\MySQL\MySQL Server 8.0\Data\*.err",
    "C:\ProgramData\MySQL\MySQL Server 5.7\Data\*.err",
    "C:\Program Files\MySQL\MySQL Server 8.0\data\*.err",
    "C:\Program Files\MySQL\MySQL Server 5.7\data\*.err",
    "C:\mysql\data\*.err",
    "C:\tools\mysql\current\data\*.err",
    "C:\tools\mysql\*\data\*.err"
)

$errorLogFound = $false
foreach ($logPath in $possibleLogPaths) {
    $logFiles = Get-ChildItem -Path $logPath -ErrorAction SilentlyContinue
    if ($logFiles) {
        foreach ($logFile in $logFiles) {
            Write-Log "Found MySQL error log: $($logFile.FullName)"
            Write-Log "Last 30 lines of error log:"
            Get-Content -Path $logFile.FullName -Tail 30 | ForEach-Object {
                Write-Log $_
            }
            $errorLogFound = $true
            break
        }
        if ($errorLogFound) { break }
    }
}

if (-not $errorLogFound) {
    Write-Log "MySQL error log not found in standard locations"
}

# Check service configuration
Write-Log ""
Write-Log "--- MySQL Service Configuration ---"
$serviceConfig = $null
try {
    $serviceConfig = Get-CimInstance -ClassName Win32_Service -Filter "Name='$serviceName'"
    Write-Log "Path to Executable: $($serviceConfig.PathName)"
    Write-Log "Start Mode: $($serviceConfig.StartMode)"
    Write-Log "Service Account: $($serviceConfig.StartName)"
    Write-Log "State: $($serviceConfig.State)"
    Write-Log "Exit Code: $($serviceConfig.ExitCode)"
    
    if ($serviceConfig.ExitCode -ne 0) {
        Write-Log "WARNING: Service has non-zero exit code: $($serviceConfig.ExitCode)"
    }
    
    # Check for malformed executable path
    if ($serviceConfig.PathName -match "mysqld\s+MySQL") {
        Write-Log "ERROR: Service executable path appears malformed (has extra 'MySQL' parameter)"
        Write-Log "Expected format: C:\path\to\mysqld.exe --defaults-file=..."
        Write-Log "Actual format: $($serviceConfig.PathName)"
    }
} catch {
    Write-Log "Could not retrieve service configuration: $($_.Exception.Message)"
}

# Check if MySQL port is in use
Write-Log ""
Write-Log "--- Port 3306 Status ---"
try {
    $portInUse = Get-NetTCPConnection -LocalPort 3306 -ErrorAction SilentlyContinue
    if ($portInUse) {
        Write-Log "WARNING: Port 3306 is already in use by another process"
        Write-Log "Process ID: $($portInUse.OwningProcess)"
        $process = Get-Process -Id $portInUse.OwningProcess -ErrorAction SilentlyContinue
        if ($process) {
            Write-Log "Process Name: $($process.ProcessName)"
            Write-Log "Process Path: $($process.Path)"
        }
    } else {
        Write-Log "Port 3306 is available"
    }
} catch {
    Write-Log "Could not check port status: $($_.Exception.Message)"
}

# Check MySQL configuration file
Write-Log ""
Write-Log "--- MySQL Configuration File ---"
$possibleConfigPaths = @(
    "C:\ProgramData\MySQL\MySQL Server 8.0\my.ini",
    "C:\ProgramData\MySQL\MySQL Server 5.7\my.ini",
    "C:\Program Files\MySQL\MySQL Server 8.0\my.ini",
    "C:\tools\mysql\current\my.ini",
    "C:\my.ini",
    "C:\Windows\my.ini"
)

$configFound = $false
$mysqlConfigPath = $null
foreach ($configPath in $possibleConfigPaths) {
    if (Test-Path $configPath) {
        Write-Log "Found MySQL configuration: $configPath"
        Write-Log "Configuration contents:"
        Get-Content -Path $configPath | ForEach-Object {
            Write-Log $_
        }
        $configFound = $true
        $mysqlConfigPath = $configPath
        break
    }
}

if (-not $configFound) {
    Write-Log "WARNING: MySQL configuration file not found in standard locations"
}

# Check MySQL data directory
Write-Log ""
Write-Log "--- MySQL Data Directory ---"
$possibleDataDirs = @(
    "C:\ProgramData\MySQL\MySQL Server 8.0\Data",
    "C:\ProgramData\MySQL\MySQL Server 5.7\Data",
    "C:\Program Files\MySQL\MySQL Server 8.0\data",
    "C:\tools\mysql\current\data",
    "C:\mysql\data"
)

$dataDirFound = $false
$mysqlDataDir = $null
foreach ($dataDir in $possibleDataDirs) {
    if (Test-Path $dataDir) {
        Write-Log "Found MySQL data directory: $dataDir"
        $mysqlDataDir = $dataDir
        
        # Check if data directory is initialized
        $systemDbExists = Test-Path (Join-Path $dataDir "mysql")
        $idbdataExists = Test-Path (Join-Path $dataDir "ibdata1")
        
        if ($systemDbExists -and $idbdataExists) {
            Write-Log "Data directory appears initialized (mysql system DB and ibdata1 found)"
        } elseif ($systemDbExists) {
            Write-Log "WARNING: mysql system DB found but ibdata1 missing - data directory may be corrupted"
        } else {
            Write-Log "ERROR: Data directory exists but is NOT initialized (missing mysql system database)"
            Write-Log "This is likely the cause of the service failure"
        }
        
        # List directory contents
        $fileCount = (Get-ChildItem -Path $dataDir -File -ErrorAction SilentlyContinue).Count
        $dirCount = (Get-ChildItem -Path $dataDir -Directory -ErrorAction SilentlyContinue).Count
        Write-Log "Contents: $fileCount files, $dirCount directories"
        
        $dataDirFound = $true
        break
    }
}

if (-not $dataDirFound) {
    Write-Log "ERROR: MySQL data directory not found in standard locations"
    Write-Log "Data directory must be created and initialized before MySQL can start"
}

# Check disk space
Write-Log ""
Write-Log "--- Disk Space ---"
Get-PSDrive -PSProvider FileSystem | Where-Object { $_.Used -gt 0 } | ForEach-Object {
    $percentFree = [math]::Round(($_.Free / ($_.Used + $_.Free)) * 100, 2)
    Write-Log "Drive $($_.Name): $percentFree% free ($([math]::Round($_.Free/1GB, 2)) GB available)"
    if ($percentFree -lt 10) {
        Write-Log "WARNING: Low disk space on drive $($_.Name)"
    }
}

# Automated fix suggestions
Write-Log ""
Write-Log "=== AUTOMATED FIX SUGGESTIONS ==="
Write-Log ""

$fixesAvailable = $false

# Detect MySQL installation path from service configuration
$mysqlBinPath = $null
$mysqlBasePath = $null
if ($serviceConfig -and $serviceConfig.PathName -match "([A-Za-z]:\\[^\\]+\\[^\\]+\\[^\\]+)\\bin\\mysqld") {
    $mysqlBasePath = $matches[1]
    $mysqlBinPath = Join-Path $mysqlBasePath "bin\mysqld.exe"
    Write-Log "Detected MySQL installation path: $mysqlBasePath"
}

# Fix 1: Initialize data directory
if ($dataDirFound -and $mysqlDataDir -and -not (Test-Path (Join-Path $mysqlDataDir "mysql"))) {
    Write-Log "FIX 1: Initialize MySQL Data Directory"
    Write-Log "Command to run:"
    if ($mysqlBinPath) {
        Write-Log "  `"$mysqlBinPath`" --initialize-insecure --datadir=`"$mysqlDataDir`""
    } else {
        Write-Log "  mysqld --initialize-insecure --datadir=`"$mysqlDataDir`""
    }
    Write-Log "This will create the system databases required for MySQL to start"
    Write-Log ""
    $fixesAvailable = $true
} elseif (-not $dataDirFound) {
    Write-Log "FIX 1: Create and Initialize MySQL Data Directory"
    Write-Log "Steps:"
    Write-Log "  1. Determine MySQL installation path (from service configuration above)"
    Write-Log "  2. Create data directory: New-Item -Path 'C:\tools\mysql\current\data' -ItemType Directory -Force"
    Write-Log "  3. Initialize: mysqld --initialize-insecure --datadir='C:\tools\mysql\current\data'"
    Write-Log ""
    $fixesAvailable = $true
}

# Fix 2: Fix malformed service path
if ($serviceConfig -and $serviceConfig.PathName -match "mysqld\s+MySQL") {
    Write-Log "FIX 2: Correct Service Executable Path"
    Write-Log "Current (malformed): $($serviceConfig.PathName)"
    
    # Try to determine correct path
    if ($mysqlBinPath -and $mysqlConfigPath) {
        $correctPath = "`"$mysqlBinPath`" --defaults-file=`"$mysqlConfigPath`""
        Write-Log "Suggested correction: $correctPath"
        Write-Log "Command to fix:"
        Write-Log "  sc.exe config $serviceName binPath= `"$correctPath`""
    } elseif ($mysqlBinPath) {
        $correctPath = "`"$mysqlBinPath`""
        Write-Log "Suggested correction: $correctPath"
        Write-Log "Command to fix:"
        Write-Log "  sc.exe config $serviceName binPath= `"$correctPath`""
    } else {
        Write-Log "Cannot auto-detect correct path. Manually run:"
        Write-Log "  sc.exe config $serviceName binPath= `"C:\path\to\mysqld.exe`""
    }
    Write-Log ""
    $fixesAvailable = $true
}

# Fix 3: Create basic my.ini
if (-not $configFound -and $mysqlBasePath) {
    $suggestedConfigPath = Join-Path $mysqlBasePath "my.ini"
    Write-Log "FIX 3: Create MySQL Configuration File"
    Write-Log "Suggested location: $suggestedConfigPath"
    Write-Log "Basic my.ini template:"
    Write-Log "[mysqld]"
    Write-Log "basedir=$mysqlBasePath"
    Write-Log "datadir=$mysqlDataDir"
    Write-Log "port=3306"
    Write-Log "sql_mode=NO_ENGINE_SUBSTITUTION,STRICT_TRANS_TABLES"
    Write-Log ""
    Write-Log "Command to create:"
    Write-Log "@'"
    Write-Log "[mysqld]"
    Write-Log "basedir=$mysqlBasePath"
    Write-Log "datadir=$mysqlDataDir"
    Write-Log "port=3306"
    Write-Log "sql_mode=NO_ENGINE_SUBSTITUTION,STRICT_TRANS_TABLES"
    Write-Log "'@ | Out-File -FilePath '$suggestedConfigPath' -Encoding ASCII"
    Write-Log ""
    $fixesAvailable = $true
}

# Manual troubleshooting recommendations
Write-Log ""
Write-Log "=== MANUAL TROUBLESHOOTING STEPS ==="
Write-Log "1. Review the MySQL error log above for specific error messages"
Write-Log "2. Verify MySQL data directory exists and is initialized"
Write-Log "3. Check MySQL data directory permissions (should be writable by LocalSystem)"
Write-Log "4. Verify service executable path is correctly configured"
Write-Log "5. Ensure my.ini configuration file exists and has correct paths"
Write-Log "6. Check if port 3306 is blocked by firewall or used by another process"
Write-Log "7. Try starting MySQL manually: net start $serviceName"
Write-Log "8. Review Windows Event Viewer for detailed service errors"
Write-Log ""

if ($fixesAvailable) {
    Write-Log "=== APPLY FIXES ==="
    Write-Log "Review the automated fix suggestions above and apply them in order."
    Write-Log "After applying fixes, run this script again to verify MySQL starts successfully."
    Write-Log ""
}

Write-Log "=== DEBUG COMPLETE - Service Failed to Start ==="
Write-Log "Full debug log saved to: $LogFile"

exit 1
