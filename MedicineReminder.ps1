<#
.SYNOPSIS
    吃药提醒自动化程序 v2.0
.DESCRIPTION
    每天 13:10 弹出提醒窗口 + Windows 系统通知。
    - 点击「已吃药」：记录日志，当天不再提醒
    - 点击「未吃药」或 60 秒超时：每 5 分钟重新提醒，直到 18:00
    - 晚启动补偿：如果开机时已过 13:10 但在 18:00 前，立即弹窗
    - 跨天自动重置
    日志保存在同目录下 MedicineReminder.log
    系统托盘图标右键可退出
#>

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# ════════════════════════════════════════════════════════════════════
#  可配置参数
# ════════════════════════════════════════════════════════════════════
$script:ReminderHour     = 13
$script:ReminderMinute   = 10
$script:EndHour          = 18
$script:TimeoutSec       = 60
$script:LoopIntervalMin  = 5
$script:LogFile          = Join-Path $PSScriptRoot 'MedicineReminder.log'

# ════════════════════════════════════════════════════════════════════
#  日志
# ════════════════════════════════════════════════════════════════════
function Write-Log {
    param([string]$Msg)
    $ts = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    Add-Content -Path $script:LogFile -Value "[$ts] $Msg" -Encoding UTF8
}

# ════════════════════════════════════════════════════════════════════
#  状态机
# ════════════════════════════════════════════════════════════════════
#   WaitingForFirst  → 等待今天首次提醒（13:10）
#   WaitingFiveMin   → 等待 N 分钟后再次提醒
#   ShowingDialog    → 弹窗中（防抖锁，防止定时器重入）
#   Idle             → 今天已完成 / 已过截止时间
# ════════════════════════════════════════════════════════════════════
$script:state            = 'WaitingForFirst'
$script:doneToday        = $false
$script:nextReminderTime = [DateTime]::MaxValue

# ════════════════════════════════════════════════════════════════════
#  隐藏主窗体（消息泵 — Application.Run 必需）
# ════════════════════════════════════════════════════════════════════
$hiddenForm                  = New-Object System.Windows.Forms.Form
$hiddenForm.ShowInTaskbar    = $false
$hiddenForm.FormBorderStyle  = 'FixedToolWindow'
$hiddenForm.Size             = New-Object System.Drawing.Size(1, 1)
$hiddenForm.Opacity          = 0
$hiddenForm.StartPosition    = 'Manual'
$hiddenForm.Location         = New-Object System.Drawing.Point(-100, -100)

# ════════════════════════════════════════════════════════════════════
#  系统托盘图标
# ════════════════════════════════════════════════════════════════════
$script:notifyIcon = New-Object System.Windows.Forms.NotifyIcon
$script:notifyIcon.Icon     = [System.Drawing.SystemIcons]::Information
$script:notifyIcon.Text     = '吃药提醒 - 运行中'
$script:notifyIcon.Visible  = $true

$ctxMenu      = New-Object System.Windows.Forms.ContextMenuStrip
$exitItem     = New-Object System.Windows.Forms.ToolStripMenuItem '退出程序'
$exitItem.add_Click({
    Write-Log '用户手动退出程序'
    $script:notifyIcon.Visible = $false
    [System.Windows.Forms.Application]::Exit()
})
$ctxMenu.Items.Add($exitItem) | Out-Null
$script:notifyIcon.ContextMenuStrip = $ctxMenu

# ════════════════════════════════════════════════════════════════════
#  Toast 系统通知（WinRT 优先，失败退回气泡通知）
# ════════════════════════════════════════════════════════════════════
$script:toastOK = $false
try {
    [Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime] | Out-Null
    [Windows.Data.Xml.Dom.XmlDocument, Windows.Data.Xml.Dom, ContentType = WindowsRuntime] | Out-Null
    $script:toastOK = $true
} catch {
    $script:toastOK = $false
}

