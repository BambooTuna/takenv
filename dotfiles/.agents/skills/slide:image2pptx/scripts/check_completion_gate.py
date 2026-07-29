#!/usr/bin/env python3
"""
完了ゲート判定。親オーケストレーターが完了報告する前に必ず実行する。

3条件すべて PASS で初めて完了:
  1. 全ページの diff_ratio < diff_threshold (default 0.05)
  2. audit.json の num_deviations == 0
  3. 最新 diff Markdown の [critical] 残件数 == 0（diff Markdown が無い場合は無視＝1ページ目の検査では skip）

使い方:
  python3 check_completion_gate.py <workdir> [--diff-threshold 0.05]

戻り値:
  exit 0 = PASS（完了報告可）
  exit 1 = FAIL（ループ続行 or ユーザー判断必須）
  stdout = JSON サマリ
"""
from __future__ import annotations
import argparse
import glob
import json
import os
import re
import subprocess
import sys
from pathlib import Path


def latest_diff_md(diff_dir: Path, page_no: int) -> Path | None:
    cands = sorted(diff_dir.glob(f"page{page_no:02d}_iter*.md"))
    return cands[-1] if cands else None


def count_critical(md_path: Path) -> int:
    if not md_path.exists():
        return 0
    text = md_path.read_text(encoding="utf-8", errors="replace")
    in_section = False
    n = 0
    for line in text.splitlines():
        if line.startswith("## 修正指示"):
            in_section = True
            continue
        if in_section and line.startswith("## ") and not line.startswith("## 修正指示"):
            in_section = False
        if in_section and re.match(r"^### \[critical\]", line):
            n += 1
    return n


def parse_completion_judgment(md_path: Path) -> str | None:
    """diff_reviewer の '完了: yes/no' を返す。見つからなければ None。"""
    if not md_path.exists():
        return None
    text = md_path.read_text(encoding="utf-8", errors="replace")
    m = re.search(r"^- *完了:\s*(yes|no)\b", text, re.MULTILINE)
    return m.group(1) if m else None


def compute_diff_ratio(reference: Path, current: Path, tmp_out: Path, script_dir: Path) -> float:
    """diff_pixels.py を呼んで diff_ratio を返す。"""
    tmp_out.mkdir(parents=True, exist_ok=True)
    diff_script = script_dir / "diff_pixels.py"
    res = subprocess.run(
        ["python3", str(diff_script), str(reference), str(current), str(tmp_out)],
        capture_output=True, text=True
    )
    # 出力末尾の JSON 行を拾う
    last_json = None
    for line in res.stdout.strip().splitlines():
        line = line.strip()
        if line.startswith("{"):
            try:
                last_json = json.loads(line)
            except json.JSONDecodeError:
                pass
    if not last_json:
        meta = tmp_out / "meta.json"
        if meta.exists():
            last_json = json.loads(meta.read_text())
    if not last_json or "diff_ratio" not in last_json:
        raise RuntimeError(f"diff_pixels.py 出力が読めません: stdout={res.stdout[:300]} stderr={res.stderr[:300]}")
    return float(last_json["diff_ratio"])


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("workdir", help="image2pptx の作業ディレクトリ（reference/, render/, audit/, diff/ を含む）")
    ap.add_argument("--diff-threshold", type=float, default=0.05,
                    help="ページごとの diff_ratio 上限 (default: 0.05)")
    ap.add_argument("--audit-name", default="audit_after.json",
                    help="audit ファイル名 (default: audit_after.json、なければ audit.json も探す)")
    args = ap.parse_args()

    workdir = Path(args.workdir).resolve()
    script_dir = Path(__file__).resolve().parent

    ref_dir = workdir / "reference"
    render_dir = workdir / "render"
    audit_dir = workdir / "audit"
    diff_dir = workdir / "diff"

    # 1. 全ページの diff_ratio
    page_results = []
    ref_pages = sorted(ref_dir.glob("page*.png"))
    if not ref_pages:
        print(json.dumps({"pass": False, "reason": "no reference pages found", "ref_dir": str(ref_dir)}))
        return 1

    fails = []
    for ref_path in ref_pages:
        m = re.match(r"page(\d+)\.png", ref_path.name)
        if not m:
            continue
        page_no = int(m.group(1))
        cur_path = render_dir / f"current_page{page_no:02d}.png"
        if not cur_path.exists():
            fails.append(f"page{page_no:02d}: current render not found ({cur_path})")
            page_results.append({"page": page_no, "diff_ratio": None, "status": "no_render"})
            continue

        tmp_out = workdir / "diff" / "_gate_check" / f"page{page_no:02d}"
        diff_ratio = compute_diff_ratio(ref_path, cur_path, tmp_out, script_dir)

        # 最新 diff Markdown の completion 判定 + critical 残数
        latest_md = latest_diff_md(diff_dir, page_no)
        crit = count_critical(latest_md) if latest_md else None
        completion = parse_completion_judgment(latest_md) if latest_md else None

        page_status = "PASS" if diff_ratio < args.diff_threshold else "FAIL_diff"
        if crit is not None and crit > 0:
            page_status = "FAIL_critical" if page_status == "PASS" else page_status + "+critical"

        page_results.append({
            "page": page_no,
            "diff_ratio": round(diff_ratio, 4),
            "diff_threshold": args.diff_threshold,
            "latest_diff_md": str(latest_md) if latest_md else None,
            "critical_remaining": crit,
            "reviewer_completion": completion,
            "status": page_status,
        })
        if page_status != "PASS":
            fails.append(f"page{page_no:02d}: {page_status} (diff_ratio={diff_ratio:.4f}, critical={crit})")

    # 2. audit deviations
    audit_path = audit_dir / args.audit_name
    if not audit_path.exists():
        alt = audit_dir / "audit.json"
        audit_path = alt if alt.exists() else audit_path
    audit_deviations = None
    if audit_path.exists():
        try:
            data = json.loads(audit_path.read_text())
            audit_deviations = int(data.get("summary", {}).get("num_deviations", data.get("num_deviations", 0)))
        except Exception as e:
            fails.append(f"audit.json parse error: {e}")
    else:
        fails.append(f"audit file not found: {audit_path}")

    if audit_deviations is None or audit_deviations > 0:
        fails.append(f"audit_deviations={audit_deviations} (must be 0)")

    summary = {
        "pass": len(fails) == 0,
        "diff_threshold": args.diff_threshold,
        "audit_deviations": audit_deviations,
        "audit_path": str(audit_path),
        "pages": page_results,
        "fails": fails,
    }
    print(json.dumps(summary, ensure_ascii=False, indent=2))
    return 0 if summary["pass"] else 1


if __name__ == "__main__":
    sys.exit(main())
