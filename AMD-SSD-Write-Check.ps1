<#
.SYNOPSIS
    AMD SSD Write & Log Checker v1.0
    Checks AMD Radeon / Chipset background processes for excessive SSD writes (idle & window-resize bugs)
    and inspects AMD log/cache directories on the system drive.

.LINK
    https://github.com/norrest/AMD-SSD-Write-Check

.EXAMPLE
    & ([scriptblock]::Create((irm "https://raw.githubusercontent.com/norrest/AMD-SSD-Write-Check/main/AMD-SSD-Write-Check.ps1")))
#>

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[System.Windows.Forms.Application]::EnableVisualStyles()

$Script:Version = "1.0"
$Script:CurrentLang = "UA"
$Script:IsRunning = $false

# Localization dictionary (EN / UA)
$Script:Lang = @{
    UA = @{
        WindowTitle   = "AMD SSD Write & Log Checker v1.0"
        Subtitle      = "Діагностика фонового запису драйверів AMD та перевірка логів на системному диску"
        BtnCheck1     = "Перевірка 1: Активність запису (15 сек)"
        BtnCheck2     = "Перевірка 2: Логи та кеш AMD (Диск C:)"
        BtnCopy       = "Копіювати звіт"
        BtnClear      = "Очистити"
        StatusReady   = "Готово до перевірки. Оберіть режим вище."
        StatusRun1    = "Йде замір ({0} с)... Рухайте це вікно або змінюйте розмір будь-якого вікна!"
        StatusRun2    = "Сканування папок та логів AMD на системному диску..."
        StatusDone    = "Перевірку завершено."
        CopiedMsg     = "Звіт скопійовано в буфер обміну!"
        Check1Header  = "=== ПЕРЕВІРКА 1: АКТИВНІСТЬ ЗАПИСУ ПРОЦЕСІВ AMD (15 СЕК) ==="
        Check1Hint    = "Підказка: під час тесту рухайте вікна для перевірки багу зміни розміру вікон."
        NoProcFound   = "[OK] Фонових процесів AMD не знайдено у пам'яті."
        ColProcess    = "Процес"
        ColPID        = "PID"
        ColTotalMB    = "Записано всього (МБ)"
        ColSpeedKBs   = "Швидкість (КБ/с)"
        ColState      = "Статус"
        Verdict1OK    = "[ВИСНОВОК: НОРМА] Аномального фонового запису (atieclxx / atiesrxx) не виявлено."
        Verdict1Warn  = "[УВАГА: ВИЯВЛЕНО АКТИВНИЙ ЗАПИС] Процес AMD активно пише на SSD! Рекомендовано оновити драйвер до Adrenalin 26.11.1+."
        InstallerNote = "[ІНФО] AMDSoftwareInstaller.exe записав {0} МБ під час розпакування/встановлення (зараз 0 КБ/с — це норма)."
        Check2Header  = "=== ПЕРЕВІРКА 2: ПАПКИ ЛОГІВ ТА КЕШУ AMD НА СИСТЕМНОМУ ДИСКУ ==="
        ColFolder     = "Категорія / Шлях"
        ColExists     = "Наявність"
        ColFiles      = "Файлів"
        ColSizeMB     = "Розмір (МБ)"
        ExistsYes     = "Є"
        ExistsNo      = "Немає"
        Verdict2OK    = "[ВИСНОВОК: НОРМА] Папки логів AMD (зокрема EEUDumps) не засмічують системний диск."
        Verdict2Warn  = "[УВАГА] Виявлено великий обсяг файлів у папках AMD ({0} МБ). Перевірте таблицю вище."
        NoteC_AMD     = "[ІНФО] Папка C:\AMD містить {0} МБ розпакованих файлів інсталятора. Її можна безпечно видалити після встановлення драйвера."
    }
    EN = @{
        WindowTitle   = "AMD SSD Write & Log Checker v1.0"
        Subtitle      = "Diagnose AMD driver background SSD writes and inspect system drive logs"
        BtnCheck1     = "Check 1: Process Write Activity (15s)"
        BtnCheck2     = "Check 2: AMD Logs & Cache (Drive C:)"
        BtnCopy       = "Copy Report"
        BtnClear      = "Clear"
        StatusReady   = "Ready. Select a check mode above."
        StatusRun1    = "Measuring ({0}s left)... Move this window or resize any app window now!"
        StatusRun2    = "Scanning AMD log and cache folders on the system drive..."
        StatusDone    = "Check completed."
        CopiedMsg     = "Report copied to clipboard!"
        Check1Header  = "=== CHECK 1: AMD PROCESS WRITE ACTIVITY (15 SECONDS) ==="
        Check1Hint    = "Tip: Move or resize windows during the test to check for the window-resize write bug."
        NoProcFound   = "[OK] No running AMD background processes found."
        ColProcess    = "Process"
        ColPID        = "PID"
        ColTotalMB    = "Total Written (MB)"
        ColSpeedKBs   = "Speed (KB/s)"
        ColState      = "Status"
        Verdict1OK    = "[VERDICT: OK] No abnormal background SSD writes (atieclxx / atiesrxx) detected."
        Verdict1Warn  = "[WARNING: EXCESSIVE WRITES DETECTED] An AMD process is actively writing to the SSD! Update to Adrenalin 26.11.1+."
        InstallerNote = "[INFO] AMDSoftwareInstaller.exe wrote {0} MB during driver unpacking/setup (currently 0 KB/s - normal)."
        Check2Header  = "=== CHECK 2: AMD LOG & CACHE FOLDERS ON SYSTEM DRIVE ==="
        ColFolder     = "Category / Path"
        ColExists     = "Exists"
        ColFiles      = "Files"
        ColSizeMB     = "Size (MB)"
        ExistsYes     = "Yes"
        ExistsNo      = "No"
        Verdict2OK    = "[VERDICT: OK] AMD log folders (including EEUDumps) are not bloating the system drive."
        Verdict2Warn  = "[WARNING] Large amount of data found in AMD log folders ({0} MB). See details above."
        NoteC_AMD     = "[INFO] C:\AMD contains {0} MB of unpacked installer files. It can be safely deleted after driver installation."
    }
}

