# nvim 設定

この設定は単独の nvim 設定リポジトリではなく、[takenv](https://github.com/BambooTuna/takenv) リポジトリの
`dotfiles/.config/nvim` として管理されている。単独で `git clone` して使う想定ではなく、
takenv のセットアップ手順 (bootstrap) 経由でシンボリンクなどにより配置される。

## ベース

[LazyVim](https://www.lazyvim.org/) をベースにしている。個人設定は `lua/plugins/` と
`lua/config/` に置き、LazyVim 標準の挙動を上書き・追加している。

## extras

LazyVim の extras (formatting / lang / linting など) は `lazyvim.json` で管理する。
一覧・追加・削除は Neovim 上で `:LazyExtras` を実行して行うこと (`lua/config/lazy.lua`
に個別 import は書かない)。

## fzf

`junegunn/fzf` は nvim のプラグインとしてだけでなく、シェルで使う fzf 本体の供給元にも
なっている (`.zshrc` が `~/.local/share/nvim/lazy/fzf/bin` を PATH に追加している)。
そのため `lua/plugins/fzf.lua` は削除しないこと。

## プラグイン管理

プラグインは [lazy.nvim](https://github.com/folke/lazy.nvim) で管理する。バージョンは
`lazy-lock.json` に固定し、コミット対象に含める。
