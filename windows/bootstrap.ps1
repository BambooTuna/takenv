# takenv windows bootstrap — Windows 母艦を「自動再起動しない・起動時に WSL 起動・.wslconfig 反映」の3点だけ整える
#
#   管理者 PowerShell で:
#   & \path\to\takenv\windows\bootstrap.ps1
#
# 冪等: 何度実行しても安全。差分がなければスキップする。
#
# 環境変数:
#   TAKENV_WSL_DISTRO   WSL ディストロ名（既定 Ubuntu）
#   TAKENV_WSL_USER     WSL 内側のユーザー名（既定 takeo_suzuki）

$OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$ErrorActionPreference = 'Continue'

function Write-Step {
    param([string]$Message)
    Write-Host "`n==> $Message" -ForegroundColor Cyan
}
function Write-Ok {
    param([string]$Message)
    Write-Host "  $([char]0x2713) $Message" -ForegroundColor Green
}
function Write-Warn {
    param([string]$Message)
    Write-Host "  $([char]0x26A0) $Message" -ForegroundColor Yellow
}
function Write-Err {
    param([string]$Message)
    Write-Host "  $([char]0x2717) $Message" -ForegroundColor Red
}

# 管理者権限が無いとタスクスケジューラー登録・powercfg・HKLM 書き込みが失敗するため先に止める
$currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if (-not $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "管理者権限で実行してください（PowerShell を管理者として開き直す）" -ForegroundColor Red
    exit 1
}

$distro = if ($env:TAKENV_WSL_DISTRO) { $env:TAKENV_WSL_DISTRO } else { 'Ubuntu' }
$wslUser = if ($env:TAKENV_WSL_USER) { $env:TAKENV_WSL_USER } else { 'takeo_suzuki' }

Write-Step "takenv windows bootstrap (distro=$distro, user=$wslUser)"

# ---------------------------------------------------------------- Step 1: .wslconfig
Write-Step ".wslconfig"
try {
    $srcPath = Join-Path $PSScriptRoot 'files\.wslconfig'
    $dstPath = Join-Path $env:USERPROFILE '.wslconfig'

    $needsCopy = $true
    if (Test-Path $dstPath) {
        $srcHash = (Get-FileHash -Path $srcPath -Algorithm SHA256).Hash
        $dstHash = (Get-FileHash -Path $dstPath -Algorithm SHA256).Hash
        if ($srcHash -eq $dstHash) {
            $needsCopy = $false
        }
    }

    if ($needsCopy) {
        Copy-Item -Path $srcPath -Destination $dstPath -Force
        Write-Ok "$dstPath を更新しました"
    } else {
        Write-Ok "$dstPath は最新です"
    }
} catch {
    Write-Err ".wslconfig の配置に失敗しました: $_"
}

# ---------------------------------------------------------------- Step 2: WSL 自動起動タスク
Write-Step "WSL 自動起動タスク (WSL-AutoStart-Ubuntu)"
try {
    $taskName = 'WSL-AutoStart-Ubuntu'
    $wslExe = (Get-Command wsl.exe).Source
    $action = New-ScheduledTaskAction -Execute $wslExe -Argument "-d $distro -u $wslUser -- true"
    $trigger = New-ScheduledTaskTrigger -AtLogOn
    $principal = New-ScheduledTaskPrincipal -UserId "$env:USERDOMAIN\$env:USERNAME" -LogonType Interactive -RunLevel Limited
    $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -MultipleInstances IgnoreNew -ExecutionTimeLimit (New-TimeSpan -Hours 72)

    Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Principal $principal -Settings $settings -Force | Out-Null
    Write-Ok "タスク '$taskName' を登録しました"
} catch {
    Write-Err "WSL 自動起動タスクの登録に失敗しました: $_"
}

# ---------------------------------------------------------------- Step 3: 自動再起動抑止
Write-Step "自動再起動の抑止"

# 3a. Wake Timer 無効化（AC/DC 両方）
try {
    powercfg /setacvalueindex SCHEME_CURRENT SUB_SLEEP BD3B718A-0680-4D9D-8AB2-E1D2B4AC806D 0 | Out-Null
    powercfg /setdcvalueindex SCHEME_CURRENT SUB_SLEEP BD3B718A-0680-4D9D-8AB2-E1D2B4AC806D 0 | Out-Null
    powercfg /setactive SCHEME_CURRENT | Out-Null
    Write-Ok "Wake Timer を無効化しました"
} catch {
    Write-Err "Wake Timer の無効化に失敗しました: $_"
}

# 3b. ログオン中の自動再起動禁止（Windows Update ポリシー）
try {
    $auKey = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU'
    New-Item -Path $auKey -Force | Out-Null
    Set-ItemProperty -Path $auKey -Name 'NoAutoRebootWithLoggedOnUsers' -Value 1 -Type DWord
    Write-Ok "NoAutoRebootWithLoggedOnUsers=1 を設定しました"
} catch {
    Write-Err "自動再起動ポリシーの設定に失敗しました: $_"
}

