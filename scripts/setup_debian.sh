#! /bin/sh

check_installed () {
	local found=`dpkg -l $1 | grep $1 | wc -l`
	return $found
}

setup_env () {
	echo "Setup Env: Install dependencies..."
	sudo apt-get update -y 
	sudo apt-get install net-tools curl build-essential libtool automake -y && \
	sudo apt-get install tree fd-find ripgrep zsh tmux proxychains4 -y && \
	sudo apt-get install gcc g++ clang clangd clang-tidy llvm cmake ninja-build -y && \
	sudo apt-get install python3-pip

	echo "Setup Env: Build directories under ${ROOT_DIR} ..."
	ls -d ${ROOT_DIR}/* | xargs rm -rf 
	local SRC_DIR=`pwd`
	cd ${ROOT_DIR}  && mkdir etc local tmp bin WorkRoot
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

setup_zsh () {
	check_installed "zsh"
	if [ $? -eq 0 ]; then
		echo "Setup Zsh: zsh not found, try install..."
		sudo apt-get install zsh -y
	fi
	if [ -d "$HOME/.oh-my-zsh" ]; then
		echo "Setup Zsh: oh-my-zsh already installed, skip..."
		return
	fi
	sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
	mv ~/.oh-my-zsh ${ROOT_DIR}/local/oh-my-zsh && ln -s ${ROOT_DIR}/local/oh-my-zsh ${HOME}/.oh-my-zsh
	cp ${CUR_DIR}/conf/zshrc ~/.zshrc && source ~/.zshrc

	local added=$(echo $PATH | grep "${ROOT_DIR}/bin" | wc -l)
	if [ $added -eq 0 ]; then
		echo "export PATH=\"\$PATH:${ROOT_DIR}/bin\"" >> ~/.zshrc
	fi
	echo "Setup zsh finished, enjoy yourself..."
}

setup_tmux () {
	check_installed "tmux"
	if [ $? -eq 0 ]; then
		echo "Setup tmux: tmux not found, try install..."
		sudo apt-get install tmux -y
	fi
	cp ${CUR_DIR}/conf/tmux.conf ~/.tmux.conf
	git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
	if [ $? -gt 0 ]; then
		echo "Setup tmux: config initiliaze failed, skip..."
		retun $?
	fi
	bash ~/.tmux/plugins/tpm/scripts/install_plugins.sh
	if [ $? -gt 0 ]; then
		echo "Setup tmux: install tmux plugin failed, skip..."
		return $?
	fi
	tmux source ~/.tmux.conf
	echo "Setup tmux finished, enjoy yourself..."
}

setup_vpn () {
	check_installed "proxychains4"
	if [ $? -eq 0 ]; then
		echo "Setup VPN: proxychains4 not found, try install..."
		sudo apt-get install proxychains4 -y
	fi

	local CONF_FILE="/tmp/proxychains4.conf.tmp"
	if [ ! -f "/etc/proxychains4.conf.old" ]; then
		echo "dynamic_chain" > $CONF_FILE
		echo "[ProxyList]" >> $CONF_FILE
		echo "socks5	192.168.50.1	7891" >> $CONF_FILE
	fi
	sudo mv /etc/proxychains4.conf /etc/proxychains4.conf.old
	sudo mv $CONF_FILE /etc/proxychains4.conf

	local aliased=$(grep "vpn=" ${HOME}/.zshrc | wc -l)
	if [ $aliased -eq 0 ]; then
		echo "alias vpn='proxychains4'" >> ${HOME}/.zshrc
	fi

	echo "Setup VPN finished, enjoy yourself"
}

setup_nvim () {
    check_installed "fd-find"
    if [ $? -eq 0 ]; then
        echo "Neovim Setup: fd not found, try install..."
        sudo apt-get install fd-find -y
    fi
    check_installed "ripgrep"
    if [ $? -eq 0 ]; then
        echo "Neovim Setup: ripgrep not found, try install..."
        sudo apt-get install ripgrep -y
    fi

	if [ ! -f "/etc/vim/vimrc.local" ]; then
		echo "Neovim Setup: initliaze vimrc..."
		echo "set number" >> /tmp/vimrc
		echo "set tabstop=4" >> /tmp/vimrc
		sudo mv /tmp/vimrc /etc/vim/vimrc.local
	fi
	
	nvim --version > /dev/null 2>&1
	if [ $? -eq 0 ]; then
		echo "Neovim already installed, skip..."
		return
	fi
	#cd ${ROOT_DIR}/tmp && curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz
	#tar xvzf nvim-linux-x86_64.tar.gz -C ${ROOT_DIR}/local && rm nvim-linux-x86_64.tar.gz
	ln -s ${ROOT_DIR}/local/nvim-linux-x86_64/bin/nvim ${ROOT_DIR}/bin/nvim
	rm -rf ${HOME}/.config/nvim && ln -s ${CUR_DIR}/neovim ${HOME}/.config/nvim
	echo "Setup Neovim: please enter nvim && execute :LazyInstall"
}

setup_lua() {
	echo "Lua Setup: check luarocks..."
	check_installed "luarocks"
	if [ $? -eq 0 ]; then
		echo "Neovim Setup: luarocks not found, try install..."
		sudo apt-get install luarocks -y
	else
		echo "Lua already installed..."
		return
	fi
	echo -e "export LUAROCKS_PATH=${HOME}/.luarocks" >> ${HOME}/.zshrc
	echo -e "export PATH=\"\$PATH:\${LUAROCKS_HOME}/bin\"" >> ${HOME}/.zshrc

	luarocks install --local  --server=https://luarocks.org/dev luaformatter
}

setup_cpp () {
	echo "Cpp Setup: check compilers...."
	check_installed "clang"
	if [ $? -eq 0 ]; then
		echo "Cpp Setup: install compilers: g++, clang..."
		sudo apt-get install gcc g++ clang llvm -y
	fi

	if [ X"$CC" != X"" ]; then
		echo "Cpp Setup: set default compiler to $CC"
		sudo update-alternatives --install /usr/bin/cc cc ${CC} 10
		sudo update-alternatives --install /usr/bin/c++ c++ ${CXX} 10
	fi

	echo "Cpp Setup: check make tools..."
	check_installed "cmake"
	if [ $? -eq 0 ]; then
		echo "Cpp Setup: install make tools: cmake, ninja, automake"
		sudo apt-get install automake cmake ninja-build -y
		sudo snap install --edge cmake-language-server
	fi

	echo "Cpp Setup: check lsp server"
	clangd --version > /dev/null 2>&1
	if [ $? -gt 0 ]; then
		echo "Cpp Setup: clangd not found, try install..."
		sudo apt-get install clangd -y
	fi
	clang-tidy --version > /dev/null 2>&1
	if [ $? -gt 0 ]; then
		echo "Cpp Setup: clang-tidy not found, try install..."
		sudo apt-get install clang-tidy -y
	fi
	if [ ! -f "$HOME/.config/clangd/config.yaml" ]; then
		mkdir -p $HOME/.config/clangd
		cp ${CUR_DIR}/conf/clangd/config.yaml $HOME/.config/clangd/
	fi

	echo "Setup cpp finished, enjoy yourself..."
}

setup_rust () {
	rustup --version > /dev/null 2>&1
	if [ $? -eq 0 ]; then
		echo "Rust Setup: already installed, skip..."
		return
	fi
	export CARGO_HOME="${ROOT_DIR}/local/cargo"
	export RUSTUP_HOME="${ROOT_DIR}/local/rustup"
	curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
	${CARGO_HOME}/bin/rustup default stable
	${CARGO_HOME}/bin/rustup component add rust-analyzer
	rustup --version > /dev/null 2>&1
	if [ $? -gt 0 ]; then
		echo "Rust Setup: add binary tool into PATH variable..."
		echo "export CARGO_HOME=${CARGO_HOME}" >> ${HOME}/.zshrc
		echo "export RUSTUP_HOME=${RUSTUP_HOME}" >> ${HOME}/.zshrc
		echo -e "export PATH=\"\$PATH:\${CARGO_HOME}/bin\"" >> ${HOME}/.zshrc
	fi
	echo "Setup rust finished, enjoy yourself..."
}

setup_golang () {
	go --version > /dev/null 2>&1
	if [ $? -eq 0 ]; then
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
	export GOROOT="${ROOT_DIR}/local/go" && mkdir ${GOROOT}/packages
	export GOPATH="${GOROOT}/packages"
	go --version > /dev/null 2>&1
	if [ $? -gt 0 ]; then
		echo "export GOROOT=${GOROOT}" >> ${HOME}/.zshrc
		echo "export GOPATH=${GOPATH}" >> ${HOME}/.zshrc
		echo "export PATH=\"\$PATH:\$GOROOT/bin:\$GOPATH/bin\"" >> ${HOME}/.zshrc
	fi

	$GOROOT/bin/go install golang.org/x/tools/gopls@latest

	echo "Setup Golang finished, enjoy yourself..."
}

setup_python () {
	pip3 --version > /dev/null 2>&1
	if [ $? -gt 0 ]; then
		echo "Python Setup: pip not found, try install it..."
		sudo apt-get install python3-pip -y
	fi
	check_installed "python3-pylsp"
	if [ $? -eq 0 ]; then
		echo "Setup Python: pylsp not found, try install..."
		sudo apt-get install python3-pylsp
	fi
	echo "Setup python finished, enjoy yourself..."
}

setup_nodejs () {
	echo "Setup Node.js: check dependencies..."

	# Check and install Node.js if needed
	node --version > /dev/null 2>&1
	if [ $? -ne 0 ]; then
		echo "Setup Node.js: Node.js not found, installing Node.js..."
		check_installed "nodejs"
		if [ $? -eq 0 ]; then
			sudo apt-get update
			sudo apt-get install -y nodejs
		fi
		node --version > /dev/null 2>&1
		if [ $? -ne 0 ]; then
			echo "Setup Node.js: Failed to install Node.js, please install manually..."
			return
		fi
	else
		echo "Setup Node.js: Node.js already installed, skipping..."
	fi

	# Check and install npm if needed
	npm --version > /dev/null 2>&1
	if [ $? -ne 0 ]; then
		echo "Setup Node.js: npm not found, installing npm..."
		check_installed "npm"
		if [ $? -eq 0 ]; then
			sudo apt-get update
			sudo apt-get install -y npm
		fi
		npm --version > /dev/null 2>&1
		if [ $? -ne 0 ]; then
			echo "Setup Node.js: Failed to install npm, please install manually..."
			return
		fi
	else
		echo "Setup Node.js: npm already installed, skipping..."
	fi
}

setup_claude () {
	echo "Setup Claude: check dependencies..."

    sudo npm install -g @anthropic-ai/claude-code
    sudo npm install -g @musistudio/claude-code-router
    sudo npm install -g ccusage   

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

	echo "Setup Claude: installing common MCP servers..."
	# Install common MCP servers
	sudo npm install -g @modelcontextprotocol/server-filesystem 2>/dev/null || echo "Setup Claude: filesystem server installation failed"
	sudo npm install -g @brave/brave-search-mcp-server 2>/dev/null || echo "Setup Claude: brave-search server installation failed"
	sudo npm install -g octocode-mcp 2>/dev/null || echo "Setup Claude: github server installation failed"
	sudo npm install -g @modelcontextprotocol/server-sequential-thinking 2>/dev/null || echo "Setup Claude: sequential-thinking server installation failed"
	sudo npm install -g @modelcontextprotocol/inspector 2>/dev/null || echo "Setup Claude: inspector server installation failed"

	echo "Setup Claude: installing common skills..."
	# Install common skills
	sudo npm install -g document-skills@anthropic-agent-skills 2>/dev/null || echo "Setup Claude: document-skills installation failed"
	sudo npm install -g example-skills@anthropic-agent-skills 2>/dev/null || echo "Setup Claude: example-skills installation failed"
	sudo npm install -g claude-mermaid@claude-mermaid 2>/dev/null || echo "Setup Claude: claude-mermaid installation failed"

	echo "Setup Claude: creating symlinks for local components..."
	# Scan and symlink skills
	if [ -d "${CUR_DIR}/claude/skills" ]; then
		for skill_dir in "${CUR_DIR}/claude/skills"/*; do
			if [ -d "$skill_dir" ]; then
				skill_name=$(basename "$skill_dir")
				ln -sf "$skill_dir" "$HOME/.claude/skills/$skill_name"
				echo "Setup Claude: linked skill $skill_name"
			fi
		done
	fi

	# Scan and symlink mcp servers
	if [ -d "${CUR_DIR}/claude/mcp" ]; then
		for mcp_dir in "${CUR_DIR}/claude/mcp"/*; do
			if [ -d "$mcp_dir" ]; then
				mcp_name=$(basename "$mcp_dir")
				ln -sf "$mcp_dir" "$HOME/.claude/mcp/$mcp_name"
				echo "Setup Claude: linked MCP server $mcp_name"
			fi
		done
	fi

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

	echo "Setup Claude: verification..."
	# Verify MCP servers
	local mcp_count=$(npm list -g 2>/dev/null | grep -E "@modelcontextprotocol|@brave|octocode-mcp|claude-mermaid" | wc -l)
	echo "Setup Claude: $mcp_count MCP/skill packages installed"

	# Verify symlinks
	local skill_links=$(ls -la "$HOME/.claude/skills" 2>/dev/null | grep "^l" | wc -l)
	local mcp_links=$(ls -la "$HOME/.claude/mcp" 2>/dev/null | grep "^l" | wc -l)
	echo "Setup Claude: $skill_links skill symlinks, $mcp_links MCP symlinks created"

	echo "Setup Claude finished! Configure your API keys in $ENV_CONFIG"
}

setup_docker () {
	echo "Setup Docker: check dependencies..."

	# Check if docker and docker-compose are installed
	docker --version > /dev/null 2>&1
	if [ $? -ne 0 ]; then
		echo "Setup Docker: Docker not found, installing Docker and docker-compose..."
		check_installed "docker-ce"
		if [ $? -eq 0 ]; then
			sudo apt-get update
			sudo apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release
			sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker.gpg
			sudo echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
			sudo apt-get update
			sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
			sudo systemctl start docker
			sudo systemctl enable docker
		fi
		docker --version > /dev/null 2>&1
		if [ $? -ne 0 ]; then
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
	echo "Setup Docker finished! Docker data directory: $HOME/docker-data"
}

if [ -z $ROOT_DIR ]; then
	ROOT_DIR="$HOME"
fi
CUR_DIR="$ROOT_DIR/etc/backup"

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
            break;
            ;;
		"nodejs")
			setup_nodejs
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
			echo -e "Usage:"
			echo -e "	ROOT_DIR=\${ROOT_DIR} bash setup.sh \${command}"
			echo -e "	Support commands: env, zsh, tmux, vpn, cpp, rust, golang, python, lua, nodejs, claude, docker, all"
			exit 1
			;;
	esac
done
