@echo off
echo 正在安装依赖...
call npm install
if %errorlevel% neq 0 (
    echo 依赖安装失败，请检查 node.js 和 npm 是否正确安装。
    pause
    exit /b %errorlevel%
)

echo 启动汉化脚本...
node index.js
pause
