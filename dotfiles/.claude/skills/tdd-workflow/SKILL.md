---
name: tdd-workflow
description: 新機能の実装、バグ修正、リファクタリング時に使用するスキル。ユニット・インテグレーション・E2Eテストを含む80%以上のカバレッジでテスト駆動開発を強制する。
origin: ECC
---

# テスト駆動開発ワークフロー

このスキルは、すべてのコード開発がTDD原則に従い、包括的なテストカバレッジを持つことを保証する。

## 発動条件

- 新機能や新しい機能の実装時
- バグや問題の修正時
- 既存コードのリファクタリング時
- APIエンドポイントの追加時
- 新しいコンポーネントの作成時

## 基本原則

### 1. コードの前にテスト

常にテストを先に書き、テストを通すためのコードを実装する。

### 2. カバレッジ要件

- 最低80%のカバレッジ（ユニット + インテグレーション + E2E）
- すべてのエッジケースをカバー
- エラーシナリオのテスト
- 境界条件の検証

### 3. テストの種類

#### ユニットテスト

- 個別の関数やユーティリティ
- コンポーネントのロジック
- 純粋関数
- ヘルパーやユーティリティ

#### インテグレーションテスト

- APIエンドポイント
- データベース操作
- サービス間のやり取り
- 外部API呼び出し

#### E2Eテスト（Playwright）

- 重要なユーザーフロー
- 完全なワークフロー
- ブラウザ自動化
- UI操作

## TDDワークフロー手順

### ステップ1: ユーザージャーニーを書く

```
[役割]として、[アクション]したい、なぜなら[利点]だから

例:
ユーザーとして、マーケットをセマンティック検索したい、
なぜなら正確なキーワードがなくても関連するマーケットを見つけられるから。
```

### ステップ2: テストケースを生成する

各ユーザージャーニーに対して、包括的なテストケースを作成する:

```typescript
describe("セマンティック検索", () => {
  it("クエリに対して関連するマーケットを返す", async () => {
    // テスト実装
  });

  it("空のクエリを適切に処理する", async () => {
    // エッジケースのテスト
  });

  it("Redisが利用不可の場合、部分文字列検索にフォールバックする", async () => {
    // フォールバック動作のテスト
  });

  it("結果を類似度スコアでソートする", async () => {
    // ソートロジックのテスト
  });
});
```

### ステップ3: テストを実行する（失敗するはず）

```bash
pnpm test
# テストは失敗するはず — まだ実装していないから
```

### ステップ4: コードを実装する

テストを通すための最小限のコードを書く:

```typescript
// テストに導かれた実装
export async function searchMarkets(query: string) {
  // 実装をここに書く
}
```

### ステップ5: テストを再実行する

```bash
pnpm test
# テストが通るはず
```

### ステップ6: リファクタリング

テストがグリーンのまま、コード品質を改善する:

- 重複の除去
- 命名の改善
- パフォーマンスの最適化
- 可読性の向上

### ステップ7: カバレッジを確認する

```bash
pnpm run test:coverage
# 80%以上のカバレッジが達成されていることを確認
```

## テストパターン

### ユニットテストパターン（Jest/Vitest）

```typescript
import { render, screen, fireEvent } from '@testing-library/react'
import { Button } from './Button'

describe('Buttonコンポーネント', () => {
  it('正しいテキストでレンダリングされる', () => {
    render(<Button>クリック</Button>)
    expect(screen.getByText('クリック')).toBeInTheDocument()
  })

  it('クリック時にonClickが呼ばれる', () => {
    const handleClick = jest.fn()
    render(<Button onClick={handleClick}>クリック</Button>)

    fireEvent.click(screen.getByRole('button'))

    expect(handleClick).toHaveBeenCalledTimes(1)
  })

  it('disabledプロパティがtrueの場合、無効になる', () => {
    render(<Button disabled>クリック</Button>)
    expect(screen.getByRole('button')).toBeDisabled()
  })
})
```

### APIインテグレーションテストパターン

```typescript
import { NextRequest } from "next/server";
import { GET } from "./route";

describe("GET /api/markets", () => {
  it("マーケットを正常に返す", async () => {
    const request = new NextRequest("http://localhost/api/markets");
    const response = await GET(request);
    const data = await response.json();

    expect(response.status).toBe(200);
    expect(data.success).toBe(true);
    expect(Array.isArray(data.data)).toBe(true);
  });

  it("クエリパラメータをバリデーションする", async () => {
    const request = new NextRequest(
      "http://localhost/api/markets?limit=invalid",
    );
    const response = await GET(request);

    expect(response.status).toBe(400);
  });

  it("データベースエラーを適切に処理する", async () => {
    // データベース障害をモック
    const request = new NextRequest("http://localhost/api/markets");
    // エラーハンドリングのテスト
  });
});
```

### E2Eテストパターン（Playwright）

