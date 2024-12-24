#!/bin/bash
#  ______ _____ _    _   _____
# |___  // ____| |  | | |  __ \
#    / /| (___ | |__| | | |__| ) __ _____  ___   _
#   / /  \___ \|  __  | |  ___/ '__/ _ \ \/ | | | |
#  / /__ ____) | |  | | | |   | | | (_) >  <| |_| |
# /_____|_____/|_|  |_| |_|   |_|  \___/_/\_\\__, |
#                                             __/ |
#                                            |___/
# -------------------------------------------------
# 一个 zsh 的代理插件
# Sukka (https://skk.moe)

__read_proxy_config() {
	__ZSHPROXY_STATUS=$(cat "${ZDOTDIR:-${HOME}}/.zsh-proxy/status")
	__ZSHPROXY_SOCKS5=$(cat "${ZDOTDIR:-${HOME}}/.zsh-proxy/socks5")
	__ZSHPROXY_HTTP=$(cat "${ZDOTDIR:-${HOME}}/.zsh-proxy/http")
	__ZSHPROXY_NO_PROXY=$(cat "${ZDOTDIR:-${HOME}}/.zsh-proxy/no_proxy")
	__ZSHPROXY_GIT_PROXY_TYPE=$(cat "${ZDOTDIR:-${HOME}}/.zsh-proxy/git_proxy_type")
}

__check_whether_init() {
	if [ ! -f "${ZDOTDIR:-${HOME}}/.zsh-proxy/status" ] || [ ! -f "${ZDOTDIR:-${HOME}}/.zsh-proxy/http" ] || [ ! -f "${ZDOTDIR:-${HOME}}/.zsh-proxy/socks5" ] || [ ! -f "${ZDOTDIR:-${HOME}}/.zsh-proxy/no_proxy" ]; then
		echo "----------------------------------------"
		echo "请先运行以下命令："
		echo "$ init_proxy"
		echo "----------------------------------------"
	else
		__read_proxy_config
	fi
}

