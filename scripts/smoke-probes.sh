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

# 数据：工作目录、扩展、用户设置都在插件数据目录（docker-compose.yml 的 ${WONTON_APP_DATA}:/data）。
# data_write 在容器里往数据目录落一个标记文件（工作区就是用户文件的目录），data_check 在升级、
# 重装后读回比对；标记文件名固定、内容带随机令牌，重复运行覆盖写。
_cs_container() { printf 'wonton-%s--%s--code-server' "${SMOKE_INSTANCE:-}" "${SMOKE_SLUG:-}"; }

_cs_marker_file() { # 标记文件：SMOKE_STATE 在 dev.sh probes 里是目录，目录里放标记文件
  if [[ -d "${SMOKE_STATE:-}" ]]; then printf '%s/data-marker' "$SMOKE_STATE"; else printf '%s' "${SMOKE_STATE:-}"; fi
}

data_write() {
  local container token out
  container="$(_cs_container)"
  token="wonton-smoke-$(od -An -N8 -tx1 /dev/urandom | tr -d ' \n')"
  docker exec "$container" sh -c "printf 'wonton-smoke %s\n' '$token' > /data/wonton-smoke-marker" ||
    { echo "往 $container:/data 写标记失败"; return 1; }
  out="$(docker exec "$container" cat /data/wonton-smoke-marker)" || { echo "标记写完读不回"; return 1; }
  grep -qF "$token" <<<"$out" || { echo "标记读回对不上：$out"; return 1; }
  printf '%s' "$token" >"$(_cs_marker_file)" || { echo "写不进标记文件"; return 1; }
}

data_check() {
  local container token out
  container="$(_cs_container)"
  token="$(cat "$(_cs_marker_file)" 2>/dev/null)" || true
  [[ -n "$token" ]] || { echo "没有 data_write 留下的标记（SMOKE_STATE=${SMOKE_STATE:-未设置}）"; return 1; }
  out="$(docker exec "$container" cat /data/wonton-smoke-marker 2>/dev/null)" ||
    { echo "标记文件没了：$container:/data/wonton-smoke-marker 读不回"; return 1; }
  grep -qF "$token" <<<"$out" || { echo "标记内容对不上：$(head -c 120 <<<"$out")"; return 1; }
  echo "数据目录里的标记还在（wonton-smoke $token）"
}
