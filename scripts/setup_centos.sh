#! /bin/sh

check_installed () {
	local found=`dnf list installed $1 2> /dev/null | grep $1 | wc -l`
	return $found
}

setup_env () {
	echo "Setup Env: Install dependencies..."
	sudo dnf install -y epel-release 
	sudo dnf config-manager --enable crb
	sudo dnf update -y 
	sudo dnf groupinstall -y "Development Tools"
	sudo dnf install -y net-tools curl libtool automake \
	tree fd-find ripgrep zsh tmux proxychains-ng \
	cmake ninja-build python3-pip llvm clang clang-tools-extra

	echo "Setup Env: Build directories under ${ROOT_DIR} ..."
	ls -d ${ROOT_DIR}/* | xargs rm -rf 
	local SRC_DIR=`pwd`
	cd ${ROOT_DIR}  && mkdir etc local tmp bin WorkRoot
	ln -s local .local
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
		sudo dnf install zsh -y
	fi
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
    echo "alias co='git checkout'" >> ~/.zshrc
    echo "alias gstat='git status'" >> ~/.zshrc
	echo "Setup zsh finished, enjoy yourself..."
}

setup_tmux () {
	check_installed "tmux"
	if [ $? -eq 0 ]; then
		echo "Setup tmux: tmux not found, try install..."
		sudo dnf install tmux -y
	fi
	cp ${CUR_DIR}/conf/tmux.conf ~/.tmux.conf
	git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
	if [ $? -gt 0 ]; then
		echo "Setup tmux: config initiliaze failed, skip..."
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

setup_vpn () {
	check_installed "proxychains-ng"
	if [ $? -eq 0 ]; then
		echo "Setup VPN: proxychains-ng not found, try install..."
		sudo dnf install proxychains-ng -y
	fi

	local CONF_FILE="/tmp/proxychains.conf.tmp"
	if [ ! -f "/etc/proxychains.conf.old" ]; then
		echo "dynamic_chain" > $CONF_FILE
		echo "[ProxyList]" >> $CONF_FILE
		echo "socks5	192.168.100.1	7891" >> $CONF_FILE
	fi
	sudo mv /etc/proxychains.conf /etc/proxychains.conf.old
	sudo mv $CONF_FILE /etc/proxychains.conf

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
        sudo dnf install fd-find -y
    fi
    check_installed "ripgrep"
    if [ $? -eq 0 ]; then
        echo "Neovim Setup: ripgrep not found, try install..."
        sudo dnf install ripgrep -y
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
	cd ${ROOT_DIR}/tmp && curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz
	tar xvzf nvim-linux-x86_64.tar.gz -C ${ROOT_DIR}/local && rm nvim-linux-x86_64.tar.gz
	ln -s ${ROOT_DIR}/local/nvim-linux-x86_64/bin/nvim ${ROOT_DIR}/bin/nvim
	rm -rf ${HOME}/.config/nvim && ln -s ${CUR_DIR}/neovim ${HOME}/.config/nvim
	echo "Setup Neovim: please enter nvim && execute :LazyInstall"
}

setup_lua() {
	echo "Lua Setup: check lua..."
	check_installed "lua-devel"
	if [ $? -eq 0 ]; then
		echo "Neovim Setup: lua not found, try install..."
		sudo dnf install lua-devel -y
	fi
	echo "Lua Setup: check luarocks..."
	check_installed "luarocks"
	if [ $? -eq 0 ]; then
		echo "Neovim Setup: luarocks not found, try install..."
		sudo dnf install luarocks -y
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
		sudo dnf groupinstall -y "Development Tools"
		sudo dnf install llvm clang clang-tools-extra
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
		sudo dnf install automake cmake ninja-build cmake-language-server -y
	fi

	echo "Cpp Setup: check lsp server"
	clangd --version > /dev/null 2>&1
	if [ $? -gt 0 ]; then
		echo "Cpp Setup: clangd not found, try install..."
		sudo dnf install clang-tools-extra
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
	curl https://sh.rustup.rs | sh
	if [ $? -ne 0 ]; then
		echo "Rust Setup: fail to download, exiting..."
		return
	fi
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
		sudo dnf install python3-pip -y
		sudo python3 -m ensurepip --upgrade
		sudo python3 -m pip install -U pip setuptools wheel
	fi
	pylsp --version > /dev/null 2>&1
	if [ $? -ne 0 ]; then
		echo "Setup Python: pylsp not found, try install..."
		python3 -m pip install "python-lsp-server[all]" 
	fi
	echo "Setup python finished, enjoy yourself..."
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
			break
			;;
		*)
			echo -e "Usage:"
			echo -e "	ROOT_DIR=\${ROOT_DIR} bash setup.sh \${command}"
			echo -e "	Support commands: env, zsh, tmux, vpn, cpp, rust, golang, python, all"
			exit 1
			;;
	esac
done
