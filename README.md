# Moltbot/Clawdbot WebUI 一键汉化工具

基于 [Moltbot-cn](https://github.com/rimhoo/Moltbot-cn) 项目开发的自动化安装脚本。本工具可以自动下载最新的汉化源码，在本地编译，并替换原版 Moltbot/Clawdbot 的 WebUI 界面。

## ✨ 功能特点

- 🚀 **自动化流程**：自动检测环境、克隆代码、安装依赖、构建项目。
- 🔍 **智能定位**：自动查找本机全局安装的 `clawdbot` 或 `moltbot` 路径。
- 🛡️ **安全备份**：在替换前自动备份原版 UI 文件，确保可以随时回滚。
- 💻 **跨平台**：支持 Windows, macOS, Linux (需具备 Node.js 环境)。

## 📋 前置要求

在运行此脚本之前，请确保您的系统已安装：

- [Node.js](https://nodejs.org/) (建议 v16+)
- [Git](https://git-scm.com/)
- 已安装原版 `clawdbot` (通过 `npm install -g clawdbot` 或 `moltbot`)

## 🚀 快速开始

### Windows 用户

1. 下载或克隆本项目。
2. 双击运行 `run.bat`。

### Linux / macOS 用户

1. 下载或克隆本项目。
2. 打开终端，进入项目目录。
3. 运行安装脚本：
   ```bash
   bash install.sh
   ```

### Linux / macOS 一条命令（无需上传文件）

如果不方便上传文件，可以把本项目托管到任意可访问的 Git 仓库，然后在服务器执行一条命令完成克隆与安装：

```bash
git clone <REPO_URL> && cd openclawcn && bash easy_install.sh -y
```

如果自动定位失败，可显式指定安装目录：

```bash
git clone <REPO_URL> && cd openclawcn && bash easy_install.sh -y /path/to/clawdbot
```

如果要直接粘贴脚本内容到终端执行，请先启用非退出模式，避免会话被脚本退出命令关闭：

```bash
export NO_EXIT=1
```

然后再粘贴 `easy_install.sh` 全文执行即可。

### 一键发布到 GitHub

如果你已经有一个 GitHub 仓库地址，可以在本地执行：

```bash
bash publish.sh <REPO_URL>
```

执行后会把当前目录推送到远程仓库，你就可以在服务器用一条命令执行安装。

如果你希望完整自动化发布，建议先安装 Git 并配置 GitHub 认证（如 PAT 或 SSH Key）。

### 手动安装 (跨平台)

1. 安装脚本依赖：
   ```bash
   npm install
   ```
2. 运行安装脚本：
   ```bash
   npm start
   ```

### 方法 2: 全局安装使用

如果将本项目打包发布到 npm (假设包名为 `moltbot-cn-installer`)：

```bash
npm install -g moltbot-cn-installer
moltbot-cn
```

## 🛠️ 使用说明

1. 运行脚本后，程序会自动检查 Git 和 Node.js 环境。
2. 程序会尝试自动定位 `clawdbot` 的安装位置。如果未找到，会提示您手动输入路径。
3. 确认安装后，程序将开始下载源码并编译（根据网络状况和电脑性能，可能需要 1-5 分钟）。
4. 编译完成后，会自动备份原文件并应用汉化。
5. 成功后，请按照提示运行 `clawdbot gateway restart` 重启服务。

## ⚠️ 注意事项

- 本工具会下载约 50MB+ 的源码和依赖，请保持网络畅通。
- 编译过程需要消耗一定的 CPU 和内存资源。
- 汉化源来自社区维护的 [rimhoo/Moltbot-cn](https://github.com/rimhoo/Moltbot-cn)，请关注该项目的更新情况。

## ❓ 常见问题

**Q: 安装过程中报错 `git clone failed`?**  
A: 请检查您的网络连接，确保能访问 GitHub。

**Q: 构建时报错?**  
A: 可能是 Node.js 版本问题或依赖下载失败。尝试清理 npm 缓存或升级 Node.js。

**Q: 汉化后界面显示异常?**  
A: 请尝试清除浏览器缓存，或检查是否版本不匹配。您可以在安装目录的 `dist` 文件夹中找到备份文件进行恢复。

## 📝 许可证

MIT License
