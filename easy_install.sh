#!/bin/bash

# ==========================================
# Moltbot/Clawdbot WebUI 一键汉化脚本 (纯Shell版)
# 无需上传任何文件，直接复制粘贴到终端即可运行
# ==========================================

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

REPO_URL="https://github.com/rimhoo/Moltbot-cn.git"
TEMP_DIR="/tmp/moltbot-cn-installer-$(date +%s)"
AUTO_YES=0
NO_EXIT="${NO_EXIT:-0}"
TARGET_ARG=""

while [ $# -gt 0 ]; do
    case "$1" in
        -y|--yes)
            AUTO_YES=1
            shift
            ;;
        --no-exit|--paste)
            NO_EXIT=1
            shift
            ;;
        *)
            TARGET_ARG="$1"
            shift
            break
            ;;
    esac
done

log_info() { echo -e "${BLUE}[INFO] $1${NC}"; }
log_success() { echo -e "${GREEN}[SUCCESS] $1${NC}"; }
log_warn() { echo -e "${YELLOW}[WARN] $1${NC}"; }
log_error() { echo -e "${RED}[ERROR] $1${NC}"; }

# 1. 环境检查
check_env() {
    log_info "正在检查环境..."
    if ! command -v git &> /dev/null; then
        log_error "未找到 git，请先安装: sudo apt install git"
        exit 1
    fi
    if ! command -v node &> /dev/null; then
        log_error "未找到 node，请先安装 Node.js"
        exit 1
    fi
    if ! command -v npm &> /dev/null; then
        log_error "未找到 npm"
        exit 1
    fi
}

resolve_path() {
    if command -v realpath &> /dev/null; then
        realpath "$1"
    else
        readlink -f "$1" 2>/dev/null || readlink "$1"
    fi
}

normalize_target_dir() {
    if [ -z "$1" ]; then
        return 1
    fi
    if [[ "$1" == */dist/control-ui ]]; then
        TARGET_DIR="$(dirname "$1")"
    else
        TARGET_DIR="$1"
    fi
    return 0
}

# 2. 查找安装位置
find_install_path() {
    log_info "正在查找 Moltbot/Clawdbot 安装位置..."

    if [ -n "$1" ]; then
        normalize_target_dir "$1"
    elif [ -n "$CLAWDBOT_DIR" ]; then
        normalize_target_dir "$CLAWDBOT_DIR"
    fi

    if [ -n "$TARGET_DIR" ] && [ -d "$TARGET_DIR/dist/control-ui" ]; then
        log_success "定位到安装路径: $TARGET_DIR"
        return 0
    fi

    CANDIDATES=()

    NPM_ROOT=$(npm root -g 2>/dev/null || true)
    if [ -n "$NPM_ROOT" ]; then
        CANDIDATES+=("$NPM_ROOT/clawdbot" "$NPM_ROOT/moltbot")
    fi

    if command -v clawdbot &> /dev/null; then
        BIN_PATH=$(resolve_path "$(command -v clawdbot)")
        if echo "$BIN_PATH" | grep -q "/node_modules/"; then
            PKG_PATH=$(echo "$BIN_PATH" | sed -E 's|(.*?/node_modules/[^/]+)/.*|\1|')
            CANDIDATES+=("$PKG_PATH")
        fi
    fi

    CANDIDATES+=(
        "/usr/local/lib/node_modules/clawdbot"
        "/usr/local/lib/node_modules/moltbot"
        "/usr/lib/node_modules/clawdbot"
        "/usr/lib/node_modules/moltbot"
        "/opt/clawdbot"
        "/opt/moltbot"
        "$HOME/.clawdbot"
        "$HOME/.moltbot"
    )

    for candidate in "${CANDIDATES[@]}"; do
        if [ -d "$candidate/dist/control-ui" ]; then
            TARGET_DIR="$candidate"
            log_success "定位到安装路径: $TARGET_DIR"
            return 0
        fi
    done

    log_warn "未在常见路径找到安装，尝试进行快速扫描..."
    FOUND=$(find /usr/local/lib/node_modules /usr/lib/node_modules /opt "$HOME" -maxdepth 6 -type d -path "*/dist/control-ui" 2>/dev/null | head -n 1 || true)
    if [ -n "$FOUND" ]; then
        TARGET_DIR="$(dirname "$FOUND")"
        log_success "定位到安装路径: $TARGET_DIR"
        return 0
    fi

    log_warn "仍未找到安装目录。"
    read -p "请输入 clawdbot 安装目录或 dist/control-ui 的绝对路径: " MANUAL_PATH
    if [ -z "$MANUAL_PATH" ]; then
        log_error "路径不能为空"
        exit 1
    fi
    normalize_target_dir "$MANUAL_PATH"

    if [ ! -d "$TARGET_DIR/dist/control-ui" ]; then
        log_error "无效的安装路径: 未找到 $TARGET_DIR/dist/control-ui"
        log_warn "提示: clawd 目录通常是工作区，不是安装目录。"
        log_warn "可运行: which clawdbot 获取安装位置。"
        exit 1
    fi

    log_success "定位到安装路径: $TARGET_DIR"
}

