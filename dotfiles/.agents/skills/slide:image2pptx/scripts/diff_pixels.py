#!/usr/bin/env python3
"""
Pixel-level diff between reference and current rendered slide images.

Usage:
  diff_pixels.py <reference> <current> <out_dir> [--threshold 25] [--min-area 200]

Outputs in <out_dir>:
  - heatmap.png   : per-pixel max-channel diff visualized (grayscale)
  - mask.png      : binary mask (white = diff > threshold)
  - overlay.png   : reference with red-tinted regions of mismatch
  - regions.json  : machine-readable list of suspicious regions
  - meta.json     : summary

regions.json schema:
  [
    {
      "id": 1,
      "bbox": [x, y, w, h],            # px in normalized (current-resized-to-ref) coords
      "area_px": int,
      "ref_mean_rgb": [r, g, b],
      "cur_mean_rgb": [r, g, b],
      "rgb_distance": float,           # L2 distance between mean RGBs
      "severity": "high" | "medium" | "low",
      "centroid": [x, y]
    },
    ...
  ]

severity rule:
  - high   : area_px >= 5000 OR rgb_distance >= 80
  - medium : area_px >= 1000 OR rgb_distance >= 40
  - low    : otherwise
"""
from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

import numpy as np
from PIL import Image

try:
    from scipy.ndimage import label as nd_label
    HAS_SCIPY = True
except ImportError:
    HAS_SCIPY = False


def parse_args():
    p = argparse.ArgumentParser()
    p.add_argument("reference")
    p.add_argument("current")
    p.add_argument("out_dir")
    p.add_argument("--threshold", type=int, default=25,
                   help="per-pixel max-channel diff threshold (0-255)")
    p.add_argument("--min-area", type=int, default=200,
                   help="ignore connected components smaller than this (px)")
    return p.parse_args()


def load_pair(ref_path: str, cur_path: str) -> tuple[np.ndarray, np.ndarray, tuple[int, int]]:
    ref = Image.open(ref_path).convert("RGB")
    cur = Image.open(cur_path).convert("RGB")
    # normalize current to reference resolution
    if cur.size != ref.size:
        cur = cur.resize(ref.size, Image.LANCZOS)
    return np.array(ref), np.array(cur), ref.size  # size = (W, H)


def build_diff(ref: np.ndarray, cur: np.ndarray) -> np.ndarray:
    """Return per-pixel max-channel absolute diff (uint8 HxW)."""
    diff = np.abs(ref.astype(np.int16) - cur.astype(np.int16))
    return diff.max(axis=2).astype(np.uint8)


def label_regions(mask: np.ndarray) -> tuple[np.ndarray, int]:
    """Connected components on a binary mask (4-connectivity).

    Returns (labels, num_features). Falls back to a pure-numpy BFS when scipy
    is unavailable.
    """
    if HAS_SCIPY:
        labels, n = nd_label(mask)
        return labels, int(n)

    # Fallback: iterative BFS, 4-connectivity. Adequate for slide-sized images.
    H, W = mask.shape
    labels = np.zeros((H, W), dtype=np.int32)
    next_label = 0
    for y in range(H):
        for x in range(W):
            if mask[y, x] and labels[y, x] == 0:
                next_label += 1
                stack = [(y, x)]
                while stack:
                    cy, cx = stack.pop()
                    if 0 <= cy < H and 0 <= cx < W and mask[cy, cx] and labels[cy, cx] == 0:
                        labels[cy, cx] = next_label
                        stack.extend([(cy + 1, cx), (cy - 1, cx),
                                      (cy, cx + 1), (cy, cx - 1)])
    return labels, next_label


def severity_of(area: int, rgb_dist: float) -> str:
    if area >= 5000 or rgb_dist >= 80:
        return "high"
    if area >= 1000 or rgb_dist >= 40:
        return "medium"
    return "low"


def region_summary(
    labels: np.ndarray, n: int, ref: np.ndarray, cur: np.ndarray, min_area: int
) -> list[dict]:
    out: list[dict] = []
    H, W = labels.shape
    for lab in range(1, n + 1):
        ys, xs = np.where(labels == lab)
        area = int(ys.size)
        if area < min_area:
            continue
        x0, x1 = int(xs.min()), int(xs.max())
        y0, y1 = int(ys.min()), int(ys.max())
        bbox = [x0, y0, x1 - x0 + 1, y1 - y0 + 1]
        ref_mean = ref[ys, xs].mean(axis=0)
        cur_mean = cur[ys, xs].mean(axis=0)
        rgb_dist = float(np.linalg.norm(ref_mean - cur_mean))
        out.append({
            "id": len(out) + 1,
            "bbox": bbox,
            "area_px": area,
            "ref_mean_rgb": [int(round(v)) for v in ref_mean.tolist()],
            "cur_mean_rgb": [int(round(v)) for v in cur_mean.tolist()],
            "rgb_distance": round(rgb_dist, 2),
            "severity": severity_of(area, rgb_dist),
            "centroid": [int(round(xs.mean())), int(round(ys.mean()))],
        })
    out.sort(key=lambda r: (-r["area_px"], -r["rgb_distance"]))
    for i, r in enumerate(out, 1):
        r["id"] = i
    return out


def save_overlay(ref: np.ndarray, mask: np.ndarray, path: Path) -> None:
    overlay = ref.copy()
    red = np.array([255, 0, 0], dtype=np.uint8)
    blend = (overlay * 0.5 + red * 0.5).astype(np.uint8)
    overlay[mask] = blend[mask]
    Image.fromarray(overlay).save(path)


def main() -> int:
    args = parse_args()
    out = Path(args.out_dir)
    out.mkdir(parents=True, exist_ok=True)

    ref, cur, (W, H) = load_pair(args.reference, args.current)
    diff = build_diff(ref, cur)
    mask = diff > args.threshold

    Image.fromarray(diff).save(out / "heatmap.png")
    Image.fromarray((mask.astype(np.uint8) * 255)).save(out / "mask.png")
    save_overlay(ref, mask, out / "overlay.png")

    labels, n = label_regions(mask)
    regions = region_summary(labels, n, ref, cur, args.min_area)
    (out / "regions.json").write_text(json.dumps(regions, ensure_ascii=False, indent=2))

    total_diff_px = int(mask.sum())
    meta = {
        "reference": args.reference,
        "current": args.current,
        "size": [W, H],
        "threshold": args.threshold,
        "min_area": args.min_area,
        "total_diff_px": total_diff_px,
        "diff_ratio": round(total_diff_px / (W * H), 4),
        "num_regions_raw": int(n),
        "num_regions_kept": len(regions),
        "scipy_used": HAS_SCIPY,
    }
    (out / "meta.json").write_text(json.dumps(meta, ensure_ascii=False, indent=2))

    print(json.dumps({"out_dir": str(out), **meta}, ensure_ascii=False))
    return 0


if __name__ == "__main__":
    sys.exit(main())
