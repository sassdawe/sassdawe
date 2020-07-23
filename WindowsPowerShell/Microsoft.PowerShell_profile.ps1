$ProgressPreference = 'SilentlyContinue'
$PSDefaultParameterValues["Out-Default:OutVariable"] = "__"

$hosts = "C:\Windows\System32\drivers\etc\hosts"

$myModulePath = "c:\Users\$((whoami).split('\')[-1])\Publishing\"

$env:psmodulepath = (($env:psmodulepath.Split(';') | Where-Object { -not [system.string]::IsNullOrEmpty($_) } | Sort-Object -Unique ) + $myModulePath) -join ';'

Import-Module Configuration
Import-Module Terminal-Icons

Import-Module posh-git
Import-Module oh-my-posh
Set-Theme Paradox

#region Application Insights
try {
}
catch { $_ }
#endregion

[System.Net.WebRequest]::DefaultWebProxy.Credentials = [System.Net.CredentialCache]::DefaultCredentials

New-Alias ip Invoke-Pester
function Get-ElevationStatus {
    [CmdletBinding()]
    [Alias("IsElevated")]
    param (
    )
    begin {
    }
    process {
        if ((New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
            Write-Output "Elevated."
        }
        else {
            Write-Output "Not elevated."
        }
    }
    end {
    }
}
$Global:IsElevated = Get-ElevationStatus
function Copy-Object {
    param (
        [PSCustomObject]
        $Object
    )
    $Object.PSObject.Copy()
}
Function dbps() {
    $Global:DebugLog = "$ENV:TEMP\psdebug.log"
    New-Item $Global:DebugLog -Force -ItemType File
    Start-Process powershell "Get-Content '$DebugLog' -Wait" -noprofile
}
#Write-Host 'dbps' -ForegroundColor Yellow
function Copy-History() { (Get-History).commandline | clip }
New-Alias -Name ch -Value 'Copy-History'

#Write-Host "Hey Master Skills!" -ForegroundColor Magenta

if ($AppInsightClient) {
    $AppInsightClient.TrackEvent("PowerShell started on $(hostname) by $(whoami), $(IsElevated)")
    $AppInsightClient.Flush()
}

function Get-IPConfig {
    [CmdletBinding()]
    param (
        [switch]
        $All
    )
    $info = Get-NetIPAddress | Where-Object { $_.SuffixOrigin -ne "Link" } | Sort-Object ifIndex | ForEach-Object {
        $ip = $_
        Get-NetAdapter -ifIndex $ip.ifIndex -ErrorAction SilentlyContinue | ForEach-Object {
            $out = @{ };
            $out.Name = $_.Name;
            $out.ifIndex = $_.ifIndex;
            $out.IPAddress = $ip.IPAddress;
            $out.PrefixLength = $ip.PrefixLength;
            $out.MacAddress = $_.MacAddress;
            $out.InterfaceDescription = $_.InterfaceDescription;
            $out.Status = $_.Status;
            [pscustomobject]$out
        }
    }
    if ( $All ) {
        $info #| Format-Table -AutoSize
    }
    else {
        $info | Where-Object { -not $_.InterfaceDescription.startsWith("Hyper") }
    }

}
#Write-Host 'Get-IPConfig' -ForegroundColor Yellow

<# function Prompt {
    $host.ui.RawUI.WindowTitle = "$IsElevated - $(Get-Location)"
    Write-Host "PS " -NoNewLine
    Write-Host $([char]9829) -ForegroundColor Red -NoNewLine
    " > "
} #>

# $host.ui.RawUI.WindowTitle = "$IsElevated"

# borrowing heavily from https://dbatools.io/prompt but formatting the execution time without using the DbaTimeSpanPretty C# type
function Prompt {
    Write-Host (Get-Date -Format "ddd HH:mm") -ForegroundColor Magenta -NoNewline
    try {
        $history = Get-History -ErrorAction Ignore -Count 1
        if ($history) {
            $ts = New-TimeSpan $history.StartExecutionTime  $history.EndExecutionTime
            switch ($ts) {
                { $_.totalminutes -gt 1 -and $_.totalminutes -lt 30 } {
                    Write-Host " [" -ForegroundColor Red -NoNewline
                    [decimal]$d = $_.TotalMinutes
                    '{0:f3}m' -f ($d) | Write-Host  -ForegroundColor Red -NoNewline
                    Write-Host "]" -ForegroundColor Red -NoNewline
                }
                { $_.totalminutes -le 1 -and $_.TotalSeconds -gt 1 } {
                    Write-Host " [" -ForegroundColor Yellow -NoNewline
                    [decimal]$d = $_.TotalSeconds
                    '{0:f3}s' -f ($d) | Write-Host  -ForegroundColor Yellow -NoNewline
                    Write-Host "[" -ForegroundColor Yellow -NoNewline
                }
                { $_.TotalSeconds -le 1 } {
                    [decimal]$d = $_.TotalMilliseconds
                    Write-Host " [" -ForegroundColor Green -NoNewline
                    '{0:f3}ms' -f ($d) | Write-Host  -ForegroundColor Green -NoNewline
                    Write-Host "]" -ForegroundColor Green -NoNewline
                }
                Default {
                    $_.Milliseconds | Write-Host  -ForegroundColor Gray -NoNewline
                }
            }
        }
    }
    catch { }
    Write-Host " $($pwd.path.Split('\')[-2..-1] -join '\') " -NoNewLine
    Write-Host $([char]9829) -ForegroundColor Red -NoNewLine
    " > "
}


# Chocolatey profile
$ChocolateyProfile = "$env:ChocolateyInstall\helpers\chocolateyProfile.psm1"
if (Test-Path($ChocolateyProfile)) {
    Import-Module "$ChocolateyProfile"
}
