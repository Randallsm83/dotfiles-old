#Requires -Version 5.1
<#
.SYNOPSIS
    Verify Windows dotfiles installation

.DESCRIPTION
    Checks that all dotfiles are properly installed:
    - Symlinks exist and point to correct targets
    - Package managers are installed
    - Optional tools are present
    - Config files have correct content
    - VS Code extensions are installed (if requested)
    - Fonts are installed

.PARAMETER IncludeVSCode
    Check VS Code settings and extensions

.PARAMETER Detailed
    Show detailed information for each check

.EXAMPLE
    .\verify.ps1
    Run basic verification

.EXAMPLE
    .\verify.ps1 -IncludeVSCode -Detailed
    Verify including VS Code with detailed output
#>

[CmdletBinding()]
param(
    [switch]$IncludeVSCode,
    [switch]$Detailed
)

$ErrorActionPreference = 'Continue'

# ================================================================================================
# Script Variables
# ================================================================================================

$Script:DotfilesRoot = (Resolve-Path (Split-Path -Parent $PSScriptRoot)).Path
$Script:Checks = @{
    Passed = 0
    Failed = 0
    Warnings = 0
    Skipped = 0
}

# ================================================================================================
# Helper Functions
# ================================================================================================

function Write-Status {
    param(
        [Parameter(Mandatory)]
        [string]$Message,
        
        [ValidateSet('Pass', 'Fail', 'Warning', 'Info', 'Skip')]
        [string]$Type = 'Info'
    )
    
    $colors = @{
        Pass = 'Green'
        Fail = 'Red'
        Warning = 'Yellow'
        Info = 'Cyan'
        Skip = 'Gray'
    }
    
    $symbols = @{
        Pass = '✓'
        Fail = '✗'
        Warning = '⚠'
        Info = 'ℹ'
        Skip = '○'
    }
    
    Write-Host "$($symbols[$Type]) " -ForegroundColor $colors[$Type] -NoNewline
    Write-Host $Message
}

function Test-SymbolicLink {
    param(
        [Parameter(Mandatory)]
        [string]$Path,
        
        [Parameter(Mandatory)]
        [string]$ExpectedTarget,
        
        [string]$Description
    )
    
    $desc = if ($Description) { $Description } else { Split-Path -Leaf $Path }
    
    if (-not (Test-Path $Path)) {
        Write-Status "$desc - Link does not exist" -Type Fail
        if ($Detailed) {
            Write-Host "    Expected: $Path" -ForegroundColor Gray
        }
        $Script:Checks.Failed++
        return $false
    }
    
    $item = Get-Item $Path -Force
    
    # Check if it's a symlink or junction
    if ($item.LinkType -notin @('SymbolicLink', 'Junction', 'HardLink')) {
        Write-Status "$desc - Not a link (regular file/directory)" -Type Warning
        if ($Detailed) {
            Write-Host "    Path: $Path" -ForegroundColor Gray
        }
        $Script:Checks.Warnings++
        return $false
    }
    
    # Resolve target
    $actualTarget = $item.Target
    if (-not $actualTarget) {
        $actualTarget = $item.LinkTarget
    }
    
    # Compare targets (normalize paths)
    $expectedNorm = [System.IO.Path]::GetFullPath($ExpectedTarget)
    $actualNorm = [System.IO.Path]::GetFullPath($actualTarget)
    
    if ($actualNorm -ne $expectedNorm) {
        Write-Status "$desc - Points to wrong target" -Type Fail
        if ($Detailed) {
            Write-Host "    Expected: $expectedNorm" -ForegroundColor Gray
            Write-Host "    Actual:   $actualNorm" -ForegroundColor Gray
        }
        $Script:Checks.Failed++
        return $false
    }
    
    Write-Status "$desc" -Type Pass
    if ($Detailed) {
        Write-Host "    Target: $actualTarget" -ForegroundColor Gray
        Write-Host "    Type:   $($item.LinkType)" -ForegroundColor Gray
    }
    $Script:Checks.Passed++
    return $true
}

