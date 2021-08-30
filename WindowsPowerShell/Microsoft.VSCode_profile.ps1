$ProgressPreference = 'SilentlyContinue'
$PSDefaultParameterValues["Out-Default:OutVariable"] = "__"
$Host.PrivateData.ErrorForegroundColor = "DarkYellow"
$hosts = "C:\Windows\System32\drivers\etc\hosts"

Set-PSReadLineOption -AddToHistoryHandler {
    param([string]$line)

    $sensitive = "password|asplaintext|token|key|secret"
    return ($line -notmatch $sensitive)
}

Set-PSReadLineOption -PredictionSource History