# Build GUI Form
$Form = New-Object System.Windows.Forms.Form
$Form.Text = $Script:Lang[$Script:CurrentLang].WindowTitle
$Form.Size = New-Object System.Drawing.Size(780, 560)
$Form.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedSingle
$Form.MaximizeBox = $false
$Form.StartPosition = "CenterScreen"
$Form.BackColor = [System.Drawing.Color]::FromArgb(24, 24, 28)
$Form.ForeColor = [System.Drawing.Color]::FromArgb(240, 240, 245)
$Form.Font = New-Object System.Drawing.Font("Segoe UI", 9.5)

# Top Header Panel
$HeaderPanel = New-Object System.Windows.Forms.Panel
$HeaderPanel.Dock = "Top"
$HeaderPanel.Height = 70
$HeaderPanel.BackColor = [System.Drawing.Color]::FromArgb(32, 32, 38)
$Form.Controls.Add($HeaderPanel)

# Accent Line
$AccentLine = New-Object System.Windows.Forms.Panel
$AccentLine.Dock = "Bottom"
$AccentLine.Height = 3
$AccentLine.BackColor = [System.Drawing.Color]::FromArgb(224, 36, 48) # AMD Red
$HeaderPanel.Controls.Add($AccentLine)

# Title Label
$TitleLabel = New-Object System.Windows.Forms.Label
$TitleLabel.Text = "AMD SSD Write & Log Checker v1.0"
$TitleLabel.Font = New-Object System.Drawing.Font("Segoe UI Semibold", 14, [System.Drawing.FontStyle]::Bold)
$TitleLabel.ForeColor = [System.Drawing.Color]::White
$TitleLabel.Location = New-Object System.Drawing.Point(18, 10)
$TitleLabel.AutoSize = $true
$HeaderPanel.Controls.Add($TitleLabel)