function Test-Command {
    param(
        [Parameter(Mandatory)]
        [string]$Command,
        
        [string]$Description,
        
        [switch]$Optional
    )
    
    $desc = if ($Description) { $Description } else { $Command }
    
    if (Get-Command $Command -ErrorAction SilentlyContinue) {
        $version = $null
        try {
            $version = & $Command --version 2>$null | Select-Object -First 1
        } catch {
            # Some commands don't support --version
        }
        
        Write-Status "$desc" -Type Pass
        if ($Detailed -and $version) {
            Write-Host "    Version: $version" -ForegroundColor Gray
        }
        $Script:Checks.Passed++
        return $true
    }
    
    if ($Optional) {
        Write-Status "$desc - Not installed (optional)" -Type Skip
        $Script:Checks.Skipped++
    } else {
        Write-Status "$desc - Not installed" -Type Fail
        $Script:Checks.Failed++
    }
    return $false
}

function Test-FileContent {
    param(
        [Parameter(Mandatory)]
        [string]$Path,
        
        [Parameter(Mandatory)]
        [string]$Pattern,
        
        [string]$Description
    )
    
    $desc = if ($Description) { $Description } else { Split-Path -Leaf $Path }
    
    if (-not (Test-Path $Path)) {
        Write-Status "$desc - File does not exist" -Type Fail
        $Script:Checks.Failed++
        return $false
    }
    
    $content = Get-Content $Path -Raw -ErrorAction SilentlyContinue
    
    if ($content -match $Pattern) {
        Write-Status "$desc - Contains expected content" -Type Pass
        if ($Detailed) {
            Write-Host "    Pattern: $Pattern" -ForegroundColor Gray
        }
        $Script:Checks.Passed++
        return $true
    }
    
    Write-Status "$desc - Missing expected content" -Type Fail
    if ($Detailed) {
        Write-Host "    Pattern: $Pattern" -ForegroundColor Gray
        Write-Host "    File: $Path" -ForegroundColor Gray
    }
    $Script:Checks.Failed++
    return $false
}

function Test-Font {
    param(
        [Parameter(Mandatory)]
        [string]$FontName
    )
    
    $fontsPath = "$env:LOCALAPPDATA\Microsoft\Windows\Fonts"
    $systemFonts = "$env:WINDIR\Fonts"
    
    $found = (Get-ChildItem -Path $fontsPath -Filter "*$FontName*" -ErrorAction SilentlyContinue).Count -gt 0
    if (-not $found) {
        $found = (Get-ChildItem -Path $systemFonts -Filter "*$FontName*" -ErrorAction SilentlyContinue).Count -gt 0
    }
    
    if ($found) {
        Write-Status "$FontName" -Type Pass
        $Script:Checks.Passed++
        return $true
    }
    
    Write-Status "$FontName - Not installed" -Type Warning
    $Script:Checks.Warnings++
    return $false
}

# ================================================================================================
# Verification Checks
# ================================================================================================

function Test-Environment {
    Write-Host "`n=== Environment ===" -ForegroundColor Cyan
    
    # XDG directories
    $xdgDirs = @{
        'XDG_CONFIG_HOME' = "$env:USERPROFILE\.config"
        'XDG_DATA_HOME' = "$env:USERPROFILE\.local\share"
        'XDG_STATE_HOME' = "$env:USERPROFILE\.local\state"
        'XDG_CACHE_HOME' = "$env:USERPROFILE\.cache"
    }
    
    foreach ($var in $xdgDirs.GetEnumerator()) {
        $envValue = [System.Environment]::GetEnvironmentVariable($var.Key, 'User')
        
        if ($envValue -eq $var.Value) {
            Write-Status "$($var.Key)" -Type Pass
            if ($Detailed) {
                Write-Host "    Value: $envValue" -ForegroundColor Gray
            }
            $Script:Checks.Passed++
        } else {
            Write-Status "$($var.Key) - Not set or incorrect" -Type Fail
            if ($Detailed) {
                Write-Host "    Expected: $($var.Value)" -ForegroundColor Gray
                Write-Host "    Actual:   $envValue" -ForegroundColor Gray
            }
            $Script:Checks.Failed++
        }
        
        # Check directory exists
        if (Test-Path $var.Value) {
            Write-Status "  Directory exists: $($var.Value -replace [regex]::Escape($env:USERPROFILE), '~')" -Type Pass
            $Script:Checks.Passed++
        } else {
            Write-Status "  Directory missing: $($var.Value -replace [regex]::Escape($env:USERPROFILE), '~')" -Type Fail
            $Script:Checks.Failed++
        }
    }
    
    # Check bin in PATH
    $userPath = [System.Environment]::GetEnvironmentVariable('Path', 'User')
    $binPath = "$env:USERPROFILE\bin"
    
    if ($userPath -like "*$binPath*") {
        Write-Status "~/bin in PATH" -Type Pass
        $Script:Checks.Passed++
    } else {
        Write-Status "~/bin not in PATH" -Type Warning
        $Script:Checks.Warnings++
    }
    
    # Developer Mode
    try {
        $key = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock'
        $value = Get-ItemProperty -Path $key -Name AllowDevelopmentWithoutDevLicense -ErrorAction SilentlyContinue
        
        if ($value.AllowDevelopmentWithoutDevLicense -eq 1) {
            Write-Status "Developer Mode enabled" -Type Pass
            $Script:Checks.Passed++
        } else {
            Write-Status "Developer Mode disabled (symlinks may require admin)" -Type Warning
            $Script:Checks.Warnings++
        }
    } catch {
        Write-Status "Developer Mode status unknown" -Type Warning
        $Script:Checks.Warnings++
    }
}

