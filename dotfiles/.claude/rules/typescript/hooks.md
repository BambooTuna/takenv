---
paths:
  - "**/*.ts"
  - "**/*.tsx"
  - "**/*.js"
  - "**/*.jsx"
---

# TypeScript/JavaScriptフック

> このファイルは [common/hooks.md](../common/hooks.md) をTypeScript/JavaScript固有の内容で拡張する。

## PostToolUseフック

`~/.claude/settings.json` で設定:

- **Prettier**: 編集後にJS/TSファイルを自動フォーマット
- **TypeScriptチェック**: `.ts`/`.tsx` ファイル編集後に `tsc` を実行
- **console.log警告**: 編集ファイル内の `console.log` を警告

## Stopフック

- **console.log監査**: セッション終了前にすべての変更ファイルで `console.log` をチェック
