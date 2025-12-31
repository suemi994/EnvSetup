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

    local added=$(echo $PATH | grep "${ROOT_DIR}/bin" | wc -l)
    if [ $added -eq 0 ]; then
        echo "export PATH=\"\$PATH:${ROOT_DIR}/bin\"" >> ~/.zshrc
    fi

    # Add git aliases (for both distributions)
    echo "alias co='git checkout'" >> ~/.zshrc
    echo "alias gstat='git status'" >> ~/.zshrc
    echo "alias glog='git log --oneline -10'" >> ~/.zshrc

    echo "Setup zsh finished, enjoy yourself..."
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

    local aliased=$(grep "vpn=" ${HOME}/.zshrc | wc -l)
    if [ $aliased -eq 0 ]; then
        echo "alias vpn='$PROXY_CMD'" >> ${HOME}/.zshrc
    fi

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

    echo -e "export LUAROCKS_HOME=${HOME}/.luarocks" >> ${HOME}/.zshrc
    echo -e "export PATH=\"\$PATH:\${LUAROCKS_HOME}/bin\"" >> ${HOME}/.zshrc

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
        echo "export CARGO_HOME=${CARGO_HOME}" >> ${HOME}/.zshrc
        echo "export RUSTUP_HOME=${RUSTUP_HOME}" >> ${HOME}/.zshrc
        echo -e "export PATH=\"\$PATH:\${CARGO_HOME}/bin\"" >> ${HOME}/.zshrc
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
        echo "export GOROOT=${GOROOT}" >> ${HOME}/.zshrc
        echo "export GOPATH=${GOPATH}" >> ${HOME}/.zshrc
        echo "export PATH=\"\$PATH:\$GOROOT/bin:\$GOPATH/bin\"" >> ${HOME}/.zshrc
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
    source $HOME/.zshrc
    nvm install --lts
    nvm use --lts
}

