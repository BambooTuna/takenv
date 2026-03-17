---
paths:
  - "**/*.ts"
  - "**/*.tsx"
  - "**/*.js"
  - "**/*.jsx"
---

# TypeScript/JavaScriptセキュリティ

> このファイルは [common/security.md](../common/security.md) をTypeScript/JavaScript固有の内容で拡張する。

## シークレット管理

```typescript
// 絶対ダメ: ハードコードされたシークレット
const apiKey = "sk-proj-xxxxx";

// 必ず: 環境変数
const apiKey = process.env.OPENAI_API_KEY;

if (!apiKey) {
  throw new Error("OPENAI_API_KEY not configured");
}
```
