# windows — Windows 母艦セットアップ層

母艦の Windows を「自動で再起動しない・起動時に WSL が立ち上がる・`.wslconfig` が反映されている」の3点だけ宣言的に整える層です。GUI は使わず、Mac から Tailscale 経由 SSH で WSL 上の Ubuntu を触る運用が前提です。

## 対象

- Windows 11 24H2 以降（Sudo for Windows は使わない）
- Windows PowerShell 5.1 / PowerShell 7 のどちらでも動作

## 前提

- WSL2 が有効化済み
- Ubuntu ディストロが導入済み
- WSL 内側の作業ユーザーが作成済み

## セットアップ手順

1. WSL の Ubuntu 内でリポジトリを clone し、通常の bootstrap を実行:
   ```bash
   git clone https://github.com/BambooTuna/takenv.git && cd takenv
   ./bootstrap.sh
   ```
2. Windows PowerShell を **管理者** で開き、以下を1発実行:
   ```powershell
   Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
   & \\wsl$\Ubuntu\home\<username>\takenv\windows\bootstrap.ps1
   ```
   リポジトリを Windows 側 (`C:\Users\<name>\...`) に clone した場合はそのパスを直接叩いても構いません:
   ```powershell
   Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
   & C:\Users\<name>\takenv\windows\bootstrap.ps1
   ```
3. 状態確認:
   ```powershell
   & \\wsl$\Ubuntu\home\<username>\takenv\windows\doctor.ps1
   ```
   4項目すべて `[OK]` になっていれば完了です。

冪等なので何度実行しても安全です（差分がなければスキップされます）。

## 環境変数

| 変数 | 既定値 | 用途 |
|---|---|---|
| `TAKENV_WSL_DISTRO` | `Ubuntu` | 自動起動対象の WSL ディストロ名 |
| `TAKENV_WSL_USER` | `takeo_suzuki` | WSL 内側のユーザー名 |

## 何が変わるか

| 項目 | 変更内容 |
|---|---|
| 自動再起動抑止 | Wake Timer OFF（AC/DC）、`NoAutoRebootWithLoggedOnUsers=1`、NIC の Wake on LAN OFF |
| WSL 自動起動 | ログオン時にタスクスケジューラーで `wsl -d Ubuntu -u <user> -- true` を実行 |
| `.wslconfig` | [`windows/files/.wslconfig`](./files/.wslconfig) を `%USERPROFILE%` に配置 |

## アンインストール

管理者 PowerShell で以下を実行すると触った設定を元に戻せます（Wake Timer は既定値の再有効化）。

```powershell
Unregister-ScheduledTask -TaskName 'WSL-AutoStart-Ubuntu' -Confirm:$false
Remove-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU' -Name 'NoAutoRebootWithLoggedOnUsers' -ErrorAction SilentlyContinue
powercfg /setacvalueindex SCHEME_CURRENT SUB_SLEEP BD3B718A-0680-4D9D-8AB2-E1D2B4AC806D 1
powercfg /setdcvalueindex SCHEME_CURRENT SUB_SLEEP BD3B718A-0680-4D9D-8AB2-E1D2B4AC806D 1
powercfg /setactive SCHEME_CURRENT
Remove-Item "$env:USERPROFILE\.wslconfig" -ErrorAction SilentlyContinue
```

NIC の Wake on LAN 個別設定はデバイスマネージャーの電源管理タブから手動で戻してください。
