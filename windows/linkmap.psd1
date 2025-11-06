# Windows Link Map
# Defines mappings from dotfiles repo to Windows target paths
# Bootstrap will create symlinks/junctions based on this map

@{
    # Cross-platform configs (using XDG paths on Windows)
    Links = @(
        # Git configuration
        @{
            Source = "git\dot-config\git"
            Target = "$env:USERPROFILE\.config\git"
            Type = "Directory"
        }
        @{
            Source = "windows\git\windows.gitconfig"
            Target = "$env:USERPROFILE\.config\git\windows.gitconfig"
            Type = "File"
        }

        # Neovim
        @{
            Source = "nvim\dot-config\nvim"
            Target = "$env:USERPROFILE\.config\nvim"
            Type = "Directory"
        }

        # WezTerm
        @{
            Source = "wezterm\dot-config\wezterm"
            Target = "$env:USERPROFILE\.config\wezterm"
            Type = "Directory"
        }

        # Starship
        @{
            Source = "starship\dot-config\starship"
            Target = "$env:USERPROFILE\.config\starship"
            Type = "Directory"
        }

        # Bat
        @{
            Source = "bat\dot-config\bat"
            Target = "$env:USERPROFILE\.config\bat"
            Type = "Directory"
        }

        # PowerShell Completions (eza)
        @{
            Source = "eza\dot-config\powershell\Completions"
            Target = "$env:USERPROFILE\.config\powershell\Completions"
            Type = "Directory"
        }

        # Utilities - Cache cleaner script
        @{
            Source = "utilities\dot-local\UtilCacheClean.ps1"
            Target = "$env:USERPROFILE\bin\UtilCacheClean.ps1"
            Type = "File"
        }

        # PowerShell profiles (pwsh 7+)
        @{
            Source = "windows\powershell\Microsoft.PowerShell_profile.ps1"
            Target = "$env:USERPROFILE\Documents\PowerShell\Microsoft.PowerShell_profile.ps1"
            Type = "File"
        }


        # Windows Terminal settings
        @{
            Source = "windows\windows-terminal\settings.json"
            Target = "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"
            Type = "File"
            Optional = $true  # Windows Terminal may not be installed
        }

        # VS Code settings (only if -IncludeVSCode is specified)
        @{
            Source = "windows\vscode\settings.json"
            Target = "$env:APPDATA\Code\User\settings.json"
            Type = "File"
            Conditional = "VSCode"
        }

        @{
            Source = "windows\vscode\keybindings.json"
            Target = "$env:APPDATA\Code\User\keybindings.json"
            Type = "File"
            Conditional = "VSCode"
        }
    )

    # Legacy shims (optional compatibility links)
    LegacyShims = @(
        @{
            Source = "git\dot-config\git\config"
            Target = "$env:USERPROFILE\.gitconfig"
            Type = "File"
        }
        @{
            Source = "wezterm\dot-config\wezterm\wezterm.lua"
            Target = "$env:USERPROFILE\.wezterm.lua"
            Type = "File"
        }
    )
}