# Subtitle Label
$SubtitleLabel = New-Object System.Windows.Forms.Label
$SubtitleLabel.Location = New-Object System.Drawing.Point(20, 40)
$SubtitleLabel.Size = New-Object System.Drawing.Size(580, 22)
$SubtitleLabel.ForeColor = [System.Drawing.Color]::FromArgb(180, 180, 195)
$HeaderPanel.Controls.Add($SubtitleLabel)

# Language Buttons (UA / EN)
$BtnLangUA = New-Object System.Windows.Forms.Button
$BtnLangUA.Text = "UA"
$BtnLangUA.Size = New-Object System.Drawing.Size(48, 30)
$BtnLangUA.Location = New-Object System.Drawing.Point(645, 18)
$BtnLangUA.FlatStyle = "Flat"
$BtnLangUA.FlatAppearance.BorderSize = 1
$BtnLangUA.Cursor = [System.Windows.Forms.Cursors]::Hand
$HeaderPanel.Controls.Add($BtnLangUA)

$BtnLangEN = New-Object System.Windows.Forms.Button
$BtnLangEN.Text = "EN"
$BtnLangEN.Size = New-Object System.Drawing.Size(48, 30)
$BtnLangEN.Location = New-Object System.Drawing.Point(698, 18)
$BtnLangEN.FlatStyle = "Flat"
$BtnLangEN.FlatAppearance.BorderSize = 1
$BtnLangEN.Cursor = [System.Windows.Forms.Cursors]::Hand
$HeaderPanel.Controls.Add($BtnLangEN)

# Main Action Buttons Panel
$ActionPanel = New-Object System.Windows.Forms.Panel
$ActionPanel.Location = New-Object System.Drawing.Point(18, 84)
$ActionPanel.Size = New-Object System.Drawing.Size(728, 52)
$Form.Controls.Add($ActionPanel)

$BtnCheck1 = New-Object System.Windows.Forms.Button
$BtnCheck1.Size = New-Object System.Drawing.Size(354, 44)
$BtnCheck1.Location = New-Object System.Drawing.Point(0, 4)
$BtnCheck1.FlatStyle = "Flat"
$BtnCheck1.BackColor = [System.Drawing.Color]::FromArgb(208, 34, 46)
$BtnCheck1.ForeColor = [System.Drawing.Color]::White
$BtnCheck1.FlatAppearance.BorderColor = [System.Drawing.Color]::FromArgb(235, 60, 70)
$BtnCheck1.Font = New-Object System.Drawing.Font("Segoe UI Semibold", 10, [System.Drawing.FontStyle]::Bold)
$BtnCheck1.Cursor = [System.Windows.Forms.Cursors]::Hand
$ActionPanel.Controls.Add($BtnCheck1)

$BtnCheck2 = New-Object System.Windows.Forms.Button
$BtnCheck2.Size = New-Object System.Drawing.Size(354, 44)
$BtnCheck2.Location = New-Object System.Drawing.Point(372, 4)
$BtnCheck2.FlatStyle = "Flat"
$BtnCheck2.BackColor = [System.Drawing.Color]::FromArgb(45, 48, 58)
$BtnCheck2.ForeColor = [System.Drawing.Color]::White
$BtnCheck2.FlatAppearance.BorderColor = [System.Drawing.Color]::FromArgb(85, 90, 105)
$BtnCheck2.Font = New-Object System.Drawing.Font("Segoe UI Semibold", 10, [System.Drawing.FontStyle]::Bold)
$BtnCheck2.Cursor = [System.Windows.Forms.Cursors]::Hand
$ActionPanel.Controls.Add($BtnCheck2)

