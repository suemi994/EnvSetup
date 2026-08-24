#! /bin/sh

# =============================================================================
# Universal Setup Script for Multiple Linux Distributions
# Supports: CentOS/RHEL (dnf), Debian/Ubuntu (apt)
# =============================================================================

# Detect Linux distribution
detect_distribution() {
    if [ -f /etc/redhat-release ] || [ -f /etc/centos-release ] || [ -f /etc/rocky-release ]; then
        echo "centos"
    elif [ -f /etc/debian_version ] || grep -q "Ubuntu" /etc/lsb-release 2>/dev/null; then
        echo "debian"
    else
        echo "unknown"
    fi
}

# Initialize package manager based on distribution
init_package_manager() {
    local distro=$(detect_distribution)
    case $distro in
        centos)
            PACKAGE_MANAGER="dnf"
            UPDATE_CMD="sudo dnf update -y"
            INSTALL_CMD="sudo dnf install -y"
            CHECK_INSTALLED="dnf list installed"
            GROUP_INSTALL_CMD="sudo dnf groupinstall -y"
            ;;
        debian)
            PACKAGE_MANAGER="apt"
            UPDATE_CMD="sudo apt-get update -y"
            INSTALL_CMD="sudo apt-get install -y"
            CHECK_INSTALLED="dpkg -l"
            GROUP_INSTALL_CMD="$INSTALL_CMD"
            ;;
        *)
            echo "Error: Unsupported distribution"
            exit 1
            ;;
    esac
}

# Package name mapping (generic_name: centos_package debian_package)
declare -A PACKAGE_MAPS=(
    ["proxychains_tool"]="proxychains-ng proxychains4"
    ["dev_tools"]="Development Tools build-essential"
    ["clang_tools"]="clang-tools-extra clangd clang-tidy"
    ["cmake_lang_server"]="cmake-language-server cmake-language-server"
    ["python_lsp"]="python3-pip python3-pylsp"
)

# Get package names for the detected distribution
get_package_names() {
    local generic_name=$1
    local distro=$(detect_distribution)
    local package_list="${PACKAGE_MAPS[$generic_name]}"

    case $distro in
        centos)
            echo "$package_list" | cut -d' ' -f1
            ;;
        debian)
            echo "$package_list" | cut -d' ' -f2-
            ;;
        *)
            echo "$package_list"
            ;;
    esac
}

# Unified package checking function
check_installed() {
    local package=$1
    local found=$($CHECK_INSTALLED $package 2>/dev/null | grep $package | wc -l)
    return $found
}

# Unified package installation function
install_if_not_found() {
    local package=$1
    check_installed "$package"
    if [ $? -eq 0 ]; then
        echo "Installing $package..."
        $INSTALL_CMD $package
    else
        echo "$package already installed, skipping..."
    fi
}

# Install multiple packages
install_packages() {
    for package in "$@"; do
        install_if_not_found "$package"
    done
}

# =============================================================================
# Shell configuration helpers
# Must run AFTER setup_zsh / setup_fish have run, which export SHELL and set
# SH_PROFILE / SH_CONF (they also create the files/dirs). If SHELL is empty or
# neither zsh nor fish, these helpers skip with a message.
#   - zsh:  lines are appended directly to the target file
#   - fish: env entries are inserted inside the existing
#           `if not contains ... $PATH` guard block (SH_PROFILE);
#           single-line commands inside the `if status is-interactive`
#           block (SH_CONF)
# =============================================================================

