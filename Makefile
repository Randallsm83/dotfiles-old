# Define paths
HOMEBREW_PREFIX := $(HOME)/.local/share/homebrew
PERLBREW_ROOT := $(HOME)/.local/share/perlbrew
DOTFILES_DIR := $(HOME)/.dotfiles
PATH := $(HOMEBREW_PREFIX)/bin:$(PERLBREW_ROOT)/bin:$(PATH)

# Default target to install everything
all: install_homebrew install_perlbrew install_perl setup_local_lib install_modules install_stow stow_dotfiles

# Step 1: Install Homebrew
install_homebrew:
	@echo "Installing Homebrew locally..."
	git clone https://github.com/Homebrew/brew $(HOMEBREW_PREFIX)
	@echo "Setting up Homebrew environment variables..."
	eval "$$($(HOMEBREW_PREFIX)/bin/brew shellenv)"

# Step 2: Install Perlbrew
install_perlbrew:
	@echo "Installing Perlbrew locally to $(PERLBREW_ROOT)..."
	curl -L https://install.perlbrew.pl | bash
	export PERLBREW_ROOT=$(PERLBREW_ROOT)
	export PATH=$(PERLBREW_ROOT)/bin:$(PATH)
	source $(PERLBREW_ROOT)/etc/bashrc

# Step 4: Install the latest Perl
install_perl:
	@echo "Installing the latest Perl with Perlbrew..."
	perlbrew install perl --notest  # installs the latest stable Perl without testing
	perlbrew install-cpanm
	perlbrew switch perl  # switch to the latest installed Perl
	source $(PERLBREW_ROOT)/etc/bashrc

# Step 5: Set up `local::lib`
setup_local_lib:
	@echo "Configuring local::lib with Perlbrew..."
	perlbrew lib create perl@local  # creates a lib named "local"
	perlbrew switch perl-@local

# Step 6: Install required Perl modules (Test::More and Test::Output)
install_modules:
	@echo "Installing Test::More and Test::Output..."
	cpanm Test::More Test::Output

# Step 7: Install GNU Stow
install_stow:
	@echo "Installing GNU Stow with Homebrew..."
	brew install stow

# Step 8: Stow dotfiles
stow_dotfiles:
	@echo "Stowing dotfiles..."
	cd $(DOTFILES_DIR) && for dir in ./*; do \
	  if [ -d "$$dir" ]; then \
	    stow --no-folding --dotfiles --verbose=2 -R -t $(HOME) -- "$$dir"; \
	  fi; \
	done

# Uninstall target
uninstall_all:
	@echo "Removing Homebrew && Perlbrew..."
	rm -rf $(HOMEBREW_PREFIX)
	rm -rf $(PERLBREW_ROOT)

uninstall_homebrew:
	@echo "Removing Homebrew..."
	rm -rf $(HOMEBREW_PREFIX)

uninstall_perlbrew:
	@echo "Removing Perlbrew..."
	rm -rf $(PERLBREW_ROOT)

# Clean target to remove temporary and cache files
clean:
	@echo "Cleaning up Homebrew && Perlbrew caches..."
	rm -rf $(HOMEBREW_CACHE)
	rm -rf $(XDG_CACHE_HOME)/perlbrew
