$ErrorActionPreference = "Stop"

function Write-Color {
    param(
        [string]$Text,
        [ConsoleColor]$Color = "White"
    )
    Write-Host $Text -ForegroundColor $Color
}

Write-Color "=== Moltbot/Clawdbot Windows 一键汉化安装脚本 ===" Cyan

# Check Node.js
if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
    Write-Color "❌ 错误: 未检测到 Node.js。" Red
    Write-Color "请先安装 Node.js (推荐 v16+): https://nodejs.org/"
    exit 1
}

# Check Git
if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    Write-Color "❌ 错误: 未检测到 Git。" Red
    Write-Color "请先安装 Git: https://git-scm.com/"
    exit 1
}

$RepoUrl = "https://github.com/atuizz/openclawcn.git"
$TempDir = Join-Path $env:TEMP ("openclawcn-" + (Get-Random))

try {
    Write-Color "🚀 正在下载安装程序..." Gray
    # 使用 git clone 下载，比下载 zip 更稳健，且我们已检查 git 存在
    git clone --depth 1 $RepoUrl $TempDir | Out-Null
    
    if (-not (Test-Path $TempDir)) {
        throw "下载失败，临时目录不存在"
    }

    Set-Location $TempDir

    Write-Color "📦 正在安装依赖 (这可能需要一点时间)..." Gray
    # 使用 cmd /c 运行 npm 以避免 PowerShell 中的一些执行策略问题或别名问题
    cmd /c "npm install --loglevel=error"
    if ($LASTEXITCODE -ne 0) {
        throw "依赖安装失败"
    }

    Write-Color "✅ 依赖安装完成，启动安装程序..." Green
    Write-Host ""
    
    # 运行主程序
    node index.js

} catch {
    Write-Color "❌ 安装过程中发生错误: $_" Red
    exit 1
} finally {
    # 尝试清理，但如果不成功也不报错（可能文件被占用）
    try {
        if (Test-Path $TempDir) {
            Set-Location $env:USERPROFILE
            Remove-Item -Path $TempDir -Recurse -Force -ErrorAction SilentlyContinue
        }
    } catch {}
}