# Add an environment variable or PATH entry to SH_PROFILE
upsert_env() {
    local line=$1

    if [ -z "$SHELL" ] || { [ "$SHELL" != "zsh" ] && [ "$SHELL" != "fish" ]; }; then
        echo "upsert_env: SHELL is empty or unsupported ($SHELL), skip..."
        return 1
    fi

    case "$SHELL" in
        zsh)
            SH_PROFILE="${SH_PROFILE:-$HOME/.zprofile}"
            ;;
        fish)
            SH_PROFILE="${SH_PROFILE:-$HOME/.config/fish/conf.d/env.fish}"
            ;;
    esac
    local target="$SH_PROFILE"

    if [ "$SHELL" = "fish" ]; then
        if grep -Fqx "$line" "$target" || grep -Fqx "    $line" "$target"; then
            return
        fi
        local tmp_file="${target}.tmp.$$"
        UPSERT_LINE="$line" awk '
            {
                lines[NR] = $0
                if (!in_guard && $0 ~ /^if not contains /) {
                    in_guard = 1
                    depth = 1
                } else if (in_guard) {
                    if ($0 ~ /^[[:space:]]*if /) depth++
                    if ($0 ~ /^[[:space:]]*end[[:space:]]*$/) {
                        depth--
                        if (depth == 0) {
                            guard_end = NR
                            in_guard = 0
                        }
                    }
                }
            }
            END {
                if (guard_end == 0) {
                    # No guard block: fall back to appending at end of file
                    for (i = 1; i <= NR; i++) print lines[i]
                    print "    " ENVIRON["UPSERT_LINE"]
                } else {
                    for (i = 1; i <= NR; i++) {
                        if (i == guard_end) print "    " ENVIRON["UPSERT_LINE"]
                        print lines[i]
                    }
                }
            }
        ' "$target" > "$tmp_file" && mv "$tmp_file" "$target"
    elif ! grep -Fqx "$line" "$target" 2>/dev/null; then
        printf '%s\n' "$line" >> "$target"
    fi
}

# Add a single-line command (e.g. alias) to SH_CONF
upsert_conf() {
    local line=$1

    if [ -z "$SHELL" ] || { [ "$SHELL" != "zsh" ] && [ "$SHELL" != "fish" ]; }; then
        echo "upsert_conf: SHELL is empty or unsupported ($SHELL), skip..."
        return 1
    fi

    case "$SHELL" in
        zsh)
            SH_CONF="${SH_CONF:-$HOME/.zshrc}"
            ;;
        fish)
            SH_CONF="${SH_CONF:-$HOME/.config/fish/config.fish}"
            ;;
    esac
    local target="$SH_CONF"

    if [ "$SHELL" = "fish" ]; then
        if grep -Fqx "$line" "$target" || grep -Fqx "    $line" "$target"; then
            return
        fi
        local tmp_file="${target}.tmp.$$"
        UPSERT_LINE="$line" awk '
            {
                lines[NR] = $0
                if (!in_block && $0 ~ /^if status is-interactive/) {
                    in_block = 1
                    depth = 1
                } else if (in_block) {
                    if ($0 ~ /^[[:space:]]*if /) depth++
                    if ($0 ~ /^[[:space:]]*end[[:space:]]*$/) {
                        depth--
                        if (depth == 0) {
                            block_end = NR
                            in_block = 0
                        }
                    }
                }
            }
            END {
                if (block_end == 0) {
                    for (i = 1; i <= NR; i++) print lines[i]
                    print "    " ENVIRON["UPSERT_LINE"]
                } else {
                    for (i = 1; i <= NR; i++) {
                        if (i == block_end) print "    " ENVIRON["UPSERT_LINE"]
                        print lines[i]
                    }
                }
            }
        ' "$target" > "$tmp_file" && mv "$tmp_file" "$target"
    elif ! grep -Fqx "$line" "$target" 2>/dev/null; then
        printf '%s\n' "$line" >> "$target"
    fi
}

# =============================================================================
# Initialize environment
# =============================================================================
init_package_manager

if [ -z $ROOT_DIR ]; then
    ROOT_DIR="$HOME"
fi
CUR_DIR="$ROOT_DIR/etc/backup"

# =============================================================================
# Installation functions
# =============================================================================

