# scripts/smoke.sh 的一项一项探测，跟着插件走。没写的项会 FAIL 并给出写法，不会默认放行。
#
# 页面：web_assert 从标准输入读页面，命中的确是应用的真实页面时返回 0。
# 身份：identity_check 用应用自己的“当前用户”接口断言认出的是用户管理员。没有用户体系时写 IDENTITY_NA=1，
#       并在 SMOKE_NOTE 里写原因。dweb / web_get 是带用户会话的请求助手，可继续走应用自己的登录链。
# 工具：MCP_TOOL 写一个只读工具名（可带插件前缀），MCP_ARGS 是 JSON 参数；mcp_assert 从标准输入读调用结果。
#       要断言多个工具时改成写 mcp_check；调用前要备数据时写 before_mcp。
# 装之前要准备（如先配出口代理）：写 before_install。

# shellcheck shell=bash
# code-server：应用自己的认证已关（--auth none），没有用户体系，入口只靠核心网关挡（匿名请求到不了插件，
# 由冒烟的“网关没拒绝匿名请求”断言验证）；清单没有 mcp。
# 两个变量都由 scripts/smoke.sh source 后读取。
# shellcheck disable=SC2034
IDENTITY_NA=1
# shellcheck disable=SC2034
SMOKE_NOTE="应用自己的认证已关（--auth none），没有用户体系；身份项不适用，网关把关由匿名请求断言验证"

web_assert() { grep -qi 'code-server'; }   # 工作台页面的 HTML 自带 code-server 字样

# 数据：code-server 的用户数据就是 /data 卷本身（工作区、设置、扩展），应用没有写文件的 API；
# 按身份探针的先例进容器，在工作区放一个标记文件、重装后读回——验证的正是"重建后还在"的
# 数据卷映射契约（重装保留 ${WONTON_APP_DATA}，init 脚本幂等不清工作区）。
cs_container() { printf 'wonton-%s--%s--code-server' "${SMOKE_INSTANCE:-${E2E_INSTANCE:?}}" "${SMOKE_SLUG:-${E2E_SLUG:?}}"; }
cs_marker() { [[ -d "$SMOKE_STATE" ]] && printf '%s/data-marker' "$SMOKE_STATE" || printf '%s' "$SMOKE_STATE"; }

data_write() {
  local marker value
  marker="$(cs_marker)"
  value="wonton-smoke-$(date +%s)-$RANDOM"
  docker exec "$(cs_container)" sh -c "printf '%s\n' '$value' > /data/workspace/wonton_smoke_marker.txt" ||
    { echo "写不进工作区" >&2; return 1; }
  docker exec "$(cs_container)" cat /data/workspace/wonton_smoke_marker.txt >"$marker" ||
    { echo "读不回刚写的标记" >&2; return 1; }
  [[ -s "$marker" ]] || { echo "标记是空的" >&2; return 1; }
}

data_check() {
  local marker written now
  marker="$(cs_marker)"
  written="$(cat "$marker" 2>/dev/null)" || { echo "读不到标记文件（data_write 没跑过？）" >&2; return 1; }
  now="$(docker exec "$(cs_container)" cat /data/workspace/wonton_smoke_marker.txt 2>/dev/null)" ||
    { echo "重装后工作区里没有标记文件" >&2; return 1; }
  [[ "$now" == "$written" ]] || { echo "标记对不上：写了 $written，读到 $now" >&2; return 1; }
}
