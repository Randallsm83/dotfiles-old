# PowerShell Profile for Windows
# Symlinked to PowerShell 7+ profile location

# ================================================================================================
# XDG Base Directory Specification for Windows
# ================================================================================================

$env:XDG_CONFIG_HOME = "$env:USERPROFILE\.config"
$env:XDG_DATA_HOME = "$env:USERPROFILE\.local\share"
$env:XDG_STATE_HOME = "$env:USERPROFILE\.local\state"
$env:XDG_CACHE_HOME = "$env:USERPROFILE\.cache"

# Ensure XDG directories exist
$xdgDirs = @($env:XDG_CONFIG_HOME, $env:XDG_DATA_HOME, $env:XDG_STATE_HOME, $env:XDG_CACHE_HOME)
foreach ($dir in $xdgDirs) {
    if (-not (Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
    }
}

# ================================================================================================
# 1Password SSH Agent Configuration
# ================================================================================================

# Configure SSH to use 1Password SSH agent
# 1Password exposes the agent via a named pipe on Windows
$env:SSH_AUTH_SOCK = "\\.\pipe\openssh-ssh-agent"

# Configure Git to use Windows native SSH (not Git Bash SSH)
# This is required for Git to work with 1Password SSH agent
$env:GIT_SSH_COMMAND = "C:/Windows/System32/OpenSSH/ssh.exe"

# ================================================================================================
# PATH Management
# ================================================================================================

$userBin = "$env:USERPROFILE\bin"
if (Test-Path $userBin) {
    if ($env:PATH -notlike "*$userBin*") {
        $env:PATH = "$userBin;$env:PATH"
    }
}

# ================================================================================================
# Custom Aliases
# ================================================================================================

# Source custom aliases file
# This must be loaded AFTER XDG variables are set but BEFORE tool integrations
$env:DOTFILES = "$env:USERPROFILE\.config\dotfiles"
$aliasesPath = "$env:DOTFILES\windows\powershell\aliases.ps1"
if (Test-Path $aliasesPath) {
    try {
        . $aliasesPath
    }
    catch {
        Write-Warning "Failed to load aliases from $aliasesPath : $_"
    }
} else {
    Write-Warning "Aliases file not found at $aliasesPath"
}

# ================================================================================================
# PSReadLine Configuration
# ================================================================================================

if (Get-Module -ListAvailable -Name PSReadLine) {
    $psrl = Get-Module -ListAvailable PSReadLine | Sort-Object Version -Descending | Select-Object -First 1
    Import-Module PSReadLine

    # Keybindings
    Set-PSReadLineKeyHandler -Key UpArrow -Function HistorySearchBackward
    Set-PSReadLineKeyHandler -Key DownArrow -Function HistorySearchForward
    Set-PSReadLineKeyHandler -Key Tab -Function MenuComplete

    # Behavior
    if ($psrl -and $PSVersionTable.PSVersion.Major -ge 7 -and $psrl.Version -ge [version]'2.1.0') {
        Set-PSReadLineOption -PredictionSource History
        Set-PSReadLineOption -PredictionViewStyle ListView
    }
    Set-PSReadLineOption -HistorySearchCursorMovesToEnd
    Set-PSReadLineOption -BellStyle None

    # Colors
    Set-PSReadLineOption -Colors @{
        Command   = 'Cyan'
        Parameter = 'DarkCyan'
        String    = 'Green'
        Operator  = 'Yellow'
    }
}

# ================================================================================================
# Starship Prompt
# ================================================================================================

# Resolve starship from PATH or common install locations and initialize
$starshipCmd = $null
try {
    $starshipCmd = Get-Command starship -ErrorAction Stop | Select-Object -ExpandProperty Path
} catch {}

if (-not $starshipCmd) {
    $candidates = @(
        (Join-Path $env:ProgramFiles 'starship\bin\starship.exe'),
        (Join-Path $env:LOCALAPPDATA 'Programs\starship\bin\starship.exe'),
        ($env:SCOOP ? (Join-Path $env:SCOOP 'apps\starship\current\starship.exe') : $null),
        ($env:ChocolateyInstall ? (Join-Path $env:ChocolateyInstall 'bin\starship.exe') : $null),
        (Join-Path $HOME '.cargo\bin\starship.exe')
    ) | Where-Object { $_ -and (Test-Path $_) }

    if ($candidates.Count -gt 0) {
        $starshipCmd = $candidates[0]
        $env:PATH = (Split-Path -Parent $starshipCmd) + ';' + $env:PATH
    }
}

if ($starshipCmd) {
    $env:STARSHIP_CONFIG = "$env:XDG_CONFIG_HOME\starship\starship.toml"
    $env:STARSHIP_CACHE = "$env:XDG_CACHE_HOME\starship"
    Invoke-Expression (& $starshipCmd init powershell)
} else {
    # Fallback minimal prompt if starship is unavailable
    function global:prompt {
        $path = (Get-Location).Path
        $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
        $user = if ($isAdmin) { '# ' } else { '$ ' }
        "PS $path$user"
    }
}

# ================================================================================================
# Tool Integrations
# ================================================================================================

# zoxide (smart cd)
if (Get-Command zoxide -ErrorAction SilentlyContinue) {
    Invoke-Expression (& zoxide init powershell | Out-String)
}

# mise (version manager)
if (Get-Command mise -ErrorAction SilentlyContinue) {
    # Configure mise XDG paths for Windows
    $env:MISE_DATA_DIR = "$env:XDG_DATA_HOME\mise"
    $env:MISE_CONFIG_DIR = "$env:XDG_CONFIG_HOME\mise"
    $env:MISE_CACHE_DIR = "$env:XDG_CACHE_HOME\mise"
    $env:MISE_STATE_DIR = "$env:XDG_STATE_HOME\mise"
    
    # Activate mise
    Invoke-Expression (& mise activate pwsh | Out-String)
}

# fnm (Fast Node Manager) - fallback if mise not available
if ((Get-Command fnm -ErrorAction SilentlyContinue) -and -not (Get-Command mise -ErrorAction SilentlyContinue)) {
    fnm env --use-on-cd | Out-String | Invoke-Expression
}

# PSFzf (fuzzy finder integration)
if (Get-Module -ListAvailable -Name PSFzf) {
    Import-Module PSFzf
    Set-PsFzfOption -PSReadlineChordProvider 'Ctrl+t' -PSReadlineChordReverseHistory 'Ctrl+r'
}

# eza integration
$ezaModulePath = Join-Path $PSScriptRoot 'Modules\EzaProfile\EzaProfile.psm1'
if (Test-Path $ezaModulePath) {
    Import-Module $ezaModulePath -Force
}

# WSLTabCompletion (WSL command completion)
if (Get-Module -ListAvailable -Name WSLTabCompletion) {
    Import-Module WSLTabCompletion
}

# Custom completions (auto-load all .ps1 files from completions directory)
$completionsPath = "$env:XDG_CONFIG_HOME\powershell\Completions"
if (Test-Path $completionsPath) {
    Get-ChildItem -Path $completionsPath -Filter "*.ps1" -ErrorAction SilentlyContinue | ForEach-Object {
        try {
            . $_.FullName
        } catch {
            Write-Warning "Failed to load completion: $($_.Name) - $($_.Exception.Message)"
        }
    }
}

# CacheCleaner module
$cacheCleanerPath = Join-Path $PSScriptRoot 'Modules\CacheCleaner\CacheCleaner.psm1'
if (Test-Path $cacheCleanerPath) {
    Import-Module $cacheCleanerPath -Force
}

# UV (Python package manager) shell completion
if (Get-Command uv -ErrorAction SilentlyContinue) {
    try {
        (& uv generate-shell-completion powershell) | Out-String | Invoke-Expression
    } catch {}
}
if (Get-Command uvx -ErrorAction SilentlyContinue) {
    try {
        (& uvx --generate-shell-completion powershell) | Out-String | Invoke-Expression
    } catch {}
}

# Visual Studio Build Tools environment
$vsDevCmdPath = "C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\Common7\Tools\VsDevCmd.bat"
if ((Test-Path $vsDevCmdPath) -and (Get-Command Import-BatchEnvironment -ErrorAction SilentlyContinue)) {
    try {
        Import-BatchEnvironment $vsDevCmdPath
    } catch {}
}

# ================================================================================================
# Aliases
# ================================================================================================

# Unix-like commands
Set-Alias -Name grep -Value Select-String -ErrorAction SilentlyContinue
Set-Alias -Name which -Value Get-Command -ErrorAction SilentlyContinue

# Process management aliases
Set-Alias -Name ps -Value Get-Process -ErrorAction SilentlyContinue
Set-Alias -Name kill -Value Stop-Process -ErrorAction SilentlyContinue

# Replace built-in scoop search (if scoop-search is available)
if (Get-Command scoop-search -ErrorAction SilentlyContinue) {
    try {
        Invoke-Expression (&scoop-search --hook)
    } catch {}
}

# Common shortcuts
if (Get-Command nvim -ErrorAction SilentlyContinue) {
    function vim { & nvim $args }
    function vi { & nvim $args }
}

# Git shortcuts
function gs { git status $args }
function ga { git add $args }
function gc { git commit $args }
function gp { git push $args }
function gl { git pull $args }
function gd { git diff $args }
function gco { git checkout $args }
function glog { git log --oneline --graph --decorate $args }

# Directory navigation
function .. { Set-Location .. }
function ... { Set-Location ..\.. }
function .... { Set-Location ..\..\.. }

# bat (better cat)
if (Get-Command bat -ErrorAction SilentlyContinue) {
    Remove-Alias -Name cat -Force -ErrorAction SilentlyContinue
    function cat { & bat $args }
}

# ================================================================================================
# Utility Functions
# ================================================================================================

# Reload profile
function Reload-Profile {
    . $PROFILE
    Write-Host "Profile reloaded!" -ForegroundColor Green
}
Set-Alias -Name reload -Value Reload-Profile

# Quick edit profile
function Edit-Profile {
    if (Get-Command nvim -ErrorAction SilentlyContinue) {
        nvim $PROFILE
    } else {
        notepad $PROFILE
    }
}
Set-Alias -Name ep -Value Edit-Profile

# Touch command
function touch {
    param([string]$file)
    if (Test-Path $file) {
        (Get-Item $file).LastWriteTime = Get-Date
    } else {
        New-Item -ItemType File -Path $file | Out-Null
    }
}

# mkcd - make directory and change into it
function mkcd {
    param([string]$path)
    New-Item -ItemType Directory -Path $path -Force | Out-Null
    Set-Location $path
}

# OSC7 terminal integration for WezTerm
function Set-EnvVar {
    $p = $executionContext.SessionState.Path.CurrentLocation
    $osc7 = ""
    if ($p.Provider.Name -eq "FileSystem") {
        $ansi_escape = [char]27
        $provider_path = $p.ProviderPath -Replace "\\", "/"
        $osc7 = "$ansi_escape]7;file://${env:COMPUTERNAME}/${provider_path}${ansi_escape}\"
    }
    $env:OSC7=$osc7
}
New-Alias -Name 'Set-PoshContext' -Value 'Set-EnvVar' -Scope Global -Force

# -------------------------------------------------------------------------------------------------
# vim: ft=ps1 sw=4 ts=4 et
# -------------------------------------------------------------------------------------------------
