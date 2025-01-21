# Define the environment cache file for the SSH agent
zstyle -s ':ssh-agent' env-cache ssh_env_cache || ssh_env_cache="${SSH_CACHE_DIR:-$HOME/.cache/ssh}/environment-${SHORT_HOST:-default}"

# Start the SSH agent
function _start_agent() {
  # Ensure the cache directory exists
  local ssh_env_dir="${ssh_env_cache:h}" # Extract directory from file path
  [[ -d "$ssh_env_dir" ]] || mkdir -p "$ssh_env_dir" || {
    echo "Error: Could not create directory $ssh_env_dir" >&2
    return 1
  }

  if [[ -f "$ssh_env_cache" ]]; then
    . "$ssh_env_cache" > /dev/null

    # Check if $SSH_AUTH_SOCK is valid
    zmodload zsh/net/socket
    if [[ -S "$SSH_AUTH_SOCK" ]] && zsocket "$SSH_AUTH_SOCK" 2>/dev/null; then
      return 0
    fi
  fi

  if [[ ! -d "$HOME/.ssh" ]]; then
    echo "Error: ~/.ssh directory is missing" >&2
    return 1
  fi

  # Set agent lifetime using zstyle
  local lifetime
  zstyle -s ':ssh-agent' lifetime lifetime || lifetime="5h"

  echo "Starting ssh-agent..."
  ssh-agent -s -t "$lifetime" | sed '/^echo/d' >! "$ssh_env_cache"
  chmod 600 "$ssh_env_cache"
  . "$ssh_env_cache" > /dev/null
}

# Add SSH identities
function _add_identities() {
  local id file sig
  local -a identities not_loaded

  if [[ ! -d "$HOME/.ssh" ]]; then
    return
  fi

  # Use zstyle to define identities, fallback to common defaults
  zstyle -a ':ssh-agent' identities identities || identities=(id_rsa id_dsa id_ecdsa id_ed25519 id_ed25519_sk identity)
  echo "Identities to load: $identities"


  # Check which identities are already loaded
  for id in $identities; do
    file="${id}"
    [[ "$id" != /* ]] && file="$HOME/.ssh/$id"

    if [[ -f "$file" ]]; then
      sig="$(ssh-keygen -lf "$file" | awk '{print $2}')"
      ssh-add -L | grep -q "$sig" || not_loaded+=("$file")
    fi
  done

  if [[ ${#not_loaded} -eq 0 ]]; then
    echo "All identities are already loaded"
    return
  fi

  echo "Not loaded IDs: $not_loaded"
  # Add missing identities
  ssh-add "${not_loaded[@]}"
}

# Create symlink for SSH_AUTH_SOCK
function _setup_agent_symlink() {
  if [[ -n "$SSH_AUTH_SOCK" ]]; then
    local link="/tmp/ssh-agent-${USER}-screen"
    ln -sf "$SSH_AUTH_SOCK" "$link"
    echo "Agent socket linked to $link"
  fi
}

# Main logic
_start_agent
_add_identities
_setup_agent_symlink
