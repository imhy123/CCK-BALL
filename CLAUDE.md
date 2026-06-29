# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

> 本仓库是 **CCK_BALL（4x6 分体无线键盘）的 ZMK user-config**：它不包含固件源码，只描述这块键盘的硬件（shield）、键位（keymap）和编译配置。固件源码在另一个工作目录 `../zmk`（imhy123 的 fork），那里有自己的 `CLAUDE.md`，凡是改动驱动 / 固件 C 代码的任务都去那边看。说明用中文。

## 这个仓库怎么被编译

正常流程是 **完全自动**的，不需要本地构建：

1. 键位一般通过 web 版开源编辑器（ZMK keymap editor / ZMK Studio）在线修改，自动推送到 GitHub。
2. `.github/workflows/build.yml` 在每次 push 时触发，复用 `zmkfirmware/zmk` 的 `build-user-config.yml@v0.3-branch`。
3. 实际的 ZMK 固件源 **不是 upstream**，而是 `config/west.yml` 里指定的 fork：
   - `zmk` ← `imhy123/zmk`，revision `v0.3-branch`（含 EC11 改动）
   - `zmk-pmw3610-driver` ← `DoctorWangWang/zmk-pmw3610-driver`，revision `main`（trackball 驱动）
4. 产物是每个 board+shield 的 `.uf2`，从 Actions 的 artifact 下载后刷入。

**关键点**：要改固件行为（比如 EC11 编码器驱动），改 `../zmk` 那个 fork 并推送它的 `v0.3-branch`；本仓库的 CI 会自动拉取新的 commit 重新编译。本仓库只能改 shield/keymap/conf 这些「配置」层面的东西。

### 本地构建（一般用不到，调试时才用）

```sh
# 在本仓库上一级目录，把 config/ 作为 manifest
west init -l CCK-BALL/config
west update
west zephyr-export
# 构建右手（central，带 trackball + studio）
west build -s zmk/app -b nice_nano_v2 -- -DSHIELD=cck_ball_right -DCONFIG_ZMK_STUDIO=y
```

`build.yaml`（注意是 GitHub Actions 矩阵文件，不是 `build.yml` workflow）定义了三个构建目标：`cck_ball_left`、`cck_ball_right`（带 `studio-rpc-usb-uart zmk-usb-logging` snippet 和 `CONFIG_ZMK_STUDIO=y`）、`settings_reset`（刷它可清空蓝牙配对 / settings）。

## Shield 架构（`config/boards/shields/cck_ball/`）

分体键盘，**右手是 central**（`Kconfig.defconfig` 里 `ZMK_SPLIT_BLE_ROLE_CENTRAL=y`），左手是 peripheral。

- `cck_ball.dtsi` —— 两手共享：5 行 × 12 列 matrix transform、kscan 的 row-gpios、以及两个 EC11 encoder（默认 `status="disabled"`）和 `keymap-sensors`。
- `cck_ball_right.overlay` —— 右手独有：col-gpios（带 `col-offset=6`）、**PMW3610 trackball**（SPI0，`scroll-layers=3` / `snipe-layers=4`）、WS2812 RGB（SPI3，27 颗灯）、并 `&right_encoder { status = "okay"; }`。
- `cck_ball_left.overlay` —— 左手：col-gpios、WS2812 RGB（29 颗灯）、`&left_encoder { status = "okay"; }`。
- `*.conf` 三层叠加：`config/cck_ball.conf`（两手都生效，开 EC11、studio、pointing 等）→ `cck_ball_left.conf` / `cck_ball_right.conf`（单手覆盖，右手开 SPI / PMW3610 / EXT_POWER）。
- `cck_ball.json` 是给 web 编辑器用的物理布局；改了实体布局才需要动它。

## EC11 编码器 —— 当前是「坏」的状态

这是这块键盘最大的坑，也是把 `../zmk` 加进 workspace 的原因：

- 滚轮是第三方 EC11 兼容件（疑似来自某种鼠标滚轮），ZMK 自带 EC11 驱动兼容不好（「慢」/「抖」/一格多触发）。
- 1 月起在 fork 的 `v0.3-branch` 上尝试修改驱动（新增 `pulses-per-detent`、`debounce-us` 两个 DT 属性做去抖/滤波），**至今未修好**：当前固件刷进去后键盘直接无响应。
- 调这个问题的主战场是 `../zmk`（看它的 `CLAUDE.md` 的「在途修改」章节）。本仓库这边相关的旋钮在 `cck_ball.dtsi` 的 encoder 节点：`steps`、`pulses-per-detent`、`debounce-us`，以及 `sensors` 的 `triggers-per-rotation`。
- 约束：`steps` 要设成 `triggers-per-rotation` 的 2 或 4 倍（见 dtsi 注释 / zmk issue #2666）。当前两者都是 24。
- 编码器行为（滚动方向等）定义在 `config/cck_ball.keymap` 顶部的 `scroll_vertical_encoder` / `scroll_horizontal_encoder`。

## 键位（`config/cck_ball.keymap`）

标准 ZMK keymap。文件开头用 `&mmv` / `&msc` / `zip_*_scaler` 调 trackball 的鼠标移动和滚动手感，并定义 combos 和编码器行为。绝大多数日常改动来自 web 编辑器的自动提交，手改时保持它能被编辑器重新解析（不要引入编辑器无法回读的结构）。
