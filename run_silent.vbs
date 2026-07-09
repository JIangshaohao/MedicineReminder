' run_silent.vbs - 静默启动吃药提醒脚本（无黑色命令行窗口）
' 双击此文件即可在后台运行提醒程序
' 通过系统托盘图标右键可退出

Set WshShell = CreateObject("WScript.Shell")
Dim fso, scriptDir, psScript
Set fso = CreateObject("Scripting.FileSystemObject")

' 获取 VBS 文件所在目录
scriptDir = fso.GetParentFolderName(WScript.ScriptFullName)
psScript  = fso.BuildPath(scriptDir, "MedicineReminder.ps1")

' 以隐藏窗口模式运行 PowerShell 脚本
WshShell.Run "powershell.exe -ExecutionPolicy Bypass -WindowStyle Hidden -File """ & psScript & """", 0, False

Set WshShell = Nothing
Set fso      = Nothing
