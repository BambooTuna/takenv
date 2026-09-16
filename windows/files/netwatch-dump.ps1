# netwatch-dump.ps1 — ネットワーク異常イベント発生瞬間のスナップショットを記録する
#
# タスクスケジューラのイベントトリガから起動される前提:
#   - System / Tcpip / 4266            (UDP エフェメラルポート枯渇)
#   - System / DNS-Client / 1014       (名前解決タイムアウト)
# 出力: %USERPROFILE%\netwatch.log に追記。犯人プロセスの特定が目的。

$log = Join-Path $env:USERPROFILE 'netwatch.log'
$ts = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'

# どのイベントで起動されたか直近5分の該当イベントから推定する
$recent = Get-WinEvent -FilterHashtable @{LogName='System'; Id=4266,1014; StartTime=(Get-Date).AddMinutes(-5)} -ErrorAction SilentlyContinue |
    Select-Object -First 3 | ForEach-Object { "$($_.TimeCreated.ToString('HH:mm:ss')) $($_.ProviderName)/$($_.Id)" }
$why = if ($recent) { $recent -join ', ' } else { 'manual/unknown' }

$udpAll = Get-NetUDPEndpoint
$tcpAll = Get-NetTCPConnection
$timeWait = @($tcpAll | Where-Object { $_.State -eq 'TimeWait' }).Count

$lines = @("===== $ts fired [$why] =====")
$lines += "UDP total: $($udpAll.Count)  TCP total: $($tcpAll.Count)  (TimeWait: $timeWait)"

$lines += '-- UDP ports by process --'
$udpAll | Group-Object OwningProcess | Sort-Object Count -Descending | Select-Object -First 15 | ForEach-Object {
    $p = Get-Process -Id $_.Name -ErrorAction SilentlyContinue
    $name = if ($p) { $p.ProcessName } else { '?' }
    $lines += ('{0,6}  pid={1,-7} {2}' -f $_.Count, $_.Name, $name)
}

$lines += '-- TCP connections by process --'
$tcpAll | Group-Object OwningProcess | Sort-Object Count -Descending | Select-Object -First 15 | ForEach-Object {
    $p = Get-Process -Id $_.Name -ErrorAction SilentlyContinue
    $name = if ($p) { $p.ProcessName } else { '?' }
    $lines += ('{0,6}  pid={1,-7} {2}' -f $_.Count, $_.Name, $name)
}

# mirrored WSL のフローは Get-NetUDPEndpoint に出ないため、ポート予約の総量も記録する
$lines += '-- UDP port reservations (netsh) --'
$resv = netsh int ipv4 show excludedportrange udp
$lines += ($resv | Where-Object { $_ -match '^\s*\d' })
$lines += "reservation ranges: $(@($resv | Where-Object { $_ -match '^\s*\d' }).Count)"

$lines += ''
Add-Content -Path $log -Value $lines -Encoding UTF8
