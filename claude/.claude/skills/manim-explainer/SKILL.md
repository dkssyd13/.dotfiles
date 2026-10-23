---
name: manim-explainer
description: >
  Makes 3Blue1Brown-style animated explainer videos (Manim + Korean voice narration) for a
  specific textbook chapter/section, lecture slide deck, or single concept from course
  materials in the current directory. Final narration uses the ElevenLabs "Chris" voice,
  generated in the ElevenLabs web app via Claude in Chrome (free plan blocks library voices
  on the API) and fetched through the History API; when there are no credits left, it uses
  local open-source TTS (Qwen3-TTS via mlx-audio) instead. Use whenever the user asks for a video/animation
  explanation of course material: "3b1b 스타일로 설명해줘", "이 절 영상으로 만들어줘",
  "3장 설명 비디오", "RL_03 강의자료 애니메이션으로", "manim으로 설명 영상", "벨만 방정식
  영상으로 보여줘", "explainer video for section 4.1".
---

# 3b1b 스타일 설명 영상

입력은 범위(챕터·절·강의자료·개념 하나)이고, 출력은 `<작업 디렉터리>/videos/<slug>/<slug>.mp4`(1080p60, 한국어 내레이션)입니다.

| 파일 | 역할 | 실행 python |
|---|---|---|
| `scripts/setup.sh` | 환경 점검·설치 (여러 번 돌려도 안전) | bash |
| `scripts/tts.py` | `narration.json` → 비트별 음성 + `audio/manifest.json` | `~/.cache/manim-explainer/qwen-venv/bin/python` |
| `scripts/explainer.py` | Manim 테마·색·`Ko()`·`NarratedScene` (scenes.py가 import) | — |
| `scripts/build.py` | 씬 렌더 → 이어 붙이기 → 점검용 콘택트 시트 | `~/.cache/manim-explainer/venv/bin/python` |
| `references/style.md` | 3b1b 연출 원칙, 주제별 시각 어휘, Manim 패턴 | 씬을 쓰기 전에 읽을 것 |

아래에서 `SK=~/.claude/skills/manim-explainer`, `TTSPY=~/.cache/manim-explainer/qwen-venv/bin/python`, `MPY=~/.cache/manim-explainer/venv/bin/python`로 줄여 씁니다.

## 0. 환경

`bash $SK/scripts/setup.sh`를 실행합니다.

**음성 정책 (사용자 결정, 2026-10-12)**
- 초안: 항상 로컬 Qwen3-TTS(`sohee`)를 씁니다. 크레딧이 들지 않습니다.
  - **강의 톤 지시문을 함께 씁니다** (사용자 선택, 2026-10-14): `~/.config/manim-explainer/config.json`의 `local_instruct`. 지시 없는 sohee는 "힘이 없다"는 평이었고, 같은 문장이 14.6초 걸렸습니다(지시문을 넣으면 9.6초). 다른 후보는 ryan 화자와 VoiceDesign 설계 목소리였습니다. VoiceDesign은 호출할 때마다 음색이 달라지므로, 쓰려면 샘플 하나를 Base 모델로 복제해야 합니다.
- 최종본: ElevenLabs 크레딧이 남아 있으면 **웹 앱에서 Chris(`PDoCXqBQFGsvfO0hNkEs`)로 생성**합니다. 크레딧이 없거나 웹 방식이 실패하면 **Qwen**으로 만듭니다. 한 영상 안에서 두 목소리를 섞지 않습니다.
- 웹을 쓰는 이유: 사용자는 당분간 무료 플랜을 씁니다. 무료 플랜은 라이브러리 목소리를 API로 부르면 402 `payment_required`가 납니다(웹에서 Select한 목소리도 같음, 2026-10-12 실측). 웹 앱에서는 무료 플랜도 라이브러리 목소리를 쓸 수 있습니다.
- 유료 플랜으로 바뀌면 `--provider elevenlabs`로 API에서 바로 합성할 수 있습니다. 이때 `config.json`의 `elevenlabs_voice_id`를 Chris로 바꿉니다. 사용자가 유료 전환을 알려 줄 때까지는 이 경로를 쓰지 않습니다.