setup_env() {
    echo "Setup Env: Install dependencies..."

    # Update package manager
    $UPDATE_CMD

    local distro=$(detect_distribution)
    case $distro in
        centos)
            sudo dnf install -y epel-release
            sudo dnf config-manager --enable crb
            install_if_not_found "net-tools"
            install_if_not_found "curl"
            install_if_not_found "libtool"
            install_if_not_found "automake"
            install_if_not_found "tree"
            install_if_not_found "fd-find"
            install_if_not_found "ripgrep"
            install_if_not_found "zsh"
            install_if_not_found "tmux"
            install_if_not_found "fzf"
            install_packages $(get_package_names "proxychains_tool")
            install_if_not_found "cmake"
            install_if_not_found "ninja-build"
            install_if_not_found "python3-pip"
            install_if_not_found "llvm"
            install_if_not_found "clang"
            install_packages $(get_package_names "clang_tools")
            ;;
        debian)
            install_packages $(get_package_names "dev_tools")
            install_if_not_found "libtool"
            install_if_not_found "tree"
            install_if_not_found "fd-find"
            install_if_not_found "ripgrep"
            install_if_not_found "zsh"
            install_if_not_found "tmux"
            install_if_not_found "fzf"
            install_packages $(get_package_names "proxychains_tool")
            install_if_not_found "gcc"
            install_if_not_found "g++"
            install_if_not_found "clang"
            install_if_not_found "llvm"
            install_packages $(get_package_names "clang_tools")
            install_if_not_found "cmake"
            install_if_not_found "ninja-build"
            install_if_not_found "python3-pip"
            ;;
    esac

    echo "Setup Env: Build directories under ${ROOT_DIR} ..."
    ls -d ${ROOT_DIR}/* 2>/dev/null | xargs rm -rf
    local SRC_DIR=`pwd`
    cd ${ROOT_DIR} && mkdir -p etc local tmp bin WorkRoot
    mv ${SRC_DIR} ${CUR_DIR} && cd ${CUR_DIR}

    echo "Setup Env: Keep alive for ssh connections..."
    local SSHD_CONF="/etc/ssh/sshd_config.d/keep_alive.conf"
    if [ ! -f "$SSHD_CONF" ]; then
        echo "ClientAliveInterval 30" > /tmp/keep_alive.conf
        echo "ClientAliveCountMax 2" >> /tmp/keep_alive.conf
        sudo mv /tmp/keep_alive.conf $SSHD_CONF
    fi

    echo "Setup Env finished, ready to setup sub modules..."
}

setup_zsh() {
    install_if_not_found "zsh"
    install_if_not_found "fzf"
    export SHELL="zsh"
    SH_PROFILE="$HOME/.zprofile"
    SH_CONF="$HOME/.zshrc"

    if [ -d "$HOME/.oh-my-zsh" ]; then
        echo "Setup Zsh: oh-my-zsh already installed, skip..."
        return
    fi
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
    if [ $? -ne 0 ]; then
        echo "Setup Zsh: fail to download ohmyzsh, exiting..."
        return
    fi
    mv ~/.oh-my-zsh ${ROOT_DIR}/local/oh-my-zsh && ln -s ${ROOT_DIR}/local/oh-my-zsh ${HOME}/.oh-my-zsh
    cp ${CUR_DIR}/conf/zshrc ~/.zshrc && source ~/.zshrc

    # Env vars/PATH go to SH_PROFILE, aliases go to SH_CONF
    cat >> "$SH_PROFILE" << EOF
export PATH="\$PATH:${ROOT_DIR}/bin"
EOF
    cat >> "$SH_CONF" << 'EOF'
alias co='git checkout'
alias gstat='git status'
alias glog='git log --oneline -10'
EOF

    echo "Setup zsh finished, enjoy yourself..."
}

setup_fish() {
    install_if_not_found "fzf"
    install_if_not_found "fish"

    export SHELL="fish"
    SH_PROFILE="$HOME/.config/fish/conf.d/env.fish"
    SH_CONF="$HOME/.config/fish/config.fish"

    if [ -f "$SH_PROFILE" ]; then
        echo "Setup fish: fish already installed, skip..."
        return
    fi

    fish -c "$(curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source && fisher install jorgebucaran/fisher)"
    if [ $? -ne 0 ]; then
        echo "Setup Fish: fail to download fisher, exiting..."
        return
    fi

    fish -c "fisher install jorgebucaran/fisher"
    fish -c "fisher install patrickf1/fzf.fish"
    fish -c "fisher install edc/bass"
    fish -c "fisher install berk-karaal/loadenv.fish"
    fish -c "fisher install ilancosman/tide@v6"

    sudo echo $(which fish) >> /etc/shells

    cat > "$SH_CONF" << 'EOF'
if status is-interactive
    if test -z "$TMUX"
        tmux attach-session -t main; or tmux new-session -s main
    end
    string match -q "$HOME" "$PWD"; or string match -q "$HOME/*" "$PWD"; or cd "$HOME"
    alias co='git checkout'
    alias gstat='git status'
    alias glog='git log'
    alias gbranch='git branch'
    alias ls='ls --color=never'
    alias tree='tree -n'
end
EOF

    cat >> "$SH_PROFILE" << 'EOF'
if not contains "$HOME/.local/bin" $PATH
    fish_add_path "$HOME/.local/bin"
end
EOF
}

setup_tmux() {
    install_if_not_found "tmux"

    cp ${CUR_DIR}/conf/tmux.conf ~/.tmux.conf
    git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
    if [ $? -gt 0 ]; then
        echo "Setup tmux: config initialize failed, skip..."
        return $?
    fi
    bash ~/.tmux/plugins/tpm/scripts/install_plugins.sh
    if [ $? -gt 0 ]; then
        echo "Setup tmux: install tmux plugin failed, skip..."
        return $?
    fi
    tmux source ~/.tmux.conf
    echo "Setup tmux finished, enjoy yourself..."
}

setup_vpn() {
    local proxychains_pkg=$(get_package_names "proxychains_tool")
    install_packages $proxychains_pkg

    local distro=$(detect_distribution)
    local CONF_FILE="/tmp/proxychains.conf.tmp"
    local PROXY_CONF="/etc/proxychains.conf"
    local PROXY_CMD="proxychains4"

    case $distro in
        centos)
            PROXY_CONF="/etc/proxychains.conf"
            PROXY_CMD="proxychains4"
            echo "socks5	192.168.100.1	7891" >> $CONF_FILE
            ;;
        debian)
            PROXY_CONF="/etc/proxychains4.conf"
            PROXY_CMD="proxychains4"
            echo "socks5	192.168.50.1	7891" >> $CONF_FILE
            ;;
    esac

    if [ ! -f "${PROXY_CONF}.old" ]; then
        echo "dynamic_chain" > $CONF_FILE
        echo "[ProxyList]" >> $CONF_FILE
    fi

    sudo mv $PROXY_CONF ${PROXY_CONF}.old 2>/dev/null
    sudo mv $CONF_FILE $PROXY_CONF

    upsert_conf "alias vpn='$PROXY_CMD'"

    echo "Setup VPN finished, enjoy yourself"
}

setup_nvim() {
    install_if_not_found "fd-find"
    install_if_not_found "ripgrep"

    if [ ! -f "/etc/vim/vimrc.local" ]; then
        echo "Neovim Setup: initialize vimrc..."
        echo "set number" >> /tmp/vimrc
        echo "set tabstop=4" >> /tmp/vimrc
        sudo mv /tmp/vimrc /etc/vim/vimrc.local
    fi

    nvim --version > /dev/null 2>&1
    if [ $? -eq 0 ]; then
        echo "Neovim already installed, skip..."
        return
    fi

    # Check if nvim is already downloaded
    if [ ! -d "${ROOT_DIR}/local/nvim-linux-x86_64" ]; then
        cd ${ROOT_DIR}/tmp && curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz
        tar xvzf nvim-linux-x86_64.tar.gz -C ${ROOT_DIR}/local && rm nvim-linux-x86_64.tar.gz
    fi

    ln -s ${ROOT_DIR}/local/nvim-linux-x86_64/bin/nvim ${ROOT_DIR}/bin/nvim
    rm -rf ${HOME}/.config/nvim && ln -s ${CUR_DIR}/neovim ${HOME}/.config/nvim
    echo "Setup Neovim: please enter nvim && execute :LazyInstall"
}

setup_lua() {
    echo "Lua Setup: check lua..."
    local distro=$(detect_distribution)

    case $distro in
        centos)
            install_if_not_found "lua-devel"
            ;;
        debian)
            # Debian lua is usually installed, mainly check luarocks
            ;;
    esac

    echo "Lua Setup: check luarocks..."
    install_if_not_found "luarocks"

    upsert_env "export LUAROCKS_HOME=${HOME}/.luarocks"
    upsert_env "export PATH=\"\$PATH:\${LUAROCKS_HOME}/bin\""

    luarocks install --local --server=https://luarocks.org/dev luaformatter 2>/dev/null || echo "Luaformatter installation failed, continuing..."
}

setup_cpp() {
    echo "Cpp Setup: check compilers...."
    local distro=$(detect_distribution)

    case $distro in
        centos)
            install_packages $(get_package_names "dev_tools")
            install_if_not_found "llvm"
            install_if_not_found "clang"
            install_packages $(get_package_names "clang_tools")
            ;;
        debian)
            install_if_not_found "gcc"
            install_if_not_found "g++"
            install_if_not_found "clang"
            install_if_not_found "llvm"
            install_packages $(get_package_names "clang_tools")
            ;;
    esac

    if [ X"$CC" != X"" ]; then
        echo "Cpp Setup: set default compiler to $CC"
        sudo update-alternatives --install /usr/bin/cc cc ${CC} 10
        sudo update-alternatives --install /usr/bin/c++ c++ ${CXX} 10
    fi

    echo "Cpp Setup: check make tools..."
    install_if_not_found "cmake"
    install_if_not_found "ninja-build"
    install_if_not_found "automake"

    # Install cmake-language-server
    local cmake_server_pkg=$(get_package_names "cmake_lang_server")
    case $distro in
        centos)
            install_if_not_found "$cmake_server_pkg"
            ;;
        debian)
            # Debian uses snap
            if ! command -v cmake-language-server >/dev/null 2>&1; then
                sudo snap install --edge cmake-language-server 2>/dev/null || echo "cmake-language-server installation failed, continuing..."
            fi
            ;;
    esac

    echo "Cpp Setup: check LSP server"
    if ! command -v clangd >/dev/null 2>&1; then
        echo "Cpp Setup: clangd not found, try install..."
        install_if_not_found "clangd"
    fi
    if ! command -v clang-tidy >/dev/null 2>&1; then
        echo "Cpp Setup: clang-tidy not found, try install..."
        install_if_not_found "clang-tidy"
    fi
    if ! command -v cmake-format > /dev/null 2>&1; then
        echo "Cpp Setup: cmake-format not found, try install..."
        if command -v pip3 > /dev/null 2>&1; then
            python3 -m pip install "cmake-format"
        else
            echo "Cpp Setup: pip not found, skip install cmake-format..."
        fi
    fi

    if [ ! -f "$HOME/.config/clangd/config.yaml" ]; then
        mkdir -p $HOME/.config/clangd
        cp ${CUR_DIR}/conf/clangd/config.yaml $HOME/.config/clangd/
    fi

    echo "Setup cpp finished, enjoy yourself..."
}

setup_rust() {
    if command -v rustup >/dev/null 2>&1; then
        echo "Rust Setup: already installed, skip..."
        return
    fi

    export CARGO_HOME="${ROOT_DIR}/local/cargo"
    export RUSTUP_HOME="${ROOT_DIR}/local/rustup"

    local distro=$(detect_distribution)
    case $distro in
        centos)
            curl https://sh.rustup.rs | sh
            ;;
        debian)
            curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
            ;;
    esac

    if [ $? -eq 0 ]; then
        ${CARGO_HOME}/bin/rustup default stable
        ${CARGO_HOME}/bin/rustup component add rust-analyzer
    fi

    if ! command -v rustup >/dev/null 2>&1; then
        echo "Rust Setup: add binary tool into PATH variable..."
        upsert_env "export CARGO_HOME=${CARGO_HOME}"
        upsert_env "export RUSTUP_HOME=${RUSTUP_HOME}"
        upsert_env "export PATH=\"\$PATH:\${CARGO_HOME}/bin\""
    fi
    ${CARGO_HOME}/bin/cargo install ast-grep --locked
    echo "Setup rust finished, enjoy yourself..."
}

setup_golang() {
    if command -v go >/dev/null 2>&1; then
        echo "Golang Setup: already installed, skip..."
        return
    fi

    local VERSION=$(curl "https://go.dev/dl/?mode=json" | grep -o 'go.*.linux-amd64.tar.gz' | head -n 1 | tr -d '\r\n' | awk -F'.tar.gz' '{print $1}')
    cd ${ROOT_DIR}/tmp && curl -LO https://dl.google.com/go/${VERSION}.tar.gz
    if [ $? -gt 0 ]; then
        echo "Golang Setup: download interrupted, skip..."
        return
    fi
    tar -C ${ROOT_DIR}/local -xzf ${VERSION}.tar.gz && rm ${VERSION}.tar.gz
    export GOROOT="${ROOT_DIR}/local/go" && mkdir -p ${GOROOT}/packages
    export GOPATH="${GOROOT}/packages"

    if ! command -v go >/dev/null 2>&1; then
        upsert_env "export GOROOT=${GOROOT}"
        upsert_env "export GOPATH=${GOPATH}"
        upsert_env "export PATH=\"\$PATH:\$GOROOT/bin:\$GOPATH/bin\""
    fi

    $GOROOT/bin/go install golang.org/x/tools/gopls@latest

    echo "Setup Golang finished, enjoy yourself..."
}

setup_python() {
    if ! command -v uv >/dev/null; then
        echo "Python Setup: uv not found, try install it..."
        curl -LsSf https://astral.sh/uv/install.sh | sh
        sudo $HOME/.local/bin/uv pip install --upgrade pip --system
        python3 -m pip install setuptools wheel
    fi

    local distro=$(detect_distribution)
    case $distro in
        centos)
            if ! command -v pylsp >/dev/null 2>&1; then
                echo "Setup Python: pylsp not found, try install..."
                python3 -m pip install "python-lsp-server[all]"
            fi
            ;;
        debian)
            install_if_not_found "python3-pylsp"
            ;;
    esac

    echo "Setup python finished, enjoy yourself..."
}

setup_nodejs() {
    echo "Setup Node.js: check dependencies..."

    # Check and install Node.js if needed
    if command -v nvm > /dev/null 2>&1; then
        echo "Setup Node.js: already installed, skipping..."
        return
    fi
    local nvm_tag=$(curl -s https://api.github.com/repos/nvm-sh/nvm/releases/latest | jq -r .tag_name)
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/${nvm_tag}/install.sh | bash
    if [ $? -ne 0 ]; then
        echo "Setup Node.js: install nvm failed!"
    fi
    nvm install --lts
    nvm use --lts
}

setup_docker() {
    echo "Setup Docker: check dependencies..."

    local distro=$(detect_distribution)

    # Check if docker and docker-compose are installed
    if ! command -v docker >/dev/null 2>&1; then
        echo "Setup Docker: Docker not found, installing Docker and docker-compose..."
        case $distro in
            centos)
                install_if_not_found "dnf-plugins-core"
                sudo dnf config-manager --add-repo=https://download.docker.com/linux/centos/docker-ce.repo
                sudo dnf install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
                ;;
            debian)
                install_if_not_found "apt-transport-https"
                install_if_not_found "ca-certificates"
                install_if_not_found "curl"
                install_if_not_found "gnupg"
                install_if_not_found "lsb-release"
                sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker.gpg
                sudo echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
                sudo apt-get update
                sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
                ;;
        esac
        sudo systemctl start docker
        sudo systemctl enable docker

        if ! command -v docker >/dev/null 2>&1; then
            echo "Setup Docker: Failed to install Docker, please install manually..."
            return
        fi
    else
        echo "Setup Docker: Docker already installed, skipping..."
    fi

    # Add current user to docker group
    if [ "$(id -gn)" != "docker" ]; then
        echo "Setup Docker: adding user to docker group..."
        sudo usermod -aG docker $USER
        echo "Setup Docker: Please log out and log back in for group changes to take effect"
    fi

    # Create system docker directories
    echo "Setup Docker: creating directories..."
    sudo mkdir -p /home/docker/{data,image,compose}

    # Create docker daemon configuration
    echo "Setup Docker: creating/updating daemon configuration..."
    sudo mkdir -p /etc/docker

    # Always ensure our data-root configuration is set
    if [ -f "/etc/docker/daemon.json" ]; then
        # Update existing configuration to ensure data-root is set
        sudo sed -i 's|"data-root":.*|"data-root": "/home/docker/data"|g' /etc/docker/daemon.json
    else
        # Create new configuration with our data-root
        sudo tee /etc/docker/daemon.json > /dev/null <<EOF
{
  "data-root": "/home/docker/data",
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  },
  "storage-driver": "overlay2"
}
EOF
    fi

    sudo systemctl restart docker

    # Add docker aliases (idempotent per line, into SH_CONF)
    upsert_conf "alias dps='docker ps --format \"table {{.Names}}\\t{{.Status}}\\t{{.Ports}}\"'"
    upsert_conf "alias dlogs='docker logs -f'"
    upsert_conf "alias dstop='docker stop \$(docker ps -q)'"
    upsert_conf "alias drm='docker rm \$(docker ps -aq)'"
    upsert_conf "alias dcu='docker-compose up -d'"
    upsert_conf "alias dcd='docker-compose down'"
    upsert_conf "alias dcl='docker-compose logs -f'"
    echo "Setup Docker: aliases added to shell config"

    echo "Setup Docker: verification..."
    docker --version
    docker-compose --version
    newgrp docker
    echo "Setup Docker finished! Docker data directory: /home/docker/data"
}

# =============================================================================
# Main program
# =============================================================================

while true; do
    case "$1" in
        "env")
            setup_env
            break
            ;;
        "zsh")
            setup_zsh
            break
            ;;
        "tmux")
            setup_tmux
            break
            ;;
        "vpn")
            setup_vpn
            break
            ;;
        "nvim")
            setup_nvim
            break
            ;;
        "cpp")
            setup_cpp
            break
            ;;
        "rust")
            setup_rust
            break
            ;;
        "golang")
            setup_golang
            break
            ;;
        "python")
            setup_python
            break
            ;;
        "lua")
            setup_lua
            break
            ;;
        "nodejs")
            setup_nodejs
            break
            ;;
        "mcp")
            shift
            if [ $# -eq 0 ]; then
                echo "Error: mcp requires at least one agent parameter"
                echo "Usage: bash $0 mcp <agent1> [agent2] ..."
                echo "Supported agents: claude, mermaid, github"
                exit 1
            fi
            setup_mcp "$@"
            break
            ;;
        "claude")
            setup_claude
            break
            ;;
        "docker")
            setup_docker
            break
            ;;
        "all")
            setup_env
            setup_zsh
            setup_tmux
            setup_vpn
            setup_cpp
            setup_rust
            setup_golang
            setup_python
            setup_lua
            setup_nvim
            setup_nodejs
            setup_claude
            setup_docker
            break
            ;;
        *)
            echo "Universal Setup Script for Multiple Linux Distributions"
            echo "Detected distribution: $(detect_distribution)"
            echo ""
            echo -e "Usage:"
            echo -e "\tROOT_DIR=\${ROOT_DIR} bash $0 \${command}"
            echo -e ""
            echo -e "Support commands:"
            echo -e "\tenv      - Install basic dependencies and setup environment"
            echo -e "\tzsh      - Install and configure Zsh with Oh My Zsh"
            echo -e "\ttmux     - Install and configure Tmux with TPM"
            echo -e "\tvpn      - Setup proxychains for network access"
            echo -e "\tnvim     - Install and configure Neovim"
            echo -e "\tcpp      - Setup C++ development environment"
            echo -e "\trust     - Setup Rust development environment"
            echo -e "\tgolang   - Setup Go development environment"
            echo -e "\tpython   - Setup Python development environment"
            echo -e "\tlua      - Setup Lua development environment"
            echo -e "\tnodejs   - Setup Node.js development environment"
            echo -e "\tmcp      - Setup MCP servers for specific agents"
            echo -e "\tclaude   - Setup Claude Code development environment"
            echo -e "\tdocker   - Setup Docker environment"
            echo -e "\tall      - Setup all components"
            echo -e ""
            echo -e "Examples:"
            echo -e "\tROOT_DIR=\$HOME bash $0 all"
            echo -e "\tbash $0 nvim"
            echo -e "\tbash $0 mcp claude mermaid"
            echo -e "\tbash $0 mcp github"
            exit 1
            ;;
    esac
done
