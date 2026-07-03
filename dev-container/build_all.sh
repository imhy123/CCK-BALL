#!/usr/bin/env bash
# 在 zmk dev container 里运行：bash /workspaces/zmk-config/dev-container/build_all.sh
# 依次编译 CCK-BALL 的 左手 / 右手 / settings_reset 三个固件，
# 产物 .uf2 复制到 /workspaces/zmk-config/dev-container/firmware（= 宿主机 CCK-BALL/dev-container/firmware）。
set -euo pipefail

BOARD=nice_nano_v2
ZMK_CONFIG=/workspaces/zmk-config/config
EXTRA_MODULES=/workspaces/zmk-modules/zmk-pmw3610-driver
OUT=/workspaces/zmk-config/dev-container/firmware

mkdir -p "$OUT"
cd /workspaces/zmk

build() {
  local name="$1"; shift
  local bdir="/tmp/build-$name"
  echo "==================== Building $name ===================="
  west build -s app -d "$bdir" -b "$BOARD" -p "$@"
  cp "$bdir/zephyr/zmk.uf2" "$OUT/${name}-${BOARD}-zmk.uf2"
}

# 左手（peripheral）
build cck_ball_left -- \
  -DSHIELD=cck_ball_left \
  -DZMK_CONFIG="$ZMK_CONFIG" \
  -DZMK_EXTRA_MODULES="$EXTRA_MODULES"

# 右手（central，带 Studio + studio snippet）
build cck_ball_right -S studio-rpc-usb-uart -- \
  -DSHIELD=cck_ball_right \
  -DZMK_CONFIG="$ZMK_CONFIG" \
  -DZMK_EXTRA_MODULES="$EXTRA_MODULES" \
  -DCONFIG_ZMK_STUDIO=y

# settings_reset（刷它清空蓝牙配对 / settings）
build settings_reset -- \
  -DSHIELD=settings_reset \
  -DZMK_CONFIG="$ZMK_CONFIG" \
  -DZMK_EXTRA_MODULES="$EXTRA_MODULES"

echo
echo "==================== Done ===================="
ls -l "$OUT"
