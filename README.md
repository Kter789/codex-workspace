# codex-workspace

所有代码/项目仓库的**统一根目录**与**换机恢复用**的配置仓库。

- 远端（Gitee，私有）：`https://gitee.com/which-Kter/codex-workspace.git`
- 远端（GitHub，公开）：`https://github.com/Kter789/codex-workspace.git`

## 目录约定

```
C:\Users\<你>\Projects\          <- 所有 git 仓库都放这里
├─ codex-workspace\              <- 本仓库：换机恢复脚本 + 仓库清单
│  ├─ setup\
│  │  ├─ setup-new-device.cmd    <- 双击运行（换机第一步）
│  │  ├─ setup-new-device.ps1    <- 实际逻辑
│  │  ├─ repos.txt               <- 要克隆的仓库清单
│  │  └─ identity.txt            <- git 提交身份
│  └─ tools\accel\               <- 开发加速工具
└─ <其他项目>\
```

## 换新电脑怎么恢复

1. 装 Git：`winget install --id Git.Git -e --source winget`
2. 克隆本仓库（任选其一，GitHub 那条免登录）：

   ```powershell
   # 公开、免登录（内地偶尔不稳）
   git clone https://github.com/Kter789/codex-workspace.git C:\Users\<你>\Projects\codex-workspace

   # 国内更稳（私有，需要登录 Gitee）
   git clone https://gitee.com/which-Kter/codex-workspace.git C:\Users\<你>\Projects\codex-workspace
   ```

3. 有备份私钥的话：`setup\setup-new-device.cmd -KeyFile D:\备份\id_ed25519`
   没有就直接双击 `setup\setup-new-device.cmd`（会生成新密钥并提示你登记）。

脚本会：UTF-8 控制台 → 检查 git → 写全局配置 → 配 SSH 通道 → SSH 自检 → 按 `repos.txt` 克隆其余仓库。

### 私钥怎么备份／恢复

推送用的私钥是 `C:\Users\<你>\.ssh\id_ed25519`（无口令）。换机时把它连同 `id_ed25519.pub`
一起放到 U 盘/网盘/密码管理器，用 `-KeyFile` 导入即可，推送权限原样恢复。
**这个文件不要提交进任何仓库。**

公钥（两处都已登记，指纹 `SHA256:s/PoLeD7XCUxYz0aptx5oi+wxCvFmJvqTkiaHo7KaA4`）：

```
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJNPo11JUZNLRKr+OxLiSWEtgkZ+sZ9x3tGyBC4PHZll Kter789@users.noreply.github.com
```

登记入口：GitHub <https://github.com/settings/ssh/new> ｜ Gitee <https://gitee.com/profile/sshkeys>


## 日常：新增一个项目要同步

```powershell
cd C:\Users\13559\Projects\新项目
git init -b main
git add -A
git commit -m "init"
git remote add origin git@gitee.com:which-Kter/新项目.git   # 主远端走 Gitee
git push -u origin main
```

然后把 `git@gitee.com:which-Kter/新项目.git 新项目` 追加到 `setup\repos.txt` 并提交，
这样换机时会被自动克隆。

## 本机 git 全局配置做了什么

| 配置 | 作用 |
| --- | --- |
| `user.name` / `user.email` | 提交身份（免回复邮箱，不暴露 QQ 邮箱） |
| `init.defaultBranch=main` | 新仓库默认 main |
| `core.quotepath=false` | 中文文件名正常显示，不再是 `\344\270\255` |
| `core.longpaths=true` | 支持超长路径 |
| `i18n.*=utf-8` / `gui.encoding=utf-8` | 中文提交信息不乱码 |
| `credential.helper=manager` | HTTPS 登录一次后由 Windows 凭据管理器记住 |
| `push.autoSetupRemote=true` | 新分支直接 `git push` 不用带 `-u` |
| `fetch.prune=true` | 自动清理远端已删分支 |
| `alias.st/co/lg` | 快捷命令 |

## 网络说明（2026-09-11 实测）

| 通道 | 结果 |
| --- | --- |
| Gitee HTTPS / SSH(22) | 通，2~3 秒，**推荐主用** |
| Gitee SSH(443 → ssh.gitee.com) | 通 |
| GitHub 网页 | 通，1.2~1.8 秒 |
| GitHub git over HTTPS(443) | **经常被重置/连不上**，不可靠 |
| GitHub git over SSH(443 → ssh.github.com) | **通且稳定，已选用** |

所以 `~/.ssh/config` 里把 `github.com` 映射到了 `ssh.github.com:443`：

```
Host github.com
  HostName ssh.github.com
  Port 443
  User git
  IdentityFile ~/.ssh/id_ed25519
  IdentitiesOnly yes
```

本仓库的远端约定：`origin` 拉取走 HTTPS（公开、免登录），推送走 SSH（免密码）。
`gitee` 是国内的备用/主远端，fetch+push 都走 SSH。


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

注意：加速通道只支持读取，推送已自动指回 GitHub 真实地址；
普通网页访问（Google、YouTube 等）不在本工具范围内，那类需求要用商业加速器。

