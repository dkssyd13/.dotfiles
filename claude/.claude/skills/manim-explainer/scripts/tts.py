#!/usr/bin/env python3
"""narration.json → 비트별 음성 파일 + audio/manifest.json

provider
  local       Qwen3-TTS (mlx-audio). 크레딧 0. 초안, 그리고 크레딧이 없을 때의 최종본.
  web         ElevenLabs 웹 앱에서 (브라우저로) 만든 take를 History API로 받아 온다.
              무료 플랜에서 라이브러리 목소리(Chris)를 쓰는 유일한 길. 비트 문장과 같은
              문장의 가장 새 take를 고르고, narration.json 비트에 "take": "<id>"가 있으면 그것.
  elevenlabs  API로 직접 합성. 무료 플랜은 premade 목소리만 됨 → 유료 전환 전에는 쓰지 않음.

실행은 반드시 ~/.cache/manim-explainer/qwen-venv/bin/python 으로 (mlx_audio 필요).

  python tts.py <video_dir>/narration.json [--provider local|web|elevenlabs]
  python tts.py <video_dir>/narration.json --provider web --pending   # 웹에서 아직 안 만든 비트
  python tts.py --credits          # 남은 ElevenLabs 크레딧
  python tts.py --list-voices      # 계정에서 쓸 수 있는 ElevenLabs 음성
"""
from __future__ import annotations

import argparse
import hashlib
import json
import os
import re
import subprocess
import sys
import time
import urllib.error
import urllib.request
from pathlib import Path

CONFIG_DIR = Path.home() / ".config" / "manim-explainer"
CONFIG_PATH = CONFIG_DIR / "config.json"
KEY_PATH = CONFIG_DIR / "elevenlabs_api_key"

DEFAULTS = {
    # ElevenLabs
    "elevenlabs_model": "eleven_multilingual_v2",
    "elevenlabs_voice_id": "JBFqnCBsd6RMkjVDRZzb",  # premade "George". --list-voices로 바꿀 것
    "elevenlabs_stability": 0.5,
    "elevenlabs_similarity": 0.75,
    # 웹 앱 (History API로 받기)
    "web_voice_id": "PDoCXqBQFGsvfO0hNkEs",  # Chris - Warm and Clear (Voice Library)
    "web_voice_name": "Chris",
    # 로컬 (Qwen3-TTS CustomVoice, mlx-audio)
    "local_model": "mlx-community/Qwen3-TTS-12Hz-1.7B-CustomVoice-bf16",
    "local_voice": "sohee",  # 한국어 화자. 그 외 serena, vivian, ryan, aiden, eric, dylan, uncle_fu, ono_anna
    "local_lang": "korean",
    "local_instruct": None,  # 예: "차분하고 또렷한 강의 톤으로"
    "local_temperature": 0.7,
}

# 모델별 문자당 크레딧 (ElevenLabs 요금표 기준; flash/turbo는 절반)
CREDIT_PER_CHAR = {"eleven_flash_v2_5": 0.5, "eleven_turbo_v2_5": 0.5}

API = "https://api.elevenlabs.io/v1"
FALLBACK_STATUSES = {
    "quota_exceeded", "payment_required", "paid_plan_required", "free_users_not_allowed",
    "detected_unusual_activity", "invalid_api_key", "missing_permissions",
}


class QuotaOrAuthError(RuntimeError):
    """로컬로 넘어가야 하는 ElevenLabs 오류 (크레딧 소진, 무료 계정 제한, 키 문제)."""


def log(msg: str) -> None:
    print(f"[tts] {msg}", file=sys.stderr, flush=True)


def load_config() -> dict:
    cfg = dict(DEFAULTS)
    if CONFIG_PATH.exists():
        cfg.update(json.loads(CONFIG_PATH.read_text()))
    return cfg


def load_key() -> str | None:
    """환경변수 → KEY_PATH → config의 elevenlabs_env_files(.env 형식) 순서. 키 값은 출력하지 않는다."""
    key = os.environ.get("ELEVENLABS_API_KEY")
    if not key and KEY_PATH.exists():
        key = KEY_PATH.read_text().strip()
    if not key:
        for f in load_config().get("elevenlabs_env_files", []):
            p = Path(f).expanduser()
            if not p.exists():
                continue
            for line in p.read_text().splitlines():
                if line.strip().startswith("ELEVENLABS_API_KEY="):
                    key = line.split("=", 1)[1].strip().strip("'\"")
                    break
            if key:
                break
    return key or None


