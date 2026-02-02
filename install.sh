#!/bin/bash
set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m'

echo -e "${GREEN}=== Moltbot/Clawdbot 中文汉化一键安装脚本 (Linux/macOS) ===${NC}"

# Check Node
if ! command -v node &> /dev/null; then
    echo -e "${RED}❌ 错误: 未检测到 Node.js。${NC}"
    echo "请先安装 Node.js (推荐 v16+): https://nodejs.org/"
    exit 1
fi

# Check Git
if ! command -v git &> /dev/null; then
    echo -e "${RED}❌ 错误: 未检测到 Git。${NC}"
    echo "请先安装 Git: sudo apt install git 或 brew install git"
    exit 1
fi

# Get script directory
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$DIR"

# Install dependencies if needed
if [ ! -d "node_modules" ]; then
    echo -e "${YELLOW}📦 检测到首次运行，正在安装依赖...${NC}"
    # Use user permission for npm install
    npm install
    if [ $? -ne 0 ]; then
        echo -e "${RED}❌ 依赖安装失败。${NC}"
        exit 1
    fi
    echo -e "${GREEN}✅ 依赖安装完成。${NC}"
fi

# Run installer
echo -e "${YELLOW}🚀 启动安装程序...${NC}"
node index.js

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✨ 安装流程结束。${NC}"
else
    echo -e "${RED}❌ 安装程序退出。${NC}"
    # Check if it might be a permission issue
    if [ "$(id -u)" -ne 0 ]; then
        echo -e "${YELLOW}💡 如果您遇到 EACCES 权限错误，请尝试运行: sudo node index.js${NC}"
    fi
    exit 1
fi