function Show-Toast {
    param([string]$Title, [string]$Body)
    if ($script:toastOK) {
        try {
            $tpl = [Windows.UI.Notifications.ToastNotificationManager]::GetTemplateContent(
                [Windows.UI.Notifications.ToastTemplateType]::ToastText02)
            $nodes = $tpl.GetElementsByTagName('text')
            $nodes.Item(0).AppendChild($tpl.CreateTextNode($Title)) | Out-Null
            $nodes.Item(1).AppendChild($tpl.CreateTextNode($Body))  | Out-Null
            $toast = [Windows.UI.Notifications.ToastNotification]::new($tpl)
            [Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier('MedicineReminder').Show($toast)
            return
        } catch { }
    }
    # 退回方案：托盘气泡通知
    if ($script:notifyIcon) {
        $script:notifyIcon.ShowBalloonTip(10000, $Title, $Body, [System.Windows.Forms.ToolTipIcon]::Warning)
    }
}

# ════════════════════════════════════════════════════════════════════
#  提醒弹窗（模态对话框 + 倒计时）
# ════════════════════════════════════════════════════════════════════
function Show-ReminderDialog {
    # ── 创建窗体 ──────────────────────────────────────────────────
    $form                  = New-Object System.Windows.Forms.Form
    $form.Text             = '吃药提醒'
    $form.Size             = New-Object System.Drawing.Size(380, 270)
    $form.FormBorderStyle  = 'FixedDialog'
    $form.MaximizeBox      = $false
    $form.MinimizeBox      = $false
    $form.StartPosition    = 'CenterScreen'
    $form.TopMost          = $true
    $form.BackColor        = [System.Drawing.Color]::White
    $form.Font             = New-Object System.Drawing.Font('Microsoft YaHei UI', 9)

    # ── 图标 ──────────────────────────────────────────────────────
    $picBox                = New-Object System.Windows.Forms.PictureBox
    $picBox.Image          = [System.Drawing.SystemIcons]::Information.ToBitmap()
    $picBox.Location       = New-Object System.Drawing.Point(25, 25)
    $picBox.Size           = New-Object System.Drawing.Size(32, 32)
    $form.Controls.Add($picBox)

    # ── 提示文字 ──────────────────────────────────────────────────
    $lbl                   = New-Object System.Windows.Forms.Label
    $lbl.Text              = "该吃药了！`n请记得按时服药，保持身体健康。"
    $lbl.Location          = New-Object System.Drawing.Point(70, 25)
    $lbl.Size              = New-Object System.Drawing.Size(280, 45)
    $lbl.Font              = New-Object System.Drawing.Font('Microsoft YaHei UI', 11)
    $form.Controls.Add($lbl)

    # ── 倒计时标签 ────────────────────────────────────────────────
    $cdLbl                 = New-Object System.Windows.Forms.Label
    $cdLbl.Text            = "（$script:TimeoutSec 秒后自动提醒）"
    $cdLbl.Location        = New-Object System.Drawing.Point(70, 78)
    $cdLbl.Size            = New-Object System.Drawing.Size(280, 20)
    $cdLbl.ForeColor       = [System.Drawing.Color]::Gray
    $cdLbl.Font            = New-Object System.Drawing.Font('Microsoft YaHei UI', 9)
    $form.Controls.Add($cdLbl)

    # ── 「已吃药」按钮（绿色） ────────────────────────────────────
    $btnTaken              = New-Object System.Windows.Forms.Button
    $btnTaken.Text         = '已吃药'
    $btnTaken.Size         = New-Object System.Drawing.Size(130, 45)
    $btnTaken.Location     = New-Object System.Drawing.Point(45, 120)
    $btnTaken.BackColor    = [System.Drawing.Color]::FromArgb(76, 175, 80)
    $btnTaken.ForeColor    = [System.Drawing.Color]::White
    $btnTaken.FlatStyle    = 'Flat'
    $btnTaken.Font         = New-Object System.Drawing.Font('Microsoft YaHei UI', 12, [System.Drawing.FontStyle]::Bold)
    $form.Controls.Add($btnTaken)

    # ── 「未吃药」按钮（红色） ────────────────────────────────────
    $btnNot                = New-Object System.Windows.Forms.Button
    $btnNot.Text           = '未吃药'
    $btnNot.Size           = New-Object System.Drawing.Size(130, 45)
    $btnNot.Location       = New-Object System.Drawing.Point(195, 120)
    $btnNot.BackColor      = [System.Drawing.Color]::FromArgb(244, 67, 54)
    $btnNot.ForeColor      = [System.Drawing.Color]::White
    $btnNot.FlatStyle      = 'Flat'
    $btnNot.Font           = New-Object System.Drawing.Font('Microsoft YaHei UI', 12, [System.Drawing.FontStyle]::Bold)
    $form.Controls.Add($btnNot)

    # ── 按钮事件（纯 scriptblock，通过 form.Tag 传递结果） ───────
    #    设置 DialogResult 后 form 自动关闭，无需手动 Close()
    $btnTaken.add_Click({
        $this.FindForm().Tag = 'taken'
        $this.FindForm().DialogResult = [System.Windows.Forms.DialogResult]::OK
        Write-Log "用户点击: 已吃药"
    })

    $btnNot.add_Click({
        $this.FindForm().Tag = 'not_taken'
        $this.FindForm().DialogResult = [System.Windows.Forms.DialogResult]::Cancel
        Write-Log "用户点击: 未吃药"
    })

    # ── 倒计时定时器 ──────────────────────────────────────────────
    $remaining    = $script:TimeoutSec
    $cdTimer      = New-Object System.Windows.Forms.Timer
    $cdTimer.Interval = 1000

    $cdTimer.add_Tick({
        $remaining--
        if ($remaining -le 0) {
            $cdTimer.Stop()
            $form.Tag = 'timeout'
            $form.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
            Write-Log '弹窗超时（60 秒无操作）自动关闭'
        } else {
            $cdLbl.Text = "（$remaining 秒后自动提醒）"
        }
    })
    $cdTimer.Start()

    # ── 弹出窗口 ──────────────────────────────────────────────────
    Write-Log '弹窗弹出'
    Show-Toast -Title '吃药提醒' -Body '该吃药了！请记得按时服药。'

    [void]$form.ShowDialog()

    # 先捕获结果，再释放资源（Dispose 后读 Tag 不可靠）
    $dialogResult = $form.Tag

    $cdTimer.Stop()
    $cdTimer.Dispose()
    $form.Dispose()

    return $dialogResult
}

# ════════════════════════════════════════════════════════════════════
#  处理弹窗结果 → 推进状态机
# ════════════════════════════════════════════════════════════════════
function Process-Result {
    param([string]$Result)

    switch ($Result) {
        'taken' {
            Write-Log '今日提醒结束（已吃药）'
            $script:doneToday = $true
            $script:state     = 'Idle'
        }
        'not_taken' {
            Write-Log '将在 5 分钟后再次提醒'
            $script:nextReminderTime = (Get-Date).AddMinutes($script:LoopIntervalMin)
            $script:state = 'WaitingFiveMin'
        }
        'timeout' {
            Write-Log '将在 5 分钟后再次提醒（超时触发）'
            $script:nextReminderTime = (Get-Date).AddMinutes($script:LoopIntervalMin)
            $script:state = 'WaitingFiveMin'
        }
        default {
            Write-Log "未知结果: $Result - 将在 5 分钟后重试"
            $script:nextReminderTime = (Get-Date).AddMinutes($script:LoopIntervalMin)
            $script:state = 'WaitingFiveMin'
        }
    }
}

# ════════════════════════════════════════════════════════════════════
#  主定时器（每秒触发，驱动状态机）
# ════════════════════════════════════════════════════════════════════
$mainTimer = New-Object System.Windows.Forms.Timer
$mainTimer.Interval = 1000

$mainTimer.add_Tick({
    # 防抖：弹窗期间不执行任何调度逻辑
    if ($script:state -eq 'ShowingDialog') { return }

    $now = Get-Date

    switch ($script:state) {

        'WaitingForFirst' {
            if (-not $script:doneToday) {
                $reminderTime = (Get-Date).Date.AddHours($script:ReminderHour).AddMinutes($script:ReminderMinute)

                if ($now -ge $reminderTime -and $now.Hour -lt $script:EndHour) {
                    # 晚启动补偿：已过提醒时间但在截止前，立即弹窗
                    Write-Log '晚启动补偿：已过提醒时间，立即弹出提醒'
                    $script:state = 'ShowingDialog'
                    try {
                        $result = Show-ReminderDialog
                        Process-Result -Result $result
                    } catch {
                        Write-Log "弹窗异常: $_"
                        $script:nextReminderTime = (Get-Date).AddMinutes($script:LoopIntervalMin)
                        $script:state = 'WaitingFiveMin'
                    }
                }
                elseif ($now.Hour -ge $script:EndHour) {
                    Write-Log '已过截止时间，今日不再提醒'
                    $script:state = 'Idle'
                }
            }
        }

        'WaitingFiveMin' {
            if ($now.Hour -ge $script:EndHour) {
                Write-Log '已过 18:00，今日提醒结束'
                $script:state = 'Idle'
            }
            elseif ($now -ge $script:nextReminderTime) {
                $script:state = 'ShowingDialog'
                try {
                    $result = Show-ReminderDialog
                    Process-Result -Result $result
                } catch {
                    Write-Log "弹窗异常: $_"
                    $script:nextReminderTime = (Get-Date).AddMinutes($script:LoopIntervalMin)
                    $script:state = 'WaitingFiveMin'
                }
            }
        }
    }

    # 更新托盘提示文字（Windows 限制 63 字符）
    $stateText = switch ($script:state) {
        'WaitingForFirst' { "等待 {0}:{1}" -f $script:ReminderHour, $script:ReminderMinute.ToString().PadLeft(2, '0') }
        'WaitingFiveMin'  { "下次 $($script:nextReminderTime.ToString('HH:mm'))" }
        'Idle'            { '今日已完成' }
        'ShowingDialog'   { '提醒中...' }
        default           { $script:state }
    }
    $script:notifyIcon.Text = $stateText
})

# ════════════════════════════════════════════════════════════════════
#  每日重置定时器（跨天自动恢复）
# ════════════════════════════════════════════════════════════════════
$resetTimer = New-Object System.Windows.Forms.Timer
$resetTimer.Interval = 60000
$script:lastDate = (Get-Date).Date

$resetTimer.add_Tick({
    $today = (Get-Date).Date
    if ($today -gt $script:lastDate) {
        $script:lastDate     = $today
        $script:doneToday    = $false
        $script:state        = 'WaitingForFirst'
        Write-Log '新的一天，重置状态，等待今天 13:10 提醒'
    }
})

# ════════════════════════════════════════════════════════════════════
#  启动
# ════════════════════════════════════════════════════════════════════
Write-Log '=========================================='
Write-Log '吃药提醒程序 v2.0 已启动'
Write-Log ("首次提醒时间: {0}:{1}" -f $script:ReminderHour, $script:ReminderMinute.ToString().PadLeft(2, '0'))
Write-Log "弹窗超时: ${script:TimeoutSec}秒 | 循环间隔: ${script:LoopIntervalMin}分钟 | 截止时间: ${script:EndHour}:00"
Write-Log '=========================================='

$mainTimer.Start()
$resetTimer.Start()

$script:notifyIcon.ShowBalloonTip(
    5000, '吃药提醒', '程序已在后台运行，将在 13:10 首次提醒。',
    [System.Windows.Forms.ToolTipIcon]::Info)

[System.Windows.Forms.Application]::Run($hiddenForm)
