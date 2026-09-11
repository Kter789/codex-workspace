#Requires -Version 5.1
<#
.SYNOPSIS
  新设备一键恢复开发环境：写入 git 全局配置 + 按清单克隆全部仓库。

.DESCRIPTION
  换新电脑后的标准流程：
    1) 装 Git：winget install --id Git.Git -e --source winget
    2) 克隆本仓库到 C:\Users\<你>\Projects\codex-workspace
    3) 双击本目录下的 setup-new-device.cmd

  脚本动作：UTF-8 控制台 -> 检查 git -> 读身份 -> 写全局配置 -> 按 repos.txt 克隆。

.EXAMPLE
  .\setup-new-device.ps1
.EXAMPLE
  .\setup-new-device.ps1 -Name "张三" -Email "zhangsan@example.com" -Root "D:\Code"
#>
[CmdletBinding()]
param(
  [string]$Root = (Join-Path $env:USERPROFILE 'Projects'),
  [string]$Name,
  [string]$Email,
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

# ---------- 5. 按清单克隆仓库 ----------
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
    Write-Host "      -> $target"
    & git clone $url $target
    if ($LASTEXITCODE -eq 0) { Write-Ok $dir } else { Write-Bad "克隆失败：$url" }
  }
} else {
  Write-Bad '未找到 repos.txt，跳过克隆'
}

# ---------- 6. 收尾提示 ----------
Write-Host ''
Write-Step '完成'
Write-Host '  验证：git config --global --list'
Write-Host '  GitHub 直连不通时（本机实测超时），先开代理再执行：'
Write-Host '      git config --global http.https://github.com.proxy http://127.0.0.1:7890'
