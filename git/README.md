# Git 設定

## ユーザー設定

`~/.gitconfig` は `dotfiles/.gitconfig` へのシンボリックリンクとして `make link` で管理される（`user.name` / `user.email` を含む）。

マシン固有の設定や秘匿情報（署名鍵・社用メールなど）は git 管理外の `~/.gitconfig.local` に書く。`dotfiles/.gitconfig` の `[include]` から読み込まれ、ファイルが無ければ無視される。

```ini
# ~/.gitconfig.local の例
[user]
	email = work@example.com
```

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
