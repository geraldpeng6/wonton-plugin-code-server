# 云吞插件：code-server

开发流程见[插件开发指南](https://github.com/geraldpeng6/wonton-docs/blob/main/develop.md)。

code-server（[coder.com](https://coder.com)，MIT）是网页版 VS Code。这个插件把它装进云吞：应用自己的登录已关
（`--auth none`），网页只由核心网关挡着；工作目录、扩展和设置都在插件数据目录里，重建后还在；共享文件夹 `documents`
以读写挂载，工作区里有指向它的软链接。

## 图标来源与许可

`icon.png` 取自 code-server 4.145.0 的官方应用图标（src/browser/media/pwa-icon-512.png），合成在 `#111111`
纯色底上，未用图片模型生成；来源、版权、处理方式、上游 MIT 全文和商标说明见 [NOTICE](NOTICE)。

该标志为 Coder Technologies Inc. 及其权利人的商标，仅用于识别本插件所集成的应用；本插件不代表 code-server
或 Coder 官方，也不表示获得其合作、认可或背书。

## 先跑起来

```bash
scripts/dev.sh up
scripts/dev.sh install
```

`up` 在本机起一套云吞，打印它的地址。浏览器打开，用 `scripts/dev.sh token` 输出的用户令牌登录；`install` 先列出
插件要的权限，确认后装上，打印插件网页的地址。

打开插件网页就是 VS Code 工作台：应用自己的登录已关，入口只过核心网关的登录。Chrome、Firefox 和 curl 把
`*.localhost` 直接解析到本机，不用改 hosts。

## 仓库里有什么

| 路径 | 内容 |
| --- | --- |
| `docker-compose.yml` | 插件本身：compose 加上 `x-wonton` 清单 |
| `icon.png`、`init/` | 清单和 compose 引用的文件：图标、交给容器的初始化脚本 |
| `screenshots/` | 商店详情页里的截图 |
| `scripts/check.sh` | 检查插件包，规则和安装时一样 |
| `scripts/dev.sh` | 开发环境：起一套云吞，装、重装、卸载插件，看日志 |
| `scripts/smoke-probes.sh` | `scripts/dev.sh smoke` 对这个插件逐项的探测 |
| `scripts/publish.sh` | 发布一个版本：打 tag、推送；`images/` 里有自己构建的镜像时先构建、推送并按摘要写回（示例没有） |
| `AGENTS.md` | 给人和 AI 编程代理的规则 |
| `LICENSE` | 插件包自己的许可证 |
| `NOTICE` | 图标等第三方素材的许可和声明 |
| `.wonton/` | 开发环境的设置、密钥和数据，不提交 |
