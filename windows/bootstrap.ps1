#Requires -Version 5.1
<#
.SYNOPSIS
    Bootstrap script for Windows dotfiles setup

.DESCRIPTION
    Sets up dotfiles on Windows by:
    - Installing packages via winget/scoop
    - Creating symlinks for config files
    - Setting up XDG environment variables
    - Configuring PowerShell profiles

.PARAMETER Packages
    Package manager to use: winget, scoop, both, or none (default: winget)

.PARAMETER LinkOnly
    Skip package installation, only create symlinks

.PARAMETER IncludeVSCode
    Include VS Code settings and extensions

.PARAMETER WhatIf
    Show what would be done without making changes

.PARAMETER Force
    Overwrite existing files/links without prompting

.EXAMPLE
    .\bootstrap.ps1
    Run with defaults (winget packages + symlinks)

.EXAMPLE
    .\bootstrap.ps1 -LinkOnly
    Only create symlinks, skip package installation

.EXAMPLE
    .\bootstrap.ps1 -Packages scoop -IncludeVSCode
    Use scoop for packages and setup VS Code
#>

[CmdletBinding(SupportsShouldProcess)]
param(
    [ValidateSet('winget', 'scoop', 'both', 'none')]
    [string]$Packages = 'winget',
    
    [switch]$LinkOnly,
    
    [switch]$IncludeVSCode,
    
    [switch]$Force
)

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

# ================================================================================================
# Script Variables
# ================================================================================================

$Script:DotfilesRoot = (Resolve-Path (Split-Path -Parent $PSScriptRoot)).Path
$Script:Stats = @{
    LinksCreated = 0
    LinksFailed = 0
    PackagesInstalled = 0
    PackagesFailed = 0
}

# ================================================================================================
# Helper Functions
# ================================================================================================

function Write-Status {
    param(
        [Parameter(Mandatory)]
        [string]$Message,
        
        [ValidateSet('Info', 'Success', 'Warning', 'Error')]
        [string]$Type = 'Info'
    )
    
    $colors = @{
        Info = 'Cyan'
        Success = 'Green'
        Warning = 'Yellow'
        Error = 'Red'
    }
    
    $symbols = @{
        Info = 'ℹ'
        Success = '✓'
        Warning = '⚠'
        Error = '✗'
    }
    
    Write-Host "$($symbols[$Type]) " -ForegroundColor $colors[$Type] -NoNewline
    Write-Host $Message
}

