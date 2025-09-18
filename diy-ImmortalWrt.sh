#!/bin/bash

# 修改版本为编译日期，数字类型。
date_version=$(date +"%Y%m%d%H")
echo $date_version > version

# 为固件版本加上编译作者
author="Wigmox"
sed -i "s/DISTRIB_DESCRIPTION.*/DISTRIB_DESCRIPTION='%D %V ${date_version} by ${author}'/g" package/base-files/files/etc/openwrt_release
sed -i "s/OPENWRT_RELEASE.*/OPENWRT_RELEASE=\"%D %V ${date_version} by ${author}\"/g" package/base-files/files/usr/lib/os-release

# 修改默认IP
sed -i 's/192.168.1.1/10.0.0.1/g' package/base-files/files/bin/config_generate

# 更改默认 Shell 为 zsh
# sed -i 's/\/bin\/ash/\/usr\/bin\/zsh/g' package/base-files/files/etc/passwd

# TTYD 免登录
sed -i 's|/bin/login|/bin/login -f root|g' feeds/packages/utils/ttyd/files/ttyd.config

# 80_mount_root 添加挂载目录
# 这个脚本用于在package/base-files/files/lib/preinit/80_mount_root文件中的do_mount_root函数内添加resize2fs命令
# 使用sed命令在do_mount_root() {之后添加resize2fs命令
sed -i '/^do_mount_root() {/a\	resize2fs /dev/mmcblk0p1\
	resize2fs /dev/mmcblk0p2\
	resize2fs /dev/mmcblk0p3\
	resize2fs /dev/mmcblk0p4\
	resize2fs /dev/mmcblk0p5' "package/base-files/files/lib/preinit/80_mount_root"


# firstboot 添加删除 overlay 目录命令
sed -i '/^#!\/bin\/sh/a\rm -rf /overlay/*' package/base-files/files/sbin/firstboot

# boot Makefile 添加机型

sed -i '/^# RK3568 boards$/a\
\
define U-Boot/nsy-g16-plus-rk3568\
  $(U-Boot/rk3568/Default)\
  NAME:=NSY G16 PLUS\
  BUILD_DEVICES:= \\\
    nsy_g16-plus\
endef' package/boot/uboot-rockchip/Makefile

sed -i '/^# RK3568 boards$/a\
\
define U-Boot/nsy-g68-plus-rk3568\
  $(U-Boot/rk3568/Default)\
  NAME:=NSY G68 PLUS\
  BUILD_DEVICES:= \\\
    nsy_g68-plus\
endef' package/boot/uboot-rockchip/Makefile

sed -i '/^# RK3568 boards$/a\
\
define U-Boot/bdy-g18-pro-rk3568\
  $(U-Boot/rk3568/Default)\
  NAME:=BDY G18 PRO\
  BUILD_DEVICES:= \\\
    bdy_g18-pro\
endef' package/boot/uboot-rockchip/Makefile

sed -i '/^UBOOT_TARGETS := \\/a\
  nsy-g16-plus-rk3568 \\\
  nsy-g68-plus-rk3568 \\\
  bdy-g18-pro-rk3568 \\' package/boot/uboot-rockchip/Makefile

# package/kernel/mt76/Makefile 修改wifi固件信息
sed -i '/[ \t]*\$([^)]*PKG_BUILD_DIR[^)]*)\/firmware\/mt7615_rom_patch\.bin[ \t]*\\$/a\
		.\/firmware\/mt7615e_rf.bin \\' package/kernel/mt76/Makefile
# 验证
sed -n '/[ \t]*$(PKG_BUILD_DIR)\/firmware\/mt7615_rom_patch.bin[ \t]*\\$/{p;n;p}' package/kernel/mt76/Makefile

sed -i '/[ \t]*$(PKG_BUILD_DIR)\/firmware\/mt7916_wa.bin[ \t]*\\$/c\
		.\/firmware\/mt7916_wa.bin \\' package/kernel/mt76/Makefile
sed -i '/[ \t]*$(PKG_BUILD_DIR)\/firmware\/mt7916_wm.bin[ \t]*\\$/c\
		.\/firmware\/mt7916_wm.bin \\' package/kernel/mt76/Makefile
sed -i '/[ \t]*$(PKG_BUILD_DIR)\/firmware\/mt7916_rom_patch.bin[ \t]*\\$/c\
		.\/firmware\/mt7916_rom_patch.bin \\' package/kernel/mt76/Makefile
sed -i '/[ \t]*\.\/firmware\/mt7916_rom_patch\.bin[ \t]*\\$/a\
		.\/firmware\/mt7916_eeprom.bin \\' package/kernel/mt76/Makefile

