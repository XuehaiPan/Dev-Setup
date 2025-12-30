chcp 65001

Import-Module -Name PSReadLine -Force -ErrorAction:Ignore
Import-Module -Name posh-git -ErrorAction:Ignore

if (Test-Path -Path "~\Miniconda3\shell\condabin\conda-hook.ps1") {
    & "~\Miniconda3\shell\condabin\conda-hook.ps1"
}

$Env:YAZI_FILE_ONE = "${Env:ProgramFiles}\Git\usr\bin\file.exe"
oh-my-posh init pwsh --config "ys" | Invoke-Expression
Set-PSReadLineOption -EditMode Emacs
Set-PSReadLineKeyHandler -Key UpArrow -Function HistorySearchBackward
Set-PSReadLineKeyHandler -Key DownArrow -Function HistorySearchForward
Set-PSReadLineKeyHandler -Key Tab -Function Complete

Set-Alias -Name which -Value Get-Command -Option AllScope
if (Get-Command -Name eza -ErrorAction SilentlyContinue) {
    Function Get-ChildItemEza {
        eza --header --group-directories-first --group --binary ``
            --time-style="+%Y-%m-%d %H:%M:%S" ``
            --color=auto --classify=auto --icons=auto --git ``
            $Args
    }
    Function Get-ChildItemEzaAll {
        Get-ChildItemEza -A
    }
    Function Get-ChildItemEzaLong {
        Get-ChildItemEza -lh
    }
    Function Get-ChildItemEzaAllLong {
        Get-ChildItemEza -Alh
    }
    Set-Alias -Name ls -Value Get-ChildItemEza -Option AllScope
    Set-Alias -Name la -Value Get-ChildItemEzaAll -Option AllScope
    Set-Alias -Name ll -Value Get-ChildItemEzaLong -Option AllScope
    Set-Alias -Name l -Value Get-ChildItemEzaAllLong -Option AllScope
} else {
    Import-Module -Name Get-ChildItemColor -ErrorAction:Ignore
    Set-Alias -Name ls -Value Get-ChildItemColorFormatWide -Option AllScope
    Set-Alias -Name ll -Value Get-ChildItemColor -Option AllScope
}

Function Set-Proxy {
    Param(
        [string]$ProxyHost = "127.0.0.1",
        [int]$HttpPort = 7890,
        [int]$HttpsPort = 7890,
        [int]$FtpPort = 7890,
        [int]$SocksPort = 7891,
        [switch]$ProcessOnly = $false
    )
    $Env:http_proxy = "http://${ProxyHost}:${HttpPort}"
    $Env:https_proxy = "http://${ProxyHost}:${HttpsPort}"
    $Env:ftp_proxy = "http://${ProxyHost}:${FtpPort}"
    $Env:all_proxy = "socks5://${ProxyHost}:${SocksPort}"
    if ($ProcessOnly) {
        return
    }

    [Environment]::SetEnvironmentVariable('http_proxy', "http://${ProxyHost}:${HttpPort}", 'User')
    [Environment]::SetEnvironmentVariable('https_proxy', "http://${ProxyHost}:${HttpsPort}", 'User')
    [Environment]::SetEnvironmentVariable('ftp_proxy', "http://${ProxyHost}:${FtpPort}", 'User')
    [Environment]::SetEnvironmentVariable('all_proxy', "socks5://${ProxyHost}:${SocksPort}", 'User')

    $regKey = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings"
    Set-ItemProperty -Path $regKey -Name ProxyEnable -Value 1
    Set-ItemProperty -Path $regKey -Name ProxyServer -Value "${ProxyHost}:${HttpPort}"
}
Function Reset-Proxy {
    Remove-Item -Path Env:\http_proxy -ErrorAction:Ignore
    Remove-Item -Path Env:\https_proxy -ErrorAction:Ignore
    Remove-Item -Path Env:\ftp_proxy -ErrorAction:Ignore
    Remove-Item -Path Env:\all_proxy -ErrorAction:Ignore
    [Environment]::SetEnvironmentVariable('http_proxy', $null, 'User')
    [Environment]::SetEnvironmentVariable('https_proxy', $null, 'User')
    [Environment]::SetEnvironmentVariable('ftp_proxy', $null, 'User')
    [Environment]::SetEnvironmentVariable('all_proxy', $null, 'User')

    $regKey = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings"
    Set-ItemProperty -Path $regKey -Name ProxyEnable -Value 0
    Set-ItemProperty -Path $regKey -Name ProxyServer -Value ""
}
