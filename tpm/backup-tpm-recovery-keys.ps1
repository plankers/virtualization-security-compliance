<#
    VMware vSphere TPM Recovery Key Backup Utility
    Copyright (C) 2024 Bob Plankers. All rights reserved.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

        http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
#>

<#
    This software is provided as is and any express or implied warranties,
    including, but not limited to, the implied warranties of merchantability and
    fitness for a particular purpose are disclaimed. In no event shall the
    copyright holder or contributors be liable for any direct, indirect,
    incidental, special, exemplary, or consequential damages (including, but not
    limited to, procurement of substitute goods or services; loss of use, data,
    or profits; or business interruption) however caused and on any theory of
    liability, whether in contract, strict liability, or tort (including
    negligence or otherwise) arising in any way out of the use of this software,
    even if advised of the possibility of such damage. The provider makes no
    claims, promises, or guarantees about the accuracy, completeness, or adequacy
    of this sample. Organizations should engage appropriate legal, business,
    technical, and audit expertise within their specific organization for review
    of requirements and effectiveness of implementations. You acknowledge that
    there may be performance or other considerations, and that this example may
    make assumptions which may not be valid in your environment or organization.
    This software is not supported by anyone.

    Make backups of all configurations and data before using this tool. Where
    prompted, monitor task progress directly in the vSphere Client.
#>

Param (
        # Output File Name
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$OutputFileName,
        # Accept-EULA
        [Parameter(Mandatory=$false)]
        [switch]$AcceptEULA,
        # Skip safety checks
        [Parameter(Mandatory=$false)]
        [switch]$NoSafetyChecks
)