setup_mcp() {
    echo "Setup MCP: installing MCP servers for specified agents..."
    # Ensure Node.js and npm are installed
    setup_nodejs
    mkdir -p "$ROOT_DIR/local/mcp"

    if npm install -g claude-mermaid 2>/dev/null; then
        for agent in "$@"; do
            case $agent in
                "claude")
                    claude mcp add --scope user mermaid claude-mermaid
                    echo "Setup MCP: mermaid server installed for Claude"
                    ;;
                *)
                    echo "Setup MCP: unknown agent '$agent', skip mermaid"
                    ;;
            esac
        done
    else
        echo "Setup MCP: mermaid server installation failed"
    fi
    
    if npm install -g @probelabs/probe 2>/dev/null; then
        for agent in "$@"; do
            case $agent in
                "claude")
                    claude mcp add --scope user probe-search npx @probelabs/probe mcp
                    echo "Setup MCP: probe search server installed for Claude"
                    ;;
                *)
                    echo "Setup MCP: unknown agent '$agent', skip probe search"
                    ;;
            esac
        done
    else
        echo "Setup MCP: probe search server installation failed"
    fi

    if npm install -g octocode-mcp 2>/dev/null; then
        for agent in "$@"; do
            case $agent in
                "claude")
                    claude mcp add --scope user octocode npx octocode-mcp@latest
                    echo "Setup MCP: github server installed for Claude"
                    ;;
                *)
                    echo "Setup MCP: unknown agent '$agent', skip github server"
                    ;;
            esac
        done
    else
        echo "Setup MCP: github server installation failed"
   fi

    local source_dir="${CUR_DIR}/mcp"
    local target_dir="$ROOT_DIR/local/mcp"
    mkdir -p $target_dir

    if [ -d "$source_dir" ]; then
        for item_dir in "$source_dir"/*; do
            if [ -d "$item_dir" ]; then
                item_name=$(basename "$item_dir")
                ln -sf "$item_dir" "$target_dir/$item_name"
                echo "Setup MCP: linked mcp server $item_name"
            fi
        done
    fi

    if ! command -v ast-grep >/dev/nul 2>&1; then
        cargo install ast-grep --locked
    fi
    if git clone https://github.com/ast-grep/ast-grep-mcp.git $target_dir/ast-grep; then
        cd $target_dir/ast-grep && uv sync
        for agent in "$@"; do
            case $agent in
                "claude")
                    local json=$(jq -n --arg dir "$target_dir/ast-grep" \
                    '{
                        "type": "stdio",
                        "command": "uv",
                        "args": ["--directory", $dir, "run", "main.py"],
                        "env": {}
                    }')
                    claude mcp add-json --scope user ast-grep $json
                    echo "Setup MCP: ast-grep server installed for Claude"
                    ;;
                *)
                    echo "Setup MCP: unknown agent '$agent', skip ast-grep server"
                    ;;
            esac
        done
    else
        echo "Setup MCP: ast-grep-mcp server installation failed"
    fi
    echo "Setup MCP finished!"
}

setup_claude() {
    echo "Setup Claude: check dependencies..."

    # Ensure Node.js and npm are installed
    setup_nodejs

    npm install -g @anthropic-ai/claude-code
    npm install -g @musistudio/claude-code-router
    npm install -g ccusage

    echo "Setup Claude: creating directories..."
    mkdir -p "$HOME/.claude/skills"
    mkdir -p "$HOME/.claude/mcp"

    echo "Setup Claude: creating configuration templates..."
    # Create claude-code-router config template
    local ROUTER_TEMPLATE="${CUR_DIR}/claude/claude-code-router.json.template"
    local ROUTER_CONFIG="$HOME/.claude-code-router/config.json"

    if [ -f "$ROUTER_TEMPLATE" ]; then
        mkdir -p "$(dirname "$ROUTER_CONFIG")"
        cp "$ROUTER_TEMPLATE" "$ROUTER_CONFIG"

        # Replace placeholders with environment variables
        if [ ! -z "$DASHSCOPE_API_KEY" ]; then
            sed -i "s/<DASHSCOPE_API_KEY>/$DASHSCOPE_API_KEY/g" "$ROUTER_CONFIG"
        fi
        if [ ! -z "$GLM_API_KEY" ]; then
            sed -i "s/<GLM_API_KEY>/$GLM_API_KEY/g" "$ROUTER_CONFIG"
        fi
        if [ ! -z "$MINIMAX_API_KEY" ]; then
            sed -i "s/<MINIMAX_API_KEY>/$MINIMAX_API_KEY/g" "$ROUTER_CONFIG"
        fi

        chmod 600 "$ROUTER_CONFIG"
        echo "Setup Claude: claude-code-router template created at $ROUTER_CONFIG"
    fi

    # Create environment variables file directly
    local ENV_CONFIG="$HOME/.claude/env.sh"

    if [ -f "$ENV_CONFIG" ]; then
        echo "Setup Claude: environment file already exists at $ENV_CONFIG"
    else
        # Create environment file with actual values if variables are set
        echo "# Claude Environment Variables" > "$ENV_CONFIG"
        if [ ! -z "$DASHSCOPE_API_KEY" ]; then
            echo "export DASHSCOPE_API_KEY=\"$DASHSCOPE_API_KEY\"" >> "$ENV_CONFIG"
        fi
        if [ ! -z "$GLM_API_KEY" ]; then
            echo "export GLM_API_KEY=\"$GLM_API_KEY\"" >> "$ENV_CONFIG"
        fi
        if [ ! -z "$BRAVE_SEARCH_API_KEY" ]; then
            echo "export BRAVE_SEARCH_API_KEY=\"$BRAVE_SEARCH_API_KEY\"" >> "$ENV_CONFIG"
        fi
        if [ ! -z "$GITHUB_TOKEN" ]; then
            echo "export GITHUB_TOKEN=\"$GITHUB_TOKEN\"" >> "$ENV_CONFIG"
        fi
        if [ ! -z "$MINIMAX_API_KEY" ]; then
            echo "export MINIMAX_API_KEY=\"$MINIMAX_API_KEY\"" >> "$ENV_CONFIG"
        fi

        chmod +x "$ENV_CONFIG"
        echo "Setup Claude: environment file created at $ENV_CONFIG"
    fi

    # Call setup_mcp for Claude agent
    setup_mcp claude

    echo "Setup Claude: creating symlinks for local components..."
    # Define component directories array
    local components=("skills" "commands")

    # Process each component type
    for component in "${components[@]}"; do
        local source_dir="${CUR_DIR}/claude/$component"
        local target_dir="$HOME/.claude/$component"
        mkdir -p $target_dir

        if [ -d "$source_dir" ]; then
            for item_dir in "$source_dir"/*; do
                if [ -d "$item_dir" ]; then
                    item_name=$(basename "$item_dir")
                    ln -sf "$item_dir" "$target_dir/$item_name"
                    echo "Setup Claude: linked $component component $item_name"
                fi
            done
        fi
    done

    # Add environment variables to .zshrc if not already present
    if [ -f "$ENV_CONFIG" ]; then
        local claude_env=$(grep "# Claude Environment Variables" "$HOME/.zshrc" | wc -l)
        if [ $claude_env -eq 0 ]; then
            echo "" >> "$HOME/.zshrc"
            echo "# Claude Environment Variables - source $ENV_CONFIG" >> "$HOME/.zshrc"
            echo "[ -f \"$ENV_CONFIG\" ] && source \"$ENV_CONFIG\"" >> "$HOME/.zshrc"
            echo "Setup Claude: environment variables added to .zshrc"
        fi
    fi

    echo "Setup Claude finished! Configure your API keys in $ENV_CONFIG"
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

    # Add docker aliases to .zshrc if not already present
    local docker_aliases=$(grep "# Docker Aliases" "$HOME/.zshrc" | wc -l)
    if [ $docker_aliases -eq 0 ]; then
        echo "" >> "$HOME/.zshrc"
        echo "# Docker Aliases" >> "$HOME/.zshrc"
        echo "alias dps='docker ps --format \"table {{.Names}}\\t{{.Status}}\\t{{.Ports}}\"'" >> "$HOME/.zshrc"
        echo "alias dlogs='docker logs -f'" >> "$HOME/.zshrc"
        echo "alias dstop='docker stop \$(docker ps -q)'" >> "$HOME/.zshrc"
        echo "alias drm='docker rm \$(docker ps -aq)'" >> "$HOME/.zshrc"
        echo "alias dcu='docker-compose up -d'" >> "$HOME/.zshrc"
        echo "alias dcd='docker-compose down'" >> "$HOME/.zshrc"
        echo "alias dcl='docker-compose logs -f'" >> "$HOME/.zshrc"
        echo "Setup Docker: aliases added to .zshrc"
    fi

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
