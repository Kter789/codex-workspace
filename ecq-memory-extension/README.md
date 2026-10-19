# ECQ 本地记忆扩展

适用于 `https://chat.echenqi.cn` 的本地长期记忆扩展。同一账号下所有智能体共享记忆；不同账号、不同电脑严格隔离。记忆保存在当前电脑的浏览器 IndexedDB，不上传平台服务器。

## 下载 v2.0.8

- 推荐下载地址（国内可用）：<https://ghfast.top/https://raw.githubusercontent.com/Kter789/codex-workspace/main/ecq-memory-extension/ecq-memory-extension-v2.0.8.zip>
- 备用地址：<https://ghproxy.net/https://raw.githubusercontent.com/Kter789/codex-workspace/main/ecq-memory-extension/ecq-memory-extension-v2.0.8.zip>
- 文件大小：67,032 字节
- SHA-256：`c9da7c4c3b3c1aa6839e6b0b126ca9611b5ef3f5b5fd17d3d1adf6f92a9cb0dd`

> v2.0.8：管理员可在“本地记忆管理”里直接看到普通学员账号名单，点击账号即可只读查看这台电脑保存的该学员记忆；名单自动排除管理员账号，普通用户看不到该名单。查看学员时隐藏备份与清理，不能切换到本机记忆。

> v2.0.7：修复新建对话页两个入口反复重排导致的闪烁；修复安装页内联脚本被浏览器 CSP 拦截的问题。

> jsDelivr 在部分网络下无法访问，不再作为主下载地址。

## 安装方法（Microsoft Edge）

入口：在“AI记忆教练”标题上方点「下载 / 安装扩展」按钮，可直接打开下载与安装说明页。

1. 下载压缩包并解压到一个固定目录，例如 `D:\ECQ\ecq-memory-extension`。压缩包里就是 `ecq-memory-extension` 文件夹，`manifest.json` 在文件夹第一层。这个目录以后不要删除。
2. 在 Edge 地址栏打开 `edge://extensions`。
3. 开启“开发人员模式”。
4. 点“加载解压缩的扩展”，选择直接包含 `manifest.json` 的文件夹。
5. 回到 <https://chat.echenqi.cn> 刷新页面。
6. 打开“AI记忆教练”，点标题上方的“打开记忆管理”。首次使用可先点扩展图标里的“刷新登录态”。

浏览器安全机制不允许网页静默安装扩展，因此需要手动加载。每台电脑安装一次；记忆不会跨电脑自动同步。

## 管理员查看学员记忆

1. 用管理员账号登录 `chat.echenqi.cn`，打开“AI记忆教练”上方“打开记忆管理”。
2. 页面顶部会出现“学员账号”，只显示普通学员，不显示管理员。
3. 点击任一学员，进入只读查看；点“返回我的账号”恢复自己的记忆。
4. 只能看到这台电脑浏览器里保存的记忆。学员在其他电脑上的记忆不会上传，需让学员导出 JSON 后导入查看。
## 升级与迁移

- 升级：下载新版本，替换固定目录中的文件，到 `edge://extensions` 点“重新加载”。不要点“移除扩展”，以免本地记忆被清除。
- 迁移：在旧电脑点“打开记忆管理” → “导出 JSON”，在新电脑安装后点“导入备份”。
- 记忆范围：同一账号下全智能体共享；不同账号、不同电脑严格隔离。

## 常见问题

- 看不到入口：确认扩展已启用、访问的是 `chat.echenqi.cn`，刷新页面并点“刷新登录态”。
- 加载失败：必须选择直接包含 `manifest.json` 的文件夹，不能选 zip 或上一层目录。
- 记忆不跨电脑：这是设计行为，平台服务器不保存扩展记忆；用导出/导入迁移。