```typescript
import { test, expect } from "@playwright/test";

test("ユーザーがマーケットを検索・フィルタリングできる", async ({ page }) => {
  // マーケットページに移動
  await page.goto("/");
  await page.click('a[href="/markets"]');

  // ページの読み込みを確認
  await expect(page.locator("h1")).toContainText("Markets");

  // マーケットを検索
  await page.fill('input[placeholder="Search markets"]', "election");

  // デバウンスと結果を待つ
  await page.waitForTimeout(600);

  // 検索結果が表示されていることを確認
  const results = page.locator('[data-testid="market-card"]');
  await expect(results).toHaveCount(5, { timeout: 5000 });

  // 結果に検索語が含まれていることを確認
  const firstResult = results.first();
  await expect(firstResult).toContainText("election", { ignoreCase: true });

  // ステータスでフィルタリング
  await page.click('button:has-text("Active")');

  // フィルタリング結果を確認
  await expect(results).toHaveCount(3);
});

test("ユーザーが新しいマーケットを作成できる", async ({ page }) => {
  // まずログイン
  await page.goto("/creator-dashboard");

  // マーケット作成フォームを入力
  await page.fill('input[name="name"]', "Test Market");
  await page.fill('textarea[name="description"]', "Test description");
  await page.fill('input[name="endDate"]', "2025-12-31");

  // フォームを送信
  await page.click('button[type="submit"]');

  // 成功メッセージを確認
  await expect(page.locator("text=Market created successfully")).toBeVisible();

  // マーケットページへのリダイレクトを確認
  await expect(page).toHaveURL(/\/markets\/test-market/);
});
```

## テストファイルの構成

```
src/
├── components/
│   ├── Button/
│   │   ├── Button.tsx
│   │   ├── Button.test.tsx          # ユニットテスト
│   │   └── Button.stories.tsx       # Storybook
│   └── MarketCard/
│       ├── MarketCard.tsx
│       └── MarketCard.test.tsx
├── app/
│   └── api/
│       └── markets/
│           ├── route.ts
│           └── route.test.ts         # インテグレーションテスト
└── e2e/
    ├── markets.spec.ts               # E2Eテスト
    ├── trading.spec.ts
    └── auth.spec.ts
```

## 外部サービスのモック

### Supabaseモック

```typescript
jest.mock("@/lib/supabase", () => ({
  supabase: {
    from: jest.fn(() => ({
      select: jest.fn(() => ({
        eq: jest.fn(() =>
          Promise.resolve({
            data: [{ id: 1, name: "Test Market" }],
            error: null,
          }),
        ),
      })),
    })),
  },
}));
```

### Redisモック

```typescript
jest.mock("@/lib/redis", () => ({
  searchMarketsByVector: jest.fn(() =>
    Promise.resolve([{ slug: "test-market", similarity_score: 0.95 }]),
  ),
  checkRedisHealth: jest.fn(() => Promise.resolve({ connected: true })),
}));
```

### OpenAIモック

```typescript
jest.mock("@/lib/openai", () => ({
  generateEmbedding: jest.fn(() =>
    Promise.resolve(
      new Array(1536).fill(0.1), // 1536次元のモックエンベディング
    ),
  ),
}));
```

## テストカバレッジの検証

### カバレッジレポートの実行

```bash
pnpm run test:coverage
```

### カバレッジ閾値

```json
{
  "jest": {
    "coverageThresholds": {
      "global": {
        "branches": 80,
        "functions": 80,
        "lines": 80,
        "statements": 80
      }
    }
  }
}
```

## よくあるテストの間違いを避ける

### ❌ 間違い: 実装の詳細をテストする

```typescript
// 内部状態をテストしない
expect(component.state.count).toBe(5);
```

### ✅ 正解: ユーザーに見える振る舞いをテストする

```typescript
// ユーザーが見るものをテスト
expect(screen.getByText("Count: 5")).toBeInTheDocument();
```

### ❌ 間違い: 脆弱なセレクタ

```typescript
// 壊れやすい
await page.click(".css-class-xyz");
```

### ✅ 正解: セマンティックセレクタ

```typescript
// 変更に強い
await page.click('button:has-text("Submit")');
await page.click('[data-testid="submit-button"]');
```

### ❌ 間違い: テストの分離がない

```typescript
// テストが互いに依存している
test("ユーザーを作成する", () => {
  /* ... */
});
test("同じユーザーを更新する", () => {
  /* 前のテストに依存 */
});
```

### ✅ 正解: 独立したテスト

```typescript
// 各テストが独自のデータをセットアップ
test("ユーザーを作成する", () => {
  const user = createTestUser();
  // テストロジック
});

test("ユーザーを更新する", () => {
  const user = createTestUser();
  // 更新ロジック
});
```

## 継続的テスト

### 開発中のウォッチモード

```bash
pnpm test -- --watch
# ファイル変更時にテストが自動実行される
```

### プリコミットフック

```bash
# 毎回のコミット前に実行
pnpm test && pnpm run lint
```

### CI/CDインテグレーション

```yaml
# GitHub Actions
- name: テスト実行
  run: pnpm test -- --coverage
- name: カバレッジアップロード
  uses: codecov/codecov-action@v3
```

## ベストプラクティス

1. **テストを先に書く** - 常にTDD
2. **1テスト1アサーション** - 単一の振る舞いに集中
3. **説明的なテスト名** - 何をテストしているか説明する
4. **Arrange-Act-Assert** - 明確なテスト構造
5. **外部依存をモックする** - ユニットテストを分離
6. **エッジケースをテストする** - null、undefined、空、大量データ
7. **エラーパスをテストする** - ハッピーパスだけでなく
8. **テストを高速に保つ** - ユニットテスト各50ms未満
9. **テスト後にクリーンアップ** - 副作用なし
10. **カバレッジレポートを確認** - ギャップを特定

## 成功指標

- 80%以上のコードカバレッジ達成
- すべてのテストがパス（グリーン）
- スキップまたは無効化されたテストがない
- 高速なテスト実行（ユニットテスト30秒未満）
- E2Eテストが重要なユーザーフローをカバー
- テストが本番前にバグを検出

---

**忘れないこと**: テストはオプションではない。自信を持ったリファクタリング、迅速な開発、本番の信頼性を支える安全ネットである。
