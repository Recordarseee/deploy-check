# 一键部署：提交 + 推送到 GitHub
# 用法：
#   .\deploy.ps1                  # 用时间戳当提交信息
#   .\deploy.ps1 "修复登录按钮"    # 自定义提交信息

param(
    [string]$Message = ("update: " + (Get-Date -Format "yyyy-MM-dd HH:mm:ss"))
)

$ErrorActionPreference = 'Stop'
$root = $PSScriptRoot
$git  = Join-Path $root "tools\MinGit\cmd\git.exe"
$gh   = "C:\Program Files\GitHub CLI\gh.exe"
$repo = "Recordarseee/deploy-check"

if (-not (Test-Path $git)) { throw "找不到便携版 git：$git" }
if (-not (Test-Path $gh))  { throw "找不到 gh：$gh" }

# 1. 确保已登录
$null = & $gh auth status 2>&1
if ($LASTEXITCODE -ne 0) {
    throw "gh 未登录，先运行：& `"$gh`" auth login"
}

# 2. 确保 git 能用 gh 的凭证（失败不致命，push 时会再试）
& $gh auth setup-git 2>&1 | Out-Null

# 3. 提交
Push-Location $root
try {
    $changes = & $git status --porcelain
    if (-not $changes) {
        Write-Host "没有改动，跳过提交。" -ForegroundColor Yellow
    } else {
        & $git add -A
        & $git commit -m $Message | Out-Null
        Write-Host "已提交：$Message" -ForegroundColor Green
    }

    # 4. 推送
    & $git push origin main 2>&1 | Select-Object -Last 3
    if ($LASTEXITCODE -ne 0) { throw "推送失败" }

    Write-Host ""
    Write-Host "✓ 已推送。Pages 通常 30-60 秒后更新：" -ForegroundColor Green
    Write-Host "  https://recordarseee.github.io/deploy-check/"
    Write-Host "  仓库：https://github.com/$repo"
}
finally {
    Pop-Location
}