**키:** History API에 필요합니다. 환경변수 `ELEVENLABS_API_KEY` → `~/.config/manim-explainer/elevenlabs_api_key` → `config.json`의 `elevenlabs_env_files` 순서로 찾습니다. 현재 키는 `~/Personal/Dev/cow_ident_video/.env.local`에 있습니다. 이 키에는 `user_read` 권한이 없어서 남은 크레딧은 **웹 앱 화면에서** 읽습니다. 키 값은 출력하지 말고, 키를 대화창에 붙여 넣으라고 하지도 마세요.

## 1. 범위와 원자료

- 작업 디렉터리에 `CLAUDE.md`가 있으면 거기 적힌 원자료 규칙을 그대로 따릅니다. 예를 들어 교재 페이지 오프셋, 강의자료와 강의계획서 중 무엇이 우선인지, 책에 없는 구간을 어떻게 다루는지, 설명 방식 규칙 같은 것입니다. 이 규칙은 영상 안의 내레이션과 화면에도 똑같이 적용됩니다.
- 텍스트는 `pdftotext -layout -f N -l M`으로 범위를 지정해 읽습니다. 그림·도표는 `pdftoppm -png -r 70 -f N -l N <pdf> <out>`으로 뽑아 Read로 봅니다. 원자료의 그림 구성을 참고해 Manim으로 **다시 그립니다**(PDF 이미지를 그대로 붙이지 않습니다).
- 원자료에 없는 내용을 보충하면 화면 구석에 `Ko("교재 밖", 22, color=C_DIM)` 라벨을 달고, 내레이션에서도 그렇다고 말합니다.
- 마지막 씬에 출처 카드를 넣습니다(예: `Sutton & Barto 3.5절 · 책 p.58 / PDF p.80`, `RL_03.pdf p.12–18`).
- 범위가 넓으면(챕터 전체 등) 중심 아이디어 하나로 좁히거나 절마다 한 편씩으로 나눕니다. 어느 쪽인지 사용자에게 한 줄로 알리고 진행합니다. 범위 자체가 모호할 때만 묻습니다.

## 2. 이야기 설계: 품질은 여기서 결정됩니다

`references/style.md`를 읽은 뒤 설계합니다.

1. **중심 질문 하나와 "아하" 순간 하나**를 먼저 한 줄씩 적습니다. 영상 전체가 이 둘을 향해 가야 합니다.
2. 흐름: 질문(hook) → 구체적 예시 → 그림으로 직관 → 수식으로 이름 붙이기(그림과 같은 색) → 변주·한계·오해 → 요약 + 다음 질문.
3. 길이는 기본 5–10분입니다. 한국어 내레이션은 1초에 약 8자(공백 포함), 1분에 약 450자입니다.
4. `videos/<slug>/narration.json`을 씁니다. `visual`은 tts.py가 무시하는 연출 메모입니다:

```json
{
  "title": "할인율 감마", "slug": "ch03-discount", "source": "S&B 3.3절 · 책 p.54 / PDF p.76",
  "scenes": [
    {"id": "S01Hook", "beats": [
      {"id": "b1", "text": "오늘 받는 보상 1과, 열 걸음 뒤에 받는 보상 1은 같은 가치일까요?",
       "visual": "좌우에 보상 1 두 개, 가운데 물음표"}
    ]}
  ]
}
```

**내레이션 문장 규칙** (TTS가 읽는 그대로 들립니다):
- 말하는 형태로 씁니다. LaTeX·기호·괄호를 쓰지 않고 "브이 파이 에스", "감마", "시그마 합"처럼 적습니다.
- 숫자는 읽는 대로 씁니다("0.9" 대신 "영 점 구"). 영어 알고리즘 이름은 한글 발음으로 씁니다("큐 러닝"). 화면에는 원문 표기를 그대로 둡니다.
- 한 비트는 1–2문장이고, 화면 변화 하나와 짝을 이룹니다. 비트가 길면 쪼갭니다.
- 씬 id는 파이썬 클래스 이름이 되므로 `S01Hook`처럼 씁니다.

## 3. 초안 음성 (Qwen, 크레딧 0)

```bash
cd videos/<slug> && $TTSPY $SK/scripts/tts.py narration.json --provider local
```

ElevenLabs 크레딧은 최종본에 한 번만 씁니다. 초안 단계에서 내레이션을 고치는 동안에는 항상 Qwen을 씁니다.

## 4. scenes.py

