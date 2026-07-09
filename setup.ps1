<#
.SYNOPSIS
    一键安装/卸载「吃药提醒」开机自启任务
.DESCRIPTION
    使用 Windows 任务计划程序（Task Scheduler）注册开机自启任务。
    需要以管理员权限运行（右键 → 以管理员身份运行）。
.EXAMPLE
    安装：右键 setup.ps1 → 使用 PowerShell 运行（需管理员）
    卸载：powershell -ExecutionPolicy Bypass -File setup.ps1 -Uninstall
#>

param(
    [switch]$Uninstall
)

$TaskName    = 'MedicineReminder'
$ScriptDir   = $PSScriptRoot
$VBSPath     = Join-Path $ScriptDir 'run_silent.vbs'

if ($Uninstall) {
    # ── 卸载 ──────────────────────────────────────────────────────
    Write-Host '正在卸载吃药提醒计划任务...' -ForegroundColor Yellow
    try {
        Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false -ErrorAction Stop
        Write-Host '已成功卸载吃药提醒计划任务。' -ForegroundColor Green
    } catch {
        Write-Host "卸载失败：$_" -ForegroundColor Red
    }
    Write-Host ''
    Write-Host '按任意键退出...'
    $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
    return
}

# ── 安装 ──────────────────────────────────────────────────────────
Write-Host '============================================' -ForegroundColor Cyan
Write-Host '  吃药提醒 - 开机自启安装程序' -ForegroundColor Cyan
Write-Host '============================================' -ForegroundColor Cyan
Write-Host ''

# 检查 VBS 文件是否存在
if (-not (Test-Path $VBSPath)) {
    Write-Host "错误：找不到 $VBSPath" -ForegroundColor Red
    Write-Host '请确保 run_silent.vbs 与本脚本在同一目录下。' -ForegroundColor Red
    Write-Host ''
    Write-Host '按任意键退出...'
    $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
    return
}

# 检查是否已存在同名任务
$existing = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
if ($existing) {
    Write-Host "检测到已有同名计划任务，将更新配置..." -ForegroundColor Yellow
    Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false
}

# 创建计划任务
try {
    # 触发器：用户登录时
    $trigger = New-ScheduledTaskTrigger -AtLogOn

    # 操作：运行 VBS 脚本（静默启动 PowerShell）
    $action = New-ScheduledTaskAction `
        -Execute 'wscript.exe' `
        -Argument "`"$VBSPath`""

    # 设置：允许按需运行、不强制终止
    $settings = New-ScheduledTaskSettingsSet `
        -AllowStartIfOnBatteries `
        -DontStopIfGoingOnBatteries `
        -StartWhenAvailable `
        -ExecutionTimeLimit ([TimeSpan]::Zero)

    # 注册任务（当前用户）
    Register-ScheduledTask `
        -TaskName $TaskName `
        -Trigger $trigger `
        -Action $action `
        -Settings $settings `
        -Description '吃药提醒自动化程序 - 每天 13:10 提醒吃药' `
        -RunLevel Limited `
        | Out-Null

    Write-Host ''
    Write-Host '安装成功！' -ForegroundColor Green
    Write-Host ''
    Write-Host '配置详情：' -ForegroundColor Cyan
    Write-Host "  任务名称：$TaskName"
    Write-Host "  触发条件：每次用户登录时自动启动"
    Write-Host "  脚本路径：$VBSPath"
    Write-Host "  首次提醒：每天 13:10"
    Write-Host "  循环间隔：每 5 分钟（点击「未吃药」或超时后）"
    Write-Host "  截止时间：18:00"
    Write-Host ''
    Write-Host '提示：' -ForegroundColor Yellow
    Write-Host '  - 程序启动后会在系统托盘显示图标'
    Write-Host '  - 右键托盘图标可退出程序'
    Write-Host '  - 日志保存在同目录下的 MedicineReminder.log'
    Write-Host ''
    Write-Host '如需立即体验，请双击 run_silent.vbs' -ForegroundColor Cyan
    Write-Host ''
    Write-Host '如需卸载，运行：' -ForegroundColor Gray
    Write-Host "  powershell -ExecutionPolicy Bypass -File `"$PSCommandPath`" -Uninstall" -ForegroundColor Gray

} catch {
    Write-Host ''
    Write-Host "安装失败：$_" -ForegroundColor Red
    Write-Host ''
    Write-Host '请确保以管理员权限运行此脚本。' -ForegroundColor Yellow
    Write-Host '方法：右键点击脚本 → 使用 PowerShell 运行（需管理员权限）' -ForegroundColor Yellow
}

Write-Host ''
Write-Host '按任意键退出...'
$null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
