#!/bin/bash
set -e

# Colors
GREEN='\033[0;32m'
CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${CYAN}=== Moltbot/Clawdbot 一键汉化安装脚本 (Linux/macOS) ===${NC}"

# Reattach to TTY for user input if running via pipe
if [ ! -t 0 ] && [ -e /dev/tty ]; then
    exec < /dev/tty
fi

# Check Node.js
if ! command -v node &> /dev/null; then
    echo -e "${RED}❌ 错误: 未检测到 Node.js。${NC}"
    echo "请先安装 Node.js (推荐 v16+): https://nodejs.org/"
    exit 1
fi

# Check Git
if ! command -v git &> /dev/null; then
    echo -e "${RED}❌ 错误: 未检测到 Git。${NC}"
    echo "请先安装 Git。"
    exit 1
fi

TEMP_DIR="/tmp/openclawcn-$(date +%s)"
REPO_URL="https://github.com/atuizz/openclawcn.git"

echo -e "${GREEN}🚀 正在下载安装程序...${NC}"
git clone --depth 1 "$REPO_URL" "$TEMP_DIR" > /dev/null 2>&1

cd "$TEMP_DIR"

echo -e "${GREEN}📦 正在安装依赖 (这可能需要几分钟)...${NC}"
# Use silent install to reduce noise, but show errors
npm install --silent

echo -e "${GREEN}✅ 依赖安装完成，启动主程序...${NC}"
echo ""

# Run the installer
node index.js

# Cleanup
# We don't delete immediately if it fails, but here we assume success or exit
cd /
rm -rf "$TEMP_DIR"
