#!/usr/bin/env bash
# 환경 점검 + 설치 (여러 번 돌려도 안전). venv 두 개를 쓴다:
#   venv       manim (렌더)
#   qwen-venv  mlx-audio (로컬 TTS: Qwen3-TTS) — tts.py는 이쪽 python으로 실행
set -euo pipefail
ROOT="$HOME/.cache/manim-explainer"
mkdir -p "$ROOT"

for bin in ffmpeg ffprobe latex dvisvgm uv; do
  command -v "$bin" >/dev/null || { echo "없음: $bin (brew install ffmpeg / MacTeX / uv)"; exit 1; }
done
brew list cairo pango pkgconf >/dev/null 2>&1 || brew install cairo pango pkgconf

if [ ! -x "$ROOT/venv/bin/manim" ]; then
  uv venv --python 3.12 "$ROOT/venv" -q
  VIRTUAL_ENV="$ROOT/venv" uv pip install -q manim
fi
if ! "$ROOT/qwen-venv/bin/python" -c "import mlx_audio" 2>/dev/null; then
  uv venv --python 3.12 "$ROOT/qwen-venv" -q
  VIRTUAL_ENV="$ROOT/qwen-venv" uv pip install -q mlx-audio
fi

fc-list | grep -qi pretendard || echo "경고: Pretendard 폰트 없음 → EXPLAINER_FONT='Apple SD Gothic Neo' 로 지정"

KEY_FILE="$HOME/.config/manim-explainer/elevenlabs_api_key"
if [ -n "${ELEVENLABS_API_KEY:-}" ] || [ -s "$KEY_FILE" ]; then
  echo "ElevenLabs 키: 있음"
else
  echo "ElevenLabs 키: 없음 → 로컬 TTS만 사용 ($KEY_FILE 에 저장하면 사용)"
fi
echo "manim: $("$ROOT/venv/bin/manim" --version 2>/dev/null | tail -1)"
echo "ok"
