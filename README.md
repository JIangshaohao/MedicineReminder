# 💊 吃药提醒工具 (Medicine Reminder)

一个基于 PowerShell 的 Windows 桌面应用，帮助您按时服药，保持健康。程序在每天指定时间自动弹出提醒窗口和系统通知，支持智能重提醒和日志记录功能。

## 📋 目录

- [项目简介](#项目简介)
- [功能特性](#功能特性)
- [系统要求](#系统要求)
- [安装方法](#安装方法)
- [使用说明](#使用说明)
- [配置说明](#配置说明)
- [卸载方法](#卸载方法)
- [文件说明](#文件说明)
- [故障排除](#故障排除)
- [许可证信息](#许可证信息)

---

## 项目简介

**吃药提醒工具**是一款轻量级的 Windows 桌面应用程序，专为需要定时服药的用户设计。它会在每天 13:10 自动弹出提醒窗口，并在您点击"未吃药"或超时时，每 5 分钟重新提醒，直到 18:00 为止。

### 核心特点

- 🕐 **智能提醒**：每天固定时间自动提醒
- 🔔 **双重通知**：弹窗 + 系统托盘通知
- ⏰ **超时处理**：60 秒无操作自动标记为"未吃药"
- 🔄 **循环提醒**：未吃药时每 5 分钟重新提醒
- 📝 **日志记录**：自动记录所有操作到日志文件
- 🚀 **开机自启**：支持通过任务计划程序实现开机自动运行
- 🌙 **静默运行**：后台运行，不显示命令行窗口

---

## 功能特性

### ✅ 主要功能

1. **定时提醒**
   - 默认每天 13:10 首次提醒
   - 可自定义提醒时间
   - 晚启动补偿机制（如果开机时已过提醒时间但在截止前，立即弹窗）

2. **智能交互**
   - "已吃药"按钮：记录日志，当天不再提醒
   - "未吃药"按钮：5 分钟后再次提醒
   - 倒计时显示：实时显示剩余秒数

3. **多重通知**
   - 模态对话框提醒（置顶显示）
   - Windows 系统通知（Toast/Balloon）
   - 系统托盘图标状态提示

4. **自动管理**
   - 跨天自动重置状态
   - 18:00 后停止当天提醒
   - 自动记录操作日志

5. **便捷操作**
   - 右键托盘图标退出程序
   - 无需手动启动（可配置开机自启）
   - 完全静默后台运行

---

## 系统要求

### 操作系统
- **Windows 10** 或更高版本（推荐）
- **Windows 8.1**（部分功能可能受限）
- **Windows 7**（仅支持气泡通知，不支持 Toast 通知）

### 运行环境
- **PowerShell 5.0** 或更高版本
- **.NET Framework 4.5** 或更高版本
- 管理员权限（仅安装/卸载时需要）

### 硬件要求
- 最低分辨率：1024x768
- 内存：至少 512MB 可用内存

---

## 安装方法

### 方法一：快速安装（推荐）

1. **下载项目文件**
   ```powershell
   # 克隆仓库或下载 ZIP 包并解压到目标目录
   git clone <repository-url>
   ```

2. **以管理员身份运行安装脚本**
   - 右键点击 `install.bat`
   - 选择"**以管理员身份运行**"
   - 等待安装完成

3. **验证安装**
   - 打开"任务计划程序"
   - 查看是否存在名为 `MedicineReminder` 的任务
   - 状态应为"就绪"

4. **测试运行**
   - 双击 `run_silent.vbs` 立即启动程序
   - 检查系统托盘是否出现药丸图标

### 方法二：手动安装

1. **创建任务计划**
   ```powershell
   # 以管理员身份打开 PowerShell
   cd D:\PowerShellAuto
   .\setup.ps1
   ```

2. **确认配置**
   - 任务名称：`MedicineReminder`
   - 触发条件：用户登录时
   - 执行动作：运行 `run_silent.vbs`

### 方法三：临时使用（不设置开机自启）

直接双击 `run_silent.vbs` 即可运行程序，但每次开机需手动启动。

---

## 使用说明

### 日常使用流程

1. **程序启动**
   - 如果已配置开机自启，登录后自动启动
   - 否则双击 `run_silent.vbs` 手动启动
   - 系统托盘会显示药丸图标

2. **接收提醒**
   - 到达设定时间（默认 13:10），弹出提醒窗口
   - 同时收到系统通知
   - 窗口显示 60 秒倒计时

3. **响应提醒**
   
   **选项 A：已吃药**
   - 点击绿色"**已吃药**"按钮
   - 程序记录日志
   - 当天不再提醒
   
   **选项 B：未吃药**
   - 点击红色"**未吃药**"按钮
   - 或等待 60 秒超时
   - 5 分钟后再次提醒

4. **退出程序**
   - 右键点击系统托盘图标
   - 选择"**退出程序**"

### 日志查看

日志文件位置：`D:\PowerShellAuto\MedicineReminder.log`

日志内容包括：
- 程序启动时间
- 弹窗时间
- 用户操作（已吃药/未吃药/超时）
- 状态变更记录

查看日志示例：
```powershell
Get-Content D:\PowerShellAuto\MedicineReminder.log -Tail 20
```

---

## 配置说明

### 修改提醒参数

编辑 `MedicineReminder.ps1` 文件的第 20-25 行：

```powershell
# ════════════════════════════════════════════════════════════════════
#  可配置参数
# ════════════════════════════════════════════════════════════════════
$script:ReminderHour     = 13      # 首次提醒小时（0-23）
$script:ReminderMinute   = 10      # 首次提醒分钟（0-59）
$script:EndHour          = 18      # 截止小时（超过此时间不再提醒）
$script:TimeoutSec       = 60      # 弹窗超时秒数
$script:LoopIntervalMin  = 5       # 未吃药时的重提醒间隔（分钟）
$script:LogFile          = Join-Path $PSScriptRoot 'MedicineReminder.log'
```

### 常用配置示例

#### 示例 1：早上 8:00 提醒
```powershell
$script:ReminderHour     = 8
$script:ReminderMinute   = 0
```

#### 示例 2：延长提醒到晚上 22:00
```powershell
$script:EndHour          = 22
```

#### 示例 3：缩短超时时间为 30 秒
```powershell
$script:TimeoutSec       = 30
```

#### 示例 4：增加重提醒间隔为 10 分钟
```powershell
$script:LoopIntervalMin  = 10
```

### 注意事项

⚠️ **修改配置后必须重启程序才能生效**

1. 右键托盘图标退出程序
2. 重新运行 `run_silent.vbs`

---

## 卸载方法

### 方法一：使用卸载脚本（推荐）

1. **以管理员身份运行卸载脚本**
   - 右键点击 `uninstall.bat`
   - 选择"**以管理员身份运行**"
   - 等待卸载完成

2. **删除项目文件**（可选）
   ```powershell
   Remove-Item -Path "D:\PowerShellAuto" -Recurse -Force
   ```

### 方法二：手动卸载

1. **删除计划任务**
   ```powershell
   # 以管理员身份打开 PowerShell
   Unregister-ScheduledTask -TaskName "MedicineReminder" -Confirm:$false
   ```

2. **删除项目文件夹**
   ```powershell
   Remove-Item -Path "D:\PowerShellAuto" -Recurse -Force
   ```

### 清理残留文件

如果需要彻底清理，还需删除：
- 日志文件：`MedicineReminder.log`（位于项目目录）
- 注册表项（如果有）：通常不会创建注册表项

---

## 文件说明

| 文件名 | 类型 | 作用 | 是否必需 |
|--------|------|------|----------|
| **MedicineReminder.ps1** | PowerShell 脚本 | 主程序，包含所有提醒逻辑 | ✅ 必需 |
| **run_silent.vbs** | VBScript 脚本 | 静默启动 PowerShell 脚本（隐藏命令行窗口） | ✅ 必需 |
| **setup.ps1** | PowerShell 脚本 | 安装/卸载脚本，配置开机自启任务 | ✅ 必需 |
| **install.bat** | 批处理文件 | 一键安装快捷方式（调用 setup.ps1） | ⭐ 推荐 |
| **uninstall.bat** | 批处理文件 | 一键卸载快捷方式（调用 setup.ps1） | ⭐ 推荐 |
| **MedicineReminder.log** | 文本文件 | 运行日志，自动创建 | 📝 自动生成 |
| **.gitignore** | Git 配置 | Git 版本控制忽略规则 | 🔧 开发用 |

### 文件关系图

```
用户操作
  ├─ install.bat ──→ setup.ps1 (安装模式) ──→ 创建计划任务
  ├─ uninstall.bat ──→ setup.ps1 (卸载模式) ──→ 删除计划任务
  └─ run_silent.vbs ──→ MedicineReminder.ps1 (隐藏窗口) ──→ 后台运行
                                              └─→ MedicineReminder.log (记录日志)
```

### 各文件详细说明

#### MedicineReminder.ps1
- **行数**：351 行
- **功能**：核心业务逻辑
  - 状态机管理（WaitingForFirst / WaitingFiveMin / ShowingDialog / Idle）
  - 定时器调度（每秒检查状态）
  - UI 界面构建（WinForms）
  - 日志记录
  - 系统托盘集成
- **依赖**：System.Windows.Forms, System.Drawing

#### run_silent.vbs
- **行数**：18 行
- **功能**：使用 WScript.Shell 以隐藏窗口模式启动 PowerShell 脚本
- **优势**：避免显示黑色命令行窗口，提升用户体验

#### setup.ps1
- **行数**：117 行
- **功能**：
  - 创建/删除 Windows 计划任务
  - 配置触发器（用户登录时）
  - 验证文件完整性
- **权限**：需要管理员权限

#### install.bat / uninstall.bat
- **行数**：各约 17-19 行
- **功能**：提供图形化安装/卸载入口
- **优势**：双击即可运行，自动请求管理员权限

---

## 故障排除

### ❌ 问题 1：程序无法启动

**症状**：双击 `run_silent.vbs` 后无任何反应

**解决方案**：
1. 检查 PowerShell 版本
   ```powershell
   $PSVersionTable.PSVersion
   ```
   确保版本 ≥ 5.0

2. 检查执行策略
   ```powershell
   Get-ExecutionPolicy
   ```
   如果为 `Restricted`，以管理员身份运行：
   ```powershell
   Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
   ```

3. 检查文件完整性
   - 确认 `MedicineReminder.ps1` 与 `run_silent.vbs` 在同一目录
   - 确认文件未被杀毒软件隔离

### ❌ 问题 2：没有收到提醒

**症状**：到达设定时间后无弹窗

**解决方案**：
1. 检查程序是否运行
   - 查看系统托盘是否有药丸图标
   - 如果没有，重新启动程序

2. 检查当前时间范围
   - 程序仅在 13:10 - 18:00 之间提醒
   - 如果超过 18:00，当天不再提醒

3. 检查日志文件
   ```powershell
   Get-Content MedicineReminder.log -Tail 30
   ```
   查看是否有异常记录

4. 检查是否已点击"已吃药"
   - 如果今天已确认吃药，当天不会再提醒
   - 等待第二天自动重置

### ❌ 问题 3：安装失败

**症状**：运行 `install.bat` 提示错误

**解决方案**：
1. 确认以管理员身份运行
   - 右键点击 → "**以管理员身份运行**"

2. 检查计划任务服务
   ```powershell
   Get-Service Schedule
   ```
   确保状态为 `Running`

3. 手动安装
   ```powershell
   # 以管理员身份打开 PowerShell
   cd D:\PowerShellAuto
   .\setup.ps1
   ```

### ❌ 问题 4：通知不显示

**症状**：有弹窗但没有系统通知

**解决方案**：
1. Windows 10/11 用户：
   - 打开"设置" → "系统" → "通知和操作"
   - 确保"获取来自应用和其他发送者的通知"已开启
   - 检查是否屏蔽了 PowerShell 的通知

2. Windows 7 用户：
   - 系统仅支持气泡通知（Balloon Tip）
   - 这是正常现象，不影响功能

### ❌ 问题 5：程序占用资源过高

**症状**：CPU 或内存占用异常

**解决方案**：
1. 检查是否有多个实例运行
   ```powershell
   Get-Process powershell | Where-Object { $_.MainWindowTitle -like "*吃药*" }
   ```
   如有多个，全部退出后重新启动

2. 重启程序
   - 右键托盘图标退出
   - 重新运行 `run_silent.vbs`

### ❌ 问题 6：日志文件过大

**症状**：`MedicineReminder.log` 文件体积过大

**解决方案**：
1. 定期清理日志
   ```powershell
   # 保留最近 30 天的日志
   $cutoffDate = (Get-Date).AddDays(-30)
   Get-Content MedicineReminder.log | Where-Object { 
       $_ -match '^\[(\d{4}-\d{2}-\d{2})' -and 
       [DateTime]::Parse($matches[1]) -ge $cutoffDate 
   } | Set-Content MedicineReminder_temp.log
   
   Move-Item MedicineReminder_temp.log MedicineReminder.log -Force
   ```

2. 或直接删除（程序会自动创建新日志）
   ```powershell
   Remove-Item MedicineReminder.log
   ```

---

## 许可证信息

本项目采用 **MIT License** 开源协议。

```
MIT License

Copyright (c) 2026 Medicine Reminder Project

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

### 免责声明

⚠️ **重要提示**：
- 本工具仅作为辅助提醒工具，不能替代专业医疗建议
- 请遵医嘱按时服药，不要因程序故障而漏服药物
- 开发者不对因使用本程序导致的任何健康问题承担责任
- 建议设置手机闹钟等多重提醒方式

---

## 📞 支持与反馈

如果您遇到问题或有改进建议，欢迎：
- 提交 Issue
- 发起 Pull Request
- 联系开发者

---

## 🙏 致谢

感谢所有为本项目做出贡献的开发者和用户！

---

**最后更新**：2026 年 7 月  
**版本**：v2.0  
**开发语言**：PowerShell / VBScript  
**适用平台**：Windows 10/11
