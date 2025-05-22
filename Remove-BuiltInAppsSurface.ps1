# ================================
# Remove Built-In Apps (Intune)
# ================================
#   Created:        April 30, 2025
#   Written by:     Dave Boblits
#   Version:        1.2
#   Description:    The script pulls the master app package list from GitHub repository. Any app marked with the "#" symbol will be removed from the system.
#                   This version removes both provisioned apps and installed apps for all users.
#   Targeted OS:    Windows 11
#   Log File:       The AppRemoval.log file will be located in C:\Windows\Temp\Intune folder.
#

$logPath = "C:\Windows\Temp\Intune\AppRemoval.log"
$cloudAppListUrl = "https://raw.githubusercontent.com/ttlcadmin/ttlc/main/AppRemovalListSurface.txt"

# Ensure log directory exists
$logDir = Split-Path -Path $logPath
if (-not (Test-Path -Path $logDir)) {
    New-Item -Path $logDir -ItemType Directory -Force | Out-Null
}

Function Write-Log {
    param([string]$message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Add-Content -Path $logPath -Value "$timestamp - $message"
}

Write-Log "===== Starting App Removal Process ====="
Write-Log "Fetching app list from: $cloudAppListUrl"

# Download the cloud-based app list
try {
    $response = Invoke-WebRequest -Uri $cloudAppListUrl -UseBasicParsing -ErrorAction Stop
    $appList = $response.Content -split "`n"
    Write-Log "Successfully retrieved app list. Processing entries..."
} catch {
    Write-Log "ERROR: Failed to download app list - $_"
    exit 1
}

# Iterate over each line and process removals
foreach ($line in $appList) {
    $trimmedLine = $line.Trim()
    if ($trimmedLine.StartsWith("#") -and $trimmedLine.Length -gt 1) {
        $appName = $trimmedLine.Substring(1)
        Write-Log "Checking for provisioned package: $appName"

        $package = Get-AppxProvisionedPackage -Online | Where-Object { $_.DisplayName -eq $appName }

        if ($package) {
            try {
                Write-Log "Attempting to remove provisioned package: $($package.PackageName)"
                Remove-AppxProvisionedPackage -Online -PackageName $package.PackageName -ErrorAction Stop
                Write-Log "SUCCESS: Removed provisioned package $($package.DisplayName)"
            } catch {
                Write-Log "ERROR: Failed to remove provisioned package $($package.DisplayName) - $_"
            }
        } else {
            Write-Log "INFO: $appName not found among provisioned packages."
        }

        # Attempt to remove installed packages for all users
        Write-Log "Checking for installed packages for $appName..."
        Get-AppxPackage -AllUsers -Name $appName | ForEach-Object {
            try {
                Write-Log "Removing installed package: $($_.PackageFullName)"
                Remove-AppxPackage -Package $_.PackageFullName -ErrorAction Stop
                Write-Log "SUCCESS: Removed installed package $($_.PackageFullName)"
            } catch {
                Write-Log "ERROR: Failed to remove installed package: $_"
            }
        }
    }
}

Write-Log "===== App Removal Process Complete ====="