function Test-PackageManagers {
    Write-Host "`n=== Package Managers ===" -ForegroundColor Cyan
    
    Test-Command 'winget' 'Windows Package Manager (winget)' -Optional
    Test-Command 'scoop' 'Scoop' -Optional
    Test-Command 'choco' 'Chocolatey' -Optional
}

function Test-CoreTools {
    Write-Host "`n=== Core Tools ===" -ForegroundColor Cyan
    
    Test-Command 'git' 'Git'
    Test-Command 'pwsh' 'PowerShell Core' -Optional
    Test-Command 'nvim' 'Neovim' -Optional
    Test-Command 'starship' 'Starship Prompt' -Optional
}

function Test-OptionalTools {
    Write-Host "`n=== Optional Tools ===" -ForegroundColor Cyan
    
    Test-Command 'rg' 'ripgrep' -Optional
    Test-Command 'fd' 'fd' -Optional
    Test-Command 'fzf' 'fzf' -Optional
    Test-Command 'bat' 'bat' -Optional
    Test-Command 'eza' 'eza' -Optional
    Test-Command 'delta' 'delta' -Optional
    Test-Command 'node' 'Node.js' -Optional
    Test-Command 'npm' 'npm' -Optional
}

function Test-ConfigLinks {
    Write-Host "`n=== Configuration Links ===" -ForegroundColor Cyan
    
    # Git config
    $gitConfig = "$env:USERPROFILE\.config\git"
    if (Test-Path "$Script:DotfilesRoot\git\dot-config\git\config") {
        Test-SymbolicLink -Path "$gitConfig\config" `
                          -ExpectedTarget "$Script:DotfilesRoot\git\dot-config\git\config" `
                          -Description "Git config"
    }
    
    if (Test-Path "$Script:DotfilesRoot\windows\dot-config\git\windows.gitconfig") {
        Test-SymbolicLink -Path "$gitConfig\windows.gitconfig" `
                          -ExpectedTarget "$Script:DotfilesRoot\windows\dot-config\git\windows.gitconfig" `
                          -Description "Git Windows config"
    }
    
    # Neovim - check files inside directory
    if (Test-Path "$Script:DotfilesRoot\nvim\dot-config\nvim\init.lua") {
        Test-SymbolicLink -Path "$env:USERPROFILE\.config\nvim\init.lua" `
                          -ExpectedTarget "$Script:DotfilesRoot\nvim\dot-config\nvim\init.lua" `
                          -Description "Neovim init.lua"
    }
    
    # Starship
    if (Test-Path "$Script:DotfilesRoot\starship\dot-config\starship.toml") {
        Test-SymbolicLink -Path "$env:USERPROFILE\.config\starship.toml" `
                          -ExpectedTarget "$Script:DotfilesRoot\starship\dot-config\starship.toml" `
                          -Description "Starship config"
    }
    
    # WezTerm - check files inside directory
    if (Test-Path "$Script:DotfilesRoot\wezterm\dot-config\wezterm\wezterm.lua") {
        Test-SymbolicLink -Path "$env:USERPROFILE\.config\wezterm\wezterm.lua" `
                          -ExpectedTarget "$Script:DotfilesRoot\wezterm\dot-config\wezterm\wezterm.lua" `
                          -Description "WezTerm wezterm.lua"
    }
    
    # Bat - check files inside directory
    if (Test-Path "$Script:DotfilesRoot\bat\dot-config\bat\config") {
        Test-SymbolicLink -Path "$env:USERPROFILE\.config\bat\config" `
                          -ExpectedTarget "$Script:DotfilesRoot\bat\dot-config\bat\config" `
                          -Description "Bat config"
    }
    
    # PowerShell profile
    if (Test-Path "$Script:DotfilesRoot\windows\powershell\Microsoft.PowerShell_profile.ps1") {
        $pwshProfile = "$env:USERPROFILE\Documents\PowerShell\Microsoft.PowerShell_profile.ps1"
        Test-SymbolicLink -Path $pwshProfile `
                          -ExpectedTarget "$Script:DotfilesRoot\windows\powershell\Microsoft.PowerShell_profile.ps1" `
                          -Description "PowerShell profile"
    }
    
    # Windows Terminal
    $wtSettings = "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"
    if (Test-Path (Split-Path $wtSettings)) {
        if (Test-Path "$Script:DotfilesRoot\windows\windows-terminal\settings.json") {
            Test-SymbolicLink -Path $wtSettings `
                              -ExpectedTarget "$Script:DotfilesRoot\windows\windows-terminal\settings.json" `
                              -Description "Windows Terminal settings"
        }
    } else {
        Write-Status "Windows Terminal - Not installed" -Type Skip
        $Script:Checks.Skipped++
    }
}

