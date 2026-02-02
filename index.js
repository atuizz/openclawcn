#!/usr/bin/env node

const fs = require('fs-extra');
const path = require('path');
const execa = require('execa');
const chalk = require('chalk');
const ora = require('ora');
const inquirer = require('inquirer');
const os = require('os');

const REPO_URL = 'https://github.com/rimhoo/Moltbot-cn.git';
const TEMP_DIR_NAME = 'moltbot-cn-temp';

// 主程序入口
async function main() {
  console.log(chalk.cyan('🚀 Moltbot/Clawdbot 中文 WebUI 一键安装工具'));
  console.log(chalk.gray('基于 https://github.com/rimhoo/Moltbot-cn 项目'));
  console.log();

  try {
    // 1. 环境检查
    await checkRequirements();

    // 2. 查找本地安装
    const targetDir = await findMoltbotInstallation();
    if (!targetDir) {
      console.log(chalk.yellow('⚠️  未检测到全局安装的 clawdbot 或 moltbot。'));
      const { manualPath } = await inquirer.prompt([
        {
          type: 'input',
          name: 'manualPath',
          message: '请输入 clawdbot 的安装目录路径 (留空退出):',
        }
      ]);
      if (!manualPath) {
        console.log(chalk.red('❌ 操作已取消'));
        return;
      }
      // 验证手动输入的路径
      if (!fs.existsSync(path.join(manualPath, 'dist', 'control-ui'))) {
        console.log(chalk.red(`❌ 路径无效: 未在 ${manualPath} 下找到 dist/control-ui 目录`));
        return;
      }
    }

    const installPath = targetDir || path.join(process.cwd(), 'mock_install'); // Fallback for testing logic if find fails in dev
    const uiPath = path.join(installPath, 'dist', 'control-ui');

    console.log(chalk.blue(`📍 目标安装路径: ${installPath}`));
    console.log(chalk.blue(`📂 UI 资源路径: ${uiPath}`));

    const { confirm } = await inquirer.prompt([
      {
        type: 'confirm',
        name: 'confirm',
        message: '确认开始安装汉化包？(这将备份并覆盖原有 UI 文件)',
        default: true
      }
    ]);

    if (!confirm) {
      console.log(chalk.yellow('操作已取消'));
      return;
    }

    // 3. 准备构建环境
    const tempDir = path.join(process.cwd(), TEMP_DIR_NAME);
    if (fs.existsSync(tempDir)) {
      const spinner = ora('清理临时目录...').start();
      await fs.remove(tempDir);
      spinner.succeed('临时目录已清理');
    }

    // 4. 克隆仓库
    const spinnerClone = ora(`正在克隆仓库 ${REPO_URL}...`).start();
    try {
      await execa('git', ['clone', '--depth', '1', REPO_URL, tempDir]);
      spinnerClone.succeed('仓库克隆完成');
    } catch (error) {
      spinnerClone.fail('克隆失败');
      throw error;
    }

    // 5. 安装依赖并构建
    const uiSourceDir = path.join(tempDir, 'source', 'ui');
    if (!fs.existsSync(uiSourceDir)) {
      throw new Error(`在仓库中未找到 UI 源码目录: ${uiSourceDir}`);
    }

    console.log(chalk.blue('📦 开始构建 UI (这可能需要几分钟)...'));
    
    // 检测包管理器
    let pkgManager = 'npm';
    if (await isCommandAvailable('pnpm')) pkgManager = 'pnpm';
    else if (await isCommandAvailable('yarn')) pkgManager = 'yarn';

    console.log(chalk.gray(`使用包管理器: ${pkgManager}`));

    const spinnerInstall = ora('安装依赖...').start();
    try {
      await execa(pkgManager, ['install'], { cwd: uiSourceDir });
      spinnerInstall.succeed('依赖安装完成');
    } catch (error) {
      spinnerInstall.fail('依赖安装失败');
      throw error;
    }

    const spinnerBuild = ora('构建项目...').start();
    try {
      await execa(pkgManager, ['run', 'build'], { cwd: uiSourceDir });
      spinnerBuild.succeed('构建完成');
    } catch (error) {
      spinnerBuild.fail('构建失败');
      throw error;
    }

    // 6. 备份与替换
    const spinnerReplace = ora('正在应用汉化...').start();
    
    // 备份
    const backupDir = path.join(installPath, 'dist', `control-ui-backup-${Date.now()}`);
    if (fs.existsSync(uiPath)) {
      await fs.move(uiPath, backupDir);
    } else {
        // 如果目标不存在，确保父目录存在
        await fs.ensureDir(path.join(installPath, 'dist'));
    }

    // 复制新文件
    // 注意：构建产物通常在 source/ui/dist 或 source/ui/build，需要确认 rimhoo 项目结构
    // 根据 README: cp -r ../dist/control-ui/* ...
    // 这意味着构建后的产物可能在 ../dist/control-ui，或者 source/ui 下的 dist
    // 让我们先检查 source/ui/dist 是否存在，或者 source/dist/control-ui
    
    // 修正：根据 Web Search 结果 "cp -r ../dist/control-ui/*"，
    // 假设我们在 source/ui 执行 build。
    // 通常 build 会生成在 source/ui/dist。
    // 但是 README 说 `cp -r ../dist/control-ui/*`，这暗示构建产物被输出到了 source/dist/control-ui 或者 source/ui/dist
    // 我们做一个智能检测
    let buildOutputDir = path.join(uiSourceDir, 'dist');
    if (!fs.existsSync(buildOutputDir)) {
        // 尝试寻找上一级的 dist
        const parentDist = path.join(tempDir, 'source', 'dist', 'control-ui');
        if (fs.existsSync(parentDist)) {
            buildOutputDir = parentDist;
        } else {
             // 再次尝试 source/ui/build (React 默认)
             const reactBuild = path.join(uiSourceDir, 'build');
             if (fs.existsSync(reactBuild)) {
                 buildOutputDir = reactBuild;
             }
        }
    }
    
    if (!fs.existsSync(buildOutputDir) || (await fs.readdir(buildOutputDir)).length === 0) {
        spinnerReplace.fail('无法定位构建产物');
        throw new Error('构建目录为空或不存在，请检查构建过程');
    }

    await fs.copy(buildOutputDir, uiPath);
    spinnerReplace.succeed(`汉化已应用! 原文件已备份至: ${backupDir}`);

    // 7. 清理
    const spinnerClean = ora('清理临时文件...').start();
    await fs.remove(tempDir);
    spinnerClean.succeed('清理完成');

    console.log();
    console.log(chalk.green('✅ 汉化安装成功！'));
    console.log(chalk.yellow('请运行以下命令重启服务以生效：'));
    console.log(chalk.inverse(' clawdbot gateway restart '));
    console.log();

  } catch (error) {
    console.error(chalk.red('\n❌ 安装过程中发生错误:'));
    console.error(error.message);
    if (error.stderr) console.error(chalk.gray(error.stderr));

    if (error.code === 'EACCES') {
      console.error(chalk.yellow('\n💡 提示: 看起来是权限不足导致无法写入文件。'));
      console.error(chalk.yellow('   如果是 Linux/macOS 系统，请尝试使用 sudo 运行此脚本:'));
      console.error(chalk.inverse('   sudo node index.js   '));
    }
    process.exit(1);
  }
}

