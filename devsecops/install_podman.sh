#!/bin/bash

# Universal Podman Installer Script
# Supports macOS, Ubuntu/Debian, and Windows (via WSL/Git Bash)

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to detect OS
detect_os() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        echo "macos"
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        if [ -f /etc/debian_version ]; then
            echo "ubuntu"
        elif [ -f /etc/redhat-release ]; then
            echo "rhel"
        else
            echo "linux"
        fi
    elif [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "cygwin" ]] || [[ -n "$WSL_DISTRO_NAME" ]]; then
        echo "windows"
    else
        echo "unknown"
    fi
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

fix_storage_conflicts() {
    log_info "Checking for storage driver conflicts..."

    if podman info 2>&1 | grep -q "User-selected graph driver.*overwritten by graph driver"; then
        log_error "Detected storage driver conflict (VFS vs Overlay)!"
        log_warning "This requires a complete storage reset to fix."

        read -p "Perform complete Podman storage reset? This will remove all Podman containers/images (Y/n): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Nn]$ ]]; then
            log_info "Performing nuclear storage reset..."

            safe_kill_podman
            podman system reset --force 2>/dev/null || true
            rm -rf ~/.local/share/containers/* 2>/dev/null || true
            rm -rf ~/.config/containers/* 2>/dev/null || true
            rm -rf /run/user/$(id -u)/containers 2>/dev/null || true
            sudo rm -rf /var/lib/containers/* 2>/dev/null || true
            rm -rf /tmp/podman-* ~/.cache/containers 2>/dev/null || true

            log_success "Complete storage reset performed"
            return 0
        else
            log_error "Cannot continue with storage conflicts. Please fix manually."
            return 1
        fi
    fi
    return 0
}

check_existing_runtimes() {
    if command_exists docker; then
        log_info "Docker installation detected"
        docker ps >/dev/null 2>&1 && log_info "Docker is running with $(docker ps -q | wc -l) containers"
    fi

    if command_exists podman; then
        log_warning "Existing Podman installation detected"
        if podman info >/dev/null 2>&1; then
            local storage_driver=$(podman info --format '{{.Store.GraphDriverName}}')
            log_info "Current Podman storage driver: $storage_driver"

            if [ -d ~/.local/share/containers/storage ]; then
                log_warning "Detected existing Podman storage that may cause driver conflicts"
                read -p "Completely reset Podman storage to avoid conflicts? (Y/n): " -n 1 -r
                echo
                if [[ ! $REPLY =~ ^[Nn]$ ]]; then
                    safe_kill_podman
                    podman system reset --force 2>/dev/null || true
                    rm -rf ~/.local/share/containers/* ~/.config/containers/* /run/user/$(id -u)/containers 2>/dev/null || true
                    sudo rm -rf /var/lib/containers/* 2>/dev/null || true
                    log_success "Complete Podman storage reset completed"
                fi
            fi
        fi
    fi
}

# Function to safely kill Podman processes
safe_kill_podman() {
    log_info "Finding Podman-related processes (excluding this script)..."
    while read -r pid cmd; do
        if [[ "$cmd" =~ podman ]] && [[ "$cmd" != *"$0"* ]] && [[ "$cmd" != *tee* ]]; then
            log_info "Killing: $pid $cmd"
            sudo kill -9 "$pid" 2>/dev/null || true
        fi
    done < <(pgrep -af podman)
}

# Function to install Podman on macOS
install_podman_macos() {
    log_info "Installing Podman on macOS..."

    if ! command_exists brew; then
        log_info "Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        eval "$($(command -v brew) shellenv)"
    fi

    brew install podman
    podman machine init
    podman machine start
    log_success "Podman installed successfully on macOS!"
}

configure_rootless() {
    log_info "Configuring rootless Podman support..."

    # Create necessary directories with correct permissions
    sudo mkdir -p /run/user/$(id -u)/containers
    sudo chown $(id -u):$(id -g) /run/user/$(id -u)/containers
    sudo chmod 700 /run/user/$(id -u)/containers

    # Create and configure user directories
    mkdir -p ~/.local/share/containers/storage
    mkdir -p ~/.config/containers

    if ! grep -q "^$(whoami):" /etc/subuid 2>/dev/null; then
        echo "$(whoami):100000:65536" | sudo tee -a /etc/subuid >/dev/null
        log_info "Added subuid mapping for $(whoami)"
    fi

    if ! grep -q "^$(whoami):" /etc/subgid 2>/dev/null; then
        echo "$(whoami):100000:65536" | sudo tee -a /etc/subgid >/dev/null
        log_info "Added subgid mapping for $(whoami)"
    fi

    # Install dbus-launch if not present
    if ! command_exists dbus-launch; then
        log_info "Installing dbus-launch..."
        if command_exists apt-get; then
            sudo apt-get install -y dbus-user-session
        elif command_exists dnf; then
            sudo dnf install -y dbus-user-session
        fi
    fi

    if [ ! -f ~/.config/containers/containers.conf ]; then
        cat > ~/.config/containers/containers.conf << 'EOF'
[containers]
rootless = true

[engine]
cgroup_manager = "cgroupfs"
events_logger = "file"
runtime = "crun"

[network]
network_backend = "netavark"
EOF
        log_info "Created containers.conf for rootless configuration"
    fi

    if [ ! -f ~/.config/containers/storage.conf ]; then
        cat > ~/.config/containers/storage.conf << EOF
[storage]
driver = "overlay"
runroot = "/run/user/$(id -u)/containers"
graphroot = "/home/$(whoami)/.local/share/containers/storage"
EOF
        log_info "Created storage.conf with overlay driver"
    fi

    # Ensure proper permissions on config files
    chmod 600 ~/.config/containers/containers.conf
    chmod 600 ~/.config/containers/storage.conf

    log_success "Rootless configuration completed"
}

install_podman_ubuntu() {
    log_info "Installing Podman on Ubuntu/Debian..."

    sudo apt-get update
    sudo apt-get install -y curl wget gnupg2 software-properties-common apt-transport-https ca-certificates \
        uidmap slirp4netns fuse-overlayfs

    . /etc/os-release

    if [[ "$VERSION_ID" == "20.04" || "$VERSION_ID" == "22.04" || "$VERSION_ID" == "24.04" ]]; then
        echo "deb https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/unstable/xUbuntu_${VERSION_ID}/ /" | sudo tee /etc/apt/sources.list.d/devel:kubic:libcontainers:unstable.list
        curl -L "https://download.opensuse.org/repositories/devel:kubic:libcontainers:unstable/xUbuntu_${VERSION_ID}/Release.key" | sudo apt-key add -
        sudo apt-get update
    fi

    # Check if Docker CLI is installed and remove it
    if dpkg -s docker-ce-cli >/dev/null 2>&1; then
        log_info "Removing existing Docker CLI to avoid conflicts..."
        sudo apt-get remove -y docker-ce-cli
        sudo apt-get autoremove -y
    fi

    # Install Podman with Docker CLI compatibility
    log_info "Installing Podman with Docker CLI compatibility..."
    sudo apt-get install -y podman podman-docker

    # Create Docker alias if it doesn't exist
    if ! grep -q "alias docker=podman" ~/.bashrc; then
        echo "alias docker=podman" >> ~/.bashrc
        log_info "Added 'docker=podman' alias to ~/.bashrc"
    fi

    configure_rootless

    if ! fix_storage_conflicts; then
        log_error "Storage conflicts detected. Please run the script again after manual cleanup."
        exit 1
    fi

    log_success "Podman installed successfully on Ubuntu/Debian with rootless support and Docker CLI compatibility!"
}

verify_installation() {
    log_info "Verifying Podman installation..."

    if command_exists podman; then
        log_success "Podman is installed!"
        log_info "Podman version: $(podman --version)"
        log_info "Testing Podman functionality..."
        if podman info >/dev/null 2>&1; then
            log_success "Podman is working correctly!"
            if podman info 2>/dev/null | grep -q "runRoot.*run/user"; then
                log_success "Running in rootless mode!"
            fi
        else
            log_warning "Podman is installed but may need additional configuration."
        fi
    else
        log_error "Podman installation failed or is not in PATH."
        exit 1
    fi
}

show_post_install_info() {
    log_success "Installation complete!"
    echo ""
    log_info "Quick start commands:"
    echo "  podman --version        # Check version"
    echo "  podman info             # Show system info"
    echo "  podman run hello-world  # Test with hello-world container"
    echo "  podman system info      # Show rootless configuration"
    echo ""
    if command_exists docker; then
        log_info "Docker compatibility:"
        echo "  alias docker=podman     # Use Podman as Docker replacement"
        echo "  podman-docker           # Docker CLI compatibility (if installed)"
        echo "  Note: Docker and Podman use separate storage - containers don't mix"
        echo ""
    fi
    log_info "Rootless daemon info:"
    echo "  podman system service  # Start rootless API service"
    echo "  systemctl --user status podman.socket  # Check socket status (Linux)"
    echo ""
    log_info "For more information, visit: https://podman.io/getting-started/"
}

main() {
    echo "========================================"
    echo "    Universal Podman Installer"
    echo "========================================"
    echo ""

    check_existing_runtimes
    OS=$(detect_os)
    log_info "Detected OS: $OS"

    if command_exists podman; then
        log_warning "Podman is already installed!"
        log_info "Current version: $(podman --version)"
        read -p "Do you want to continue anyway? (y/N): " -n 1 -r
        echo
        [[ ! $REPLY =~ ^[Yy]$ ]] && log_info "Installation cancelled." && exit 0
    fi

    case $OS in
        "macos") install_podman_macos ;;
        "ubuntu") install_podman_ubuntu ;;
        "windows") install_podman_windows ;;
        "rhel")
            sudo dnf install -y podman podman-docker slirp4netns fuse-overlayfs
            configure_rootless
            fix_storage_conflicts || exit 1
            log_success "Podman installed successfully with rootless support!"
            ;;
        *)
            log_error "Unsupported OS: $OS"
            exit 1
            ;;
    esac

    verify_installation
    show_post_install_info
}

main "$@"
