"""Manim 쪽 도우미: 3b1b 톤의 테마 + 내레이션 동기화.

scenes.py 맨 위에서:

    import os, sys
    sys.path.insert(0, os.path.expanduser("~/.claude/skills/manim-explainer/scripts"))
    from explainer import *

씬 클래스 이름 = narration.json의 scene id. 비트는 이렇게 쓴다:

    class S01Hook(NarratedScene):
        def construct(self):
            with self.narrate("b1") as b:          # 이 비트 음성이 재생되기 시작
                self.play(Write(eq), run_time=b.part(0.6))   # 비트 길이의 60%
                self.play(Indicate(eq[2]), run_time=b.remaining())
            # with 블록을 나가면 음성이 끝날 때까지 자동으로 기다린다 (+ gap)

애니메이션 시간을 초로 박지 말고 b.part()/b.remaining()으로 쓰면,
초안(로컬 TTS)과 최종본(ElevenLabs)의 음성 길이가 달라도 싱크가 유지된다.
"""
from __future__ import annotations

import json
import os
from contextlib import contextmanager
from pathlib import Path

from manim import *  # noqa: F401,F403
from manim import BLUE_C, GREEN_C, GREY_B, MAROON_C, RED_C, TEAL_C, YELLOW_C, Scene, Text, config

# ── 테마 ────────────────────────────────────────────────────────────────────
config.background_color = "#0F1115"
KO_FONT = os.environ.get("EXPLAINER_FONT", "Pretendard")

# 개념별 고정 색. 한 영상 안에서 같은 개념은 끝까지 같은 색 (수식 조각과 그림을 같은 색으로 묶는다)
C_STATE = BLUE_C
C_ACTION = GREEN_C
C_REWARD = YELLOW_C
C_VALUE = TEAL_C
C_POLICY = MAROON_C
C_ERROR = RED_C
C_DIM = GREY_B


def Ko(text: str, size: float = 36, **kw) -> Text:
    """한글 텍스트. MathTex에는 한글을 넣지 말 것 (LaTeX 한글 미설정)."""
    kw.setdefault("font", KO_FONT)
    return Text(text, font_size=size, **kw)


# ── 내레이션 동기화 ──────────────────────────────────────────────────────────
_MANIFEST: dict | None = None


def _manifest() -> dict:
    global _MANIFEST
    if _MANIFEST is None:
        p = Path(os.environ.get("EXPLAINER_MANIFEST", "audio/manifest.json"))
        if not p.exists():
            raise FileNotFoundError(f"{p} 없음 — 먼저 tts.py를 돌릴 것")
        _MANIFEST = json.loads(p.read_text())
    return _MANIFEST


class Beat:
    def __init__(self, scene: Scene, duration: float):
        self.scene = scene
        self.start = scene.time
        self.duration = duration

    @property
    def elapsed(self) -> float:
        return self.scene.time - self.start

    def part(self, frac: float, floor: float = 0.3) -> float:
        """비트 전체 길이의 frac 비율 (초)."""
        return max(floor, self.duration * frac)

    def remaining(self, frac: float = 1.0, floor: float = 0.3) -> float:
        """남은 음성 시간의 frac 비율 (초)."""
        return max(floor, (self.duration - self.elapsed) * frac)


class NarratedScene(Scene):
    gap = 0.35  # 비트 사이 숨 고르기 (초)

    def setup(self):
        super().setup()
        self._spoken: set[str] = set()

    @contextmanager
    def narrate(self, beat_id: str, gap: float | None = None):
        key = f"{type(self).__name__}/{beat_id}"
        beats = _manifest()["beats"]
        if key not in beats:
            raise KeyError(f"manifest에 {key} 없음 — narration.json과 씬/비트 id를 맞출 것")
        info = beats[key]
        self.add_sound(info["path"])
        b = Beat(self, info["duration"])
        yield b
        left = b.duration - b.elapsed
        if left > 0.02:
            self.wait(left)
        g = self.gap if gap is None else gap
        if g > 0:
            self.wait(g)
        self._spoken.add(beat_id)

    def tear_down(self):
        prefix = f"{type(self).__name__}/"
        missing = [k for k in _manifest()["beats"]
                   if k.startswith(prefix) and k[len(prefix):] not in self._spoken]
        if missing:
            print(f"[explainer] 경고: 재생 안 된 비트 {missing}")
        super().tear_down()