```python
import os, sys
sys.path.insert(0, os.path.expanduser("~/.claude/skills/manim-explainer/scripts"))
from explainer import *

class S01Hook(NarratedScene):
    def construct(self):
        with self.narrate("b1") as b:
            self.play(FadeIn(x), run_time=b.part(0.3))       # 비트 길이의 30%
            self.play(Write(y), run_time=b.remaining(0.6))   # 남은 시간의 60%
        # with를 나가면 음성 끝까지 기다린 뒤 0.35초 숨을 고름
```

- 애니메이션 시간은 **초로 박지 말고** `b.part()`·`b.remaining()`으로 씁니다. 그래야 로컬 음성과 ElevenLabs 음성의 길이가 달라도 싱크가 유지됩니다.
- 한글은 반드시 `Ko(text, size)`로 씁니다. 기본 `Text`는 한글 폰트가 아닙니다. `MathTex` 안에 한글을 넣지 마세요(LaTeX 한글이 설정되어 있지 않습니다). 한글과 수식을 섞을 때는 `VGroup(Ko(..), MathTex(..)).arrange(RIGHT)`로 붙입니다.
- 수식 색은 **조각 인덱스로** 칠합니다: `eq = MathTex("G_t", "=", "R_{t+1}", ...)` 다음에 `eq[2].set_color(C_REWARD)`. `set_color_by_tex`는 부분 문자열 매칭이 빠지는 일이 있어 쓰지 않습니다(실측: `R_`·`\gamma^2` 누락).
- 개념 색은 `explainer.py`의 `C_STATE / C_ACTION / C_REWARD / C_VALUE / C_POLICY`를 영상 끝까지 고정해서 씁니다.
- 화면은 14.2 × 8 단위입니다. 가장자리에서 0.5 이상 띄우고, 긴 수식은 `.scale_to_fit_width(12)`로 줄입니다.

## 5. 초안 렌더와 점검

```bash
$MPY $SK/scripts/build.py videos/<slug> -q l          # → draft.mp4, check/<Scene>.png
$MPY $SK/scripts/build.py videos/<slug> -q l --scenes S03Bellman   # 고친 씬만 다시 렌더
```

`check/*.png`를 **모두 Read로 확인**합니다. 각 이미지는 씬 하나의 프레임을 시간순으로 모은 격자입니다. 점검할 것:
- 화면 밖으로 잘린 요소, 겹친 텍스트·수식
- 2–3칸 넘게 아무 변화가 없는 화면(내레이션은 진행되는데 그림이 멈춤)
- 수식 조각의 색이 그림 속 같은 개념의 색과 맞는지
- 화면 글자가 너무 많은지(문장을 띄우지 말고 핵심어·수식만)

렌더 로그에 `[explainer] 경고: 재생 안 된 비트`가 나오면 그 비트의 `narrate()`가 빠진 것입니다.

## 6. 최종본

내레이션이 확정된 뒤에 실행합니다. 웹에서 문장을 한 글자라도 바꾸면 그 비트는 다시 생성해야 합니다.

### 6-1. 웹 앱에서 Chris로 생성 (크레딧이 있을 때)

웹 앱 조작 방법은 `~/Personal/Dev/cow_ident_video/CLAUDE.md` 「TTS 엔진·목소리 후보」 절에 검증된 기록이 있습니다. 아래는 그 요약입니다.

