# Git 設定

## コミットテンプレート

```bash
cp .gittemplate ~/.gittemplate
git config --global commit.template ~/.gittemplate
```

## SSH

1. 鍵を生成する

```bash
cd ~/.ssh
ssh-keygen -t ed25519 -C "<your-email>"
```

2. 公開鍵を GitHub に登録する: https://github.com/settings/ssh/new

3. エイリアスを作成する

```config:~/.ssh/config
Host github github.com
  HostName github.com
  IdentityFile ~/.ssh/github
  User git
```

4. 確認

```bash
ssh -T git@github.com
```
