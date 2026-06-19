# ルール

Claude Code に効かせる規約・チェックリストの最小セット。

## 構造

```
rules/
├── common/          # 言語に依存しない原則
│   ├── coding-style.md
│   ├── git-workflow.md
│   └── security.md
└── typescript/      # TypeScript / JavaScript 固有
    ├── coding-style.md
    └── security.md
```

- **common/** は普遍的な原則。言語固有のコード例は含めない。
- **言語ディレクトリ** は common ルールをフレームワーク固有のパターンやコード例で拡張する。各ファイルは対応する common ファイルを冒頭で参照する。

## ルール vs スキル

- **ルール** は広く適用される標準・規約・チェックリスト（例: 「ハードコードされたシークレットなし」）。
- **スキル**（`skills/`）は特定タスクへの実行可能な参考資料（例: `tdd-workflow`、`gogcli`）。

ルールは _何を_ するかを示し、スキルは _どのように_ するかを示す。
