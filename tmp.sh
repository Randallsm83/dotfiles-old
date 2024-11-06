# Define variables
LOCAL_DIR="$HOME/.local"
LOCAL_BIN="$HOME/.local/bin"
LOCAL_LIB="$HOME/.local/lib"
LOCAL_INCLUDE="$HOME/.local/include"

# Create necessary directories
mkdir -p "$LOCAL_BIN" "$LOCAL_LIB" "$LOCAL_INCLUDE"

# Function to get the latest pkg-config URL
get_custom_url() {
  local package=$1
  local base_url=$2

  local version
  version=$(curl -s "$base_url" | grep -oP "$package-[0-9.]+\.tar\.gz" | sort -V | tail -n1)

  echo "${base_url}${version}"
}

# Function to get the latest URL for GNU packages
get_gnu_url() {
  local package=$1
  local base_url="https://ftp.gnu.org/gnu/$package"

  # Fetch the latest version
  local version
  version=$(curl -s "$base_url/" | grep -oP "$package-[0-9.]+\.tar\.gz" | sort -V | tail -n1)

  # Check if version fetch was successful
  if [ -z "$version" ]; then
    echo "Failed to fetch latest version for $package" >&2
    return 1
  fi

  echo "$base_url/$version"
}

# Function to get the latest version and URL
get_git_url() {
  local repo=$1
  local base_url=$2

  # Fetch the latest version
  local version
  version=$(curl --silent "https://api.github.com/repos/$repo/releases/latest" |
    grep '"tag_name":' |
    sed -E 's/.*"([^"]+)".*/\1/' |
    sed 's/^v//')

  # Check if version fetch was successful
  if [ -z "$version" ]; then
    echo "Failed to fetch latest version for $repo" >&2
    return 1
  fi

  # Construct and output the URL
  local url
  url="${base_url/VERSION/$version}"
  echo "$url"
}

install_linux() {
  local package=$1
  local url=$2
  local temp_dir

  echo
  echo "============================="
  echo "Installing $package from $url"
  echo "============================="
  echo

  # Create a temporary directory
  temp_dir=$(mktemp -d)
  if [[ ! "$temp_dir" || ! -d "$temp_dir" ]]; then
    echo "Failed to create temporary directory" >&2
    return 1
  fi

  # Navigate to the temporary directory
  cd "$temp_dir" || {
    echo "Failed to change to temporary directory" >&2
    return 1
  }

  # Download the package
  if ! wget "$url"; then
    echo "Failed to download $package" >&2
    return 1
  fi

  # Extract the package
  if ! tar xf ./*.tar*; then
    echo "Failed to extract $package" >&2
    return 1
  fi

  # Find and enter the extracted directory
  local extracted_dir
  extracted_dir=$(find . -maxdepth 1 -type d | tail -n 1)
  cd "$extracted_dir" || {
    echo "Failed to change to extracted directory" >&2
    return 1
  }

  # Run autogen.sh if it exists
  if [[ -f "./autogen.sh" ]]; then
    echo "Running autogen.sh for $package"
    if ! ./autogen.sh; then
      echo "autogen.sh failed for $package" >&2
      return 1
    fi
  fi

  # Configure, make and install
  if [[ -f "./configure" ]]; then
    if ! ./configure --prefix="$LOCAL_DIR" PKG_CONFIG_PATH="$LOCAL_LIB/pkgconfig"; then
      echo "Configuration failed for $package" >&2
      return 1
    fi
  else
    echo "No configure script found for $package" >&2
    return 1
  fi

  # Make
  if ! make -j"$(nproc)"; then
    echo "Make failed for $package" >&2
    return 1
  fi

  # Make Install
  if ! make install; then
    echo "Installation failed for $package" >&2
    return 1
  fi

  echo "$package installed successfully"
}

gnutools=(
  "m4"
  "autoconf"
  "automake"
)

# Install gnutools
for tool in "${gnutools[@]}"; do
  if url=$(get_gnu_url "$tool"); then
    install_linux "$tool" "$url"
  else
    echo "Failed to get URL for $tool. Skipping installation." >&2
  fi
done

# Install pkg-config
if url=$(get_custom_url "pkg-config" "https://pkg-config.freedesktop.org/releases/"); then
  install_linux "pkg-config" "$url"
fi

# Install ctags
if url=$(get_git_url "universal-ctags/ctags" "https://github.com/universal-ctags/ctags/archive/refs/tags/vVERSION.tar.gz"); then
  install_linux "ctags" "$url"
fi

# read -r diffutils_version diffutils_url <<< $(get_latest_url "gnu/diffutils" "https://ftp.gnu.org/gnu/diffutils/diffutils-VERSION.tar.xz")
# install_linux "diffutils" "$diffutils_version" "$diffutils_url"
#
# read -r findutils_version findutils_url <<< $(get_latest_url "gnu/findutils" "https://ftp.gnu.org/gnu/findutils/findutils-VERSION.tar.xz")
# install_linux "findutils" "$findutils_version" "$findutils_url"
#
# read -r gettext_version gettext_url <<< $(get_latest_url "gnu/gettext" "https://ftp.gnu.org/gnu/gettext/gettext-VERSION.tar.xz")
# install_linux "gettext" "$gettext_version" "$gettext_url"
#
# read -r gmp_version gmp_url <<< $(get_latest_url "gmp-ecm/gmp" "https://gmplib.org/download/gmp/gmp-VERSION.tar.xz")
# install_linux "gmp" "$gmp_version" "$gmp_url"
#
# read -r make_version make_url <<< $(get_latest_url "gnu/make" "https://ftp.gnu.org/gnu/make/make-VERSION.tar.gz")
# install_linux "make" "$make_version" "$make_url"
#
# read -r coreutils_version coreutils_url <<< $(get_latest_url "coreutils/coreutils" "https://ftp.gnu.org/gnu/coreutils/coreutils-VERSION.tar.xz")
# install_linux "coreutils" "$coreutils_version" "$coreutils_url"
#
# read -r sed_version sed_url <<< $(get_latest_url "mirror/sed" "https://ftp.gnu.org/gnu/sed/sed-VERSION.tar.xz")
# install_linux "sed" "$sed_version" "$sed_url"
#
# read -r grep_version grep_url <<< $(get_latest_url "git/grep" "https://ftp.gnu.org/gnu/grep/grep-VERSION.tar.xz")
# install_linux "grep" "$grep_version" "$grep_url"
