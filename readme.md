# AMD SSD Write & Log Checker (v1.0)

[](#українська) [](#english)

---

## Українська

Проста утиліта з графічним інтерфейсом (PowerShell WinForms, **UA / EN**) для швидкої перевірки систем з драйверами AMD Radeon / Chipset на баги надмірного запису на системний SSD.

### Швидкий запуск (PowerShell)

```powershell
& ([scriptblock]::Create((irm "https://raw.githubusercontent.com/norrest/AMD-SSD-Write-Check/main/AMD-SSD-Write-Check.ps1")))
```

### Що перевіряє скрипт

1. **Перевірка 1 — Активність запису (15 сек):** вимірює загальний обсяг запису з моменту запуску Windows (`TotalWritten_MB`) та швидкість запису в реальному часі (`КБ/с`) для процесів `atieclxx.exe`, `atiesrxx.exe`, `RadeonSoftware.exe`, `AMDRSServ.exe` та інших фонових служб AMD (у тому числі під час переміщення/зміни розміру вікон).
2. **Перевірка 2 — Логи та кеш AMD (Диск C:):** сканує наявність і розмір папок `EEUDumps`, системного профілю `AMD`, `AppData` та `C:\AMD` на системному диску.

---

## English

A lightweight GUI utility (PowerShell WinForms, **UA / EN**) to check Windows systems with AMD Radeon / Chipset drivers for excessive background SSD writes.

### Quick Run (PowerShell)

```powershell
& ([scriptblock]::Create((irm "https://raw.githubusercontent.com/norrest/AMD-SSD-Write-Check/main/AMD-SSD-Write-Check.ps1")))
```

### What It Checks

1. **Check 1 — Process Write Activity (15s):** measures cumulative writes since boot (`TotalWritten_MB`) and live write speed (`KB/s`) for `atieclxx.exe`, `atiesrxx.exe`, `RadeonSoftware.exe`, `AMDRSServ.exe`, and other AMD background services (including during window move/resize).
2. **Check 2 — AMD Logs & Cache (Drive C:):** scans the existence and size of `EEUDumps`, system profile `AMD`, `AppData`, and `C:\AMD` folders on the system drive.