def duration_of(path: Path) -> float:
    out = subprocess.run(
        ["ffprobe", "-v", "error", "-show_entries", "format=duration",
         "-of", "default=nw=1:nk=1", str(path)],
        capture_output=True, text=True, check=True,
    ).stdout.strip()
    return float(out)


# ── ElevenLabs ──────────────────────────────────────────────────────────────

def _el_request(key: str, method: str, path: str, body: dict | None = None,
                query: str = "") -> bytes:
    url = f"{API}{path}{query}"
    data = json.dumps(body).encode() if body is not None else None
    req = urllib.request.Request(url, data=data, method=method, headers={
        "xi-api-key": key, "Content-Type": "application/json", "Accept": "*/*",
    })
    for attempt in range(4):
        try:
            with urllib.request.urlopen(req, timeout=120) as r:
                return r.read()
        except urllib.error.HTTPError as e:
            raw = e.read().decode(errors="replace")
            try:
                detail = json.loads(raw).get("detail", {})
            except json.JSONDecodeError:
                detail = {}
            status = detail.get("status", "") if isinstance(detail, dict) else ""
            msg = detail.get("message", raw[:300]) if isinstance(detail, dict) else raw[:300]
            if e.code == 429 and attempt < 3:  # 동시 요청/속도 제한 → 잠시 후 재시도
                time.sleep(2 ** attempt * 2)
                continue
            if e.code in (401, 402, 403) or status in FALLBACK_STATUSES:
                raise QuotaOrAuthError(f"HTTP {e.code} {status}: {msg}") from None
            raise RuntimeError(f"ElevenLabs HTTP {e.code} {status}: {msg}") from None
        except urllib.error.URLError as e:
            if attempt < 3:
                time.sleep(2)
                continue
            raise RuntimeError(f"ElevenLabs 연결 실패: {e}") from None
    raise RuntimeError("unreachable")


def el_remaining_credits(key: str) -> int | None:
    """남은 크레딧. 키에 user_read 권한이 없으면 None."""
    try:
        sub = json.loads(_el_request(key, "GET", "/user/subscription"))
    except QuotaOrAuthError as e:
        if "missing_permissions" in str(e):
            return None
        raise
    return int(sub["character_limit"]) - int(sub["character_count"])


def el_synthesize(key: str, cfg: dict, text: str, prev_text: str, next_text: str,
                  out: Path) -> None:
    body = {
        "text": text,
        "model_id": cfg["elevenlabs_model"],
        "voice_settings": {
            "stability": cfg["elevenlabs_stability"],
            "similarity_boost": cfg["elevenlabs_similarity"],
        },
    }
    if cfg["elevenlabs_model"] != "eleven_v3":  # 앞뒤 문맥으로 비트 간 억양을 이어 준다
        if prev_text:
            body["previous_text"] = prev_text
        if next_text:
            body["next_text"] = next_text
    audio = _el_request(key, "POST", f"/text-to-speech/{cfg['elevenlabs_voice_id']}",
                        body, query="?output_format=mp3_44100_128")
    out.write_bytes(audio)


# ── 웹 앱 take (History API) ────────────────────────────────────────────────

def _norm(s: str) -> str:
    s = re.sub(r"\[[^\]]*\]", " ", s)  # v3/v4 오디오 태그 [cheerfully] 등은 비교에서 뺀다
    return " ".join(s.split())


def _item_voice(it: dict) -> str | None:
    # v3/v4 웹 생성은 맨 위 voice_id가 비고 dialogue[0].voice_id에 들어 있다
    return it.get("voice_id") or next(
        (d.get("voice_id") for d in it.get("dialogue") or [] if d.get("voice_id")), None)


def _item_text(it: dict) -> str:
    return it.get("text") or " ".join(d.get("text", "") for d in it.get("dialogue") or [])