function Test-Administrator {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = [Security.Principal.WindowsPrincipal]$identity
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Test-DeveloperMode {
    try {
        $key = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock'
        $value = Get-ItemProperty -Path $key -Name AllowDevelopmentWithoutDevLicense -ErrorAction SilentlyContinue
        return $value.AllowDevelopmentWithoutDevLicense -eq 1
    } catch {
        return $false
    }
}

function Enable-DeveloperMode {
    if (-not (Test-Administrator)) {
        Write-Status "Developer Mode requires administrator privileges" -Type Warning
        Write-Host "Run this script as administrator or enable Developer Mode manually:"
        Write-Host "  Settings > Update & Security > For developers > Developer mode"
        return $false
    }
    
    Write-Status "Enabling Developer Mode..." -Type Info
    
    $key = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock'
    if (-not (Test-Path $key)) {
        New-Item -Path $key -Force | Out-Null
    }
    
    Set-ItemProperty -Path $key -Name AllowDevelopmentWithoutDevLicense -Value 1 -Type DWord
    
    Write-Status "Developer Mode enabled (restart may be required)" -Type Success
    return $true
}

function New-Link {
    param(
        [Parameter(Mandatory)]
        [string]$Source,
        
        [Parameter(Mandatory)]
        [string]$Target,
        
        [Parameter(Mandatory)]
        [ValidateSet('File', 'Directory')]
        [string]$Type
    )
    
    # Resolve paths
    $Source = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($Source)
    $Target = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($Target)
    
    # Check source exists
    if (-not (Test-Path $Source)) {
        Write-Status "Source does not exist: $Source" -Type Error
        $Script:Stats.LinksFailed++
        return $false
    }
    
    # Ensure parent directory exists
    $TargetParent = Split-Path -Parent $Target
    if (-not (Test-Path $TargetParent)) {
        New-Item -ItemType Directory -Path $TargetParent -Force | Out-Null
    }
    
    # Handle existing target
    if (Test-Path $Target) {
        $item = Get-Item $Target -Force
        
        # If it's already a symlink pointing to the right place, skip
        if ($item.LinkType -eq 'SymbolicLink' -and $item.Target -eq $Source) {
            Write-Verbose "Link already exists: $Target"
            return $true
        }
        
        # Otherwise, back it up
        if (-not $Force -and -not $WhatIfPreference) {
            $response = Read-Host "Target exists: $Target. Backup? (Y/n)"
            if ($response -eq 'n') {
                Write-Status "Skipped: $Target" -Type Warning
                return $false
            }
        }
        
        $timestamp = Get-Date -Format 'yyyyMMdd_HHmmss'
        $backup = "$Target.backup_$timestamp"
        Write-Verbose "Backing up to: $backup"
        Move-Item -Path $Target -Destination $backup -Force
    }
    
    # Try to create symlink
    if ($PSCmdlet.ShouldProcess($Target, "Create symlink to $Source")) {
        try {
            $itemType = if ($Type -eq 'Directory') { 'SymbolicLink' } else { 'SymbolicLink' }
            New-Item -ItemType $itemType -Path $Target -Target $Source -Force -ErrorAction Stop | Out-Null
            Write-Status "Linked: $(Split-Path -Leaf $Target)" -Type Success
            $Script:Stats.LinksCreated++
            return $true
        } catch {
            # Try junction for directories
            if ($Type -eq 'Directory') {
                try {
                    cmd /c mklink /J "$Target" "$Source" 2>&1 | Out-Null
                    Write-Status "Linked (junction): $(Split-Path -Leaf $Target)" -Type Success
                    $Script:Stats.LinksCreated++
                    return $true
                } catch {
                    Write-Status "Failed to link: $Target - $($_.Exception.Message)" -Type Error
                    $Script:Stats.LinksFailed++
                    return $false
                }
            }
            
            # For files, try hardlink or copy as last resort
            if ($Type -eq 'File') {
                try {
                    New-Item -ItemType HardLink -Path $Target -Target $Source -Force -ErrorAction Stop | Out-Null
                    Write-Status "Linked (hardlink): $(Split-Path -Leaf $Target)" -Type Success
                    $Script:Stats.LinksCreated++
                    return $true
                } catch {
                    Write-Status "Copying instead: $(Split-Path -Leaf $Target)" -Type Warning
                    Copy-Item -Path $Source -Destination $Target -Force
                    $Script:Stats.LinksCreated++
                    return $true
                }
            }
            
            Write-Status "Failed to link: $Target" -Type Error
            $Script:Stats.LinksFailed++
            return $false
        }
    }
    
    return $false
}

# ================================================================================================
# Environment Setup
# ================================================================================================

function Initialize-Environment {
    Write-Host "`n========================================" -ForegroundColor Cyan
    Write-Host " Windows Dotfiles Bootstrap" -ForegroundColor White
    Write-Host "========================================`n" -ForegroundColor Cyan
    
    # Check PowerShell version
    if ($PSVersionTable.PSVersion.Major -lt 5) {
        Write-Status "PowerShell 5.1 or higher is required" -Type Error
        exit 1
    }
    
    if ($PSVersionTable.PSVersion.Major -ge 7) {
        Write-Status "PowerShell $($PSVersionTable.PSVersion)" -Type Success
    } else {
        Write-Status "PowerShell 5.1 (consider upgrading to PowerShell 7+)" -Type Warning
    }
    
    # Check Developer Mode for symlinks
    if (Test-DeveloperMode) {
        Write-Status "Developer Mode is enabled" -Type Success
    } else {
        Write-Status "Developer Mode is disabled" -Type Warning
        Write-Host "  Symlinks will require admin privileges or use fallbacks (junctions/hardlinks)"
        
        if (Test-Administrator) {
            $response = Read-Host "Enable Developer Mode now? (Y/n)"
            if ($response -ne 'n') {
                Enable-DeveloperMode | Out-Null
            }
        }
    }
    
    # Create XDG directories
    Write-Status "Creating XDG directories..." -Type Info
    
    $xdgDirs = @(
        "$env:USERPROFILE\.config",
        "$env:USERPROFILE\.local\share",
        "$env:USERPROFILE\.local\state",
        "$env:USERPROFILE\.cache",
        "$env:USERPROFILE\bin"
    )
    
    foreach ($dir in $xdgDirs) {
        if (-not (Test-Path $dir)) {
            New-Item -ItemType Directory -Path $dir -Force | Out-Null
        }
    }
    
    Write-Status "XDG directories created" -Type Success
}

function Set-EnvironmentVariables {
    Write-Status "Setting environment variables..." -Type Info
    
    $xdgVars = @{
        'XDG_CONFIG_HOME' = "$env:USERPROFILE\.config"
        'XDG_DATA_HOME' = "$env:USERPROFILE\.local\share"
        'XDG_STATE_HOME' = "$env:USERPROFILE\.local\state"
        'XDG_CACHE_HOME' = "$env:USERPROFILE\.cache"
    }
    
    foreach ($var in $xdgVars.GetEnumerator()) {
        [System.Environment]::SetEnvironmentVariable($var.Key, $var.Value, 'User')
        Set-Item -Path "env:$($var.Key)" -Value $var.Value
    }
    
    # Add user bin to PATH if not present
    $userPath = [System.Environment]::GetEnvironmentVariable('Path', 'User')
    $binPath = "$env:USERPROFILE\bin"
    
    if ($userPath -notlike "*$binPath*") {
        $newPath = "$binPath;$userPath"
        [System.Environment]::SetEnvironmentVariable('Path', $newPath, 'User')
        $env:Path = "$binPath;$env:Path"
        Write-Status "Added $binPath to PATH" -Type Success
    }
    
    Write-Status "Environment variables set" -Type Success
}

# ================================================================================================
# Package Installation
# ================================================================================================

function Install-WingetPackages {
    Write-Host "`n--- Installing packages via winget ---`n" -ForegroundColor Cyan
    
    if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
        Write-Status "winget not found" -Type Error
        return
    }
    
    $packageFile = Join-Path $PSScriptRoot 'packages\winget.json'
    
    if (Test-Path $packageFile) {
        Write-Status "Installing from winget.json..." -Type Info
        winget import -i $packageFile --accept-source-agreements --accept-package-agreements
    } else {
        Write-Status "winget.json not found, skipping" -Type Warning
    }
}

