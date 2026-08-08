# shellcheck shell=bash
# takenv bootstrap — 完了後に案内する手動ステップ

print_manual_steps() {
  log "完了 🎉 — 残りの手動ステップ"
  cat <<'EOS'
  1. シェルを開き直す（exec zsh -l）
  2. SSH 鍵の作成と GitHub 登録: git/README.md 参照
EOS
  if [ "$OS" = "Linux" ]; then
    cat <<'EOS'
  3. Tailscale に参加（SSH 受付も有効化）: make tailscale-up
     → Mac から herdr --remote <user>@<このホスト名> で接続できる
EOS
    if grep -qi microsoft /proc/version 2>/dev/null; then
      cat <<'EOS'
  4. Windows 母艦側の設定（自動再起動抑止・WSL 自動起動・.wslconfig 反映）:
     Windows PowerShell を管理者で開いて windows/bootstrap.ps1 を実行
EOS
    fi
  fi
  if [ "$OS" = "Darwin" ]; then
    cat <<'EOS'
  3. Karabiner-Elements の権限承認（初回のみ）
     - システム設定 > 一般 > ログイン項目と機能拡張 > ドライバ機能拡張 を有効化
     - システム設定 > プライバシーとセキュリティ > 入力監視 を許可
  4. cask が無い/機能しないアプリ: LINE (App Store), tldv (https://tldv.io), Amazon Music
EOS
  fi
  printf '\n  環境の健全性チェック: make doctor\n\n'
}
