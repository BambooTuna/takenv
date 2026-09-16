# netwatch-sampler.ps1 — 5秒間隔の常駐サンプラー。異常時のみ記録 + 毎時ハートビート。
#
# 見るもの:
#   udp/tcp   : Windows プロセスのソケット数 (Get-NetUDPEndpoint / Get-NetTCPConnection)
#   routerdns : ルーター (DHCP 配布の DNS サーバー) への直接クエリ — Chrome が使う経路
#   pubdns    : 8.8.8.8 への直接クエリ — ルーターを迂回した経路
# 判定:
#   routerdns だけ失敗 → ルーターの DNS 中継が犯人
#   両方失敗           → マシンの UDP 送出層 (ポート枯渇 / NIC) が犯人
#   失敗なしで udp 急増 → バーストの立ち上がりを捕捉
#
# 出力: %USERPROFILE%\netwatch-sampler.log (5MB 超で世代ローテート1回)

$log = Join-Path $env:USERPROFILE 'netwatch-sampler.log'
$routerDns = (Get-DnsClientServerAddress -AddressFamily IPv4 |
    Where-Object { $_.ServerAddresses } | Select-Object -First 1).ServerAddresses[0]
$lastBeat = [datetime]::MinValue

function Test-Dns {
    param([string]$Server)
    try {
        Resolve-DnsName -Name google.com -Server $Server -DnsOnly -QuickTimeout -ErrorAction Stop | Out-Null
        return $true
    } catch { return $false }
}

Add-Content -Path $log -Value "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') sampler start (routerdns=$routerDns)"

while ($true) {
    $ts = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $udp = @(Get-NetUDPEndpoint -ErrorAction SilentlyContinue).Count
    $tcp = @(Get-NetTCPConnection -ErrorAction SilentlyContinue).Count
    $rOk = Test-Dns $routerDns
    $pOk = Test-Dns '8.8.8.8'

    $anomaly = (-not $rOk) -or (-not $pOk) -or ($udp -gt 300)
    if ($anomaly) {
        $line = "$ts ANOMALY udp=$udp tcp=$tcp routerdns=$(if($rOk){'ok'}else{'FAIL'}) pubdns=$(if($pOk){'ok'}else{'FAIL'})"
        Add-Content -Path $log -Value $line
        # 異常中はプロセス別 UDP 上位も添える (バーストの犯人がプロセスなら映る)
        Get-NetUDPEndpoint -ErrorAction SilentlyContinue | Group-Object OwningProcess |
            Sort-Object Count -Descending | Select-Object -First 5 | ForEach-Object {
                $p = Get-Process -Id $_.Name -ErrorAction SilentlyContinue
                Add-Content -Path $log -Value ("    {0,5}  pid={1,-7} {2}" -f $_.Count, $_.Name, $(if($p){$p.ProcessName}else{'?'}))
            }
    } elseif (((Get-Date) - $lastBeat).TotalMinutes -ge 60) {
        Add-Content -Path $log -Value "$ts heartbeat udp=$udp tcp=$tcp all-ok"
        $lastBeat = Get-Date
    }

    if ((Test-Path $log) -and (Get-Item $log).Length -gt 5MB) {
        Move-Item -Path $log -Destination "$log.1" -Force
    }
    Start-Sleep -Seconds 5
}
