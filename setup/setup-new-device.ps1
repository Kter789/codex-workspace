#Requires -Version 5.1
<#
.SYNOPSIS
  新设备一键恢复开发环境：git 全局配置 + SSH 通道 + 按清单克隆仓库。

.DESCRIPTION
  换新电脑后的标准流程：
    1) 装 Git：winget install --id Git.Git -e --source winget
    2) 克隆本仓库（Gitee 直连最稳）：
       git clone https://gitee.com/which-Kter/codex-workspace.git C:\Users\<你>\Projects\codex-workspace
    3) 双击本目录下的 setup-new-device.cmd
       备份过私钥的话用：setup-new-device.cmd -KeyFile D:\备份\id_ed25519

.EXAMPLE
  .\setup-new-device.ps1
.EXAMPLE
  .\setup-new-device.ps1 -KeyFile D:\keys\id_ed25519 -Root D:\Code
#>
[CmdletBinding()]
param(
  [string]$Root = (Join-Path $env:USERPROFILE 'Projects'),
  [string]$Name,
  [string]$Email,
  [string]$KeyFile,
  [switch]$SkipGlobalConfig
)

$ErrorActionPreference = 'Stop'
$here = Split-Path -Parent $MyInvocation.MyCommand.Path

function Write-Step($m) { Write-Host "==> $m" -ForegroundColor Cyan }
function Write-Ok($m)   { Write-Host "    OK  $m" -ForegroundColor Green }
function Write-Bad($m)  { Write-Host "    !!  $m" -ForegroundColor Yellow }


# ---------- 1. 控制台 UTF-8（避免中文乱码） ----------
try {
  [Console]::OutputEncoding = [Text.Encoding]::UTF8
  & chcp 65001 | Out-Null
} catch {}

# ---------- 2. 检查 Git ----------
Write-Step '检查 Git'
$git = Get-Command git -ErrorAction SilentlyContinue
if (-not $git) {
  Write-Bad '未检测到 Git，请先安装后重新运行本脚本：'
  Write-Host '      winget install --id Git.Git -e --source winget'
  exit 1
}
Write-Ok ((& git --version) -join ' ')

# ---------- 3. 解析提交身份 ----------
Write-Step '确定提交身份'
if (-not $Name -or -not $Email) {
  $idFile = Join-Path $here 'identity.txt'
  if (Test-Path $idFile) {
    foreach ($line in (Get-Content $idFile -Encoding UTF8)) {
      if ($line -match '^\s*name\s*=\s*(.+?)\s*$'  -and -not $Name)  { $Name  = $Matches[1] }
      if ($line -match '^\s*email\s*=\s*(.+?)\s*$' -and -not $Email) { $Email = $Matches[1] }
    }
  }
}
if (-not $Name)  { $Name  = Read-Host '请输入 Git 用户名（提交里显示的名字）' }
if (-not $Email) { $Email = Read-Host '请输入 Git 邮箱' }


# ---------- 4. 写入全局配置 ----------
if (-not $SkipGlobalConfig) {
  Write-Step '写入 git 全局配置'
  $cfg = [ordered]@{
    'init.defaultBranch'     = 'main'
    'core.quotepath'         = 'false'
    'core.longpaths'         = 'true'
    'core.autocrlf'          = 'true'
    'i18n.commitEncoding'    = 'utf-8'
    'i18n.logOutputEncoding' = 'utf-8'
    'gui.encoding'           = 'utf-8'
    'credential.helper'      = 'manager'
    'push.default'           = 'simple'
    'push.autoSetupRemote'   = 'true'
    'pull.rebase'            = 'false'
    'fetch.prune'            = 'true'
    'http.postBuffer'        = '524288000'
    'alias.st'               = 'status -sb'
    'alias.co'               = 'checkout'
    'alias.lg'               = 'log --oneline --graph --decorate -20'
  }
  foreach ($k in $cfg.Keys) { & git config --global $k $cfg[$k] }
  & git config --global user.name  $Name
  & git config --global user.email $Email
  Write-Ok "user.name  = $Name"
  Write-Ok "user.email = $Email"
} else {
  Write-Bad '按参数要求跳过全局配置'
}


# ---------- 5. SSH 通道（github.com 走 443，绕开 22 端口封锁） ----------
Write-Step '配置 SSH 通道'
$sshDir  = Join-Path $env:USERPROFILE '.ssh'
$keyPath = Join-Path $sshDir 'id_ed25519'
if (-not (Test-Path $sshDir)) { New-Item -ItemType Directory -Force -Path $sshDir | Out-Null }

