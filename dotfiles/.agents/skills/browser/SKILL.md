---
description: ヘッドレスブラウザ (Playwright + chromium) を使って Web ページを操作する。フルページスクショ、DOM/テキスト抽出、クリック・フォーム入力・多段フロー、レンダリング後のHTML解析、PDF化まで全般。撮った画像は Read でそのまま解析できる。
allowed-tools: Bash(playwright:*), Bash(mise:*), Bash(node:*), Bash(mkdir:*), Bash(cat:*), Read, Write
---

# browser — Playwright で Web ページを操作

## いつ使うか

- URL を渡してスクショが欲しい (フルページ / 要素単位 / dark mode)
- レンダリング後の DOM を取ってきて解析したい (SPA も可)
- 「XX にログインして YY ページを開いて ZZ を抽出」等の**多段フロー**
- ボタンクリック・フォーム入力・ダウンロード発火などブラウザ操作全般
- 画像を撮った後 Read で開いて UI 批評・要約・比較したい

## 前提

- `mise` で `npm:playwright` が入っている (`~/takenv/dotfiles/.config/mise/config.toml`)
- chromium 本体は `~/.cache/ms-playwright/` に導入済み (bootstrap.sh の `setup_headless_browser`)
- 対話スクリプト用の scratch: `~/.cache/browser-scratch/` (`node_modules/playwright` が symlink 済みなので `import { chromium } from 'playwright'` が通る)
- 未セットアップの環境なら `~/takenv/bootstrap.sh` を実行するのが正 (apt依存・fonts-noto-cjk・chromium ダウンロード等が入る)

## 実行モード

### モードA: 一発系 (組み込み CLI)

**スクショ** (フルページ):
```bash
mise x -- playwright screenshot --full-page https://example.com out.png
```

**要素待ち・遅延を伴うページ**:
```bash
mise x -- playwright screenshot --full-page \
  --wait-for-selector="main" --wait-for-timeout=1000 \
  https://example.com out.png
```

**PDF**:
```bash
mise x -- playwright pdf https://example.com out.pdf
```

**ダークモード / 特定デバイス**:
```bash
mise x -- playwright screenshot --color-scheme=dark --device="iPhone 14" URL out.png
```

`mise x -- playwright screenshot --help` で全オプション確認可能。

### モードB: 対話・多段フロー (scratch mjs)

`~/.cache/browser-scratch/` 配下に `.mjs` を書いて `node` で走らせる。この dir から `import { chromium } from 'playwright'` がそのまま通る。

**標準テンプレ**:
```javascript
// ~/.cache/browser-scratch/task.mjs
import { chromium } from 'playwright';

const browser = await chromium.launch();          // headless: true がデフォルト
const ctx = await browser.newContext({
  viewport: { width: 1440, height: 900 },
  deviceScaleFactor: 2,
  locale: 'ja-JP',
});
const page = await ctx.newPage();

try {
  await page.goto('https://example.com/', { waitUntil: 'networkidle', timeout: 60_000 });

  // ここで操作する (下のパターン参照)

} finally {
  await browser.close();
}
```

実行:
```bash
cd ~/.cache/browser-scratch && node task.mjs
```

## よく使うパターン

**要素テキスト抽出**:
```javascript
const title = await page.title();
const heading = await page.locator('h1').first().innerText();
const items = await page.locator('article h2').allInnerTexts();
const jsonld = await page.locator('script[type="application/ld+json"]').allTextContents();
```

**クリック → ページ遷移**:
```javascript
await page.getByRole('link', { name: '料金' }).click();
await page.waitForLoadState('networkidle');
```

**フォーム入力・送信**:
```javascript
await page.getByLabel('Email').fill('foo@example.com');
await page.getByLabel('Password').fill(process.env.PW);
await page.getByRole('button', { name: 'Sign in' }).click();
await page.waitForURL(/dashboard/);
```

**要素単位のスクショ** (カード1枚だけ等):
```javascript
await page.locator('.pricing-card').first().screenshot({ path: 'card.png' });
```

**フルページを撮る** (モードAが使えないカスタム条件):
```javascript
await page.screenshot({ path: 'full.png', fullPage: true });
```

**遅延ロード対策** (画像/コンテンツ):
```javascript
await page.evaluate(async () => {
  await new Promise(r => {
    let y = 0; const step = 400;
    const t = setInterval(() => {
      window.scrollBy(0, step); y += step;
      if (y >= document.body.scrollHeight) { clearInterval(t); window.scrollTo(0,0); setTimeout(r, 500); }
    }, 100);
  });
});
```

**JSONで結果を返す** (親プロセスに渡す標準形):
```javascript
console.log(JSON.stringify({ title, items, screenshotPath: 'out.png' }));
```

## スクショ → 画像解析の定番フロー

1. `playwright screenshot --full-page URL /tmp/out.png` (または mjs で `page.screenshot(...)`)
2. `Read /tmp/out.png` で開く (Claude はマルチモーダルなので画像が直接見える)
3. ユーザーの依頼 (要約、UI批評、テキスト抽出、比較等) に応える

## トラブルシュート

- `Cannot find package 'playwright'` → scratch dir 以外で ESM 実行している。`cd ~/.cache/browser-scratch/` してから叩くか、そこに script を置く
- `Executable doesn't exist at ...` → `mise x -- playwright install chromium` を叩く (or `bootstrap.sh`)
- 依存ライブラリ不足で起動できない (WSL初回等) → `~/takenv/bootstrap.sh` (libnss3 群 + fonts-noto-cjk を含む)
- 日本語が豆腐 → 同上 (`fonts-noto-cjk` 未導入)
- SPA でコンテンツが取れない → `waitUntil: 'networkidle'` + `--wait-for-selector` 併用、それでも駄目なら `page.waitForTimeout(1500)` を挟む
- 403/Bot detected → `--user-agent` (CLI) or `newContext({ userAgent: '...' })`、それでも駄目なら `chromium.launch({ channel: 'chrome' })` で本物のChromeを使う