function Install-ScoopPackages {
    Write-Host "`n--- Installing packages via scoop ---`n" -ForegroundColor Cyan
    
    # Note: On Windows, package management is split:
    # - scoop: CLI tools (git, neovim, bat, ripgrep, starship, etc.) + mise
    # - winget: GUI applications only
    # - mise: Language runtimes ONLY (node, python, ruby, go, rust, etc.)
    #
    # This differs from Linux/WSL/macOS where mise handles both CLI tools and language runtimes.
    
    # Install scoop if not present
    if (-not (Get-Command scoop -ErrorAction SilentlyContinue)) {
        Write-Status "Installing scoop..." -Type Info
        $scoopInstaller = 'https://get.scoop.sh'
        Invoke-RestMethod -Uri $scoopInstaller | Invoke-Expression
    }
    
    $packageFile = Join-Path $PSScriptRoot 'packages\scoop.json'
    
    if (-not (Test-Path $packageFile)) {
        Write-Status "scoop.json not found, skipping" -Type Warning
        return
    }
    
    $config = Get-Content $packageFile | ConvertFrom-Json
    
    # Add buckets
    foreach ($bucket in $config.buckets) {
        Write-Status "Adding bucket: $bucket" -Type Info
        scoop bucket add $bucket 2>$null
    }
    
    # Install apps
    foreach ($app in $config.apps) {
        if (-not (scoop list $app 2>$null)) {
            # Special message for mise
            if ($app -eq 'mise') {
                Write-Status "Installing mise (for language runtimes only)..." -Type Info
                Write-Host "  Note: CLI tools are managed by scoop on Windows" -ForegroundColor DarkGray
            } else {
                Write-Status "Installing: $app" -Type Info
            }
            scoop install $app
        }
    }
    
    # Install fonts
    if ($config.fonts) {
        foreach ($font in $config.fonts) {
            if (-not (scoop list $font 2>$null)) {
                Write-Status "Installing font: $font" -Type Info
                scoop install $font
            }
        }
    }
}

