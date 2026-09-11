#Requires -Version 5.1
<#
.SYNOPSIS
  开发加速工具：镜像源一键切换 / GitHub 拉取加速 / 线路自检 / 同步到 Gitee。

.DESCRIPTION
  纯本地配置，不需要服务器、不需要 VPN。覆盖开发流量（git / npm / pip / go）。
  通用网页访问（Google、YouTube 等）不在此工具范围内，那需要一台海外中转服务器。

.EXAMPLE
  .\accel.ps1 test                        线路自检
  .\accel.ps1 mirrors on                  切到国内镜像源
  .\accel.ps1 mirrors off                 还原原始配置
  .\accel.ps1 mirrors status              看当前配置
  .\accel.ps1 gh-clone https://github.com/user/repo.git
  .\accel.ps1 gh-remote on                给当前仓库的 origin 套上加速通道
  .\accel.ps1 to-gitee https://gitee.com/kter/repo.git
#>
[CmdletBinding()]
param(
  [Parameter(Position = 0)][string]$Command = 'help',
  [Parameter(Position = 1, ValueFromRemainingArguments = $true)][string[]]$Rest
)

$ErrorActionPreference = 'Stop'
$StateDir    = Join-Path $env:USERPROFILE '.accel'
$ProxyPrefix = 'https://ghproxy.net/'
$MirrorNpm   = 'https://registry.npmmirror.com'
$MirrorPip   = 'https://mirrors.aliyun.com/pypi/simple/'
$MirrorGo    = 'https://goproxy.cn,direct'

function Write-Step($m) { Write-Host "==> $m" -ForegroundColor Cyan }
function Write-Ok($m)   { Write-Host "    OK  $m" -ForegroundColor Green }
function Write-Bad($m)  { Write-Host "    !!  $m" -ForegroundColor Yellow }
function Ensure-State { if (-not (Test-Path $StateDir)) { New-Item -ItemType Directory -Force -Path $StateDir | Out-Null } }

function Test-Endpoint {
  param([string]$Url, [int]$TimeoutSec = 7)
  $sw = [Diagnostics.Stopwatch]::StartNew()
  try {
    $null = Invoke-WebRequest -Uri $Url -Method Head -TimeoutSec $TimeoutSec -UseBasicParsing -ErrorAction Stop
    [pscustomobject]@{ Ok = $true;  Ms = $sw.ElapsedMilliseconds }
  } catch {
    [pscustomobject]@{ Ok = $false; Ms = $sw.ElapsedMilliseconds }
  }
}

function Invoke-Test {
  Write-Step '线路自检'
  $targets = [ordered]@{
    'Gitee 直连'            = 'https://gitee.com'
    'GitHub 直连'           = 'https://github.com'
    'GitHub 加速通道'        = $ProxyPrefix + 'https://github.com/git/git/archive/refs/tags/v2.43.0.tar.gz'
    'npm 官方'              = 'https://registry.npmjs.org'
    'npm 镜像 npmmirror'    = $MirrorNpm
    'pip 阿里云'            = $MirrorPip
    'pip 清华'              = 'https://pypi.tuna.tsinghua.edu.cn/simple/'
    'Go 代理 goproxy.cn'    = 'https://goproxy.cn'
  }
  foreach ($k in $targets.Keys) {
    $r = Test-Endpoint $targets[$k]
    $line = '{0,-22} {1,7} ms' -f $k, $r.Ms
    if ($r.Ok) { Write-Ok $line } else { Write-Bad ($line + '   不通') }
  }
  Write-Host '    提示：线路波动大，直连超时属常态，走加速通道即可。'
}

function Enable-Mirrors {
  Ensure-State
  Write-Step '开启国内镜像源'

  $npm = Get-Command npm -ErrorAction SilentlyContinue
  if ($npm) {
    $bak = Join-Path $StateDir 'npm-registry.txt'
    $cur = (& npm config get registry) 2>$null
    if ($cur -and -not (Test-Path $bak)) { Set-Content -Path $bak -Value $cur -Encoding ascii }
    & npm config set registry $MirrorNpm | Out-Null
    Write-Ok "npm  -> $MirrorNpm"
  } else { Write-Bad 'npm 未安装，跳过' }

  $pipIni = Join-Path $env:APPDATA 'pip\pip.ini'
  $pipDir = Split-Path $pipIni -Parent
  if (-not (Test-Path $pipDir)) { New-Item -ItemType Directory -Force -Path $pipDir | Out-Null }
  $bak = Join-Path $StateDir 'pip.ini.bak'
  if ((Test-Path $pipIni) -and -not (Test-Path $bak)) { Copy-Item $pipIni $bak -Force }
  $host_ = ([Uri]$MirrorPip).Host
  "[global]`nindex-url = $MirrorPip`ntrusted-host = $host_`n" | Set-Content -Path $pipIni -Encoding utf8
  Write-Ok "pip  -> $MirrorPip"

  $go = Get-Command go -ErrorAction SilentlyContinue
  if ($go) {
    $bak = Join-Path $StateDir 'go-goproxy.txt'
    $cur = (& go env GOPROXY) 2>$null
    if ($cur -and -not (Test-Path $bak)) { Set-Content -Path $bak -Value $cur -Encoding ascii }
    & go env -w "GOPROXY=$MirrorGo" | Out-Null
    Write-Ok "go   -> $MirrorGo"
  } else { Write-Bad 'go 未安装，跳过' }

  Write-Host "    备份在 $StateDir，用 mirrors off 可还原。"
}

