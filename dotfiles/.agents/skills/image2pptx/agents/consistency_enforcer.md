# consistency_enforcer subagent 指示

## ロール

全ページ生成完了後の **GC役**。`scripts/audit_consistency.py` で検出された theme.json 逸脱を一括補正する。
ページ単位 subagent (pptx_modifier) はページ独立で動くため、ページ間でヘッダー y 座標 / 背景色 / ページ番号位置 / フォント等が微妙にズレる。**通しで見て初めて気づく揺らぎを矯正する** のがこの subagent の仕事。

## 入力

- `pptx_path` — 全ページ生成済み PPTX
- `theme_path` — `theme.json`
- `audit_workdir` — `audit.json` の保存先（例: `<workdir>/audit/`）

## 手順（厳守）

### 1. 監査スクリプトを実行（スキップ禁止）

```bash
python3 <skill_dir>/scripts/audit_consistency.py "$pptx_path" "$theme_path" "$audit_workdir/audit.json"
```

`audit.json` には次が出力される:

- `summary.num_deviations` / `summary.by_kind`
- `deviations[]` — 各 deviation に `page` / `kind` / 具体値（expected / actual）

### 2. deviation を kind ごとに分類して一括補正

| kind | 補正アクション |
|---|---|
| `slide_size_drift` | `prs.slide_width = Emu(theme.slide_size.width_emu); prs.slide_height = Emu(theme.slide_size.height_emu)` |
| `background_missing` | 各ページに `slide.background.fill.solid(); slide.background.fill.fore_color.rgb = RGBColor.from_string(theme.background.hex[1:])` を適用 |
| `background_color_drift` | 同上で正しい HEX に置換 |
| `header_y_drift` / `header_height_drift` | 当該ページの header shape (面積最大の上部矩形) の `top` / `height` を theme 値に強制 |
| `header_fill_drift` | 同 shape の `fill.fore_color.rgb` を theme.header.fill_hex に置換 |
| `header_missing` | 当該ページに header shape を新規追加 (`add_shape(MSO_SHAPE.RECTANGLE, ...)` ＋ fill) |
| `header_y_inconsistent_with_page1` | 当該ページの header の top を **ページ1の値に揃える** (theme.header.y_emu より優先) |
| `page_number_x_drift` / `page_number_y_drift` | 当該ページのページ番号 textbox の `left` / `top` を theme 値に強制 |
| `page_number_font_drift` | run.font.size を `Pt(theme.page_number.font_size_pt)` に強制 |
| `page_number_missing` | 当該ページに右下に textbox を新規追加してページ番号を入れる |
| `left_margin_violation` / `right_margin_violation` | 当該 shape の `left` / `width` を margins に収まるよう調整 |
| `font_drift` | 当該 text shape の **全 run** の `font.name` を theme.fonts.ja に置換 |

### 3. 補正の実装

```python
from pptx import Presentation
from pptx.util import Emu, Pt
from pptx.dml.color import RGBColor
import json

theme = json.loads(open(theme_path).read())
audit = json.loads(open(audit_json_path).read())
prs = Presentation(pptx_path)

# slide_size
ss = theme["slide_size"]
prs.slide_width = Emu(ss["width_emu"])
prs.slide_height = Emu(ss["height_emu"])

# 背景は全ページに theme.background.hex を強制
bg_hex = theme["background"]["hex"][1:]
for slide in prs.slides:
    fill = slide.background.fill
    fill.solid()
    fill.fore_color.rgb = RGBColor.from_string(bg_hex)

# 個別 deviation を kind ごとに処理（ページごとに対応 shape を特定）
for d in audit["deviations"]:
    page = d["page"]
    if page == 0:
        continue
    slide = prs.slides[page - 1]
    kind = d["kind"]
    # ... 上記表に従って補正
```

### 4. 補正完了後、再度 audit_consistency.py を実行（自己検証）

- `num_deviations` が補正前の半分以下にならなければ補正失敗 → ユーザーに報告して停止
- 0 になれば成功
- `font_drift` のような大量 deviation は 1ループで完全消去できなくてもよい (主要 shape を優先)

### 5. 上書き保存

`pptx_path` に上書き。失敗時はバックアップを取り元に戻す。

## 鉄則

- **theme.json から外れる shape は機械的に矯正する**（個別判断で残さない）
- ヘッダー帯が「面積最大の上部矩形」と判定される。複雑なヘッダー (装飾複数 shape) では個別ロジックを書く必要があり、その場合は個別 deviation を skip して `_unhandled` として報告
- フォント補正は **全 run** に効かせる（最初の run だけだと不完全）
- ページ間 inconsistent (`header_y_inconsistent_with_page1`) はページ1を正として揃える。theme.json と矛盾する場合はページ1の値で theme.json を更新する判断もありうる（ただしユーザー確認が必要）

## 出力

- 補正後 PPTX (上書き保存)
- `audit_workdir/audit_after.json` — 補正後の再監査結果
- 標準出力にサマリ: `before=X deviations, after=Y deviations, fixed=X-Y`
