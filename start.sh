#!/bin/bash

curl -o chroot_install.sh https://raw.githubusercontent.com/Fansirsqi/chroot-qinglong/main/chroot_install.sh
curl -o proot_install.sh https://raw.githubusercontent.com/Fansirsqi/chroot-qinglong/main/proot_install.sh
chmod +x proot_install.sh
chmod +x chroot_install.sh

TERMUX_BIN=/data/data/com.termux/files/usr/bin
NORMAL_BIN=/usr/local/bin

TERMUX_CHECK=$TERMUX_BIN/termux-info
# 定义基础变量和初始分支为 unknown
QL_BRANCH="unknown"
QL_TARS=("qinglong-latest.tar" "qinglong-latest.tar.gz" "qinglong-latest.tar.bz2" "qinglong-latest.tar.xz" "qinglong-debian.tar" "qinglong-debian.tar.gz" "qinglong-debian.tar.bz2" "qinglong-debian.tar.xz")

# 设置安装目录
QL_INSTALL_DIR=/rootfs/$QL_BRANCH

require_root() {
  if [ "$(id -u)" == "0" ]; then
    echo "✅您是root用户，将继续运行脚本。"
  else
    echo "❌您需要root权限来运行此脚本。"
    exit 1
  fi
}

check_decompression() {
  local QL_TARS=$1
  local QL_INSTALL_DIR=$2
  # 检查当前目录下存在的文件以确定分支和解压方法
  for tar_file in "${QL_TARS[@]}"; do
    if [ -f "$tar_file" ]; then
      if [[ "$tar_file" == *"debian"* ]]; then
        QL_BRANCH="debian"
      elif [[ "$tar_file" == *"latest"* ]]; then
        QL_BRANCH="master"
      fi

      # 根据文件后缀确定解压命令
      case "$tar_file" in
      *.tar.gz)
        EXTRACT_CMD="gzip -dc"
        ;;
      *.tar.bz2)
        EXTRACT_CMD="bzip2 -dc"
        ;;
      *.tar.xz)
        EXTRACT_CMD="xz -dc"
        ;;
      *.tar)
        EXTRACT_CMD="cat"
        ;;
      *)
        EXTRACT_CMD="echo '未知文件格式，无法解压'; exit 1"
        ;;
      esac

      # 如果找到debian分支，则不再检查其他文件
      if [ "$QL_BRANCH" = "debian" ]; then
        break
      fi
    fi
  done

  # 如果找到了对应的tar文件但未设置分支，则说明未找到预期的安装包
  if [ "$QL_BRANCH" = "unknown" ]; then
    echo "未找到 qinglong-latest 或 qinglong-debian 的压缩文件，退出脚本。"
    exit 1
  fi

  # 检查并创建安装目录
  if [ ! -d "$QL_INSTALL_DIR" ]; then
    mkdir -p "$QL_INSTALL_DIR" || {
      echo "无法创建目录 $QL_INSTALL_DIR，退出脚本。"
      exit 1
    }
    echo "创建目录 $QL_INSTALL_DIR 成功。"
  fi

  # 检查 QingLong 是否已经安装
  installed=$(ls "$QL_INSTALL_DIR" 2>/dev/null | grep -c 'ql')

  if [ "$installed" -eq 0 ]; then
    # 解压对应分支的安装包到指定目录
    echo "开始解压 $tar_file 到$QL_INSTALL_DIR"
    eval "$EXTRACT_CMD$tar_file | tar -xv -C $QL_INSTALL_DIR"
    echo "解压完成，分支: $QL_BRANCH"
  else
    echo "QingLong 已经安装在 $QL_INSTALL_DIR，跳过解压步骤。"
  fi
}

install_script() {
  # 检查是否在Termux环境中
  if [ -f $TERMUX_CHECK ]; then
    echo "当前环境是Termux。默认使用proot安装"
    # 读取用户输入
    read -p "请输入(Y/y使用proot安装, N/n使用chroot安装, 输入Q/q退出安装): " input

    # 判断用户输入
    case $input in
    [Yy] | '')
      echo "Termux使用proot安装"
      # 在这里添加您希望执行的代码
      ./proot_install.sh $QL_BRANCH $QL_INSTALL_DIR $TERMUX_BIN
      ;;
    [Nn])
      echo "Termux使用chroot安装"
      # 在这里添加您希望执行的代码
      require_root
      ./chroot_install.sh $QL_BRANCH $QL_INSTALL_DIR $TERMUX_BIN
      ;;
    [Qq])
      echo "您选择了退出。"
      # 在这里添加您希望执行的代码
      exit 1
      ;;
    *)
      echo "无效输入，请输入Y/y继续或N/n退出。"
      # 如果需要，可以在这里添加重试逻辑
      ;;
    esac

  else
    echo "当前环境不是Termux。"

    read -p "请输入(Y/y使用proot安装, N/n使用chroot安装, 输入Q/q退出安装): " input

    # 判断用户输入
    case $input in
    [Yy] | '')
      echo "使用proot安装"
      # 在这里添加您希望执行的代码
      ./proot_install.sh $QL_BRANCH $QL_INSTALL_DIR $TERMUX_BIN
      ;;
    [Nn])
      echo "使用chroot安装"
      # 在这里添加您希望执行的代码
      require_root
      ./chroot_install.sh $QL_BRANCH $QL_INSTALL_DIR $TERMUX_BIN
      ;;
    [Qq])
      echo "您选择了退出。"
      # 在这里添加您希望执行的代码
      exit 1
      ;;
    *)
      echo "无效输入，请输入Y/y继续或N/n退出。"
      # 如果需要，可以在这里添加重试逻辑
      ;;
    esac

  fi
}