def el_history(key: str, max_pages: int = 5) -> list[dict]:
    """최신순 History 항목."""
    items, after = [], None
    for _ in range(max_pages):
        q = "?page_size=1000" + (f"&start_after_history_item_id={after}" if after else "")
        page = json.loads(_el_request(key, "GET", "/history", query=q))
        items += page.get("history", [])
        if not page.get("has_more"):
            break
        after = page.get("last_history_item_id")
    return items


def web_takes(key: str, cfg: dict, beats: list[tuple[str, str]], fixed: dict) -> dict:
    hist = el_history(key)
    takes = {}
    for k, t in beats:
        if k in fixed:
            takes[k] = fixed[k]
            continue
        for it in hist:
            if _item_voice(it) == cfg["web_voice_id"] and _norm(_item_text(it)) == _norm(t):
                takes[k] = it["history_item_id"]
                break
    return takes


# ── 로컬: Qwen3-TTS ─────────────────────────────────────────────────────────

class LocalQwen:
    def __init__(self, cfg: dict):
        self.cfg = cfg
        self.model = None  # 캐시만으로 끝나면 모델을 올리지 않는다

    def synthesize(self, text: str, out: Path) -> None:
        import numpy as np
        from mlx_audio.audio_io import write as audio_write
        if self.model is None:
            from mlx_audio.tts.utils import load_model
            log(f"로컬 모델 로드: {self.cfg['local_model']}")
            self.model = load_model(self.cfg["local_model"])
        kw = dict(text=text, voice=self.cfg["local_voice"], lang_code=self.cfg["local_lang"],
                  temperature=self.cfg["local_temperature"], split_pattern="\n")
        if self.cfg.get("local_instruct"):
            kw["instruct"] = self.cfg["local_instruct"]
        chunks, sr = [], self.model.sample_rate
        for r in self.model.generate(**kw):
            chunks.append(np.array(r.audio))
            sr = r.sample_rate
        audio_write(str(out), np.concatenate(chunks), sr, format="wav")


# ── 메인 ────────────────────────────────────────────────────────────────────

def beats_of(narr: dict) -> list[tuple[str, str]]:
    out = []
    for sc in narr["scenes"]:
        for b in sc["beats"]:
            text = b["text"].strip()
            if text:
                out.append((f"{sc['id']}/{b['id']}", text))
    return out


def fixed_takes(narr: dict) -> dict:
    return {f"{sc['id']}/{b['id']}": b["take"]
            for sc in narr["scenes"] for b in sc["beats"] if b.get("take")}


def cache_path(audio_dir: Path, provider: str, cfg: dict, key: str, text: str,
               extra: str = "") -> Path:
    if provider == "web":
        sig, ext = f"{cfg['web_voice_id']}|{extra}", "mp3"
    elif provider == "elevenlabs":
        sig, ext = f"{cfg['elevenlabs_model']}|{cfg['elevenlabs_voice_id']}", "mp3"
    else:
        sig, ext = f"{cfg['local_model']}|{cfg['local_voice']}|{cfg.get('local_instruct')}", "wav"
    h = hashlib.sha1(f"{sig}|{text}".encode()).hexdigest()[:10]
    return audio_dir / provider / f"{key.replace('/', '__')}__{h}.{ext}"