function Test-ConfigContent {
    Write-Host "`n=== Configuration Content ===" -ForegroundColor Cyan
    
    # Check if git is available
    if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
        Write-Status "Git not installed - skipping config checks" -Type Skip
        $Script:Checks.Skipped++
        return
    }
    
    # Verify windows.gitconfig is loaded
    $gitConfigList = git config --list --show-origin 2>$null
    $windowsConfigPath = "$env:USERPROFILE\.config\git\windows.gitconfig" -replace '\\', '/'
    
    if ($gitConfigList -match [regex]::Escape($windowsConfigPath)) {
        Write-Status "Git loads windows.gitconfig" -Type Pass
        if ($Detailed) {
            $matchedLine = $gitConfigList | Where-Object { $_ -match [regex]::Escape($windowsConfigPath) } | Select-Object -First 1
            Write-Host "    Found: $matchedLine" -ForegroundColor Gray
        }
        $Script:Checks.Passed++
    } else {
        Write-Status "Git windows.gitconfig not loaded" -Type Warning
        if ($Detailed) {
            Write-Host "    Expected path: $windowsConfigPath" -ForegroundColor Gray
        }
        $Script:Checks.Warnings++
    }
    
    # Check Windows-specific git settings
    $windowsSettings = @{
        'core.autocrlf' = 'Auto CRLF handling'
        'core.symlinks' = 'Symlink support'
        'core.longpaths' = 'Long path support'
    }
    
    foreach ($setting in $windowsSettings.GetEnumerator()) {
        $value = git config --get $setting.Key 2>$null
        
        if ($value) {
            Write-Status "$($setting.Value) ($($setting.Key) = $value)" -Type Pass
            $Script:Checks.Passed++
        } else {
            Write-Status "$($setting.Value) ($($setting.Key)) - Not set" -Type Warning
            $Script:Checks.Warnings++
        }
    }
    
    # PowerShell profile should load Starship
    $pwshProfile = "$env:USERPROFILE\Documents\PowerShell\Microsoft.PowerShell_profile.ps1"
    if (Test-Path $pwshProfile) {
        Test-FileContent -Path $pwshProfile `
                         -Pattern 'starship' `
                         -Description "PowerShell profile loads Starship"
    }
}

