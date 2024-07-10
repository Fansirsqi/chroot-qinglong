#!/bin/bash

export rootfs=/rootfs

# 检查文件并解压相应的tar文件
if [ -f "qinglong-debian.tar" ]; then
  tar -xvf qinglong-debian.tar
  QL_BRANCH="debian"
elif [ -f "qinglong-latest.tar" ]; then
  tar -xvf qinglong-latest.tar
  QL_BRANCH="master"
else
  echo "文件不存在，退出脚本"
  exit 1
fi

# 绑定必要的文件系统
mount --bind /etc/resolv.conf /$rootfs/etc/resolv.conf
mount --bind /etc/hosts /$rootfs/etc/hosts
mount --bind /sys /$rootfs/sys
mount --bind /proc /$rootfs/proc
mount --bind /dev /$rootfs/dev
mount --bind /proc/sys/net /$rootfs/proc/sys/net
mount --bind /proc/net /$rootfs/proc/net
mount --bind /sys/class/net /$rootfs/sys/class/net

# 在chroot环境中执行命令
chroot $rootfs /usr/bin/env -i HOME=/root TMPDIR=/tmp PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin TERM=linux /bin/bash <<EOF
  export PNPM_HOME=/root/.local/share/pnpm \
  PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/root/.local/share/pnpm:/root/.local/share/pnpm/global/5/node_modules:\$PNPM_HOME \
  NODE_PATH=/usr/local/bin:/usr/local/pnpm-global/5/node_modules:/usr/local/lib/node_modules:/root/.local/share/pnpm/global/5/node_modules \
  LANG=C.UTF-8 \
  SHELL=/bin/bash \
  QL_DIR=/ql \
  QL_BRANCH=$QL_BRANCH
  cd /ql && /ql/docker/docker-entrypoint.sh
EOF

chroot $rootfs /bin/bash <<EOF
  ql check
EOF

chroot $rootfs /usr/bin/env -i HOME=/root TMPDIR=/tmp PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin TERM=linux /bin/bash
