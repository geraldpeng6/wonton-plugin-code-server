# scripts/smoke.sh 的一项一项探测，跟着插件走。没写的项会 FAIL 并给出写法，不会默认放行。
#
# 页面：web_assert 从标准输入读页面，命中的确是应用的真实页面时返回 0。
# 身份：identity_check 用应用自己的“当前用户”接口断言认出的是用户管理员。没有用户体系时写 IDENTITY_NA=1，
#       并在 SMOKE_NOTE 里写原因。dweb / web_get 是带用户会话的请求助手，可继续走应用自己的登录链。
# 工具：MCP_TOOL 写一个只读工具名（可带插件前缀），MCP_ARGS 是 JSON 参数；mcp_assert 从标准输入读调用结果。
#       要断言多个工具时改成写 mcp_check；调用前要备数据时写 before_mcp。
# 装之前要准备（如先配出口代理）：写 before_install。

# code-server：应用自己的认证已关（--auth none），没有用户体系，入口只靠核心网关挡（匿名请求到不了插件，
# 由冒烟的“网关没拒绝匿名请求”断言验证）；清单没有 mcp。
SSO=none
MCP=0
IDENTITY_NA=1
SMOKE_NOTE="应用自己的认证已关（--auth none），没有用户体系；身份项不适用，网关把关由匿名请求断言验证"

web_assert() { grep -qi 'code-server'; }   # 工作台页面的 HTML 自带 code-server 字样
