## sTemplate


```bash
$ cp .gittemplate ~/.gittemplate
$ git config --global commit.template ~/.gittemplate
```


## SSH

1. 鍵を生成する

```bash
$ cd ~/.ssh
$ ssh-keygen -t rsa -b 4096 -C "bambootuna@gmail.com"
```

2. 公開鍵をGithubにあげる

3. エイリアスを作成する

```config:~/.ssh/config
Host github github.com
  HostName github.com
  IdentityFile ~/.ssh/github
  User git
```

3. 確認

```bash
$ ssh -T git@github.com
```