function Disable-Mirrors {
  Write-Step '还原镜像源'
  $npm = Get-Command npm -ErrorAction SilentlyContinue
  $bak = Join-Path $StateDir 'npm-registry.txt'
  if ($npm -and (Test-Path $bak)) {
    & npm config set registry (Get-Content $bak -Raw).Trim() | Out-Null
    Write-Ok 'npm 已还原'
  }

  $pipIni = Join-Path $env:APPDATA 'pip\pip.ini'
  $bak = Join-Path $StateDir 'pip.ini.bak'
  if (Test-Path $bak) {
    Copy-Item $bak $pipIni -Force
    Write-Ok 'pip 已还原'
  } elseif (Test-Path $pipIni) {
    Remove-Item -LiteralPath $pipIni -Force
    Write-Ok 'pip 已移除（原本没有配置文件）'
  }

  $go = Get-Command go -ErrorAction SilentlyContinue
  $bak = Join-Path $StateDir 'go-goproxy.txt'
  if ($go -and (Test-Path $bak)) {
    & go env -w ("GOPROXY=" + (Get-Content $bak -Raw).Trim()) | Out-Null
    Write-Ok 'go 已还原'
  }
}

function Show-MirrorStatus {
  Write-Step '当前配置'
  $npm = Get-Command npm -ErrorAction SilentlyContinue
  if ($npm) { Write-Host ('    npm  ' + (& npm config get registry)) }
  $pipIni = Join-Path $env:APPDATA 'pip\pip.ini'
  if (Test-Path $pipIni) { Write-Host ('    pip  ' + ((Get-Content $pipIni | Where-Object { $_ -match 'index-url' }) -join '')) }
  else { Write-Host '    pip  (默认官方源)' }
  $go = Get-Command go -ErrorAction SilentlyContinue
  if ($go) { Write-Host ('    go   ' + (& go env GOPROXY)) }
}

function Invoke-GhClone {
  $url = $Rest[0]
  if (-not $url) { Write-Bad '用法：accel.ps1 gh-clone <github-url> [目标目录]'; return }
  if ($url -notmatch '^[a-z]+://') { $url = "https://github.com/$url" }
  $plain = $url -replace [regex]::Escape($ProxyPrefix), ''
  $proxied = $ProxyPrefix + $plain
  $target = if ($Rest.Count -ge 2) { $Rest[1] } else { [IO.Path]::GetFileNameWithoutExtension($plain) }
  Write-Step "加速克隆 $plain"
  & git clone $proxied $target
  if ($LASTEXITCODE -eq 0) {
    & git -C $target remote set-url --push origin $plain | Out-Null
    Write-Ok "完成：$target"
    Write-Host '    读取走加速通道，推送已自动指回 GitHub 真实地址。'
  } else {
    Write-Bad '克隆失败，用 accel.ps1 test 看看通道是否可用'
  }
}

function Set-GhRemote {
  $mode = if ($Rest.Count -ge 1) { $Rest[0] } else { 'on' }
  $origin = (& git remote get-url origin) 2>$null
  if (-not $origin) { Write-Bad '当前目录没有 origin 远端'; return }
  if ($mode -eq 'on') {
    if ($origin -notlike ($ProxyPrefix + '*')) { & git remote set-url origin ($ProxyPrefix + $origin) }
    Write-Ok ('origin = ' + (& git remote get-url origin))
  } elseif ($mode -eq 'off') {
    & git remote set-url origin ($origin -replace [regex]::Escape($ProxyPrefix), '')
    Write-Ok ('origin = ' + (& git remote get-url origin))
  } else { Write-Bad '用法：accel.ps1 gh-remote on|off' }
}

function Send-ToGitee {
  $gitee = $Rest[0]
  if (-not $gitee) { Write-Bad '用法：accel.ps1 to-gitee https://gitee.com/<账号>/<仓库>.git'; return }
  if ($gitee -notmatch '\.git$') { $gitee += '.git' }
  $existing = (& git remote) 2>$null
  if ($existing -contains 'gitee') { & git remote set-url gitee $gitee }
  else { & git remote add gitee $gitee }
  Write-Step "推送全部分支与标签到 $gitee"
  & git push gitee --all
  if ($LASTEXITCODE -eq 0) { & git push gitee --tags }
  if ($LASTEXITCODE -eq 0) { Write-Ok '同步完成' } else { Write-Bad '推送失败（Gitee 仓库需先在网页上创建）' }
}

switch ($Command.ToLower()) {
  'test'      { Invoke-Test }
  'mirrors'   {
    $m = if ($Rest.Count -ge 1) { $Rest[0].ToLower() } else { 'status' }
    switch ($m) {
      'on'     { Enable-Mirrors }
      'off'    { Disable-Mirrors }
      'status' { Show-MirrorStatus }
      default  { Write-Bad '用法：accel.ps1 mirrors on|off|status' }
    }
  }
  'gh-clone'  { Invoke-GhClone }
  'gh-remote' { Set-GhRemote }
  'to-gitee'  { Send-ToGitee }
  'help'      {
    Write-Host ''
    Write-Host '  开发加速工具' -ForegroundColor Cyan
    Write-Host '    accel.ps1 test                     线路自检'
    Write-Host '    accel.ps1 mirrors on|off|status     镜像源切换/还原/查看'
    Write-Host '    accel.ps1 gh-clone <url> [dir]      加速克隆 GitHub 仓库'
    Write-Host '    accel.ps1 gh-remote on|off          当前仓库 origin 套/去加速通道'
    Write-Host '    accel.ps1 to-gitee <gitee-url>      把当前仓库同步到 Gitee'
    Write-Host ''
  }
  default { Write-Bad "未知命令：$Command（用 accel.ps1 help 查看）" }
}