# ================================================================================================
# Link Creation
# ================================================================================================

function Invoke-Stow {
    Write-Host "`n--- Creating symlinks (Stow-like) ---`n" -ForegroundColor Cyan
    
    # Get all packages with dot-config or dot-local directories
    $packages = Get-ChildItem -Path $Script:DotfilesRoot -Directory | Where-Object {
        (Test-Path (Join-Path $_.FullName 'dot-config')) -or (Test-Path (Join-Path $_.FullName 'dot-local'))
    }
    
    foreach ($pkg in $packages) {
        $pkgPath = $pkg.FullName
        
        Write-Status "Stowing: $($pkg.Name)" -Type Info
        
        # Find dot-config and dot-local directories
        $dotConfig = Join-Path $pkgPath 'dot-config'
        if (Test-Path $dotConfig) {
            # Get all items (files and directories) recursively
            Get-ChildItem -Path $dotConfig -Recurse | ForEach-Object {
                $relPath = $_.FullName.Substring($dotConfig.Length + 1)
                
                # Strip 'dot-' prefix from path components
                $relPath = $relPath -replace '(^|\\)dot-', '$1.'
                
                $source = $_.FullName
                $target = Join-Path "$env:USERPROFILE\.config" $relPath
                
                if ($_.PSIsContainer) {
                    # Strip 'dot-' prefix from directory name
                    if ($_.Name -match '^dot-') {
                        # Skip creating directories with dot- prefix, they'll be created with . prefix
                        return
                    }
                    # Create directory if it doesn't exist
                    if (-not (Test-Path $target)) {
                        New-Item -ItemType Directory -Path $target -Force | Out-Null
                    }
                } else {
                    # Link file
                    # Ensure parent directory exists
                    $targetParent = Split-Path -Parent $target
                    if (-not (Test-Path $targetParent)) {
                        New-Item -ItemType Directory -Path $targetParent -Force | Out-Null
                    }
                    
                    New-Link -Source $source -Target $target -Type File
                }
            }
        }
        
        $dotLocal = Join-Path $pkgPath 'dot-local'
        if (Test-Path $dotLocal) {
            Get-ChildItem -Path $dotLocal -Recurse | ForEach-Object {
                $relPath = $_.FullName.Substring($dotLocal.Length + 1)
                
                # Strip 'dot-' prefix from path components
                $relPath = $relPath -replace '(^|\\)dot-', '$1.'
                
                $source = $_.FullName
                $target = Join-Path "$env:USERPROFILE\.local" $relPath
                
                if ($_.PSIsContainer) {
                    # Strip 'dot-' prefix from directory name
                    if ($_.Name -match '^dot-') {
                        # Skip creating directories with dot- prefix, they'll be created with . prefix
                        return
                    }
                    # Create directory if it doesn't exist
                    if (-not (Test-Path $target)) {
                        New-Item -ItemType Directory -Path $target -Force | Out-Null
                    }
                } else {
                    # Link file
                    # Ensure parent directory exists
                    $targetParent = Split-Path -Parent $target
                    if (-not (Test-Path $targetParent)) {
                        New-Item -ItemType Directory -Path $targetParent -Force | Out-Null
                    }
                    
                    New-Link -Source $source -Target $target -Type File
                }
            }
        }
    }
}

