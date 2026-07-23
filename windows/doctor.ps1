# takenv windows doctor — Windows 母艦側の設定が3目的（自動再起動抑止・WSL自動起動・.wslconfig）を
# 満たしているか検証する。管理者権限は不要（レジストリ読み取り・powercfg クエリのみ）。

$OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$status = 0

function Write-Section {
    param([string]$Message)
    Write-Host "`n== $Message ==" -ForegroundColor Cyan
}
function Write-Pass {
    param([string]$Message)
    Write-Host "  $([char]0x2713) $Message" -ForegroundColor Green
}
function Write-Fail {
    param([string]$Message)
    Write-Host "  $([char]0x2717) $Message" -ForegroundColor Red
}

# ---------------------------------------------------------------- 1. .wslconfig
Write-Section ".wslconfig"
try {
    $srcPath = Join-Path $PSScriptRoot 'files\.wslconfig'
    $dstPath = Join-Path $env:USERPROFILE '.wslconfig'
    if (-not (Test-Path $dstPath)) {
        Write-Fail "$dstPath が存在しません"
        $status = 1
    } else {
        $srcHash = (Get-FileHash -Path $srcPath -Algorithm SHA256).Hash
        $dstHash = (Get-FileHash -Path $dstPath -Algorithm SHA256).Hash
        if ($srcHash -eq $dstHash) {
            Write-Pass "$dstPath は宣言と一致しています"
        } else {
            Write-Fail "$dstPath が宣言と異なります（windows\bootstrap.ps1 を再実行してください）"
            $status = 1
        }
    }
} catch {
    Write-Fail ".wslconfig の検証に失敗しました: $_"
    $status = 1
}

# ---------------------------------------------------------------- 2. WSL 自動起動タスク
Write-Section "WSL 自動起動タスク"
try {
    $task = Get-ScheduledTask -TaskName 'WSL-AutoStart-Ubuntu' -ErrorAction Stop
    if ($task.State -ne 'Ready') {
        Write-Fail "タスクの State が Ready ではありません（現在: $($task.State)）"
        $status = 1
    } else {
        $execute = $task.Actions[0].Execute
        if ($execute -like '*wsl.exe') {
            Write-Pass "タスク 'WSL-AutoStart-Ubuntu' は Ready です（Execute: $execute）"
        } else {
            Write-Fail "タスクの Execute が wsl.exe ではありません（現在: $execute）"
            $status = 1
        }
    }
} catch {
    Write-Fail "タスク 'WSL-AutoStart-Ubuntu' が見つかりません"
    $status = 1
}

# ---------------------------------------------------------------- 3. Wake Timer
Write-Section "Wake Timer"
try {
    $query = powercfg /query SCHEME_CURRENT SUB_SLEEP BD3B718A-0680-4D9D-8AB2-E1D2B4AC806D

    function Get-PowerSettingIndex {
        param([string[]]$Lines, [string]$Marker)
        $line = $Lines | Where-Object { $_ -match "\b$Marker\b" -and $_ -match '0x[0-9A-Fa-f]+' } | Select-Object -First 1
        if ($line -and $line -match '(0x[0-9A-Fa-f]+)') {
            return [Convert]::ToInt32($Matches[1], 16)
        }
        return $null
    }

    $acValue = Get-PowerSettingIndex -Lines $query -Marker 'AC'
    $dcValue = Get-PowerSettingIndex -Lines $query -Marker 'DC'

    if ($acValue -eq 0 -and $dcValue -eq 0) {
        Write-Pass "Wake Timer は AC/DC とも無効です"
    } else {
        Write-Fail "Wake Timer が有効です（AC=$acValue, DC=$dcValue）"
        $status = 1
    }
} catch {
    Write-Fail "Wake Timer の検証に失敗しました: $_"
    $status = 1
}

# ---------------------------------------------------------------- 4. NoAutoRebootWithLoggedOnUsers
Write-Section "自動再起動ポリシー"
try {
    $auKey = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU'
    $value = (Get-ItemProperty -Path $auKey -Name 'NoAutoRebootWithLoggedOnUsers' -ErrorAction Stop).NoAutoRebootWithLoggedOnUsers
    if ($value -eq 1) {
        Write-Pass "NoAutoRebootWithLoggedOnUsers=1"
    } else {
        Write-Fail "NoAutoRebootWithLoggedOnUsers が 1 ではありません（現在: $value）"
        $status = 1
    }
} catch {
    Write-Fail "NoAutoRebootWithLoggedOnUsers が未設定です"
    $status = 1
}

Write-Host ""
if ($status -eq 0) {
    Write-Host "すべて OK です。" -ForegroundColor Green
} else {
    Write-Host "問題があります。windows\bootstrap.ps1 を管理者権限で実行してください。" -ForegroundColor Red
}

exit $status