# 3. 确认执行
confirm_action() {
    if [ "$AUTO_YES" -eq 1 ] || [ ! -t 0 ]; then
        log_warn "检测到非交互环境，自动确认继续执行"
        return 0
    fi
    echo -e "${YELLOW}即将开始汉化安装。这将会备份并覆盖原有的 WebUI 文件。${NC}"
    read -p "是否继续? [y/N] " response
    case "$response" in
        [yY][eE][sS]|[yY]) 
            ;;
        *)
            log_warn "操作已取消"
            exit 0
            ;;
    esac
}

# 4. 执行构建和替换
do_install() {
    # 清理旧的临时目录
    rm -rf "$TEMP_DIR"
    mkdir -p "$TEMP_DIR"
    
    log_info "正在克隆汉化仓库到临时目录..."
    git clone --depth 1 "$REPO_URL" "$TEMP_DIR"
    
    UI_SOURCE_DIR="$TEMP_DIR/source/ui"
    if [ ! -d "$UI_SOURCE_DIR" ]; then
        log_error "仓库结构异常: 未找到 $UI_SOURCE_DIR"
        exit 1
    fi
    
    log_info "开始构建 WebUI (这可能需要几分钟)..."
    cd "$UI_SOURCE_DIR"
    
    # 优先使用 pnpm, 其次 yarn, 最后 npm
    if command -v pnpm &> /dev/null; then
        PKG_CMD="pnpm"
    elif command -v yarn &> /dev/null; then
        PKG_CMD="yarn"
    else
        PKG_CMD="npm"
    fi
    
    log_info "使用包管理器: $PKG_CMD"
    $PKG_CMD install
    $PKG_CMD run build
    
    # 查找构建产物
    # 可能是 build 或 dist
    if [ -d "dist" ]; then
        BUILD_OUTPUT="$UI_SOURCE_DIR/dist"
    elif [ -d "build" ]; then
        BUILD_OUTPUT="$UI_SOURCE_DIR/build"
    # 兼容 rimhoo 项目可能的特殊结构
    elif [ -d "$TEMP_DIR/source/dist/control-ui" ]; then
        BUILD_OUTPUT="$TEMP_DIR/source/dist/control-ui"
    else
        log_error "构建失败或未找到构建产物目录"
        exit 1
    fi
    
    log_info "构建完成，准备替换..."
    
    TARGET_UI_PATH="$TARGET_DIR/dist/control-ui"
    BACKUP_PATH="$TARGET_DIR/dist/control-ui-backup-$(date +%s)"
    
    # 备份
    if [ -d "$TARGET_UI_PATH" ]; then
        mv "$TARGET_UI_PATH" "$BACKUP_PATH"
        log_success "原文件已备份至: $BACKUP_PATH"
    else
        mkdir -p "$(dirname "$TARGET_UI_PATH")"
    fi
    
    # 复制
    cp -r "$BUILD_OUTPUT" "$TARGET_UI_PATH"
    
    # 清理
    cd /tmp
    rm -rf "$TEMP_DIR"
    
    echo ""
    log_success "✅ 汉化安装成功！"
    echo -e "${YELLOW}请运行以下命令重启服务以生效：${NC}"
    echo -e "${GREEN}clawdbot gateway restart${NC}"
}

main() {
    set -e
    check_env
    find_install_path "$TARGET_ARG"
    confirm_action
    do_install
}

if [ "$NO_EXIT" -eq 1 ]; then
    ( main )
else
    main
fi
