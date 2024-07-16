#!/bin/bash

require_root() {
  if [ "$(id -u)" == "0" ]; then
    echo "✅您是root用户，将继续运行脚本。"
  else
    echo "❌您需要root权限来运行此脚本。"
    exit 1
  fi
}

require_root

# 定义基础变量和初始分支为 unknown
QL_BRANCH="unknown"
QL_TARS=("qinglong-latest.tar" "qinglong-debian.tar")

# 检查当前目录下存在的文件以确定分支
for tar_file in "${QL_TARS[@]}"; do
  if [ -f "$tar_file" ]; then
    if [[ "$tar_file" == *"latest"* ]]; then
      QL_BRANCH="master"
    elif [[ "$tar_file" == *"debian"* ]]; then
      QL_BRANCH="debian"
    fi
    break
  fi
done

# 如果找到了对应的tar文件但未设置分支，则说明未找到预期的安装包
if [ "$QL_BRANCH" = "unknown" ]; then
  echo "未找到 qinglong-latest.tar 或 qinglong-debian.tar，退出脚本。"
  exit 1
fi

# 设置安装目录
QL_INSTALL_DIR="/rootfs/$QL_BRANCH"

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
  echo "开始解压 $tar_file 到 $QL_INSTALL_DIR"
  tar -xvf "$tar_file" -C "$QL_INSTALL_DIR"
  echo "解压完成，分支: $QL_BRANCH"
else
  echo " QingLong 已经安装在 $QL_INSTALL_DIR，跳过解压步骤。"
fi

# 设置启动和停止脚本
cat <<EOF >/usr/local/bin/start_qinglong
#!/bin/bash
set -e

# 挂载点检查与挂载
for MOUNT_POINT in etc/resolv.conf etc/hosts sys proc dev proc/sys/net proc/net sys/class/net; do
  if ! mountpoint -q /$QL_INSTALL_DIR/$MOUNT_POINT; then
    mount --bind /$MOUNT_POINT /$QL_INSTALL_DIR/$MOUNT_POINT
    echo "挂载 /$MOUNT_POINT 到 /$QL_INSTALL_DIR/$MOUNT_POINT"
  fi
done


# 启动 QingLong
chroot $QL_INSTALL_DIR/$QL_BRANCH /usr/bin/env -i HOME=/root TMPDIR=/tmp PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin TERM=linux /bin/bash <<'INNER_EOF'
  export PNPM_HOME=/root/.local/share/pnpm \
  PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/root/.local/share/pnpm:/root/.local/share/pnpm/global/5/node_modules:$PNPM_HOME \
  NODE_PATH=/usr/local/bin:/usr/local/pnpm-global/5/node_modules:/usr/local/lib/node_modules:/root/.local/share/pnpm/global/5/node_modules \
  LANG=C.UTF-8 \
  SHELL=/bin/bash \
  QL_DIR=/ql \
  QL_BRANCH=$QL_BRANCH
  cd /ql && /ql/docker/docker-entrypoint.sh && ql check
INNER_EOF
EOF

cat <<EOF >/usr/local/bin/stop_qinglong
#!/bin/bash
chroot $QL_INSTALL_DIR/$QL_BRANCH /bin/bash <<'INNER_EOF'
  pm2 stop all
  pm2 flush
INNER_EOF
EOF

cat <<EOF >/usr/local/bin/uninstall_qinglong
#!/bin/bash
set -e

# 解除挂载点
for MOUNT_POINT in sys class/net net proc/sys/net proc/net proc sys dev hosts resolv.conf; do
  if mountpoint -q /$QL_INSTALL_DIR/$MOUNT_POINT; then
    umount -l /$QL_INSTALL_DIR/$MOUNT_POINT
    echo "解除挂载 /$QL_INSTALL_DIR/$MOUNT_POINT"
  fi
done

# 检查并删除安装目录
if [ -d "$QL_INSTALL_DIR/$QL_BRANCH" ]; then
  rm -rf "$QL_INSTALL_DIR/$QL_BRANCH"
  echo "删除目录 $QL_INSTALL_DIR/$QL_BRANCH 成功。"
else
  echo "目录 $QL_INSTALL_DIR/$QL_BRANCH 不存在，可能已被删除。"
fi

# 删除启动和停止脚本
rm -f $scriptDir/start_qinglong $scriptDir/stop_qinglong $scriptDir/chroot_qinglong
echo "QingLong 卸载完成。"
EOF

# 提供一个进入chroot终端的快捷方式（可选）
cat <<EOF >/usr/local/bin/chroot_qinglong
#!/bin/bash
chroot $QL_INSTALL_DIR/$QL_BRANCH /bin/bash
EOF

scriptDir=/usr/local/bin

chmod +x $scriptDir/start_qinglong $scriptDir/stop_qinglong $scriptDir/uninstall_qinglong $scriptDir/chroot_qinglong

echo "启动脚本已创建，请使用 'start_qinglong' 来启动 QingLong。"
echo "停止脚本已创建，请使用 'stop_qinglong' 来停止 QingLong。"
echo "进入Chroot终端的命令已创建，请使用 'chroot_qinglong'。"
echo "进入后请使您可以使用 exit退出chroot容器"

echo "安装配置完成。"
