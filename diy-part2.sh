#!/bin/bash
# DIY脚本
# https://github.com/P3TERX/Actions-OpenWrt
# 文件名: diy-part2.sh
# 功能说明: OpenWrt DIY脚本第2部分（更新feeds之后）
# 版权: (c) 2019-2024 P3TERX <https://p3terx.com>
# 基于 MIT 开源协议，详见 /LICENSE

# 修改默认IP地址
#sed -i 's/192.168.1.1/192.168.100.1/g' package/base-files/files/bin/config_generate


# 修改默认主题为 argon（路径不存在时跳过，不中断编译）
sed -i 's/luci-theme-bootstrap/luci-theme-argon/g' feeds/luci/collections/luci/Makefile 2>/dev/null || true


# ─────────────────────────────────────────────────────────────────────────
# 修复 libffi 缺失导致的 glib2 编译失败
#
# 背景：上游已把 libffi 从 packages feed 移入核心源码树（package/libs/libffi）。
#       本仓库 upstream_lock.txt 锁定的核心 hash 早于这次迁移，
#       而 feeds 是浮动的（跟随 immortalwrt/packages master），
#       于是两边都没有 libffi。glib2 的 glib2-gobject 打包时报
#       "Package glib2-gobject is missing dependencies ... libffi.so.8"，
#       glib2 编译失败 -> make world 失败 -> 没有 boot.img/system.img。
#
# 处理：仅当整棵树确实找不到 libffi 时，才从上游核心仓库补回，
#       避免将来核心 hash 更新后又出现重复包。
# ─────────────────────────────────────────────────────────────────────────
if ! find package feeds -path '*/libffi/Makefile' -print -quit | grep -q .; then
  echo "⚠️  整棵树未找到 libffi，从 immortalwrt 核心仓库补回 package/libs/libffi"
  rm -rf /tmp/libffi-src
  git clone --depth 1 --filter=blob:none --sparse \
    https://github.com/immortalwrt/immortalwrt.git /tmp/libffi-src \
    && git -C /tmp/libffi-src sparse-checkout set package/libs/libffi \
    && mkdir -p package/libs \
    && cp -a /tmp/libffi-src/package/libs/libffi package/libs/libffi \
    || { echo "::error::补回 libffi 失败，glib2 将无法编译"; exit 1; }
  rm -rf /tmp/libffi-src
  echo "✅ 已补回 libffi：$(ls package/libs/libffi)"
else
  echo "✅ 树中已有 libffi：$(find package feeds -path '*/libffi/Makefile' -print)"
fi

# USB OTG 角色切换插件
echo 'src-git usbrole https://github.com/wvivi5/luci-app-usbrole.git' >> feeds.conf.default
# 更新并安装 USB OTG 角色切换插件
#./scripts/feeds update usbrole
#./scripts/feeds install luci-app-usbrole

# 启用 IPv4 策略路由（直接写入内核 platform config，绕过 make defconfig 的依赖检查）
# CONFIG_KERNEL_IP_ADVANCED_ROUTER 在 OpenWrt Config.in 中无对应 wrapper，必须用此方式
#for cfg in target/linux/msm89xx/config-*; do
#  grep -q 'CONFIG_IP_ADVANCED_ROUTER' "$cfg" || echo 'CONFIG_IP_ADVANCED_ROUTER=y' >> "$cfg"
#  grep -q 'CONFIG_IP_MULTIPLE_TABLES' "$cfg" || echo 'CONFIG_IP_MULTIPLE_TABLES=y' >> "$cfg"
#done


# 临时添加的插件
# git clone https://github.com/lkiuyu/luci-app-cpu-perf package/luci-app-cpu-perf
# git clone https://github.com/lkiuyu/luci-app-cpu-status package/luci-app-cpu-status
# git clone https://github.com/gSpotx2f/luci-app-cpu-status-mini package/luci-app-cpu-status-mini
# git clone https://github.com/lkiuyu/luci-app-temp-status package/luci-app-temp-status
# git clone https://github.com/lkiuyu/DbusSmsForwardCPlus package/DbusSmsForwardCPlus