# Progress Bar
$ProgressBar = New-Object System.Windows.Forms.ProgressBar
$ProgressBar.Location = New-Object System.Drawing.Point(18, 142)
$ProgressBar.Size = New-Object System.Drawing.Size(726, 14)
$ProgressBar.Minimum = 0
$ProgressBar.Maximum = 150
$ProgressBar.Value = 0
$ProgressBar.Style = "Continuous"
$Form.Controls.Add($ProgressBar)

# Output Console TextBox
$OutputBox = New-Object System.Windows.Forms.RichTextBox
$OutputBox.Location = New-Object System.Drawing.Point(18, 164)
$OutputBox.Size = New-Object System.Drawing.Size(726, 300)
$OutputBox.BackColor = [System.Drawing.Color]::FromArgb(16, 16, 20)
$OutputBox.ForeColor = [System.Drawing.Color]::FromArgb(225, 230, 238)
$OutputBox.Font = New-Object System.Drawing.Font("Consolas", 9.75)
$OutputBox.ReadOnly = $true
$OutputBox.BorderStyle = "None"
$OutputBox.WordWrap = $false
$OutputBox.ScrollBars = "Both"
$Form.Controls.Add($OutputBox)

# Bottom Bar (Status + Copy/Clear buttons)
$StatusLabel = New-Object System.Windows.Forms.Label
$StatusLabel.Location = New-Object System.Drawing.Point(18, 478)
$StatusLabel.Size = New-Object System.Drawing.Size(470, 26)
$StatusLabel.ForeColor = [System.Drawing.Color]::FromArgb(170, 175, 190)
$Form.Controls.Add($StatusLabel)

$BtnCopy = New-Object System.Windows.Forms.Button
$BtnCopy.Size = New-Object System.Drawing.Size(130, 32)
$BtnCopy.Location = New-Object System.Drawing.Point(504, 472)
$BtnCopy.FlatStyle = "Flat"
$BtnCopy.BackColor = [System.Drawing.Color]::FromArgb(40, 42, 50)
$BtnCopy.ForeColor = [System.Drawing.Color]::White
$BtnCopy.FlatAppearance.BorderColor = [System.Drawing.Color]::FromArgb(75, 80, 95)
$BtnCopy.Cursor = [System.Windows.Forms.Cursors]::Hand
$Form.Controls.Add($BtnCopy)

$BtnClear = New-Object System.Windows.Forms.Button
$BtnClear.Size = New-Object System.Drawing.Size(102, 32)
$BtnClear.Location = New-Object System.Drawing.Point(642, 472)
$BtnClear.FlatStyle = "Flat"
$BtnClear.BackColor = [System.Drawing.Color]::FromArgb(40, 42, 50)
$BtnClear.ForeColor = [System.Drawing.Color]::White
$BtnClear.FlatAppearance.BorderColor = [System.Drawing.Color]::FromArgb(75, 80, 95)
$BtnClear.Cursor = [System.Windows.Forms.Cursors]::Hand
$Form.Controls.Add($BtnClear)

function Update-LanguageUI {
    $L = $Script:Lang[$Script:CurrentLang]
    $Form.Text = $L.WindowTitle
    $SubtitleLabel.Text = $L.Subtitle
    $BtnCheck1.Text = $L.BtnCheck1
    $BtnCheck2.Text = $L.BtnCheck2
    $BtnCopy.Text = $L.BtnCopy
    $BtnClear.Text = $L.BtnClear
    if (-not $Script:IsRunning) {
        $StatusLabel.Text = $L.StatusReady
    }

    if ($Script:CurrentLang -eq "UA") {
        $BtnLangUA.BackColor = [System.Drawing.Color]::FromArgb(208, 34, 46)
        $BtnLangUA.ForeColor = [System.Drawing.Color]::White
        $BtnLangEN.BackColor = [System.Drawing.Color]::FromArgb(45, 48, 58)
        $BtnLangEN.ForeColor = [System.Drawing.Color]::FromArgb(180, 180, 195)
    } else {
        $BtnLangEN.BackColor = [System.Drawing.Color]::FromArgb(208, 34, 46)
        $BtnLangEN.ForeColor = [System.Drawing.Color]::White
        $BtnLangUA.BackColor = [System.Drawing.Color]::FromArgb(45, 48, 58)
        $BtnLangUA.ForeColor = [System.Drawing.Color]::FromArgb(180, 180, 195)
    }
}

