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
        *.tar.gz)  EXTRACT_CMD="gzip -dc" ;;
        *.tar.bz2) EXTRACT_CMD="bzip2 -dc" ;;
        *.tar.xz)  EXTRACT_CMD="xz -dc" ;;
        *.tar)     EXTRACT_CMD="cat" ;;
        *)         EXTRACT_CMD="echo '未知文件格式，无法解压'; exit 1" ;;
      esac

      break
    fi
  done

  # 检查并创建安装目录
  if [ ! -d "$QL_INSTALL_DIR" ]; then
    mkdir -p "$QL_INSTALL_DIR" || { echo "无法创建目录 $QL_INSTALL_DIR，退出脚本。"; exit 1; }
  fi

  # 解压文件
  if [ -n "$EXTRACT_CMD" ]; then
    echo "开始解压 $tar_file 到 $QL_INSTALL_DIR"
    eval "$EXTRACT_CMD $tar_file | tar -xv -C $QL_INSTALL_DIR"
    echo "解压完成，分支: $QL_BRANCH"
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
      [Yy]|'') ./proot_install.sh "$QL_BRANCH" "$QL_INSTALL_DIR" "$TERMUX_BIN" ;;
      [Nn])   ./chroot_install.sh "$QL_BRANCH" "$QL_INSTALL_DIR" "$TERMUX_BIN" ;;
      [Qq])   exit 1 ;;
      *)      echo "无效输入，请输入Y/y继续或N/n退出。";;
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