async function checkRequirements() {
  const spinner = ora('检查环境依赖...').start();
  
  if (!(await isCommandAvailable('git'))) {
    spinner.fail('未找到 git');
    throw new Error('请先安装 Git');
  }
  
  if (!(await isCommandAvailable('node'))) {
    spinner.fail('未找到 node');
    throw new Error('请先安装 Node.js');
  }

  spinner.succeed('环境依赖检查通过');
}

async function isCommandAvailable(cmd) {
  try {
    // Windows 下使用 where, Linux/Mac 使用 which
    const checkCmd = process.platform === 'win32' ? 'where' : 'which';
    await execa(checkCmd, [cmd]);
    return true;
  } catch {
    return false;
  }
}

async function findMoltbotInstallation() {
  const spinner = ora('正在查找 Moltbot/Clawdbot 安装位置...').start();
  try {
    const { stdout } = await execa('npm', ['root', '-g']);
    const globalPath = stdout.trim();
    
    // 检查可能的包名
    const possibleNames = ['clawdbot', 'moltbot'];
    
    for (const name of possibleNames) {
      const pkgPath = path.join(globalPath, name);
      if (fs.existsSync(pkgPath)) {
        spinner.succeed(`找到安装: ${pkgPath}`);
        return pkgPath;
      }
    }
    
    spinner.info('未在默认全局路径找到自动安装，请手动指定');
    return null;
  } catch (error) {
    spinner.warn('无法确定 npm 全局路径');
    return null;
  }
}

main();