function Append-ColoredLine {
    param(
        [string]$Text,
        [System.Drawing.Color]$Color = [System.Drawing.Color]::FromArgb(225, 230, 238)
    )
    $OutputBox.SelectionStart = $OutputBox.TextLength
    $OutputBox.SelectionLength = 0
    $OutputBox.SelectionColor = $Color
    $OutputBox.AppendText("$Text`r`n")
    $OutputBox.ScrollToCaret()
}

# Language Switch Events
$BtnLangUA.Add_Click({
    $Script:CurrentLang = "UA"
    Update-LanguageUI
})

$BtnLangEN.Add_Click({
    $Script:CurrentLang = "EN"
    Update-LanguageUI
})

# Check 1: Process Write Activity (15s live test + cumulative writes since boot)
$BtnCheck1.Add_Click({
    if ($Script:IsRunning) { return }
    $Script:IsRunning = $true
    $BtnCheck1.Enabled = $false
    $BtnCheck2.Enabled = $false
    $L = $Script:Lang[$Script:CurrentLang]

    if ($OutputBox.TextLength -gt 0) { Append-ColoredLine "" }
    Append-ColoredLine $L.Check1Header ([System.Drawing.Color]::FromArgb(90, 190, 255))
    Append-ColoredLine $L.Check1Hint ([System.Drawing.Color]::FromArgb(165, 170, 185))

    $RegexFilter = '^(atieclxx|atiesrxx|RadeonSoftware|AMDRSServ|amdfendrsr|AmdPpkgSvc|AMD.*)\.exe$'
    $Snap1 = @(Get-CimInstance Win32_Process -ErrorAction SilentlyContinue | Where-Object { $_.Name -match $RegexFilter })

    if ($Snap1.Count -eq 0) {
        Append-ColoredLine $L.NoProcFound ([System.Drawing.Color]::FromArgb(100, 230, 130))
        $StatusLabel.Text = $L.StatusDone
        $BtnCheck1.Enabled = $true
        $BtnCheck2.Enabled = $true
        $Script:IsRunning = $false
        return
    }

    # Responsive 15-second loop (150 x 100ms) so the user can move/resize windows during measurement
    $ProgressBar.Value = 0
    for ($i = 1; $i -le 150; $i++) {
        $SecLeft = [math]::Ceiling((150 - $i) / 10.0)
        $StatusLabel.Text = [string]::Format($L.StatusRun1, $SecLeft)
        $ProgressBar.Value = $i
        [System.Windows.Forms.Application]::DoEvents()
        Start-Sleep -Milliseconds 100
    }

    $Snap2 = @(Get-CimInstance Win32_Process -ErrorAction SilentlyContinue | Where-Object { $_.Name -match $RegexFilter })

    $Results = @()
    $HasBug = $false
    $InstallerMB = 0

    foreach ($p2 in $Snap2) {
        $p1 = $Snap1 | Where-Object { $_.ProcessId -eq $p2.ProcessId } | Select-Object -First 1
        $TotalMB = [math]::Round($p2.WriteTransferCount / 1MB, 2)
        $SpeedKBs = 0
        if ($p1) {
            $SpeedKBs = [math]::Round(($p2.WriteTransferCount - $p1.WriteTransferCount) / 15.0 / 1KB, 2)
        }

        $State = "OK"
        if ($p2.Name -eq "AMDSoftwareInstaller.exe") {
            $InstallerMB = $TotalMB
            if ($SpeedKBs -gt 50) { $State = "SETUP" }
        } elseif ($SpeedKBs -gt 50 -or ($p2.Name -in @("atieclxx.exe", "atiesrxx.exe") -and $TotalMB -gt 200)) {
            $State = "WARN!"
            $HasBug = $true
        }

        $Results += [PSCustomObject]@{
            Process  = $p2.Name
            PID      = $p2.ProcessId
            TotalMB  = $TotalMB
            SpeedKBs = $SpeedKBs
            State    = $State
        }
    }

    Append-ColoredLine ""
    $FormatStr = "{0,-26} {1,-8} {2,20} {3,17}   {4}"
    Append-ColoredLine ($FormatStr -f $L.ColProcess, $L.ColPID, $L.ColTotalMB, $L.ColSpeedKBs, $L.ColState) ([System.Drawing.Color]::White)
    Append-ColoredLine ("-" * 82) ([System.Drawing.Color]::FromArgb(100, 105, 120))

    foreach ($row in $Results) {
        $RowColor = if ($row.State -eq "WARN!") {
            [System.Drawing.Color]::FromArgb(255, 95, 95)
        } elseif ($row.State -eq "SETUP") {
            [System.Drawing.Color]::FromArgb(255, 210, 90)
        } else {
            [System.Drawing.Color]::FromArgb(220, 225, 235)
        }
        $Line = $FormatStr -f $row.Process, $row.PID, ("{0:N2}" -f $row.TotalMB), ("{0:N2}" -f $row.SpeedKBs), $row.State
        Append-ColoredLine $Line $RowColor
    }

    Append-ColoredLine ("-" * 82) ([System.Drawing.Color]::FromArgb(100, 105, 120))
    if ($HasBug) {
        Append-ColoredLine $L.Verdict1Warn ([System.Drawing.Color]::FromArgb(255, 95, 95))
    } else {
        Append-ColoredLine $L.Verdict1OK ([System.Drawing.Color]::FromArgb(100, 230, 130))
    }
    if ($InstallerMB -gt 50) {
        Append-ColoredLine ([string]::Format($L.InstallerNote, $InstallerMB)) ([System.Drawing.Color]::FromArgb(255, 210, 90))
    }

    $ProgressBar.Value = 0
    $StatusLabel.Text = $L.StatusDone
    $BtnCheck1.Enabled = $true
    $BtnCheck2.Enabled = $true
    $Script:IsRunning = $false
})