function Test-VSCode {
    Write-Host "`n=== VS Code ===" -ForegroundColor Cyan
    
    if (-not (Get-Command code -ErrorAction SilentlyContinue)) {
        Write-Status "VS Code - Not installed" -Type Skip
        $Script:Checks.Skipped++
        return
    }
    
    Write-Status "VS Code" -Type Pass
    $Script:Checks.Passed++
    
    # Settings
    $vscodeSettings = "$env:APPDATA\Code\User\settings.json"
    if (Test-Path "$Script:DotfilesRoot\windows\vscode\settings.json") {
        Test-SymbolicLink -Path $vscodeSettings `
                          -ExpectedTarget "$Script:DotfilesRoot\windows\vscode\settings.json" `
                          -Description "  Settings"
    }
    
    # Keybindings
    $vscodeKeybindings = "$env:APPDATA\Code\User\keybindings.json"
    if (Test-Path "$Script:DotfilesRoot\windows\vscode\keybindings.json") {
        Test-SymbolicLink -Path $vscodeKeybindings `
                          -ExpectedTarget "$Script:DotfilesRoot\windows\vscode\keybindings.json" `
                          -Description "  Keybindings"
    }
    
    # Extensions
    $extensionsFile = "$Script:DotfilesRoot\windows\vscode\extensions.txt"
    if (Test-Path $extensionsFile) {
        Write-Host "`n  Checking extensions..." -ForegroundColor Gray
        $expectedExtensions = Get-Content $extensionsFile
        $installedExtensions = code --list-extensions
        
        $missing = $expectedExtensions | Where-Object { $_ -notin $installedExtensions }
        
        if ($missing.Count -eq 0) {
            Write-Status "  All extensions installed ($($expectedExtensions.Count))" -Type Pass
            $Script:Checks.Passed++
        } else {
            Write-Status "  Missing $($missing.Count) extension(s)" -Type Warning
            if ($Detailed) {
                foreach ($ext in $missing) {
                    Write-Host "    - $ext" -ForegroundColor Gray
                }
            }
            $Script:Checks.Warnings++
        }
    }
}

function Test-Fonts {
    Write-Host "`n=== Fonts ===" -ForegroundColor Cyan
    
    $commonNerdFonts = @(
        'FiraCode',
        'CascadiaCode',
        'JetBrainsMono',
        'Meslo',
        'SourceCodePro',
        'Hack'
    )
    
    foreach ($font in $commonNerdFonts) {
        Test-Font -FontName $font
    }
}

# ================================================================================================
# Main Execution
# ================================================================================================

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host " Dotfiles Verification" -ForegroundColor White
Write-Host "========================================`n" -ForegroundColor Cyan

Write-Host "Dotfiles: $Script:DotfilesRoot" -ForegroundColor Gray
Write-Host ""

# Run all checks
Test-Environment
Test-PackageManagers
Test-CoreTools
Test-OptionalTools
Test-ConfigLinks
Test-ConfigContent

if ($IncludeVSCode) {
    Test-VSCode
}

Test-Fonts

# Summary
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host " Summary" -ForegroundColor White
Write-Host "========================================`n" -ForegroundColor Cyan

$total = $Script:Checks.Passed + $Script:Checks.Failed + $Script:Checks.Warnings + $Script:Checks.Skipped

Write-Host "Passed:   " -NoNewline
Write-Host $Script:Checks.Passed -ForegroundColor Green
Write-Host "Failed:   " -NoNewline
Write-Host $Script:Checks.Failed -ForegroundColor Red
Write-Host "Warnings: " -NoNewline
Write-Host $Script:Checks.Warnings -ForegroundColor Yellow
Write-Host "Skipped:  " -NoNewline
Write-Host $Script:Checks.Skipped -ForegroundColor Gray
Write-Host "Total:    $total`n"

if ($Script:Checks.Failed -gt 0) {
    Write-Host "Some checks failed. Review the output above." -ForegroundColor Red
    Write-Host "Run with -Detailed for more information.`n" -ForegroundColor Yellow
    exit 1
} elseif ($Script:Checks.Warnings -gt 0) {
    Write-Host "All critical checks passed, but there are warnings." -ForegroundColor Yellow
    Write-Host "Run with -Detailed for more information.`n" -ForegroundColor Yellow
    exit 0
} else {
    Write-Host "All checks passed! Your dotfiles are properly configured." -ForegroundColor Green
    exit 0
}