def run(narr_path: Path, provider: str, pending_only: bool = False) -> dict | None:
    cfg = load_config()
    narr = json.loads(narr_path.read_text())
    beats = beats_of(narr)
    audio_dir = narr_path.parent / "audio"
    total_chars = sum(len(t) for _, t in beats)
    reason = ""

    if provider == "web":
        key = load_key()
        if not key:
            sys.exit("ElevenLabs 키 없음 (History API에 필요)")
        takes = web_takes(key, cfg, beats, fixed_takes(narr))
        pending = [{"key": k, "text": t} for k, t in beats if k not in takes]
        if pending_only:
            print(json.dumps({"pending": pending, "chars": sum(len(p["text"]) for p in pending),
                              "done": len(takes), "total": len(beats)},
                             ensure_ascii=False, indent=1))
            return None
        if pending:
            sys.exit(f"웹에서 아직 만들지 않은 비트 {len(pending)}개: "
                     f"{[p['key'] for p in pending]} — --pending으로 문장 확인")
        return finish(narr_path, beats, audio_dir, "web", cfg,
                      lambda k, t, p, n, out: out.write_bytes(
                          _el_request(key, "GET", f"/history/{takes[k]}/audio")),
                      total_chars, "", extras=takes)

    if provider == "elevenlabs":  # 유료 전환 뒤에만. 실패하면 그대로 에러
        key = load_key()
        if not key:
            sys.exit(f"ElevenLabs 키 없음: ELEVENLABS_API_KEY 또는 {KEY_PATH}")
        need = int(sum(len(t) for k, t in beats
                       if not cache_path(audio_dir, "elevenlabs", cfg, k, t).exists())
                   * CREDIT_PER_CHAR.get(cfg["elevenlabs_model"], 1.0))
        remaining = el_remaining_credits(key)
        if remaining is not None and remaining < need:
            sys.exit(f"크레딧 부족: 필요 {need}, 남음 {remaining}")
        log(f"ElevenLabs API: 필요 크레딧 {need}, 남음 {remaining}")
        return finish(narr_path, beats, audio_dir, "elevenlabs", cfg,
                      lambda k, t, p, n, out: el_synthesize(key, cfg, t, p, n, out),
                      total_chars, "")

    if reason:
        log(f"로컬 Qwen3-TTS로 전환: {reason}")
    engine = LocalQwen(cfg)
    return finish(narr_path, beats, audio_dir, "local", cfg,
                  lambda k, t, p, n, out: engine.synthesize(t, out), total_chars, reason)


def finish(narr_path, beats, audio_dir, provider, cfg, synth, total_chars, reason,
           extras: dict | None = None) -> dict:
    voice = {"elevenlabs": cfg["elevenlabs_voice_id"], "web": cfg["web_voice_name"]}
    manifest = {"provider": provider, "reason": reason, "total_chars": total_chars,
                "voice": voice.get(provider, cfg["local_voice"]), "beats": {}}
    if extras:
        manifest["takes"] = extras
    for i, (key, text) in enumerate(beats):
        out = cache_path(audio_dir, provider, cfg, key, text, (extras or {}).get(key, ""))
        out.parent.mkdir(parents=True, exist_ok=True)
        if not out.exists():
            prev_text = beats[i - 1][1] if i > 0 else ""
            next_text = beats[i + 1][1] if i + 1 < len(beats) else ""
            log(f"{provider}: {key} ({len(text)}자)")
            tmp = out.with_suffix(".part" + out.suffix)
            synth(key, text, prev_text, next_text, tmp)
            tmp.rename(out)
        manifest["beats"][key] = {"path": str(out.resolve()), "duration": duration_of(out)}
    total = sum(b["duration"] for b in manifest["beats"].values())
    manifest["total_seconds"] = round(total, 2)
    (audio_dir / "manifest.json").write_text(json.dumps(manifest, ensure_ascii=False, indent=2))
    log(f"완료: provider={provider}, 비트 {len(beats)}개, 음성 총 {total/60:.1f}분, {total_chars}자")
    return manifest


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("narration", nargs="?", type=Path)
    ap.add_argument("--provider", default="local", choices=["local", "web", "elevenlabs"])
    ap.add_argument("--pending", action="store_true", help="web: 아직 웹에서 안 만든 비트만 출력")
    ap.add_argument("--credits", action="store_true")
    ap.add_argument("--list-voices", action="store_true")
    a = ap.parse_args()

    if a.credits or a.list_voices:
        key = load_key()
        if not key:
            sys.exit(f"ElevenLabs 키 없음: ELEVENLABS_API_KEY 또는 {KEY_PATH}")
        if a.credits:
            rem = el_remaining_credits(key)
            print("남은 크레딧: 조회 불가 (키에 user_read 권한 없음 — elevenlabs.io 사용량 페이지에서 확인)"
                  if rem is None else f"남은 크레딧: {rem}")
        if a.list_voices:
            for v in json.loads(_el_request(key, "GET", "/voices"))["voices"]:
                print(f"{v['voice_id']}  {v['name']:<24} {v.get('category', '')}  "
                      f"{(v.get('labels') or {}).get('accent', '')}")
        return
    if not a.narration:
        ap.error("narration.json 경로가 필요합니다")
    run(a.narration.resolve(), a.provider, a.pending)


if __name__ == "__main__":
    main()
