#!/bin/bash

mkdir -p files/etc/openclash/core

CLASH_DEV_URL="https://raw.githubusercontent.com/vernesong/OpenClash/core/dev/meta/clash-linux-${1}.tar.gz"
CLASH_DEV_SMART_URL="https://raw.githubusercontent.com/vernesong/OpenClash/core/dev/smart/clash-linux-${1}.tar.gz"

CLASH_META_URL="https://raw.githubusercontent.com/vernesong/OpenClash/core/master/meta/clash-linux-${1}.tar.gz"
CLASH_META_SMART_URL="https://raw.githubusercontent.com/vernesong/OpenClash/core/master/smart/clash-linux-${1}.tar.gz"

GEOIP_URL="https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/geoip.dat"
GEOSITE_URL="https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/geosite.dat"

# wget -qO- $CLASH_DEV_URL | tar xOvz > files/etc/openclash/core/clash
# wget -qO- $CLASH_DEV_SMART_URL | tar xOvz > files/etc/openclash/core/clash
# wget -qO- $CLASH_META_URL | tar xOvz > files/etc/openclash/core/clash
wget -qO- $CLASH_META_SMART_URL | tar xOvz > files/etc/openclash/core/clash
wget -qO- $GEOIP_URL > files/etc/openclash/GeoIP.dat
wget -qO- $GEOSITE_URL > files/etc/openclash/GeoSite.dat

chmod +x files/etc/openclash/core/clash*
