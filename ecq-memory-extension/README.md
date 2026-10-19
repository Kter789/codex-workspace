# ECQ 本地记忆扩展

适用于 `https://chat.echenqi.cn` 的本地长期记忆扩展。记忆按“账号 + 智能体”隔离，保存在当前电脑的浏览器 IndexedDB，不上传平台服务器。

## 下载 v2.0.4

- 主下载地址（jsDelivr）：<https://cdn.jsdelivr.net/gh/Kter789/codex-workspace@main/ecq-memory-extension/ecq-memory-extension-v2.0.4.zip>
- 备用地址（GitHub Raw）：<https://raw.githubusercontent.com/Kter789/codex-workspace/main/ecq-memory-extension/ecq-memory-extension-v2.0.4.zip>
- 文件大小：61,349 字节
- SHA-256：`6b1254ce1d6d0a40e208c1183eb3a06b00068e5e7ad5aaa2379ca631466508a4`

## 安装方法（Microsoft Edge）

1. 下载并解压到一个固定目录，例如 `D:\ECQ\ecq-memory-extension`。这个目录以后不要删除。
2. 在 Edge 地址栏打开 `edge://extensions`。
3. 开启“开发人员模式”。
4. 点“加载解压缩的扩展”，选择直接包含 `manifest.json` 的文件夹。
5. 回到 <https://chat.echenqi.cn> 刷新页面。
6. 打开“AI记忆教练”，点标题上方的“打开记忆管理”。首次使用可先点扩展图标里的“刷新登录态”。

浏览器安全机制不允许网页静默安装扩展，因此需要手动加载。每台电脑安装一次；记忆不会跨电脑自动同步。

## 升级与迁移

- 升级：下载新版本，替换固定目录中的文件，到 `edge://extensions` 点“重新加载”。不要点“移除扩展”，以免本地记忆被清除。
- 迁移：在旧电脑点“打开记忆管理” → “导出 JSON”，在新电脑安装后点“导入备份”。
- 记忆范围：账号记忆、本机兜底记忆、不同智能体之间均互相隔离。

## 常见问题

- 看不到入口：确认扩展已启用、访问的是 `chat.echenqi.cn`，刷新页面并点“刷新登录态”。
- 加载失败：必须选择直接包含 `manifest.json` 的文件夹，不能选 zip 或上一层目录。
- 记忆不跨电脑：这是设计行为，平台服务器不保存扩展记忆；用导出/导入迁移。