# target/linux/generic/config-6.6，config-6.12 启用 WIFI

CONFIGS6=("target/linux/generic/config-6.6" "target/linux/generic/config-6.12")

for cfg in "${CONFIGS6[@]}"; do
    if [ ! -f "$cfg" ]; then
        echo "[跳过] 文件不存在: $cfg" >&2
        continue
    fi
    
    sed -i -e 's/^# CONFIG_WEXT_CORE is not set$/CONFIG_WEXT_CORE=y/' \
           -e 's/^# CONFIG_WEXT_PRIV is not set$/CONFIG_WEXT_PRIV=y/' \
           -e 's/^# CONFIG_WEXT_PROC is not set$/CONFIG_WEXT_PROC=y/' \
           -e 's/^# CONFIG_WEXT_SPY is not set$/CONFIG_WEXT_SPY=y/' \
           -e 's/^# CONFIG_WIRELESS_EXT is not set$/CONFIG_WIRELESS_EXT=y/' "$cfg" && 
echo "[成功] 已修改: $cfg" || echo "[失败] 修改出错: $cfg"
done

# target/linux/rockchip/armv8/config-6.6 ，config-6.12启用 CONFIG_SWCONFIG=y

CONFIG_DIR="target/linux/rockchip/armv8"
CONFIG_PATTERN="$CONFIG_DIR/config-*"

for cfg in $CONFIG_PATTERN; do
    [ -f "$cfg" ] || continue
    
    if grep -q '^# CONFIG_SWCONFIG is not set$' "$cfg"; then
        sed -i 's/^# CONFIG_SWCONFIG is not set$/CONFIG_SWCONFIG=y/' "$cfg"
        echo "[替换] $cfg: 已修改禁用配置"
    elif ! grep -q '^CONFIG_SWCONFIG=' "$cfg"; then
        echo "CONFIG_SWCONFIG=y" >> "$cfg"
        echo "[追加] $cfg: 已添加新配置"
    else
        echo "[保持] $cfg: 配置已存在"
    fi
done

# 添加机型

# 增加nsy_g68-plus
echo -e "\\ndefine Device/nsy_g68-plus
  DEVICE_VENDOR := NSY
  DEVICE_MODEL := G68-PLUS
  SOC := rk3568
  DEVICE_DTS := rockchip/rk3568-nsy-g68-plus
  UBOOT_DEVICE_NAME := nsy-g68-plus-rk3568
  BOOT_FLOW := pine64-img
  DEVICE_PACKAGES := kmod-mt7916-firmware kmod-switch-rtl8367b wpad-openssl
endef
TARGET_DEVICES += nsy_g68-plus" >> target/linux/rockchip/image/armv8.mk


# 增加nsy_g16-plus
echo -e "\\ndefine Device/nsy_g16-plus
  DEVICE_VENDOR := NSY
  DEVICE_MODEL := G16-PLUS
  SOC := rk3568
  DEVICE_DTS := rockchip/rk3568-nsy-g16-plus
  UBOOT_DEVICE_NAME := nsy-g16-plus-rk3568
  BOOT_FLOW := pine64-img
  DEVICE_PACKAGES := kmod-mt7615-firmware kmod-switch-rtl8367b wpad-openssl
endef
TARGET_DEVICES += nsy_g16-plus" >> target/linux/rockchip/image/armv8.mk


# 增加bdy_g18-pro
echo -e "\\ndefine Device/bdy_g18-pro
  DEVICE_VENDOR := BDY
  DEVICE_MODEL := G18-PRO
  SOC := rk3568
  DEVICE_DTS := rockchip/rk3568-bdy-g18-pro
  UBOOT_DEVICE_NAME := bdy-g18-pro-rk3568
  BOOT_FLOW := pine64-img
  DEVICE_PACKAGES := kmod-mt7615-firmware kmod-switch-rtl8367b wpad-openssl
endef
TARGET_DEVICES += bdy_g18-pro" >> target/linux/rockchip/image/armv8.mk


# 下载 openclash 内核文件 
    mkdir target/linux/rockchip/armv8/base-files/etc/openclash/core
    # Download clash_meta
    META_URL="https://raw.githubusercontent.com/vernesong/OpenClash/core/master/meta/clash-linux-arm64.tar.gz"
    wget -qO- $META_URL | tar xOvz > target/linux/rockchip/armv8/base-files/etc/openclash/core/clash_meta
    chmod +x target/linux/rockchip/armv8/base-files/etc/openclash/core/clash_meta
    # Download GeoIP and GeoSite
    wget -q https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/geoip.dat -O target/linux/rockchip/armv8/base-files/etc/openclash/GeoIP.dat
    # wget -q https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/geosite.dat -O target/linux/rockchip/armv8/base-files/etc/openclash/GeoSite.dat

