#!/usr/bin/env node

const fs = require('fs-extra');
const path = require('path');
const chalk = require('chalk');
const ora = require('ora');
const inquirer = require('inquirer');
const os = require('os');
const { execSync } = require('child_process');

// 汉化资源路径 (随项目分发)
const SOURCE_UI_PATH = path.join(__dirname, 'resources', 'control-ui');

async function main() {
  console.log(chalk.cyan('🚀 Moltbot/Clawdbot 中文 WebUI 离线安装工具'));
  console.log(chalk.gray('无需网络下载，直接替换本地文件'));
  console.log();

  // 0. 检查资源文件
  if (!fs.existsSync(SOURCE_UI_PATH)) {
    console.error(chalk.red('❌ 严重错误: 未找到内置的汉化资源文件。'));
    console.error(chalk.gray(`期望路径: ${SOURCE_UI_PATH}`));
    console.error(chalk.yellow('请确保您下载了完整的安装包，并且 resources 文件夹存在。'));
    process.exit(1);
  }

  try {
    // 1. 查找安装目录
    let targetDir = await findMoltbotInstallation();
    
    // 如果自动查找失败，或者用户想要确认/修改
    if (!targetDir) {
      console.log(chalk.yellow('⚠️  自动检测未找到 clawdbot 或 moltbot 的安装位置。'));
      const answer = await inquirer.prompt([
        {
          type: 'input',
          name: 'manualPath',
          message: '请输入安装目录路径 (包含 dist/control-ui 的父目录):',
          validate: (input) => {
            if (!input) return '路径不能为空';
            // 允许用户输入根目录，我们自动检查子目录
            if (fs.existsSync(path.join(input, 'dist', 'control-ui')) || 
                fs.existsSync(path.join(input, 'control-ui')) ||
                fs.existsSync(input)) {
                  return true;
            }
            return '路径无效或未找到 control-ui 目录';
          }
        }
      ]);
      targetDir = answer.manualPath;
    }

    // 规范化路径：确保指向包含 dist/control-ui 的根目录
    // 比如用户输入了 /opt/clawdbot/dist/control-ui，我们要定位到 /opt/clawdbot
    if (targetDir.endsWith('control-ui')) {
        if (targetDir.endsWith('dist/control-ui') || targetDir.endsWith('dist\\control-ui')) {
            targetDir = path.resolve(targetDir, '../..');
        } else {
             targetDir = path.resolve(targetDir, '..'); // 假设是直接的 control-ui
        }
    }

    const targetUiPath = path.join(targetDir, 'dist', 'control-ui');
    
    // 二次验证
    if (!fs.existsSync(targetUiPath)) {
        // 尝试创建一个 mock 结构用于测试？不，生产环境直接报错
        // 除非文件夹不存在但 dist 存在
        if (!fs.existsSync(path.join(targetDir, 'dist'))) {
             console.log(chalk.red(`❌ 路径验证失败: ${targetUiPath} 不存在。`));
             return;
        }
    }

    console.log(chalk.blue(`📍 目标安装路径: ${targetDir}`));
    console.log(chalk.blue(`📂 UI 目标路径: ${targetUiPath}`));

    // 2. 确认安装
    const { confirm } = await inquirer.prompt([
      {
        type: 'confirm',
        name: 'confirm',
        message: '确认开始安装汉化包？(将备份原文件)',
        default: true
      }
    ]);

    if (!confirm) {
      console.log(chalk.yellow('操作已取消'));
      return;
    }

    // 3. 执行替换
    const spinner = ora('正在安装...').start();

    try {
        // 备份
        const backupPath = path.join(targetDir, 'dist', `control-ui-backup-${Date.now()}`);
        if (fs.existsSync(targetUiPath)) {
            spinner.text = '正在备份原文件...';
            await fs.move(targetUiPath, backupPath);
        } else {
            // 如果目标不存在，确保父目录存在
            await fs.ensureDir(path.join(targetDir, 'dist'));
        }

        // 复制
        spinner.text = '正在部署汉化文件...';
        await fs.copy(SOURCE_UI_PATH, targetUiPath);

        spinner.succeed('安装完成！');
        
        console.log();
        console.log(chalk.green('✅ 汉化包已成功应用。'));
        if (fs.existsSync(backupPath)) {
            console.log(chalk.gray(`💾 原文件已备份至: ${backupPath}`));
        }
        console.log();
        console.log(chalk.yellow('请重启服务以生效：'));
        console.log(chalk.white('  clawdbot gateway restart'));
        console.log();

    } catch (err) {
        spinner.fail('安装失败');
        console.error(err);
        // 尝试回滚
        // if (fs.existsSync(backupPath)) ... 
    }

  } catch (error) {
    console.error(chalk.red('\n发生意外错误:'), error);
  }
}

async function findMoltbotInstallation() {
    const candidates = [];

    // 1. 检查环境变量
    if (process.env.CLAWDBOT_DIR) candidates.push(process.env.CLAWDBOT_DIR);
    
    // 2. 检查 npm 全局安装路径
    try {
        const npmRoot = execSync('npm root -g', { encoding: 'utf8' }).trim();
        if (npmRoot) {
            candidates.push(path.join(npmRoot, 'clawdbot'));
            candidates.push(path.join(npmRoot, 'moltbot'));
        }
    } catch (e) {}

    // 3. 常见系统路径
    const commonPaths = [
        '/usr/local/lib/node_modules/clawdbot',
        '/usr/lib/node_modules/clawdbot',
        '/opt/clawdbot',
        path.join(os.homedir(), '.clawdbot'),
        // Windows paths
        process.env.APPDATA ? path.join(process.env.APPDATA, 'npm', 'node_modules', 'clawdbot') : null
    ].filter(Boolean);
    
    candidates.push(...commonPaths);

    // 4. 检查所有候选路径
    for (const p of candidates) {
        if (await isValidInstall(p)) {
            return p;
        }
    }

    // 5. 如果还没找到，尝试搜索（深度有限）
    // 这里为了性能暂时不开启全盘搜索，但在 Windows 下可以尝试搜索 npm 目录
    
    return null;
}

async function isValidInstall(dir) {
    try {
        return await fs.pathExists(path.join(dir, 'dist', 'control-ui'));
    } catch (e) {
        return false;
    }
}

main();
