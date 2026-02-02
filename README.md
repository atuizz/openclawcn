# OpenClawCN - Moltbot/Clawdbot 中文汉化包

这是一个针对 Moltbot/Clawdbot 的一键汉化工具。与旧版不同，本版本**直接内置了汉化好的 WebUI 资源文件**，安装过程无需编译，无需下载额外源码，速度极快且稳定。

## ✨ 特性

- **📦 内置资源**：汉化文件随安装包分发，无需网络拉取源码。
- **⚡ 极速安装**：直接替换文件，秒级完成。
- **🛡️ 自动备份**：自动备份原版 UI，随时可恢复。
- **🤖 智能定位**：自动查找系统中的安装目录，支持手动指定。

## 🚀 一键安装 (推荐)

无需手动下载代码，直接在终端执行以下命令即可。

### Linux / macOS
```bash
bash <(curl -fsSL https://raw.githubusercontent.com/atuizz/openclawcn/main/easy_install.sh)
```

### Windows (PowerShell)
```powershell
iwr https://raw.githubusercontent.com/atuizz/openclawcn/main/easy_install.ps1 | iex
```

## 📦 手动安装

1. 下载本项目 ZIP 包或 `git clone`。
2. 安装依赖：
   ```bash
   npm install
   ```
3. 运行安装程序：
   ```bash
   node index.js
   ```

## 🛠️ 常见问题

**Q: 提示“未找到安装目录”怎么办？**  
A: 程序会提示您手动输入路径。请找到您的 `clawdbot` 安装位置（通常包含 `dist/control-ui` 文件夹），输入该路径即可。

**Q: 如何恢复原版？**  
A: 安装程序会在 `dist` 目录下生成 `control-ui-backup-时间戳` 文件夹。只需将其重命名回 `control-ui` 即可恢复。

## 📝 许可证

MIT License