#####################
# Log to both screen and file
function Log-Message {
    param (
        [Parameter(Mandatory=$false)]
        [AllowEmptyString()]
        [AllowNull()]
        [string]$Message = "",

        [Parameter(Mandatory=$false)]
        [ValidateSet("INFO", "WARNING", "ERROR", "EULA")]
        [string]$Level = "INFO"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"
    
    # Output to screen
    switch ($Level) {
        "INFO"    { Write-Host $logEntry -ForegroundColor White }
        "WARNING" { Write-Host $logEntry -ForegroundColor Yellow }
        "ERROR"   { Write-Host $logEntry -ForegroundColor Red }
        "EULA"    { Write-Host $logEntry -ForegroundColor Cyan }
    }
    
    # Append to file
    $logEntry | Out-File -FilePath $outputfilename -Append
}

#####################
# Accept EULA and terms to continue
Function Accept-EULA() {
    Log-Message "This software is provided as is and any express or implied warranties, including," -Level "EULA"
    Log-Message "but not limited to, the implied warranties of merchantability and fitness for a particular" -Level "EULA"
    Log-Message "purpose are disclaimed. In no event shall the copyright holder or contributors be liable" -Level "EULA"
    Log-Message "for any direct, indirect, incidental, special, exemplary, or consequential damages (including," -Level "EULA"
    Log-Message "but not limited to, procurement of substitute goods or services; loss of use, data, or" -Level "EULA"
    Log-Message "profits; or business interruption) however caused and on any theory of liability, whether" -Level "EULA"
    Log-Message "in contract, strict liability, or tort (including negligence or otherwise) arising in any" -Level "EULA"
    Log-Message "way out of the use of this software, even if advised of the possibility of such damage." -Level "EULA"
    Log-Message "The provider makes no claims, promises, or guarantees about the accuracy, completeness, or" -Level "EULA"
    Log-Message "adequacy of this sample. Organizations should engage appropriate legal, business, technical," -Level "EULA"
    Log-Message "and audit expertise within their specific organization for review of requirements and" -Level "EULA"
    Log-Message "effectiveness of implementations. You acknowledge that there may be performance or other" -Level "EULA"
    Log-Message "considerations, and that this example may make assumptions which may not be valid in your" -Level "EULA"
    Log-Message "environment or organization." -Level "EULA"
    Log-Message "" -Level "EULA"
    Log-Message "This software is not supported." -Level "EULA"
    Log-Message "" -Level "EULA"
    Log-Message "Make backups of all configurations and data before using this tool. Where prompted, monitor" -Level "EULA"
    Log-Message "task progress directly in the vSphere Client." -Level "EULA"
    Log-Message "" -Level "EULA"
    Log-Message "Press any key to accept all terms and risk. Use CTRL+C to exit." -Level "EULA"

    $null = $host.UI.RawUI.FlushInputBuffer()
    while ($true) {
        $key = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        if ($key.Character -match '[a-zA-Z0-9 ]') {
            break
        }
    }
}

Function Do-Pause() {
    Write-Output "[WAIT]  Check the vSphere Client to make sure all tasks have completed, then press a key." 
    $null = $host.UI.RawUI.FlushInputBuffer()
    while ($true) {
        $key = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        if ($key.Character -match '[a-zA-Z0-9 ]') {
            break
        }
    }
}

#####################
# Check to see if we have the required version of VMware.PowerCLI
Function Check-PowerCLI() {
    $installedVersion = (Get-InstalledModule -Name 'VMware.PowerCLI' -AllVersions -ErrorAction SilentlyContinue).Version | Sort-Object -Desc | Select-Object -First 1
    if ('13.1.0' -gt $installedVersion) {
        Log-Message "This script requires PowerCLI 13.1 or newer. Current version is $installedVersion" -Level "ERROR"
        Log-Message "Instructions for installation & upgrade can be found at https://developer.vmware.com/powercli" -Level "ERROR"
        Exit
    }
}

#####################
# Check to see if we are attached to a supported vCenter Server
Function Check-vCenter() {
    if ($global:DefaultVIServers.Count -lt 1) {
        Log-Message "Please connect to a vCenter Server (use Connect-VIServer) prior to running this script. Thank you." -Level "ERROR"
        Exit
    }

    # Cannot override these, they're important.
    if (($global:DefaultVIServers.Count -lt 1) -or ($global:DefaultVIServers.Count -gt 1)) {
        Log-Message "Connect to a single vCenter Server (use Connect-VIServer) prior to running this script." -Level "ERROR"
        Exit
    }

    $vcVersion = $global:DefaultVIServers.Version
    if (($vcVersion -lt '7.0.0') -or ($vcVersion -gt '8.0.3')) {
        Log-Message "vCenter Server is not the correct version for this script." -Level "ERROR"
        Exit
    }
}

#####################
# Check to see if we are attached to supported hosts. Older hosts might work but things change.
Function Check-Hosts() {
    $ESXi = Get-VMHost
    foreach ($hostVersion in $ESXi.Version) {
        if (($hostVersion -lt '7.0.0') -or ($hostVersion -gt '8.0.3')) {
            Log-Message "This script requires vSphere 7 or 8 throughout the environment." -Level "ERROR"
            Log-Message "There is at least one host attached that is downlevel ($hostVersion). Exiting." -Level "ERROR"
            Exit
        }
    }    
}

#######################################################################################################

Log-Message "VMware vSphere Cluster TPM Recovery Key Backup Utility v8.0.3" -Level "INFO"
Log-Message "Date: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")" -Level "INFO"

# Accept EULA and terms to continue
if ($false -eq $AcceptEULA) {
    Accept-EULA
} else {
    Log-Message "EULA accepted." -Level "INFO"
}

# Safety checks
if ($false -eq $NoSafetyChecks) {
    Check-PowerCLI
    Check-vCenter
    Check-Hosts
} else {
    Log-Message "Safety checks skipped." -Level "INFO"
}

Log-Message "Logged format is: Hostname Key RecoveryID" -Level "INFO"

foreach ($ESXi in Get-VMHost) {

    $esxcli = Get-EsxCli -VMHost $ESXi -V2
    try {
        $key = $esxcli.system.settings.encryption.recovery.list.Invoke() | Select-Object -ExpandProperty Key
        $recoveryID = $esxcli.system.settings.encryption.recovery.list.Invoke() | Select-Object -ExpandProperty RecoveryID
    }
    catch {
        Log-Message "Unable to retrieve TPM Recovery Key for $ESXi. Skipping." -Level "WARNING"
        $key = "-"
        $recoveryID = "-"
    }

    $output = "$ESXi $key $recoveryID"
    Log-Message $output

}
