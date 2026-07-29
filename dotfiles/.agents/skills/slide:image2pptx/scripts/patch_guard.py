#!/usr/bin/env python3
"""
patch 適用の前後で diff_ratio を比較し、悪化していたらロールバックする。

modifier subagent の前後で親が呼ぶ：
  before: python3 patch_guard.py before <workdir> <page_no>
    → workdir/pptx/current.pptx を current.pptx.bak.preN にコピー（N = iteration）
    → 現在の diff_ratio を計測して workdir/diff/_guard/page{NN}_pre.json に書く

  after:  python3 patch_guard.py after <workdir> <page_no> [--tolerance 1.10]
    → 再レンダリングして post diff_ratio を計算
    → post > pre * tolerance なら .bak から戻して "ROLLBACK" を返し exit 2
    → そうでなければ "OK" を返し exit 0

入力:
  workdir: image2pptx 作業ディレクトリ
  page_no: 1始まり

副作用:
  before: pptx/current.pptx.bak.iterN を作る
  after (rollback): pptx/current.pptx を bak から書き戻し、render を再実行

戻り値:
  exit 0 = OK（patch 維持）
  exit 1 = エラー（パス不正など）
  exit 2 = ROLLBACK（悪化検出して戻した）
"""
from __future__ import annotations
import argparse
import json
import shutil
import subprocess
import sys
import re
from pathlib import Path


def script_dir() -> Path:
    return Path(__file__).resolve().parent


def render_page(pptx: Path, render_dir: Path, page_no: int) -> Path:
    """指定ページを PNG にレンダリングして PNG パスを返す。"""
    sh = script_dir() / "pptx_page_to_image.sh"
    res = subprocess.run(
        ["bash", str(sh), str(pptx), str(page_no), str(render_dir)],
        capture_output=True, text=True
    )
    if res.returncode != 0:
        raise RuntimeError(f"render failed: {res.stderr}")
    # 標準的な命名 current_pageNN.png を返す
    return render_dir / f"current_page{page_no:02d}.png"


def compute_diff_ratio(reference: Path, current: Path, tmp_out: Path) -> float:
    diff_script = script_dir() / "diff_pixels.py"
    tmp_out.mkdir(parents=True, exist_ok=True)
    res = subprocess.run(
        ["python3", str(diff_script), str(reference), str(current), str(tmp_out)],
        capture_output=True, text=True
    )
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
    if not last_json:
        raise RuntimeError(f"diff_pixels output empty: {res.stdout}\n{res.stderr}")
    return float(last_json["diff_ratio"])


def cmd_before(args):
    workdir = Path(args.workdir).resolve()
    page_no = args.page_no
    pptx = workdir / "pptx" / "current.pptx"
    if not pptx.exists():
        print(json.dumps({"ok": False, "error": f"pptx not found: {pptx}"}))
        return 1

    bak = workdir / "pptx" / f"current.pptx.bak.iter{args.iteration:02d}_p{page_no:02d}"
    shutil.copy2(pptx, bak)

    ref = workdir / "reference" / f"page{page_no:02d}.png"
    render_dir = workdir / "render"
    cur = render_page(pptx, render_dir, page_no)
    tmp = workdir / "diff" / "_guard" / f"page{page_no:02d}_iter{args.iteration:02d}_pre"
    pre_ratio = compute_diff_ratio(ref, cur, tmp)

    state = workdir / "diff" / "_guard" / f"page{page_no:02d}_pre.json"
    state.parent.mkdir(parents=True, exist_ok=True)
    state.write_text(json.dumps({
        "page": page_no, "iteration": args.iteration,
        "pre_diff_ratio": pre_ratio,
        "bak_path": str(bak),
        "pptx_path": str(pptx),
    }, ensure_ascii=False, indent=2))
    print(json.dumps({"ok": True, "phase": "before", "page": page_no,
                      "pre_diff_ratio": round(pre_ratio, 4),
                      "bak": str(bak)}, ensure_ascii=False))
    return 0


def cmd_after(args):
    workdir = Path(args.workdir).resolve()
    page_no = args.page_no
    state = workdir / "diff" / "_guard" / f"page{page_no:02d}_pre.json"
    if not state.exists():
        print(json.dumps({"ok": False, "error": f"pre state not found: {state}. before を先に呼べ"}))
        return 1
    pre = json.loads(state.read_text())
    bak = Path(pre["bak_path"])
    pptx = Path(pre["pptx_path"])
    pre_ratio = float(pre["pre_diff_ratio"])

    ref = workdir / "reference" / f"page{page_no:02d}.png"
    render_dir = workdir / "render"
    cur = render_page(pptx, render_dir, page_no)
    tmp = workdir / "diff" / "_guard" / f"page{page_no:02d}_iter{pre['iteration']:02d}_post"
    post_ratio = compute_diff_ratio(ref, cur, tmp)

    delta = post_ratio - pre_ratio
    threshold = pre_ratio * args.tolerance
    if post_ratio > threshold:
        # ロールバック
        shutil.copy2(bak, pptx)
        # render も戻す
        render_page(pptx, render_dir, page_no)
        print(json.dumps({
            "ok": False, "phase": "after", "page": page_no,
            "pre_diff_ratio": round(pre_ratio, 4),
            "post_diff_ratio": round(post_ratio, 4),
            "delta": round(delta, 4),
            "threshold": round(threshold, 4),
            "tolerance": args.tolerance,
            "action": "ROLLBACK",
            "reason": f"post {post_ratio:.4f} > pre {pre_ratio:.4f} * tolerance {args.tolerance} = {threshold:.4f}",
            "bak_used": str(bak),
        }, ensure_ascii=False, indent=2))
        return 2
    else:
        print(json.dumps({
            "ok": True, "phase": "after", "page": page_no,
            "pre_diff_ratio": round(pre_ratio, 4),
            "post_diff_ratio": round(post_ratio, 4),
            "delta": round(delta, 4),
            "threshold": round(threshold, 4),
            "action": "KEEP",
        }, ensure_ascii=False, indent=2))
        return 0


def main():
    ap = argparse.ArgumentParser()
    sub = ap.add_subparsers(dest="cmd", required=True)

    p_before = sub.add_parser("before")
    p_before.add_argument("workdir")
    p_before.add_argument("page_no", type=int)
    p_before.add_argument("--iteration", type=int, default=1)

    p_after = sub.add_parser("after")
    p_after.add_argument("workdir")
    p_after.add_argument("page_no", type=int)
    p_after.add_argument("--tolerance", type=float, default=1.10,
                         help="post > pre * tolerance ならロールバック (default 1.10 = 10%悪化で戻す)")

    args = ap.parse_args()

    if args.cmd == "before":
        return cmd_before(args)
    if args.cmd == "after":
        return cmd_after(args)
    return 1


if __name__ == "__main__":
    sys.exit(main())
