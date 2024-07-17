#!/bin/bash

local QL_BRANCH=$1
local QL_INSTALL_DIR=$2
local SCRIPT_POINT=$3 #/usr/bin
local SCRIPT_ENV=$3/env
local SCRIPTDIR=$SCRIPTDIR #/usr/loacl/bin

# 设置启动脚本
cat <<EOF >$SCRIPTDIR/start_qinglong
#!/bin/bash
set -e

# 挂载点检查与挂载
for MOUNT_POINT in /etc/resolv.conf /etc/hosts; do
  if ! mountpoint -q /$QL_INSTALL_DIR/$MOUNT_POINT; then
    mount --bind /$MOUNT_POINT /$QL_INSTALL_DIR/$MOUNT_POINT
    echo "挂载 /$MOUNT_POINT 到 /$QL_INSTALL_DIR/$MOUNT_POINT"
  fi
done


# 启动 QingLong 使用 proot
proot -b /dev -b /proc -b /sys -r $QL_INSTALL_DIR/$QL_BRANCH $SCRIPT_ENV -i HOME=/root TMPDIR=/tmp PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin TERM=linux /bin/bash <<'INNER_EOF'
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

# 设置停止脚本
cat <<EOF >$SCRIPTDIR/stop_qinglong
#!/bin/bash
proot -b /dev -b /proc -b /sys -r $QL_INSTALL_DIR/$QL_BRANCH $SCRIPT_ENV -i /bin/bash <<'INNER_EOF'
  pm2 stop all
  pm2 flush
INNER_EOF
EOF

# 设置卸载脚本
cat <<EOF >$SCRIPTDIR/uninstall_qinglong
#!/bin/bash
set -e

# 解除挂载点
for MOUNT_POINT in hosts resolv.conf; do
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
rm -f $SCRIPTDIR/start_qinglong $SCRIPTDIR/stop_qinglong $SCRIPTDIR/chroot_qinglong
echo "QingLong 卸载完成。"
EOF

# 提供一个进入proot终端的快捷方式（可选）
cat <<EOF >$SCRIPTDIR/chroot_qinglong
#!/bin/bash
proot -b /dev -b /proc -b /sys -r $QL_INSTALL_DIR/$QL_BRANCH $SCRIPT_ENV -i /bin/bash
EOF

chmod +x $SCRIPTDIR/start_qinglong $SCRIPTDIR/stop_qinglong $SCRIPTDIR/uninstall_qinglong $SCRIPTDIR/chroot_qinglong

echo "启动脚本已创建，请使用 'start_qinglong' 来启动 QingLong。"
echo "停止脚本已创建，请使用 'stop_qinglong' 来停止 QingLong。"
echo "进入Proot终端的命令已创建，请使用 'chroot_qinglong'。"
echo "进入后请使您可以使用 exit退出proot容器"

echo "安装配置完成。"