1. `claude-in-chrome` 스킬을 먼저 불러온 뒤, 새 탭에서 `https://elevenlabs.io/app/speech-synthesis/text-to-speech`를 엽니다(사용자가 로그인한 상태여야 합니다). 로그인이 안 되어 있거나 브라우저 확장이 연결되지 않으면 Qwen(6-2)으로 갑니다.
2. **사용자 작업 보존:** 편집기에 이미 있는 문장·목소리·모델을 기록해 두고, 끝나면 되돌립니다.
3. **크레딧 확인:** 생성해야 할 글자 수를 `$TTSPY $SK/scripts/tts.py narration.json --provider web --pending`으로 봅니다. 출력의 `chars`가 필요한 글자 수입니다. 웹 앱의 남은 크레딧(화면 표시 또는 `elevenlabs.io/app/subscription`)과 비교해, 모자라면 Qwen(6-2)으로 갑니다. Multilingual v2는 1자에 1크레딧입니다.
4. **목소리:** `[data-testid=tts-voice-selector]`를 누르고 창의 My voices 또는 Explore 탭에서 `aria-label="Select Chris…"` 버튼을 고릅니다. Explore에서는 먼저 'Reset all filters'를 누른 뒤 검색합니다. 선택이 실제로 적용됐는지 확인한 다음 생성합니다.
5. **모델:** `[data-testid=tts-model-selector]` → `button[role=radio]`에서 **Eleven Multilingual v2**를 고릅니다. 차분한 강의 톤이 기본입니다. v4는 음높이가 크게 올라 다른 사람처럼 들릴 수 있으므로, 사용자가 밝은 톤을 원할 때만 씁니다.
6. **설정 슬라이더는 건드리지 않습니다.** 웹은 목소리에 저장된 설정(Chris 0.5/0.75/0/1.0)을 쓰고, 슬라이더를 움직이면 키 입력마다 설정 저장 요청이 나갑니다.
7. **비트마다 반복:** `--pending` 목록의 문장을 **글자 그대로** 넣고 `[data-testid=tts-generate]`를 누른 뒤 생성이 끝날 때까지 기다립니다.
   - 넣는 방법: v2 편집기 `textarea[data-testid=tts-editor]`(v3·v4는 `.ProseMirror`)에 focus → `execCommand('selectAll')` → `execCommand('insertText', false, 문장)`
   - 몇 비트마다 `--pending`을 다시 돌려, 생성한 것이 History에 잡히는지 확인합니다.
8. **함정:**
   - 탭이 가려지면(`document.hidden`) 타이머가 멈춰 생성 버튼이 'Loading...'에 걸립니다. 새로 고치면 됩니다(선택한 목소리·모델·문장은 유지됨).
   - 스크린샷이 되지 않으므로 `read_page`나 JS로 상태를 읽습니다.
   - 크레딧 부족 메시지가 뜨면 즉시 멈추고 **영상 전체를** Qwen(6-2)으로 만듭니다. 이미 만든 Chris 음성은 쓰지 않습니다.
9. 모두 생성되면 음성을 받아 manifest를 만듭니다:
   `$TTSPY $SK/scripts/tts.py narration.json --provider web`
   - 같은 문장의 take가 여러 개면 가장 새 것을 씁니다.
   - 특정 take를 쓰려면 narration.json 비트에 `"take": "<history_item_id>"`를 넣습니다.
10. **받아쓰기 점검:** 숫자나 용어가 들어간 비트는 들리는 대로 맞게 읽혔는지 확인합니다. 이 점검은 크레딧이 들지 않습니다.
    - 명령: `uvx --python 3.12 --from mlx-whisper mlx_whisper <mp3> --model mlx-community/whisper-large-v3-mlx --language ko --output-format txt --output-dir <dir>`
    - 잘못 읽힌 비트는 웹에서 다시 생성하고 9번을 다시 실행합니다.
    - 잘라 낸 짧은 파일은 첫 자음을 잘못 듣는 일이 있으니, 앞에 0.5초 무음을 붙여 받아쓰면 정확합니다.
11. 편집기를 2번에서 기록한 상태로 되돌립니다.
12. 무료 플랜 결과물은 비상업 용도이고 출처 표기가 필요합니다. 출처 카드에 `음성: ElevenLabs (Chris)`를 넣습니다.

### 6-2. Qwen (크레딧이 없거나 웹이 실패했을 때)

초안 음성을 그대로 최종본에 씁니다. 캐시가 있으므로 다시 합성하지 않습니다.

```bash
cd videos/<slug> && $TTSPY $SK/scripts/tts.py narration.json --provider local
```

### 6-3. 렌더

```bash
$MPY $SK/scripts/build.py videos/<slug> -q h --no-sheets           # → <slug>.mp4
```

음성 길이가 초안과 달라져도 `b.part()`·`b.remaining()` 덕분에 싱크가 유지됩니다. 그래도 Chris로 바꿨다면 `-q l`로 한 번 렌더해 콘택트 시트를 다시 확인합니다. 실제로 쓴 엔진은 `audio/manifest.json`의 `provider`(`web` 또는 `local`)에 남습니다.

## 7. 보고

대화에서 짧게 전합니다: 영상 경로, 길이, 다룬 원자료 범위(책 p. / PDF p.), 사용한 목소리(Chris 또는 Qwen, Qwen이면 그 이유), 이번에 쓴 크레딧과 웹 화면에 보이는 남은 크레딧. 그리고 `open <경로>`로 열어 볼지 묻습니다. `media/`(중간 산출물)는 지워도 된다고 알립니다.
