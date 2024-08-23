#!/bin/bash

# 下载脚本
curl -osL chroot_install.sh https://raw.githubusercontent.com/Fansirsqi/chroot-qinglong/main/chroot_install.sh
curl -osL proot_install.sh https://raw.githubusercontent.com/Fansirsqi/chroot-qinglong/main/proot_install.sh

# 使脚本可执行
chmod +x proot_install.sh
chmod +x chroot_install.sh

# 定义基础变量和初始分支为 unknown
QL_BRANCH="unknown"
QL_TARS=("qinglong-latest.tar" "qinglong-latest.tar.gz" "qinglong-latest.tar.bz2" "qinglong-latest.tar.xz" "qinglong-debian.tar" "qinglong-debian.tar.gz" "qinglong-debian.tar.bz2" "qinglong-debian.tar.xz")

# 检查是否为root用户
require_root() {
	if [ "$(id -u)" != "0" ]; then
		echo "❌您需要root权限来运行此脚本。"
		exit 1
	fi
}

# 设置安装目录
QL_INSTALL_DIR=/rootfs/$QL_BRANCH

# 添加一个函数来检查文件是否为空
check_if_file_is_empty() {
	if [ ! -s "$1" ]; then
		echo "文件 $1 是空的。"
		return 0
	else
		echo "文件 $1 已存在，大小为 $(du -h "$1" | cut -f1)。"
		local action
		read -p "您想覆盖(o)，删除(d)，还是跳过(s)？(默认覆盖): " action
		case $action in
		d) rm -f "$1" ;;
		s) return 1 ;;
		*) echo "覆盖现有文件。" ;;
		esac
	fi
}

# 检测文件夹是否为空
is_empty_directory() {
	local directory="$1" # 获取函数参数作为目录路径

	# 检查目录是否存在
	if [ ! -d "$directory" ]; then
		echo "错误：提供的路径不是一个目录或路径不存在。"
		return 2
	fi

	# 使用find命令检查目录是否为空
	if [ -z "$(ls -A "$directory")" ]; then
		echo "目录 $directory 是空的。"
		return 1 # 目录为空，直接返回1
	else
		echo "目录 $directory 不是空的。"
		echo "目录包含文件和/或子目录。您想删除这些内容吗？(y/n):"
		read -r user_choice
		case $user_choice in
		[yY])
			echo "正在删除目录 $directory 中的内容..."
			rm -rf "$directory"/*
			if [ $? -eq 0 ]; then
				echo "目录内容已删除。"
				return 1 # 用户选择删除
			else
				echo "删除失败。"
				return 0 # 删除失败，返回0
			fi
			;;
		*)
			echo "已选择不删除目录内容。"
			return 0 # 用户选择不删除，直接返回0
			;;
		esac
	fi
}

# 检查并解压QingLong安装包
check_and_decompress() {
	local QL_TARS=("$@")
	local QL_INSTALL_DIR="$QL_INSTALL_DIR"

	for tar_file in "${QL_TARS[@]}"; do
		if [ -f "$tar_file" ]; then
			if [[ "$tar_file" == *"debian"* ]]; then
				QL_BRANCH="debian"
			elif [[ "$tar_file" == *"latest"* ]]; then
				QL_BRANCH="master"
			fi

			# 确定解压命令
			case "$tar_file" in
			*.tar.gz) EXTRACT_CMD="gzip -dc" ;;
			*.tar.bz2) EXTRACT_CMD="bzip2 -dc" ;;
			*.tar.xz) EXTRACT_CMD="xz -dc" ;;
			*.tar) EXTRACT_CMD="cat" ;;
			*) EXTRACT_CMD="echo '未知文件格式，无法解压'; exit 1" ;;
			esac

			break
		fi
	done

	# 检查并创建安装目录
	if [ ! -d "$QL_INSTALL_DIR" ]; then
		mkdir -p "$QL_INSTALL_DIR" || {
			echo "无法创建目录 $QL_INSTALL_DIR，退出脚本。"
			exit 1
		}
	fi

	# 调用函数并捕获返回值
	status=$(is_empty_directory "$QL_INSTALL_DIR")

	# 解压文件
	if [ -n "$EXTRACT_CMD" ]; then
		# 根据返回值执行不同的操作
		if [ $status -eq 0 ]; then
			echo "已存在。"
			# 执行一些操作...
		elif [ $status -eq 1 ]; then
			echo "目录是空的或用户选择删除并成功删除了内容。"
			echo "开始解压 $tar_file 到 $QL_INSTALL_DIR"
			eval "$EXTRACT_CMD $tar_file | tar -xv -C $QL_INSTALL_DIR"
			echo "解压完成，分支: $QL_BRANCH"
		else
			echo "检查目录时发生错误。"
			# 处理错误...
		fi
	fi
}

# 根据环境和用户选择安装QingLong
install_script() {
	# 检查是否在Termux环境中
	if [ -f "$TERMUX_CHECK" ]; then
		echo "当前环境是Termux。"
		# 读取用户输入
		read -p "请输入(Y/y使用proot安装, N/n使用chroot安装, 输入Q/q退出安装): " input

		case $input in
		[Yy] | '') ./proot_install.sh "$QL_BRANCH" "$QL_INSTALL_DIR" "$TERMUX_BIN" ;;
		[Nn]) ./chroot_install.sh "$QL_BRANCH" "$QL_INSTALL_DIR" "$TERMUX_BIN" ;;
		[Qq]) exit 1 ;;
		*) echo "无效输入，请输入Y/y继续或N/n退出。" ;;
		esac
	else
		echo "当前环境不是Termux。"
		# 非Termux环境的安装逻辑
	fi
}

# 脚本入口
main() {
	require_root
	check_and_decompress "${QL_TARS[@]}"
	install_script
}

# 执行脚本
main
