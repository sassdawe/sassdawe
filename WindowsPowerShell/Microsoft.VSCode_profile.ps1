$ProgressPreference = 'SilentlyContinue'
$PSDefaultParameterValues["Out-Default:OutVariable"] = "__"
$Host.PrivateData.ErrorForegroundColor = "DarkYellow"
$hosts = "C:\Windows\System32\drivers\etc\hosts"

if ($true) {
    if ($PSVersionTable.PSVersion.Major -eq 5) {
        $env:PSModulePath = ($env:PSModulePath.Split(';') | Where-Object { (-not ( $_ -like "*Files\powershell*" ))-and (-not ( $_ -like "*\Powershell\Modules" )) }) -join ';'
        $env:PSModulePath += ";$(Split-Path $profile)\Modules"
        Get-Module | Where-Object { $_.path -ilike '*Files\PowerShell*' } | Remove-Module
    }

}

Set-PSReadLineOption -AddToHistoryHandler {
    param([string]$line)

    $sensitive = "password|asplaintext|token|key|secret"
    return ($line -notmatch $sensitive)
}

Set-PSReadLineOption -PredictionSource History