if ($KeyFile) {
  if (-not (Test-Path -LiteralPath $KeyFile)) { Write-Bad "找不到私钥文件：$KeyFile" }
  else {
    Copy-Item -LiteralPath $KeyFile -Destination $keyPath -Force
    if (Test-Path -LiteralPath "$KeyFile.pub") { Copy-Item -LiteralPath "$KeyFile.pub" -Destination "$keyPath.pub" -Force }
    else { & ssh-keygen -y -f $keyPath | Set-Content -Encoding ASCII "$keyPath.pub" }
    Write-Ok "已从备份导入私钥：$keyPath"
  }
}


if (-not (Test-Path $keyPath)) {
  $kc = 'ssh-keygen -t ed25519 -f "' + $keyPath + '" -N "" -C "' + $Email + '" -q'
  & cmd /c $kc
  if (Test-Path $keyPath) {
    Write-Ok "已生成新密钥：$keyPath"
    Write-Bad '新密钥需要登记到 GitHub / Gitee 才能推送，公钥内容：'
    Get-Content "$keyPath.pub"
    Write-Host '  GitHub: https://github.com/settings/ssh/new'
    Write-Host '  Gitee : https://gitee.com/profile/sshkeys'
  } else {
    Write-Bad '密钥生成失败，请手动生成 id_ed25519 后重跑'
  }
} else {
  Write-Ok "已存在私钥，沿用：$keyPath"
}


$cfgPath = Join-Path $sshDir 'config'
$needBlock = $true
if (Test-Path $cfgPath) {
  $old = Get-Content $cfgPath -Raw -Encoding UTF8
  if ($old -match 'ssh\.github\.com') { $needBlock = $false; Write-Ok '~/.ssh/config 已有 GitHub 443 通道，跳过' }
}
if ($needBlock) {
  $block = @"

# ---- github.com 走 443 端口（内地直连 22 常被封） ----
Host github.com
  HostName ssh.github.com
  Port 443
  User git
  IdentityFile ~/.ssh/id_ed25519
  IdentitiesOnly yes

Host gitee.com
  HostName gitee.com
  Port 22
  User git
  IdentityFile ~/.ssh/id_ed25519
  IdentitiesOnly yes

Host ssh.gitee.com
  HostName ssh.gitee.com
  Port 443
  User git
  IdentityFile ~/.ssh/id_ed25519
  IdentitiesOnly yes
"@
  Add-Content -Path $cfgPath -Value $block -Encoding UTF8
  Write-Ok "已写入 $cfgPath"
}

Write-Step 'SSH 自检'
foreach ($h in @('git@gitee.com','git@github.com')) {
  $r = & ssh -o ConnectTimeout=12 -o BatchMode=yes -o StrictHostKeyChecking=no -T $h 2>&1 | Select-Object -First 1
  Write-Host "      $h -> $r"
}


# ---------- 6. 按清单克隆仓库 ----------
Write-Step "仓库根目录：$Root"
if (-not (Test-Path $Root)) { New-Item -ItemType Directory -Force -Path $Root | Out-Null }

$listFile = Join-Path $here 'repos.txt'
if (Test-Path $listFile) {
  $lines = Get-Content $listFile -Encoding UTF8 | Where-Object { $_ -match '\S' -and $_ -notmatch '^\s*#' }
  foreach ($line in $lines) {
    $parts = @($line.Trim() -split '\s+')
    $url   = $parts[0]
    $dir   = if ($parts.Count -ge 2) { $parts[1] } else { [IO.Path]::GetFileNameWithoutExtension($url) }
    $target = Join-Path $Root $dir
    if (Test-Path (Join-Path $target '.git')) { Write-Ok "已存在，跳过：$dir"; continue }
    Write-Host "    克隆 $url"
    & git clone $url $target
    if ($LASTEXITCODE -eq 0) { Write-Ok $dir } else { Write-Bad "克隆失败：$url" }
  }
} else {
  Write-Bad '未找到 repos.txt，跳过克隆'
}

# ---------- 7. 收尾提示 ----------
Write-Host ''
Write-Step '完成'
Write-Host '  验证：git config --global --list'
Write-Host '    Gitee   https://gitee.com/which-Kter/codex-workspace.git   （私有，主用）'
Write-Host '    GitHub  https://github.com/Kter789/codex-workspace.git     （公开，镜像）'
Write-Host '  GitHub 的 git 走 SSH 443 通道；若仍超时，改走 Gitee。'

