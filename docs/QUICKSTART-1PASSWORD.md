# 1Password SSH Quick Start Guide

## TL;DR

1Password SSH agent = No more key files, biometric auth for all SSH connections

## Setup (5 minutes)

### Step 1: Enable 1Password SSH Agent

1. Open **1Password** desktop app
2. Go to **Settings** → **Developer**
3. Enable **"Use the SSH agent"**
4. Done!

### Step 2: Add SSH Keys to 1Password

**Option A: Generate New Key in 1Password**
1. In 1Password, click **"+"** → **SSH Key**
2. Click **"Generate a New Key"**
3. Name it (e.g., "GitHub Personal", "Work Servers")
4. Copy the public key
5. Add to your servers/GitHub/GitLab/etc.

**Option B: Import Existing Key**
1. In 1Password, click **"+"** → **SSH Key**
2. Click **"Import"**
3. Select your private key file (e.g., `~/.ssh/id_rsa`)
4. Done!

### Step 3: Configure Windows

**Add to your PowerShell profile (`$PROFILE`):**

```powershell
# 1Password SSH Agent
$env:SSH_AUTH_SOCK = "$env:USERPROFILE\.1password\agent.sock"
```

Reload:
```powershell
. $PROFILE
```

### Step 4: Configure WSL (if using)

**Run the setup script:**

```bash
# From WSL
cd /mnt/c/Users/Randall/.config/dotfiles/warp/dot-config/warp/launch_configurations
bash setup-1password-wsl.sh
```

Or manually create wrappers:

```bash
mkdir -p ~/.local/bin

cat > ~/.local/bin/ssh << 'EOF'
#!/bin/bash
/mnt/c/Windows/System32/OpenSSH/ssh.exe "$@"
EOF

chmod +x ~/.local/bin/ssh

# Add to ~/.zshrc
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc
```

### Step 5: Test It

**Windows (PowerShell):**
```powershell
# Should list 1Password SSH keys
ssh-add -l

# Test GitHub
ssh -T git@github.com
```

**WSL:**
```bash
# Should list 1Password SSH keys
ssh-add -l

# Test GitHub
ssh -T git@github.com
```

## Usage

### Simple SSH Connection

Just use `ssh` normally - 1Password handles everything:

```bash
ssh user@hostname
```

1Password will:
1. Pop up biometric prompt
2. Select the right key
3. Connect you

### Recommended: Use SSH Config

Create `C:\Users\Randall\.ssh\config`:

```ssh-config
Host *
    IdentityAgent ~/.1password/agent.sock
    ServerAliveInterval 60

Host dev
    HostName dev.example.com
    User rmiller

Host prod
    HostName prod.example.com
    User rmiller
```

Then just:
```bash
ssh dev
ssh prod
```

Works in both PowerShell and WSL!

### Warp Launch Configuration

```yaml
---
name: Servers
windows:
  - tabs:
      - title: Development
        layout:
          commands:
            - exec: ssh dev
        color: green
      
      - title: Production
        layout:
          commands:
            - exec: ssh prod
        color: red
```

No key files, no `-i` flags needed!

## Advantages Over Traditional SSH Keys

| Traditional | 1Password |
|-------------|-----------|
| Keys in `~/.ssh/` | Keys in 1Password vault |
| Same key unlocked all day | Biometric auth per connection |
| Manual key rotation | Easy rotation from one place |
| Risk if laptop stolen | Keys never on disk |
| Different keys per machine | Same keys everywhere |
| Hard to share with team | Easy sharing (Business) |

## Common Issues

### "Permission denied (publickey)"

**Checklist:**
1. ✅ 1Password SSH agent enabled?
2. ✅ Key added to 1Password?
3. ✅ Public key on server?
4. ✅ `ssh-add -l` shows your keys?

### WSL not using Windows SSH

```bash
# Check which SSH
which ssh

# Should be: /home/you/.local/bin/ssh
# If not, check PATH order in ~/.zshrc
```

### Git not working

```bash
# Test SSH to Git host
ssh -T git@github.com

# If that works, check git remote
git remote -v

# Should use SSH URLs (git@github.com:user/repo.git)
# Not HTTPS (https://github.com/user/repo.git)
```

## Next Steps

1. ✅ **Move all SSH keys to 1Password**
   - Safer than files on disk
   - Accessible from all devices

2. ✅ **Set up SSH config file**
   - Shorter commands
   - Centralized management
   - See `README-1PASSWORD-SSH.md`

3. ✅ **Update Warp launch configs**
   - Simple `ssh hostname` commands
   - No more `-i` flags
   - See `ssh-connections.yaml`

4. ✅ **Enable Git commit signing** (optional)
   ```bash
   git config --global gpg.format ssh
   git config --global user.signingkey "ssh-ed25519 AAAA..."
   git config --global commit.gpgsign true
   ```

## Full Documentation

- **`README-1PASSWORD-SSH.md`** - Complete guide with advanced features
- **`README-SSH.md`** - General SSH configuration guide
- **`setup-1password-wsl.sh`** - Automated WSL setup script

## Resources

- [1Password SSH Documentation](https://developer.1password.com/docs/ssh/)
- [1Password SSH + WSL](https://developer.1password.com/docs/ssh/agent/advanced/#use-the-windows-ssh-agent-in-wsl)
