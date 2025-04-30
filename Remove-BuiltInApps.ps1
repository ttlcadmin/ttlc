# ================================
# Remove Built-In Apps (Intune)
# ================================

$logPath = "C:\Windows\Temp\AppRemoval.log"
$cloudAppListUrl = "https://raw.githubusercontent.com/ttlcadmin/ttlc/main/AppRemovalList.txt"

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
                Write-Log "Attempting to remove: $($package.PackageName)"
                Remove-AppxProvisionedPackage -Online -PackageName $package.PackageName -ErrorAction Stop
                Write-Log "SUCCESS: Removed $($package.DisplayName)"
            } catch {
                Write-Log "ERROR: Failed to remove $($package.DisplayName) - $_"
            }
        } else {
            Write-Log "INFO: $appName not found among provisioned packages."
        }
    }
}

Write-Log "===== App Removal Process Complete ====="
