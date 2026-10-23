#!/usr/bin/env python3
"""씬 렌더 → 이어 붙이기 → 점검용 콘택트 시트.

실행은 ~/.cache/manim-explainer/venv/bin/python 으로.

  python build.py <video_dir> [-q l|m|h|k] [--scenes S01Hook S03Bellman] [--no-sheets]

<video_dir>에 narration.json, scenes.py, audio/manifest.json이 있어야 한다.
결과: -q l → <video_dir>/draft.mp4, 그 외 → <video_dir>/<slug>.mp4
      check/<Scene>.png  씬마다 프레임을 격자로 모은 이미지 (Read로 레이아웃 점검)
"""
from __future__ import annotations

import argparse
import json
import math
import os
import subprocess
import sys
from pathlib import Path

VENV_BIN = Path.home() / ".cache" / "manim-explainer" / "venv" / "bin"
RES_DIR = {"l": "480p15", "m": "720p30", "h": "1080p60", "p": "1440p60", "k": "2160p60"}


def sh(cmd: list[str], **kw) -> subprocess.CompletedProcess:
    return subprocess.run(cmd, check=True, **kw)


def probe(path: Path, entries: str, stream: str | None = None) -> str:
    cmd = ["ffprobe", "-v", "error"]
    if stream:
        cmd += ["-select_streams", stream]
    cmd += ["-show_entries", entries, "-of", "default=nw=1:nk=1", str(path)]
    return subprocess.run(cmd, capture_output=True, text=True, check=True).stdout.strip()


def ensure_audio(mp4: Path) -> Path:
    """음성 없는 씬이 있으면 concat이 깨지므로 무음 트랙을 붙인다."""
    if probe(mp4, "stream=codec_type", "a"):
        return mp4
    out = mp4.with_name(mp4.stem + "_a.mp4")
    sh(["ffmpeg", "-y", "-v", "error", "-i", str(mp4), "-f", "lavfi",
        "-i", "anullsrc=r=44100:cl=stereo", "-shortest", "-c:v", "copy",
        "-c:a", "aac", str(out)])
    return out


def contact_sheet(mp4: Path, out: Path, cols: int = 4, max_tiles: int = 16) -> None:
    dur = float(probe(mp4, "format=duration"))
    n = max(1, min(max_tiles, math.ceil(dur / 2.5)))
    rows = math.ceil(n / cols)
    step = dur / n
    sh(["ffmpeg", "-y", "-v", "error", "-ss", f"{step/2:.2f}", "-i", str(mp4),
        "-vf", f"fps=1/{step:.3f},scale=400:-1,tile={cols}x{rows}:padding=4:color=white",
        "-frames:v", "1", str(out)])
    print(f"  {out.name}: {n}칸, 칸당 {step:.1f}초 (왼→오, 위→아래)")


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("video_dir", type=Path)
    ap.add_argument("-q", "--quality", default="l", choices=list(RES_DIR))
    ap.add_argument("--scenes", nargs="*")
    ap.add_argument("--no-sheets", action="store_true")
    a = ap.parse_args()

    vd = a.video_dir.resolve()
    narr = json.loads((vd / "narration.json").read_text())
    manifest = vd / "audio" / "manifest.json"
    if not manifest.exists():
        sys.exit("audio/manifest.json 없음 — tts.py 먼저")
    order = [s["id"] for s in narr["scenes"]]
    targets = a.scenes or order

    env = dict(os.environ, EXPLAINER_MANIFEST=str(manifest),
               PATH=f"{VENV_BIN}:{os.environ['PATH']}")
    sh([str(VENV_BIN / "manim"), f"-q{a.quality}", "--media_dir", str(vd / "media"),
        "--disable_caching", str(vd / "scenes.py"), *targets], cwd=vd, env=env)

    res = vd / "media" / "videos" / "scenes" / RES_DIR[a.quality]
    clips = [res / f"{s}.mp4" for s in order]
    missing = [c.name for c in clips if not c.exists()]
    if missing:
        print(f"아직 렌더 안 된 씬: {missing} — 이어 붙이기 생략")
        return
    clips = [ensure_audio(c) for c in clips]

    lst = vd / "media" / "concat.txt"
    lst.write_text("".join(f"file '{c}'\n" for c in clips))
    final = vd / ("draft.mp4" if a.quality == "l" else f"{narr.get('slug', vd.name)}.mp4")
    sh(["ffmpeg", "-y", "-v", "error", "-f", "concat", "-safe", "0", "-i", str(lst),
        "-c:v", "copy", "-c:a", "aac", "-b:a", "192k", str(final)])
    dur = float(probe(final, "format=duration"))
    print(f"완성: {final} ({dur/60:.1f}분)")

    if not a.no_sheets:
        (vd / "check").mkdir(exist_ok=True)
        for s in targets:
            contact_sheet(res / f"{s}.mp4", vd / "check" / f"{s}.png")


if __name__ == "__main__":
    main()