function New-WindowsLinks {
    Write-Host "`n--- Creating Windows-specific links ---`n" -ForegroundColor Cyan
    
    # Windows-specific git config
    $gitConfigSource = Join-Path $PSScriptRoot 'dot-config\git\windows.gitconfig'
    $gitConfigTarget = "$env:USERPROFILE\.config\git\windows.gitconfig"
    if (Test-Path $gitConfigSource) {
        New-Link -Source $gitConfigSource -Target $gitConfigTarget -Type File
    }
    
    # PowerShell profiles
    $profileSource = Join-Path $PSScriptRoot 'powershell\Microsoft.PowerShell_profile.ps1'
    
    if (Test-Path $profileSource) {
        # PowerShell 7+ only
        $pwshProfile = "$env:USERPROFILE\Documents\PowerShell\Microsoft.PowerShell_profile.ps1"
        New-Link -Source $profileSource -Target $pwshProfile -Type File
    }
    
    # Windows Terminal settings
    $wtSettingsSource = Join-Path $PSScriptRoot 'windows-terminal\settings.json'
    $wtSettingsTarget = "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"
    
    if ((Test-Path $wtSettingsSource) -and (Test-Path (Split-Path $wtSettingsTarget))) {
        New-Link -Source $wtSettingsSource -Target $wtSettingsTarget -Type File
    }
    
    # VS Code (if requested)
    if ($IncludeVSCode) {
        $vscodeSource = Join-Path $PSScriptRoot 'vscode'
        $vscodeTarget = "$env:APPDATA\Code\User"
        
        if (Test-Path (Join-Path $vscodeSource 'settings.json')) {
            New-Link -Source (Join-Path $vscodeSource 'settings.json') -Target (Join-Path $vscodeTarget 'settings.json') -Type File
        }
        
        if (Test-Path (Join-Path $vscodeSource 'keybindings.json')) {
            New-Link -Source (Join-Path $vscodeSource 'keybindings.json') -Target (Join-Path $vscodeTarget 'keybindings.json') -Type File
        }
    }
    
    # Warp launch configurations
    # Note: Stow links warp configs to ~/.config/warp/, but Warp looks in AppData
    $warpConfigSource = "$env:USERPROFILE\.config\warp\launch_configurations"
    $warpLaunchTarget = "$env:APPDATA\warp\Warp\data\launch_configurations"
    
    if (Test-Path $warpConfigSource) {
        Write-Status "Linking Warp launch configurations..." -Type Info
        
        # Ensure target directory exists
        if (-not (Test-Path $warpLaunchTarget)) {
            New-Item -ItemType Directory -Path $warpLaunchTarget -Force | Out-Null
        }
        
        # Link each launch configuration file
        Get-ChildItem -Path $warpConfigSource -Filter '*.yaml' | ForEach-Object {
            $source = $_.FullName
            $target = Join-Path $warpLaunchTarget $_.Name
            New-Link -Source $source -Target $target -Type File
        }
    }
}

# ================================================================================================
# Main Execution
# ================================================================================================

try {
    # Initialize
    Initialize-Environment
    Set-EnvironmentVariables
    
    # Install packages (unless -LinkOnly)
    if (-not $LinkOnly) {
        if ($Packages -eq 'winget' -or $Packages -eq 'both') {
            Install-WingetPackages
        }
        
        if ($Packages -eq 'scoop' -or $Packages -eq 'both') {
            Install-ScoopPackages
        }
    }
    
    # Create links
    Invoke-Stow
    New-WindowsLinks
    
    # Summary
    Write-Host "`n========================================" -ForegroundColor Cyan
    Write-Host " Setup Complete" -ForegroundColor Green
    Write-Host "========================================`n" -ForegroundColor Cyan
    
    Write-Host "Links created: $($Script:Stats.LinksCreated)" -ForegroundColor Green
    if ($Script:Stats.LinksFailed -gt 0) {
        Write-Host "Links failed: $($Script:Stats.LinksFailed)" -ForegroundColor Red
    }
    
    Write-Host "`nNext steps:" -ForegroundColor Cyan
    Write-Host "  1. Restart your terminal to load new environment variables"
    Write-Host "  2. Run 'pwsh' to test PowerShell profile with Starship"
    Write-Host "  3. Verify configs are linked: Get-Item ~\.config\nvim"
    Write-Host "`nTroubleshooting:" -ForegroundColor Cyan
    Write-Host "  - If symlinks failed, enable Developer Mode or run as admin"
    Write-Host "  - Check logs above for any errors"
    Write-Host "  - Run '.\windows\verify.ps1' to verify installation`n"
    
} catch {
    Write-Status "Bootstrap failed: $($_.Exception.Message)" -Type Error
    Write-Host $_.ScriptStackTrace -ForegroundColor Red
    exit 1
}
