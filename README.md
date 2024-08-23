# chroot-qinglong

在[releases](https://github.com/Fansirsqi/chroot-qinglong/releases)列表中你能看到压缩的镜像文件

`qinglong-latest.tar`

`qinglong-debian.tar`

以上两个分别对应`debian`和`alpine`

你可以在对应架构的linux中使用chroot运行他们

相关内容
```bash
xz -dc xxx | tar -xvf -C /rootfs
PNPM_HOME=/root/.local/share/pnpm
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/root/.local/share/pnpm:/root/.local/share/pnpm/global/5/node
NODE_PATH=/usr/local/bin:/usr/local/pnpm-global/5/node_modules:/usr/local/lib/node_modules:/root/.local/share/pnpm/global/5/nod
LANG=C.UTF-8
SHELL=/bin/bash
QL_DIR=/ql QL_BRANCH=debian

chroot /rootfs /usr/bin/env -i HOME=/root TMPDIR=/tmp PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin TERM=linux QL_DIR=/ql QL_BRANCH=debian /bin/bash

mount -t proc proc /proc

export PNPM_HOME=/root/.local/share/pnpm
export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/root/.local/share/pnpm:/root/.local/share/pnpm/global/5/node_modules:$PNPM_HOME
export NODE_PATH=/usr/local/bin:/usr/local/pnpm-global/5/node_modules:/usr/local/lib/node_modules:/root/.local/share/pnpm/global/5/node_modules
export LANG=C.UTF-8
export SHELL=/bin/bash
export QL_DIR=/ql
export QL_BRANCH=debian
source /ql/shell/share.sh
```
