<#
    VMware vSphere Key Provider Audit Utility
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

#####################
# Accept EULA and terms to continue
Function Accept-EULA() {
    Write-Output "[EULA]  This software is provided as is and any express or implied warranties, including," 
    Write-Output "[EULA]  but not limited to, the implied warranties of merchantability and fitness for a particular" 
    Write-Output "[EULA]  purpose are disclaimed. In no event shall the copyright holder or contributors be liable" 
    Write-Output "[EULA]  for any direct, indirect, incidental, special, exemplary, or consequential damages (including," 
    Write-Output "[EULA]  but not limited to, procurement of substitute goods or services; loss of use, data, or" 
    Write-Output "[EULA]  profits; or business interruption) however caused and on any theory of liability, whether" 
    Write-Output "[EULA]  in contract, strict liability, or tort (including negligence or otherwise) arising in any" 
    Write-Output "[EULA]  way out of the use of this software, even if advised of the possibility of such damage." 
    Write-Output "[EULA]  The provider makes no claims, promises, or guarantees about the accuracy, completeness, or" 
    Write-Output "[EULA]  adequacy of this sample. Organizations should engage appropriate legal, business, technical," 
    Write-Output "[EULA]  and audit expertise within their specific organization for review of requirements and" 
    Write-Output "[EULA]  effectiveness of implementations. You acknowledge that there may be performance or other" 
    Write-Output "[EULA]  considerations, and that this example may make assumptions which may not be valid in your" 
    Write-Output "[EULA]  environment or organization." 
    Write-Output "[EULA]" 
    Write-Output "[EULA]  This software is not supported."    
    Write-Output "[EULA]" 
    Write-Output "[EULA]  Make backups of all configurations and data before using this tool. Where prompted, monitor" 
    Write-Output "[EULA]  task progress directly in the vSphere Client." 
    Write-Output "[EULA]" 
    Write-Output "[EULA]  Press any key to accept all terms and risk. Use CTRL+C to exit."
    $null = $host.UI.RawUI.FlushInputBuffer()
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

Function Do-Pause() {
    Write-Output "[WAIT]  Check the vSphere Client to make sure all tasks have completed, then press a key." 
    $null = $host.UI.RawUI.FlushInputBuffer()
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

#####################
# Check to see if we have the required version of VMware.PowerCLI
Function Check-PowerCLI() {
    $installedVersion = (Get-InstalledModule -Name 'VMware.PowerCLI' -AllVersions -ErrorAction SilentlyContinue).Version | Sort-Object -Desc | Select-Object -First 1
    if ('13.1.0' -gt $installedVersion) {
        Write-Output "[ERROR] This script requires PowerCLI 13.1 or newer. Current version is $installedVersion" 
        Write-Output "[ERROR] Instructions for installation & upgrade can be found at https://developer.vmware.com/powercli" 
        Exit
    }
}

#####################
# Check to see if we are attached to a supported vCenter Server
Function Check-vCenter() {
    if ($global:DefaultVIServers.Count -lt 1) {
        Write-Output "[ERROR] Please connect to a vCenter Server (use Connect-VIServer) prior to running this script. Thank you." 
        Exit
    }

    # Cannot override these, they're important.
    if (($global:DefaultVIServers.Count -lt 1) -or ($global:DefaultVIServers.Count -gt 1)) {
        Write-Output "[ERROR] Connect to a single vCenter Server (use Connect-VIServer) prior to running this script." 
        Exit
    }

    $vcVersion = $global:DefaultVIServers.Version
    if (($vcVersion -lt '7.0.0') -or ($vcVersion -gt '8.0.3')) {
        Write-Output "[ERROR] vCenter Server is not the correct version for this script." 
        Exit
    }
}

#####################
# Check to see if we are attached to supported hosts. Older hosts might work but things change.
Function Check-Hosts()
{
    $ESXi = Get-VMHost
    foreach ($hostVersion in $ESXi.Version) {
        if (($hostVersion -lt '7.0.0') -or ($hostVersion -gt '8.0.3')) {
            Write-Output "[ERROR] This script requires vSphere 7 or 8 throughout the environment." 
            Write-Output "[ERROR] There is at least one host attached that is downlevel ($hostVersion). Exiting." 
            Exit
        }
    }    
}

#######################################################################################################
Write-Output "[INFO]  VMware Key Provider Audit Tool v8.0.3`n"

Accept-EULA
Check-PowerCLI
Check-vCenter
Check-Hosts

$date = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

Write-Output ""

foreach ($kp in Get-KeyProvider) {
    Write-Output "[PROVIDER] $($kp.name) is $($kp.Type) and DefaultForSystem is $($kp.DefaultForSystem)"
}

Write-Output ""

foreach ($VM in Get-VM) {
    if ($vm.ExtensionData.Config.KeyId) { 
        $provider = $vm.ExtensionData.Config.KeyId.ProviderID | Select-Object -ExpandProperty Id
        Write-Output "[VM] $($vm.name) is using key provider $provider"
    } else {
        Write-Output "[VM] $($vm.name) does not have encryption enabled"
    }
}

Write-Output ""

foreach ($cluster in Get-Cluster) {
    $clusterinfo = Get-VsanClusterConfiguration -Cluster $cluster
    $provider = $clusterinfo.KeyProvider | Select-Object -ExpandProperty Name

    if ($clusterinfo.EncryptionEnabled) {
        Write-Output "[VSAN] Cluster $($clusterinfo.Name) is using key provider $provider"
    } else {
        Write-Output "[VSAN] Cluster $($clusterinfo.Name) does not have encryption enabled"
    }
}

Write-Output ""

foreach ($vmhost in Get-VMHost) {
    if ($vmhost.ConnectionState -ne 'Connected') {
        Write-Output "[WARN]  $vmhost is not connected or in maintenance mode"
    } else {
        $vmhostview = Get-View $vmhost
        if ($vmhostview.Runtime.CryptoKeyId) {
            $provider = $vmhostview.Runtime.CryptoKeyId.ProviderId | Select-Object -ExpandProperty Id
            Write-Output "[HOST] Host $vmhost is using key provider $provider"
        } else {
            Write-Output "[HOST] Host $vmhost is not participating in encryption"
        }
    }
}