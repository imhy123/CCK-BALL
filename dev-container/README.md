# 在zmk的Dev Container中编译本固件

## 1. 前置准备Docker Volume

```shell
docker volume create --driver local -o o=bind -o type=none \
    -o device="/path/to/CCK-BALL" zmk-config

# zmk-pmw3610-driver 放在 /path/to/zmk-modules/ 下

docker volume create --driver local -o o=bind -o type=none \
  -o device="/path/to/zmk-modules/" zmk-modules
```

## 2. 启动容器

启动容器后进入终端，首次需要west初始化一下：
```shell
west init -l app/ # Initialization
west update       # Update modules
```

## 3. 编译固件

在容器内执行该命令，最终生成的固件放在了本项目的 `dev-container/firmware/` 下：
```shell
bash /workspaces/zmk-config/dev-container/build_all.sh
```