__check_ip() {
	echo "========================================"
	echo "Check what your IP is"
	echo "----------------------------------------"
	ipv4=$(curl -s -k https://api-ipv4.ip.sb/ip -H 'user-agent: zsh-proxy')
	if [[ "$ipv4" != "" ]]; then
		echo "IPv4: $ipv4"
	else
		echo "IPv4: -"
	fi
	echo "----------------------------------------"
	ipv6=$(curl -s -k -m10 https://api-ipv6.ip.sb/ip -H 'user-agent: zsh-proxy')
	if [[ "$ipv6" != "" ]]; then
		echo "IPv6: $ipv6"
	else
		echo "IPv6: -"
	fi
	if command -v python >/dev/null; then
		geoip=$(curl -s -k https://api.ip.sb/geoip -H 'user-agent: zsh-proxy')
		if [[ "$geoip" != "" ]]; then
			echo "----------------------------------------"
			echo "Info: "
			echo "$geoip" | python -m json.tool
		fi
	fi
	echo "========================================"
}

__config_proxy() {
	echo "========================================"
	echo "ZSH 代理插件配置"
	echo "----------------------------------------"

	echo -n "[socks5 代理] {默认值为 127.0.0.1:1080}
(地址:端口): "
	read -r __read_socks5

	echo -n "[socks5 类型] 选择你想使用的代理类型 {默认值为 socks5}:
1. socks5
2. socks5h (通过代理服务器解析 DNS)
(1 或 2): "
	read -r __read_socks5_type

	echo -n "[http 代理]   {默认值为 127.0.0.1:8080}
(地址:端口): "
	read -r __read_http

	echo -n "[不使用代理的域名] {默认值为 'localhost,127.0.0.1,localaddress,.localdomain.com'}
(用逗号分隔域名): "
	read -r __read_no_proxy

	echo -n "[git 代理类型] {默认值为 socks5}
(socks5 或 http): "
	read -r __read_git_proxy_type
	echo "========================================"

	if [ -z "${__read_socks5}" ]; then
		__read_socks5="127.0.0.1:1080"
	fi
	if [ -z "${__read_socks5_type}" ]; then
		__read_socks5_type="1"
	fi
	if [ -z "${__read_http}" ]; then
		__read_http="127.0.0.1:8080"
	fi
	if [ -z "${__read_no_proxy}" ]; then
		__read_no_proxy="localhost,127.0.0.1,localaddress,.localdomain.com"
	fi
	if [ -z "${__read_git_proxy_type}" ]; then
		__read_git_proxy_type="socks5"
	fi

	echo "http://${__read_http}" >"${ZDOTDIR:-${HOME}}/.zsh-proxy/http"
	if [ "${__read_socks5_type}" = "2" ]; then
		echo "socks5h://${__read_socks5}" >"${ZDOTDIR:-${HOME}}/.zsh-proxy/socks5"
	else
		echo "socks5://${__read_socks5}" >"${ZDOTDIR:-${HOME}}/.zsh-proxy/socks5"
	fi
	echo "${__read_no_proxy}" >"${ZDOTDIR:-${HOME}}/.zsh-proxy/no_proxy"
	echo "${__read_git_proxy_type}" >"${ZDOTDIR:-${HOME}}/.zsh-proxy/git_proxy_type"

	__read_proxy_config
}

# ==================================================

# APT 代理

__enable_proxy_apt() {
	if [ -d "/etc/apt/apt.conf.d" ]; then
		sudo touch /etc/apt/apt.conf.d/proxy.conf
		echo -e "Acquire::http::Proxy \"${__ZSHPROXY_HTTP}\";" | sudo tee -a /etc/apt/apt.conf.d/proxy.conf >/dev/null
		echo -e "Acquire::https::Proxy \"${__ZSHPROXY_HTTP}\";" | sudo tee -a /etc/apt/apt.conf.d/proxy.conf >/dev/null
		echo "- apt"
	fi
}

__disable_proxy_apt() {
	if [ -d "/etc/apt/apt.conf.d" ]; then
		sudo rm -rf /etc/apt/apt.conf.d/proxy.conf
	fi
}

# pip 代理
# pip 可以读取 http_proxy 和 https_proxy

# 终端代理

__enable_proxy_all() {
	# http_proxy
	export http_proxy="${__ZSHPROXY_HTTP}"
	export HTTP_PROXY="${__ZSHPROXY_HTTP}"
	# https_proxy
	export https_proxy="${__ZSHPROXY_HTTP}"
	export HTTPS_PROXY="${__ZSHPROXY_HTTP}"
	# ftp_proxy
	export ftp_proxy="${__ZSHPROXY_HTTP}"
	export FTP_PROXY="${__ZSHPROXY_HTTP}"
	# rsync_proxy
	export rsync_proxy="${__ZSHPROXY_HTTP}"
	export RSYNC_PROXY="${__ZSHPROXY_HTTP}"
	# all_proxy
	export ALL_PROXY="${__ZSHPROXY_SOCKS5}"
	export all_proxy="${__ZSHPROXY_SOCKS5}"

	export no_proxy="${__ZSHPROXY_NO_PROXY}"
}

__disable_proxy_all() {
	unset http_proxy
	unset HTTP_PROXY
	unset https_proxy
	unset HTTPS_PROXY
	unset ftp_proxy
	unset FTP_PROXY
	unset rsync_proxy
	unset RSYNC_PROXY
	unset ALL_PROXY
	unset all_proxy
	unset no_proxy
}

# Git 代理

__enable_proxy_git() {
	if [ "${__ZSHPROXY_GIT_PROXY_TYPE}" = "http" ]; then
		git config --global http.proxy "${__ZSHPROXY_HTTP}"
		git config --global https.proxy "${__ZSHPROXY_HTTP}"
	else
		git config --global http.proxy "${__ZSHPROXY_SOCKS5}"
		git config --global https.proxy "${__ZSHPROXY_SOCKS5}"
	fi
}

__disable_proxy_git() {
	git config --global --unset http.proxy
	git config --global --unset https.proxy
}

# 使用 SSH 克隆可以在 https://github.com/comwrg/FUCK-GFW#git 找到

# NPM

__enable_proxy_npm() {
	if command -v npm >/dev/null; then
		npm config set proxy "${__ZSHPROXY_HTTP}"
		npm config set https-proxy "${__ZSHPROXY_HTTP}"
		echo "- npm"
	fi
	if command -v yarn >/dev/null; then
		yarn config set proxy "${__ZSHPROXY_HTTP}" >/dev/null 2>&1
		yarn config set https-proxy "${__ZSHPROXY_HTTP}" >/dev/null 2>&1
		echo "- yarn"
	fi
	if command -v pnpm >/dev/null; then
		pnpm config set proxy "${__ZSHPROXY_HTTP}" >/dev/null 2>&1
		pnpm config set https-proxy "${__ZSHPROXY_HTTP}" >/dev/null 2>&1
		echo "- pnpm"
	fi
}

__disable_proxy_npm() {
	if command -v npm >/dev/null; then
		npm config delete proxy
		npm config delete https-proxy
	fi
	if command -v yarn >/dev/null; then
		yarn config delete proxy >/dev/null 2>&1
		yarn config delete https-proxy >/dev/null 2>&1
	fi
	if command -v pnpm >/dev/null; then
		pnpm config delete proxy >/dev/null 2>&1
		pnpm config delete https-proxy >/dev/null 2>&1
	fi
}

# ==================================================

__enable_proxy() {
	if [ -z "${__ZSHPROXY_STATUS}" ] || [ -z "${__ZSHPROXY_SOCKS5}" ] || [ -z "${__ZSHPROXY_HTTP}" ]; then
		echo "========================================"
		echo "zsh-proxy 无法读取配置。"
		echo "你可能需要重新初始化并重新配置插件。"
		echo "使用以下命令可能会有所帮助："
		echo "$ init_proxy"
		echo "$ config_proxy"
		echo "$ proxy"
		echo "========================================"
	else
		echo "========================================"
		echo -n "重置代理... "
		__disable_proxy_all
		__disable_proxy_git
		__disable_proxy_npm
		__disable_proxy_apt
		echo "完成!"
		echo "----------------------------------------"
		echo "启用代理："
		echo "- shell"
		__enable_proxy_all
		echo "- git"
		# npm & yarn & pnpm"
		__enable_proxy_npm
		# apt"
		__enable_proxy_apt
		echo "完成!"
	fi
}

__disable_proxy() {
	__disable_proxy_all
	__disable_proxy_git
	__disable_proxy_npm
	__disable_proxy_apt
}

__auto_proxy() {
	if [ "${__ZSHPROXY_STATUS}" = "1" ]; then
		__enable_proxy_all
	fi
}

__zsh_proxy_update() {
	__NOW_PATH=$(
		cd "$(dirname "$0")" || exit
		pwd
	)
	cd "$HOME/.oh-my-zsh/custom/plugins/zsh-proxy" || exit
	git fetch --all
	git reset --hard origin/master
	source "${ZDOTDIR:-${HOME}}/.zshrc"
	cd "${__NOW_PATH}" || exit
}

# ==================================================

init_proxy() {
	mkdir -p "${ZDOTDIR:-${HOME}}/.zsh-proxy"
	touch "${ZDOTDIR:-${HOME}}/.zsh-proxy/status"
	echo "0" >"${ZDOTDIR:-${HOME}}/.zsh-proxy/status"
	touch "${ZDOTDIR:-${HOME}}/.zsh-proxy/http"
	touch "${ZDOTDIR:-${HOME}}/.zsh-proxy/socks5"
	touch "${ZDOTDIR:-${HOME}}/.zsh-proxy/no_proxy"
	touch "${ZDOTDIR:-${HOME}}/.zsh-proxy/git_proxy_type"
	echo "----------------------------------------"
	echo "太棒了！zsh-proxy 已初始化"
	echo ""
	echo -E '  ______ _____ _    _   _____  '
	echo -E ' |___  // ____| |  | | |  __ \ '
	echo -E '    / /| (___ | |__| | | |__| ) __ _____  ___   _ '
	echo -E "   / /  \___ \|  __  | |  ___/ '__/ _ \ \/ | | | |"
	echo -E '  / /__ ____) | |  | | | |   | | | (_) >  <| |_| |'
	echo -E ' /_____|_____/|_|  |_| |_|   |_|  \___/_/\_\\__, |'
	echo -E '                                             __/ |'
	echo -E '                                            |___/ '
	echo "----------------------------------------"
	echo "现在你可能想运行以下命令："
	echo "$ config_proxy"
	echo "----------------------------------------"
}

config_proxy() {
	__config_proxy
}

proxy() {
	echo "1" >"${ZDOTDIR:-${HOME}}/.zsh-proxy/status"
	__enable_proxy
}

noproxy() {
	echo "0" >"${ZDOTDIR:-${HOME}}/.zsh-proxy/status"
	__disable_proxy
}

myip() {
	__check_ip
}

zsh_proxy_update() {
	__zsh_proxy_update
}

__check_whether_init
__auto_proxy
