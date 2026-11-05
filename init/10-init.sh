#!/bin/sh
# 每次创建容器都跑（幂等）。核心只预建数据目录本身（挂载源），工作目录是它里面的子目录，由这里建。
mkdir -p /data/workspace
# 工作区里放一个指向共享文件夹的软链接，资源管理器里点开就能用。
ln -sfn /documents /data/workspace/documents
# --disable-telemetry 只关 code-server 自己的；内核 product.json 的 enableTelemetry 仍是 true。
# 首次运行把内核遥测也关掉；用户自己的设置文件存在以后不再动。
settings=/data/user-data/User/settings.json
if [ ! -f "$settings" ]; then
  mkdir -p /data/user-data/User
  printf '{\n  "telemetry.telemetryLevel": "off"\n}\n' >"$settings"
fi