# 拉取仓库文件夹
merge_package() {
	# 参数1是分支名,参数2是库地址,参数3是所有文件下载到指定路径。
	# 同一个仓库下载多个文件夹直接在后面跟文件名或路径，空格分开。
	# 示例:
	# merge_package master https://github.com/WYC-2020/openwrt-packages package/openwrt-packages luci-app-eqos luci-app-openclash luci-app-ddnsto ddnsto 
	# merge_package master https://github.com/lisaac/luci-app-dockerman package/lean applications/luci-app-dockerman
	
	# 应用过滤（OpenAppFilter）
	merge_package master https://github.com/destan19/OpenAppFilter package/OpenAppFilter luci-app-oaf oaf open-app-filter
	
	if [[ $# -lt 3 ]]; then
		echo "Syntax error: [$#] [$*]" >&2
		return 1
	fi
	trap 'rm -rf "$tmpdir"' EXIT
	branch="$1" curl="$2" target_dir="$3" && shift 3
	rootdir="$PWD"
	localdir="$target_dir"
	[ -d "$localdir" ] || mkdir -p "$localdir"
	tmpdir="$(mktemp -d)" || exit 1
        echo "开始下载：$(echo $curl | awk -F '/' '{print $(NF)}')"
	git clone -b "$branch" --depth 1 --filter=blob:none --sparse "$curl" "$tmpdir"
	cd "$tmpdir"
	git sparse-checkout init --cone
	git sparse-checkout set "$@"
	# 使用循环逐个移动文件夹
	for folder in "$@"; do
		mv -f "$folder" "$rootdir/$localdir"
	done
	cd "$rootdir"
}

# Git稀疏克隆，只克隆指定目录到本地
function git_sparse_clone() {
  branch="$1" repourl="$2" && shift 2
  git clone --depth=1 -b $branch --single-branch --filter=blob:none --sparse $repourl
  repodir=$(echo $repourl | awk -F '/' '{print $(NF)}')
  cd $repodir && git sparse-checkout set $@
  mv -f $@ ../package
  cd .. && rm -rf $repodir
}



# Themes
# git clone --depth=1 -b 18.06 https://github.com/jerrykuku/luci-theme-argon package/luci-theme-argon
# git clone --depth=1 https://github.com/jerrykuku/luci-app-argon-config package/luci-app-argon-config
# merge_package master https://github.com/coolsnowwolf/luci feeds/luci/themes themes/luci-theme-design


# 更改 Argon 主题背景
rm -rf feeds/luci/themes/luci-theme-argon/htdocs/luci-static/argon/background/*
# cp -f $GITHUB_WORKSPACE/images/bg1.jpg feeds/luci/themes/luci-theme-argon/htdocs/luci-static/argon/img/bg1.jpg
# mkdir -p package/luci-theme-argon/htdocs/luci-static/argon/img
# cp -f $GITHUB_WORKSPACE/images/bg1.jpg package/luci-theme-argon/htdocs/luci-static/argon/img/bg1.jpg


# iStore
# git_sparse_clone main https://github.com/linkease/istore-ui app-store-ui
# git_sparse_clone main https://github.com/linkease/istore luci


# 修改 Makefile
# find package/*/ -maxdepth 2 -path "*/Makefile" | xargs -i sed -i 's/..\/..\/luci.mk/\$(TOPDIR)\/feeds\/luci\/luci.mk/g' {}
# find package/*/ -maxdepth 2 -path "*/Makefile" | xargs -i sed -i 's/..\/..\/lang\/golang\/golang-package.mk/\$(TOPDIR)\/feeds\/packages\/lang\/golang\/golang-package.mk/g' {}
# find package/*/ -maxdepth 2 -path "*/Makefile" | xargs -i sed -i 's/PKG_SOURCE_URL:=@GHREPO/PKG_SOURCE_URL:=https:\/\/github.com/g' {}
# find package/*/ -maxdepth 2 -path "*/Makefile" | xargs -i sed -i 's/PKG_SOURCE_URL:=@GHCODELOAD/PKG_SOURCE_URL:=https:\/\/codeload.github.com/g' {}


# samba解除root限制
# sed -i 's/invalid users = root/#&/g' feeds/packages/net/samba4/files/smb.conf.template


# 最大连接数修改为65535
sed -i '/customized in this file/a net.netfilter.nf_conntrack_max=65535' package/base-files/files/etc/sysctl.conf


# 定时限速插件
git clone --depth=1 https://github.com/sirpdboy/luci-app-eqosplus package/luci-app-eqosplus


./scripts/feeds update -a
./scripts/feeds install -a
