# codex-workspace

所有代码/项目仓库的**统一根目录**与**换机恢复用**的配置仓库。

## 目录约定

```
C:\Users\<你>\Projects\          <- 所有 git 仓库都放这里
├─ codex-workspace\              <- 本仓库：换机恢复脚本 + 仓库清单
│  └─ setup\
│     ├─ setup-new-device.cmd    <- 双击运行（换机第一步）
│     ├─ setup-new-device.ps1    <- 实际逻辑
│     ├─ repos.txt               <- 要克隆的仓库清单
│     └─ identity.txt            <- git 提交身份
└─ <其他项目>\
```

## 换新电脑怎么恢复

1. 装 Git：`winget install --id Git.Git -e --source winget`
2. 克隆本仓库：
   `git clone https://gitee.com/<你的账号>/codex-workspace.git C:\Users\<你>\Projects\codex-workspace`
3. 双击 `setup\setup-new-device.cmd`

脚本会：设置 UTF-8 控制台 → 检查 git → 写入全局配置 → 从 `identity.txt` 恢复提交身份 → 按 `repos.txt` 克隆其余仓库。

## 日常：新增一个项目要同步

```powershell
cd C:\Users\13559\Projects\新项目
git init -b main
git add -A
git commit -m "init"
git remote add origin https://gitee.com/<你的账号>/新项目.git
git push -u origin main
```

然后把 `https://gitee.com/<你的账号>/新项目.git 新项目` 追加到 `setup\repos.txt` 并提交，这样换机时会被自动克隆。

## 本机 git 全局配置做了什么

| 配置 | 作用 |
| --- | --- |
| `user.name` / `user.email` | 提交身份 |
| `init.defaultBranch=main` | 新仓库默认 main |
| `core.quotepath=false` | 中文文件名正常显示，不再是 `\344\270\255` |
| `core.longpaths=true` | 支持超长路径 |
| `i18n.*=utf-8` / `gui.encoding=utf-8` | 中文提交信息不乱码 |
| `credential.helper=manager` | HTTPS 登录一次后由 Windows 凭据管理器记住 |
| `push.autoSetupRemote=true` | 新分支直接 `git push` 不用带 `-u` |
| `fetch.prune=true` | 自动清理远端已删分支 |
| `alias.st/co/lg` | 快捷命令 |

## 网络说明

- **Gitee 可直连**，推荐作为主远端。
- **GitHub 本机直连超时**（2026-09-11 实测）。需要时先开代理，再执行：
  `git config --global http.https://github.com.proxy http://127.0.0.1:7890`
  取消代理：`git config --global --unset http.https://github.com.proxy`

## 开发加速工具 tools\accel

纯本地配置，**不需要服务器、不需要 VPN**，覆盖开发流量。

```powershell
cd C:\Users\13559\Projects\codex-workspace\tools\accel
.\accel.cmd test                      # 线路自检
.\accel.cmd mirrors on                # npm / pip / go 切国内镜像
.\accel.cmd mirrors off               # 还原（备份在 %USERPROFILE%\.accel）
.\accel.cmd gh-clone <github-url>     # 加速克隆 GitHub 仓库
.\accel.cmd gh-remote on              # 给当前仓库 origin 套加速前缀
.\accel.cmd to-gitee <gitee-url>      # 把当前仓库同步到 Gitee
```

2026-09-11 实测（本机）：

| 线路 | 延迟 |
| --- | --- |
| Go 代理 goproxy.cn | 62 ms |
| pip 阿里云 | 197 ms |
| Gitee 直连 | 258 ms |
| npm npmmirror | 394 ms |
| GitHub 直连 | 736~2915 ms（波动大，时通时超时） |
| GitHub 加速通道 ghproxy.net | 2175 ms（稳定可读） |

注意：加速通道只支持读取，推送已自动指回 GitHub 真实地址；普通网页访问（Google、YouTube 等）不在本工具范围内。