# 3c. NIC の Wake on LAN 無効化（リモート起床による意図しない再起動要因を断つ）
try {
    $adapters = Get-NetAdapter -ErrorAction Stop
    foreach ($adapter in $adapters) {
        $desc = $adapter.InterfaceDescription
        try {
            powercfg /devicedisablewake "$desc" | Out-Null
            # powercfg は失敗時も終了コードのみで通知する（例外を投げない）ため明示チェックする
            if ($LASTEXITCODE -eq 0) {
                Write-Ok "Wake on LAN 無効化: $desc"
            } else {
                Write-Warn "Wake on LAN 無効化に失敗（続行）: $desc"
            }
        } catch {
            Write-Warn "Wake on LAN 無効化に失敗（続行）: $desc"
        }
    }
} catch {
    Write-Err "ネットワークアダプタの列挙に失敗しました: $_"
}

# ---------------------------------------------------------------- Step 4: UDP ポート枯渇の監視タスク
# ★調査用の一時計装 (2026-09): デスクトップの UDP ポート枯渇 / ルーター DNS 障害の
# 犯人特定が目的。決着したら Step 4-5・files/netwatch-*.ps1・doctor.ps1 の検査を削除し、
# Unregister-ScheduledTask で両タスクを解除する。
# Tcpip イベント 4266 (UDP エフェメラルポート枯渇) の発生瞬間に、プロセス別ソケット数を
# %USERPROFILE%\netwatch.log へ記録する。バースト消費の犯人プロセス特定が目的。
Write-Step "UDP ポート枯渇監視タスク (Netwatch-PortExhaustion)"
try {
    $taskName = 'Netwatch-PortExhaustion'
    $scriptSrc = Join-Path $PSScriptRoot 'files\netwatch-dump.ps1'
    $scriptDst = Join-Path $env:USERPROFILE 'netwatch-dump.ps1'
    Copy-Item -Path $scriptSrc -Destination $scriptDst -Force

    $action = New-ScheduledTaskAction -Execute 'powershell.exe' -Argument "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$scriptDst`""

    # New-ScheduledTaskTrigger はイベントトリガ未対応のため CIM で直接組む
    $triggerClass = Get-CimClass MSFT_TaskEventTrigger root/Microsoft/Windows/TaskScheduler
    $trigger = New-CimInstance -CimClass $triggerClass -ClientOnly
    $trigger.Subscription = '<QueryList><Query Id="0" Path="System"><Select Path="System">*[System[Provider[@Name=''Tcpip''] and EventID=4266]]</Select></Query></QueryList>'
    $trigger.Enabled = $true

    $principal = New-ScheduledTaskPrincipal -UserId "$env:USERDOMAIN\$env:USERNAME" -LogonType S4U -RunLevel Highest
    $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -MultipleInstances IgnoreNew -ExecutionTimeLimit (New-TimeSpan -Minutes 5)

    Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Principal $principal -Settings $settings -Force | Out-Null
    Write-Ok "タスク '$taskName' を登録しました (ログ: %USERPROFILE%\netwatch.log)"
} catch {
    Write-Err "監視タスクの登録に失敗しました: $_"
}

# ---------------------------------------------------------------- Step 5: ネットワーク常駐サンプラー
# 5秒間隔でルーターDNS/公開DNSの生死とソケット数を監視し、異常時のみ記録する常駐スクリプト。
# ログオン時に自動起動。ログ: %USERPROFILE%\netwatch-sampler.log
Write-Step "ネットワーク常駐サンプラー (Netwatch-Sampler)"
try {
    $taskName = 'Netwatch-Sampler'
    $scriptSrc = Join-Path $PSScriptRoot 'files\netwatch-sampler.ps1'
    $scriptDst = Join-Path $env:USERPROFILE 'netwatch-sampler.ps1'
    Copy-Item -Path $scriptSrc -Destination $scriptDst -Force

    $action = New-ScheduledTaskAction -Execute 'powershell.exe' -Argument "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$scriptDst`""
    $trigger = New-ScheduledTaskTrigger -AtLogOn
    $principal = New-ScheduledTaskPrincipal -UserId "$env:USERDOMAIN\$env:USERNAME" -LogonType Interactive -RunLevel Limited
    $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -MultipleInstances IgnoreNew -ExecutionTimeLimit ([TimeSpan]::Zero) -RestartCount 3 -RestartInterval (New-TimeSpan -Minutes 1)

    Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Principal $principal -Settings $settings -Force | Out-Null
    Write-Ok "タスク '$taskName' を登録しました (ログ: %USERPROFILE%\netwatch-sampler.log)"
} catch {
    Write-Err "サンプラータスクの登録に失敗しました: $_"
}

Write-Host "`n完了。状態確認は windows\doctor.ps1 を実行してください。`n" -ForegroundColor Cyan
