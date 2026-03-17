---
paths:
  - "**/*.ts"
  - "**/*.tsx"
  - "**/*.js"
  - "**/*.jsx"
---

# TypeScript/JavaScriptコーディングスタイル

> このファイルは [common/coding-style.md](../common/coding-style.md) をTypeScript/JavaScript固有の内容で拡張する。

## 型とインターフェース

型を使用して、パブリックAPI、共有モデル、コンポーネントpropsを明示的で読みやすく再利用可能にする。

### パブリックAPI

- エクスポート関数、共有ユーティリティ、パブリッククラスメソッドにパラメータ型と戻り値の型を追加する
- 明らかなローカル変数の型はTypeScriptに推論させる
- 繰り返されるインラインオブジェクトの形状を名前付きの型またはインターフェースに抽出する

```typescript
// 間違い: 明示的な型のないエクスポート関数
export function formatUser(user) {
  return `${user.firstName} ${user.lastName}`;
}

// 正解: パブリックAPIに明示的な型
interface User {
  firstName: string;
  lastName: string;
}

export function formatUser(user: User): string {
  return `${user.firstName} ${user.lastName}`;
}
```

### インターフェース vs 型エイリアス

- 拡張または実装される可能性のあるオブジェクトの形状には `interface` を使用
- ユニオン、インターセクション、タプル、マップ型、ユーティリティ型には `type` を使用
- 相互運用のために `enum` が必要でない限り、文字列リテラルユニオンを `enum` より優先

```typescript
interface User {
  id: string;
  email: string;
}

type UserRole = "admin" | "member";
type UserWithRole = User & {
  role: UserRole;
};
```

### `any` を避ける

- アプリケーションコードで `any` を避ける
- 外部または信頼できない入力には `unknown` を使用し、安全にナロイングする
- 値の型が呼び出し元に依存する場合はジェネリクスを使用

```typescript
// 間違い: anyは型安全性を除去する
function getErrorMessage(error: any) {
  return error.message;
}

// 正解: unknownは安全なナロイングを強制する
function getErrorMessage(error: unknown): string {
  if (error instanceof Error) {
    return error.message;
  }

  return "Unexpected error";
}
```

### Reactのprops

- コンポーネントpropsを名前付きの `interface` または `type` で定義する
- コールバックpropsを明示的に型付けする
- 特別な理由がない限り `React.FC` を使用しない

```typescript
interface User {
  id: string
  email: string
}

interface UserCardProps {
  user: User
  onSelect: (id: string) => void
}

function UserCard({ user, onSelect }: UserCardProps) {
  return <button onClick={() => onSelect(user.id)}>{user.email}</button>
}
```

### JavaScriptファイル

- `.js` と `.jsx` ファイルでは、型が明確さを向上させTypeScript移行が実用的でない場合にJSDocを使用する
- JSDocをランタイムの振る舞いと一致させる

```javascript
/**
 * @param {{ firstName: string, lastName: string }} user
 * @returns {string}
 */
export function formatUser(user) {
  return `${user.firstName} ${user.lastName}`;
}
```

## イミュータビリティ

イミュータブルな更新にスプレッド演算子を使用する:

```typescript
interface User {
  id: string;
  name: string;
}

// 間違い: ミューテーション
function updateUser(user: User, name: string): User {
  user.name = name; // ミューテーション!
  return user;
}

// 正解: イミュータビリティ
function updateUser(user: Readonly<User>, name: string): User {
  return {
    ...user,
    name,
  };
}
```

## エラーハンドリング

async/awaitとtry-catchを使用し、unknownエラーを安全にナロイングする:

```typescript
interface User {
  id: string;
  email: string;
}

declare function riskyOperation(userId: string): Promise<User>;

function getErrorMessage(error: unknown): string {
  if (error instanceof Error) {
    return error.message;
  }

  return "Unexpected error";
}

const logger = {
  error: (message: string, error: unknown) => {
    // 本番用ロガー（例: pinoやwinston）に置き換えること。
  },
};

async function loadUser(userId: string): Promise<User> {
  try {
    const result = await riskyOperation(userId);
    return result;
  } catch (error: unknown) {
    logger.error("Operation failed", error);
    throw new Error(getErrorMessage(error));
  }
}
```

## 入力バリデーション

Zodを使用してスキーマベースのバリデーションを行い、スキーマから型を推論する:

```typescript
import { z } from "zod";

const userSchema = z.object({
  email: z.string().email(),
  age: z.number().int().min(0).max(150),
});

type UserInput = z.infer<typeof userSchema>;

const validated: UserInput = userSchema.parse(input);
```

## Console.log

- 本番コードに `console.log` 文を含めない
- 代わりに適切なロギングライブラリを使用する
- 自動検出についてはhooksを参照