# Check 2: AMD Logs & Cache Folders on System Drive
$BtnCheck2.Add_Click({
    if ($Script:IsRunning) { return }
    $Script:IsRunning = $true
    $BtnCheck1.Enabled = $false
    $BtnCheck2.Enabled = $false
    $L = $Script:Lang[$Script:CurrentLang]

    $StatusLabel.Text = $L.StatusRun2
    [System.Windows.Forms.Application]::DoEvents()

    if ($OutputBox.TextLength -gt 0) { Append-ColoredLine "" }
    Append-ColoredLine $L.Check2Header ([System.Drawing.Color]::FromArgb(90, 190, 255))

    $TargetPaths = @(
        @{ Label = "System32 EEUDumps";   Path = "$env:SystemRoot\System32\AMD\EEUDumps"; IsLog = $true }
        @{ Label = "SystemProfile AMD";   Path = "$env:SystemRoot\System32\config\systemprofile\AppData\Local\AMD"; IsLog = $true }
        @{ Label = "LocalAppData AMD";    Path = "$env:LOCALAPPDATA\AMD"; IsLog = $false }
        @{ Label = "RoamingAppData AMD";  Path = "$env:APPDATA\AMD"; IsLog = $false }
        @{ Label = "Installer (C:\AMD)";  Path = "C:\AMD"; IsLog = $false }
    )

    # Also check DriverStore for any EeuDumps subfolder
    $DriverStoreDumps = @(Get-ChildItem "$env:SystemRoot\System32\DriverStore\FileRepository\amdfendr*" -Directory -ErrorAction SilentlyContinue | ForEach-Object {
        $Sub = Join-Path $_.FullName "AMD\EeuDumps"
        if (Test-Path $Sub) { $Sub }
    })
    foreach ($dsPath in $DriverStoreDumps) {
        $TargetPaths += @{ Label = "DriverStore EEUDumps"; Path = $dsPath; IsLog = $true }
    }

    Append-ColoredLine ""
    $FormatStr = "{0,-48} {1,-10} {2,9} {3,13}"
    Append-ColoredLine ($FormatStr -f $L.ColFolder, $L.ColExists, $L.ColFiles, $L.ColSizeMB) ([System.Drawing.Color]::White)
    Append-ColoredLine ("-" * 83) ([System.Drawing.Color]::FromArgb(100, 105, 120))

    $LogBloatMB = 0
    $CAmdSizeMB = 0

    foreach ($item in $TargetPaths) {
        [System.Windows.Forms.Application]::DoEvents()
        $PathStr = $item.Path
        $DisplayPath = if ($PathStr.Length -gt 46) { "..." + $PathStr.Substring($PathStr.Length - 43) } else { $PathStr }

        if (Test-Path -LiteralPath $PathStr) {
            $Files = @(Get-ChildItem -LiteralPath $PathStr -Recurse -File -Force -ErrorAction SilentlyContinue)
            $Count = $Files.Count
            $Bytes = ($Files | Measure-Object -Property Length -Sum -ErrorAction SilentlyContinue).Sum
            if (-not $Bytes) { $Bytes = 0 }
            $SizeMB = [math]::Round($Bytes / 1MB, 2)

            if ($item.IsLog -and $SizeMB -gt 100) {
                $LogBloatMB += $SizeMB
            }
            if ($PathStr -eq "C:\AMD") {
                $CAmdSizeMB = $SizeMB
            }

            $RowColor = if ($item.IsLog -and $SizeMB -gt 100) {
                [System.Drawing.Color]::FromArgb(255, 95, 95)
            } elseif ($SizeMB -gt 500) {
                [System.Drawing.Color]::FromArgb(255, 210, 90)
            } else {
                [System.Drawing.Color]::FromArgb(220, 225, 235)
            }

            $Line = $FormatStr -f $DisplayPath, $L.ExistsYes, $Count, ("{0:N2}" -f $SizeMB)
            Append-ColoredLine $Line $RowColor
        } else {
            $Line = $FormatStr -f $DisplayPath, $L.ExistsNo, 0, ("{0:N2}" -f 0)
            Append-ColoredLine $Line ([System.Drawing.Color]::FromArgb(130, 135, 150))
        }
    }

    Append-ColoredLine ("-" * 83) ([System.Drawing.Color]::FromArgb(100, 105, 120))
    if ($LogBloatMB -gt 100) {
        Append-ColoredLine ([string]::Format($L.Verdict2Warn, $LogBloatMB)) ([System.Drawing.Color]::FromArgb(255, 95, 95))
    } else {
        Append-ColoredLine $L.Verdict2OK ([System.Drawing.Color]::FromArgb(100, 230, 130))
    }

    if ($CAmdSizeMB -gt 100) {
        Append-ColoredLine ([string]::Format($L.NoteC_AMD, $CAmdSizeMB)) ([System.Drawing.Color]::FromArgb(255, 210, 90))
    }

    $StatusLabel.Text = $L.StatusDone
    $BtnCheck1.Enabled = $true
    $BtnCheck2.Enabled = $true
    $Script:IsRunning = $false
})

# Copy & Clear Buttons
$BtnCopy.Add_Click({
    if ($OutputBox.TextLength -gt 0) {
        [System.Windows.Forms.Clipboard]::SetText($OutputBox.Text)
        $StatusLabel.Text = $Script:Lang[$Script:CurrentLang].CopiedMsg
    }
})

$BtnClear.Add_Click({
    $OutputBox.Clear()
    $StatusLabel.Text = $Script:Lang[$Script:CurrentLang].StatusReady
})

# Initialize UI & Show Form
Update-LanguageUI
[void]$Form.ShowDialog()
