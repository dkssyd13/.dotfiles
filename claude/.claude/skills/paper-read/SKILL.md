---
name: paper-read
description: "논문 PDF에 대해 한국어 번역, 섹션별 풀이 설명, 카테고리별 하이라이트를 생성하고 책처럼 좌우 분할된 단일 HTML 뷰어로 통합하는 에이전트 팀을 생성한다. /paper-read 또는 '논문 분석해줘', '논문 읽어줘', '이 논문 정리해줘', 'pointworld 논문 분석' 등 특정 논문을 깊게 읽어보고 싶다는 요청에 사용. papers/{폴더명}/ 안에 viewer.html을 생성."
---

# 중요: 에이전트 팀을 만들어서 아래 작업을 수행해. tmux 분할 창으로 팀원들을 spawn해.

절대로 Task tool이나 subagent로 실행하지 마라. 반드시 **에이전트 팀(agent team)** 으로 만들어야 한다. 각 팀원은 tmux 분할 창(tmux pane)에서 독립적으로 실행되어야 한다. 모든 팀원은 **Opus** 모델을 사용한다.

## 목표

`/Users/vladkim/Documents/Obsidian Vault/papers/{paper_folder}/` 안의 PDF를 읽어 다음 산출물을 만든다:

1. **한국어 번역** (전문 용어/개념은 영어 그대로 유지)
2. **섹션별 풀이 설명** (개념을 비유로 풀어 설명)
3. **카테고리별 하이라이트 2종**
   - 5-카테고리: Novelty(노랑) / Method(파랑) / Results(초록) / Limitations(빨강) / Key Concepts(보라)
   - 3-카테고리: Novelty / Method / Results (더 엄선)
4. **완전 self-contained 단일 HTML 뷰어**: 좌측에 번역+설명(토글), 우측에 PDF.js로 렌더링된 PDF + 하이라이트 오버레이. 좌우 스왑 가능. 하이라이트 모드 토글(5cat/3cat/off). **PDF.js 라이브러리 코드와 PDF 본문이 모두 HTML 안에 inline embed되어** file:// 더블클릭만으로 작동(인터넷 불필요, 외부 의존성 0). 좌우 패널 스크롤 독립. 좌측 텍스트 크기 조절(A-/A+) 가능. PDF 줌 조절(-/+) 가능, 기본 fit-to-width.

## 사전 준비 (리더가 직접 수행)

### 1. 대상 논문 폴더 식별

- 사용자가 `/paper-read [폴더명]`처럼 인자를 줬으면 해당 폴더 사용.
- 자연어 표현이면 `papers/` 하위 폴더에서 키워드 매칭.
- 매칭이 모호하거나 없으면 **반드시 `AskUserQuestion`으로 사용자에게 어떤 논문인지 물어봐라**. 추측하지 마라.
- 폴더 내 PDF가 여러 개면 어느 PDF를 분석할지 사용자에게 질문.

### 2. PDF 텍스트 + 좌표 추출

PyMuPDF(fitz)로 PDF를 파싱한다. 가상환경 없이도 실행 가능하면 `python3 -m pip install --user pymupdf`를 먼저 시도(이미 설치되어 있으면 스킵).

추출 스크립트를 임시로 작성 후 실행하여 결과를 `{paper_folder}/agents/extracted_text.json`에 저장. 스키마:

```json
{
  "pdf_path": "absolute path",
  "num_pages": 12,
  "pages": [
    {
      "page_num": 1,
      "width": 612.0,
      "height": 792.0,
      "blocks": [
        {
          "block_id": "p1_b0",
          "bbox": [x0, y0, x1, y1],
          "text": "...",
          "font_size": 12.0,
          "font_flags": 16
        }
      ]
    }
  ]
}
```

좌표는 PDF 좌표계(좌상단 원점, points). HTML 측에서 PDF.js viewport scale로 변환한다.

### 3. 섹션 구조 자동 감지

`extracted_text.json`에서 본문 폰트보다 큰/굵은 블록을 섹션 헤더로 추출. "Abstract", "Introduction", "Related Work", "Method"/"Approach", "Experiments"/"Results", "Conclusion", "References" 등 일반 패턴과 폰트 휴리스틱을 함께 사용. 결과를 `{paper_folder}/agents/sections.json`에 저장:

```json
{
  "sections": [
    {
      "id": "abstract",
      "title": "Abstract",
      "page_start": 1,
      "page_end": 1,
      "block_ids": ["p1_b3", "p1_b4"],
      "full_text": "..."
    }
  ]
}
```

References 이후의 부록(supplementary)은 별도 처리 — 일단 동일 sections에 포함하되 `is_appendix: true` 플래그를 둔다.

### 4. PDF base64 인코딩

PDF 본문을 builder가 HTML에 inline할 수 있도록 base64 문자열로 변환해 둔다.

```bash
python3 -c "import base64,sys; sys.stdout.write(base64.b64encode(open('{pdf_path}','rb').read()).decode())" > {paper_folder}/agents/pdf_base64.txt
```

base64는 원본보다 약 1.33배 커진다(12MB PDF → 16MB 텍스트). builder가 그대로 HTML에 박는다.

### 5. PDF.js 라이브러리 캐시 다운로드

PDF.js를 인터넷 없이도 쓸 수 있도록 사용자 캐시 디렉토리에 한 번만 다운로드한다.

```bash
PDFJS_VERSION=4.0.379
CACHE_DIR=~/.cache/paper-read/pdfjs-$PDFJS_VERSION
mkdir -p $CACHE_DIR
[ -f $CACHE_DIR/pdf.min.mjs ] || curl -sSL "https://cdnjs.cloudflare.com/ajax/libs/pdf.js/$PDFJS_VERSION/pdf.min.mjs" -o $CACHE_DIR/pdf.min.mjs
[ -f $CACHE_DIR/pdf.worker.min.mjs ] || curl -sSL "https://cdnjs.cloudflare.com/ajax/libs/pdf.js/$PDFJS_VERSION/pdf.worker.min.mjs" -o $CACHE_DIR/pdf.worker.min.mjs
```

이미 캐시되어 있으면 스킵. builder가 이 두 파일을 읽어 HTML에 inline한다.

**왜 이렇게 하는가**: 사용자가 viewer.html을 더블클릭으로 열면 `file://` 프로토콜이 되고, 브라우저 보안 정책 때문에 옆에 있는 PDF나 외부 CDN을 fetch할 수 없다. 따라서 PDF.js 코드와 PDF 본문 모두 HTML 안에 박아 외부 요청을 0으로 만든다. 한 번 만든 viewer.html은 인터넷 없이도 어디서든 열린다.

### 6. agents/ 디렉토리 생성

`{paper_folder}/agents/` 디렉토리를 만들고 위 모든 산출물(`extracted_text.json`, `sections.json`, `pdf_base64.txt`)을 저장.

## 팀 구성 (5명의 팀원을 spawn)

모든 팀원은 작업 시작 전에 `{paper_folder}/agents/extracted_text.json`과 `{paper_folder}/agents/sections.json`을 읽는다. 작업이 끝나면 리더에게 결과 파일 경로와 한 줄 요약을 보고한다.

### 팀원 1: translator (번역 담당)

각 섹션을 한국어로 번역한다.

**번역 원칙**:
- **전문 용어/고유 개념은 영어 그대로 유지**: Transformer, attention, self-attention, embedding, gradient, loss, point cloud, voxel, NeRF, Gaussian splatting, MLP, CNN, IoU, SOTA, ablation 등. "변압기", "주의 기제" 같은 어색한 직역 금지.
- 일반 동사, 접속사, 설명문은 자연스러운 한국어로 번역.
- 수식/숫자/표 캡션 그대로 유지.
- **문단 단위 1:1 매핑**: 원문 문단 1개당 번역 문단 1개. 합치거나 쪼개지 마라.

작업:
1. `agents/sections.json`을 읽어 섹션별 본문을 가져온다.
2. 각 섹션의 본문을 문단으로 쪼개고, 각 문단을 한국어로 번역.
3. 결과를 `{paper_folder}/agents/translation.json`에 저장:

```json
{
  "sections": [
    {
      "id": "intro",
      "title": "Introduction",
      "paragraphs": [
        { "orig": "Recent advances in ...", "ko": "최근 ...의 발전은 ..." }
      ]
    }
  ]
}
```

4. 완료 후 리더에게 보고: "번역 완료, N개 섹션, M개 문단".

### 팀원 2: explainer (섹션 설명 담당)

각 섹션을 풀어 설명한다.

**설명 원칙**:
- 섹션당 3~5문단의 한국어 설명.
- 무엇을 했는지 → 왜 했는지 → 어떻게 작동하는지 순서.
- 어려운 개념은 비유로 풀어준다 ("attention은 마치 ~처럼 동작한다").
- 이전 섹션의 맥락을 짧게 연결 ("앞에서 X를 설명했는데, 여기서는 ...").
- 번역과 중복되지 않게, **추가적인 해설/직관**에 집중.

작업:
1. `agents/sections.json`을 읽는다.
2. 각 섹션에 대해 설명을 작성.
3. 결과를 `{paper_folder}/agents/explanation.json`에 저장:

```json
{
  "sections": [
    { "id": "intro", "title": "Introduction", "explanation": "이 섹션에서는 ..." }
  ]
}
```

4. 완료 후 리더에게 보고.

### 팀원 3: highlighter-5cat (5-카테고리 하이라이트)

논문 전체에서 5개 관점으로 중요 문장을 식별하고, PDF 좌표를 함께 저장한다.

**카테고리**:
- `novelty` (노랑 #FFEB3B): 논문의 핵심 기여, 이전 연구 대비 새로운 점.
- `method` (파랑 #2196F3): 제안하는 방법의 아키텍처, 알고리즘, 핵심 수식.
- `results` (초록 #4CAF50): 정량적 결과, SOTA 비교, ablation의 주요 발견.
- `limitations` (빨강 #F44336): 논문이 인정하는 한계, 실패 케이스, 향후 과제.
- `key_concepts` (보라 #9C27B0): 핵심 정의, 기호 표기, 자주 등장하는 용어의 정의문.

**원칙**:
- 카테고리당 **5~15개** 정도(논문 길이에 따라 조정). 너무 많으면 무의미해진다.
- 한 문장 단위가 기본이지만, 짧은 구문이나 수식만 하이라이트해도 됨.
- block_id를 사용해 `extracted_text.json`의 정확한 좌표를 그대로 가져온다. 텍스트 일부만 하이라이트하려면 해당 block의 bbox를 그대로 사용(추후 fine-grained는 v2).

작업:
1. `agents/extracted_text.json`과 `agents/sections.json`을 읽는다.
2. 각 페이지를 훑으며 카테고리에 해당하는 블록을 선별.
3. 결과를 `{paper_folder}/agents/highlights_5cat.json`에 저장:

```json
{
  "category_order": ["novelty", "method", "results", "limitations", "key_concepts"],
  "highlights": [
    {
      "id": "h1",
      "page": 1,
      "bbox": [x0, y0, x1, y1],
      "page_width": 612.0,
      "page_height": 792.0,
      "category": "novelty",
      "section_id": "intro",
      "snippet": "원문 문장 일부"
    }
  ]
}
```

4. 완료 후 리더에게 보고.

### 팀원 4: highlighter-3cat (3-카테고리 하이라이트)

5cat과 동일하지만 더 엄선된 3개 카테고리.

**카테고리**:
- `novelty` (노랑), `method` (파랑), `results` (초록).

**원칙**: 카테고리당 **3~8개** 정도. "이 한 문장만 봐도 논문의 요지가 드러난다" 수준으로 엄선.

작업:
1. 위와 동일한 입력 읽기.
2. 결과를 `{paper_folder}/agents/highlights_3cat.json`에 5cat과 같은 스키마로 저장(`category_order`는 3개).
3. 완료 후 리더에게 보고.

### 팀원 5: builder (HTML 뷰어 생성)

다른 팀원들이 모두 완료된 후 `{paper_folder}/viewer.html`을 생성한다. 다른 팀원들의 작업 완료 보고가 들어올 때까지 대기.

**입력**:
- `{paper_folder}/agents/translation.json`
- `{paper_folder}/agents/explanation.json`
- `{paper_folder}/agents/highlights_5cat.json`
- `{paper_folder}/agents/highlights_3cat.json`
- `{paper_folder}/agents/sections.json`
- `{paper_folder}/agents/pdf_base64.txt` — PDF 본문 base64 (리더가 사전 작업에서 생성)
- `~/.cache/paper-read/pdfjs-{version}/pdf.min.mjs` — PDF.js 메인 코드 (리더가 캐시)
- `~/.cache/paper-read/pdfjs-{version}/pdf.worker.min.mjs` — PDF.js worker 코드

**핵심 작업**: 위 모든 데이터를 단일 HTML 파일에 inline하여 외부 의존성 0의 self-contained viewer.html을 만든다. 결과 HTML 크기가 ~16-20MB가 되는 건 정상.

**HTML 사양**:

1. **상단 컨트롤 바** (sticky, 약 64-80px, 좁으면 2줄 wrap 허용):
   - 좌측: 논문 제목(섹션 1의 title 또는 파일명)
   - 가운데: 하이라이트 모드 토글 (3개 라디오: `5-category` / `3-category` / `off`)
   - 카테고리별 체크박스 (각 색상 배지와 함께, 기본 모두 on)
   - **텍스트 크기 컨트롤 (좌측 패널 전용)**: `A-` / 현재 크기(px) / `A+` 버튼. 기본 18px. 단계: 14·16·18·20·22·24·28px(7단계). 키보드 단축키 `Cmd/Ctrl + -` 축소, `Cmd/Ctrl + =` 확대. 현재 설정은 `localStorage`에 저장하여 다음 열람 시 복원.
   - **PDF 줌 컨트롤 (우측 패널 전용)**: `−` / 현재 줌(%) / `+` 버튼. 단계 50·75·100·125·150·175·200·250·300%. fit-to-width 토글 버튼(기본 켜짐) — 켜져 있으면 우측 패널 폭에 자동 맞춤. 줌 버튼을 누르면 fit 모드가 꺼지고 명시적 스케일로 전환.
   - 우측: 좌우 스왑 버튼 (`⇄ 좌우 교체`)

2. **본문**: 좌우 50:50 분할 (CSS Grid 또는 Flex), 사이에 5px resizable splitter (드래그로 너비 조절).

3. **좌측 패널 (기본: 번역+설명)**:
   - 세로 스크롤 영역. **우측 PDF 패널과 완전히 독립적인 overflow 스크롤 컨테이너** — 한쪽을 스크롤해도 다른 쪽은 그대로. 이전 v2까지 있던 IntersectionObserver 자동 동기화는 제거.
   - 각 섹션마다 카드:
     - 섹션 제목 (h2, 본문보다 큰 크기 — 컨트롤의 본문 크기 × 1.35 정도)
     - 원문 문단 / 번역 문단 페어 (원문은 작은 회색 글씨로 본문보다 한 단계 작게, 번역은 본문 크기의 진한 글씨로) — 문단별로 묶음
     - `▶ 설명 보기` 토글 버튼 — 클릭 시 explainer의 설명이 펼쳐짐 (slide down)
   - 본문 폰트 크기는 상단 컨트롤의 텍스트 크기 설정값을 따른다. 크기를 바꾸면 좌측 패널의 모든 텍스트가 비례적으로 커지거나 작아진다.
   - 명시적 점프만 허용: 우측 PDF의 하이라이트 박스를 클릭하면 단발성으로 해당 section_id 카드로 스크롤(동기화 아닌 one-shot 이동).

4. **우측 패널 (기본: PDF + 하이라이트, 완전 self-contained)**:

   **PDF.js 라이브러리 inline** (CDN 사용 안 함):
   - `~/.cache/paper-read/pdfjs-{version}/pdf.min.mjs`의 전체 내용을 builder가 읽어 `<script type="module" id="pdfjs-lib">...</script>` 블록에 그대로 박는다. 단, ES module로 inline하려면 import 경로 처리가 까다로우므로 다음과 같이 **window 전역에 노출하는 패턴**을 사용:
     ```html
     <script type="module">
       const blob = new Blob([PDFJS_LIB_CODE], { type: 'application/javascript' });
       const url = URL.createObjectURL(blob);
       const pdfjsLib = await import(url);
       window.pdfjsLib = pdfjsLib;
       // pdf.worker.min.mjs도 Blob URL로 만들어 workerSrc 지정
       const workerBlob = new Blob([PDFJS_WORKER_CODE], { type: 'application/javascript' });
       pdfjsLib.GlobalWorkerOptions.workerSrc = URL.createObjectURL(workerBlob);
     </script>
     ```
     `PDFJS_LIB_CODE`와 `PDFJS_WORKER_CODE`는 builder가 캐시 파일 내용을 JS 템플릿 리터럴(또는 base64 디코드 패턴)로 박은 상수.
   - `Blob URL + dynamic import + module worker`는 브라우저와 `file://` 조합에 따라 실패하거나 응답 없이 멈출 수 있다. 따라서 PDF.js 초기화, worker 준비, PDF 파싱, 첫 페이지 렌더링을 각각 단계별 status로 표시하고 모든 단계에 timeout을 둔다. `PDF 로딩 중...` 상태가 10초 이상 지속되면 실패로 간주하고 반드시 fallback 영역에 구체적인 오류 메시지를 보여준다.
   - `loadPdfJs()`와 `loadPdfBytes()`는 반드시 timeout wrapper로 감싼다. 예시:
     ```js
     function withTimeout(promise, ms, label) {
       let timer;
       const timeout = new Promise((_, reject) => {
         timer = setTimeout(() => reject(new Error(label + " timeout after " + ms + "ms")), ms);
       });
       return Promise.race([promise, timeout]).finally(() => clearTimeout(timer));
     }

     async function boot() {
       const watchdog = setTimeout(() => {
         showFallback("PDF 로딩이 10초 이상 지속되어 중단했습니다. PDF.js 초기화/worker/PDF 파싱 단계를 확인하세요.");
       }, 10000);
       try {
         setPdfStatus("PDF.js 초기화 중...");
         await withTimeout(loadPdfJs(), 10000, "PDF.js 초기화");
         setPdfStatus("PDF 파싱 중...");
         await withTimeout(loadPdfBytes(pdfBytes), 10000, "PDF 파싱/렌더링");
         verifyPdfRendered();
         clearTimeout(watchdog);
       } catch (e) {
         clearTimeout(watchdog);
         showFallback(e && e.message ? e.message : String(e));
       }
     }
     ```
   - worker는 한 방식에만 의존하지 않는다. `new Worker(workerUrl, { type: "module" })`를 직접 만들어 `GlobalWorkerOptions.workerPort`에 즉시 고정하면 worker 생성은 성공했지만 handshake가 멈추는 경우를 놓칠 수 있다. 우선 `GlobalWorkerOptions.workerSrc = workerUrl`로 지정해 PDF.js가 worker handshake를 관리하게 하고, 명시적 Worker/`workerPort`를 쓰는 경우에도 `getDocument(...).promise`나 첫 페이지 렌더링이 timeout되면 `workerPort`를 해제하고 `workerSrc` 또는 fake-worker fallback으로 다시 시도한다.

   **PDF 본문 inline** (옆 PDF 파일 fetch 안 함):
   - `agents/pdf_base64.txt`의 내용을 JS 상수로 박는다:
     ```js
     const PDF_BASE64 = "JVBERi0xLjQK...";  // builder가 inline
     const bytes = Uint8Array.from(atob(PDF_BASE64), c => c.charCodeAt(0));
     const pdf = await pdfjsLib.getDocument({ data: bytes }).promise;
     ```

   **렌더링 + fit-to-width + 줌**:
   - 우측 패널 자체가 세로 스크롤 컨테이너(`overflow-y: auto`). 페이지들이 세로로 쌓이고 각 페이지는 `<div class="page-container">` 안의 `<canvas>`. 페이지 간 간격 8px.
   - fit-to-width 모드(기본 켜짐): 우측 패널 `clientWidth`를 측정해 `baseScale = panelClientWidth / pdfPage.getViewport({scale:1}).width`. 모든 페이지에 동일 스케일 적용(논문 PDF는 보통 모든 페이지가 같은 폭).
   - `window.resize`와 splitter drag 종료 시 fit 모드라면 스케일 재계산 → 모든 페이지 재렌더링.
   - 줌 버튼 누르면 fit 모드 해제 + 명시적 스케일(`zoomLevel ∈ {0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0, 2.5, 3.0}`)로 전환. fit 토글 다시 켜면 원래대로.
   - 줌 변경 시 모든 페이지 canvas를 새 viewport로 다시 그림. 하이라이트 박스도 새 스케일로 좌표 재계산.
   - 첫 렌더 완료 후 반드시 canvas 기반 검증 함수를 실행한다. 성공 조건은 `#pdf-status`가 숨겨지고, `.page-container canvas`가 1개 이상 있으며, 첫 canvas의 `width > 0 && height > 0`인 상태다. 조건을 만족하지 않으면 `showFallback("PDF canvas 렌더 검증 실패: ...")`로 전환한다.
     ```js
     function verifyPdfRendered() {
       const canvases = document.querySelectorAll(".page-container canvas");
       const first = canvases[0];
       const statusHidden = getComputedStyle(document.getElementById("pdf-status")).display === "none";
       if (!statusHidden || !first || first.width <= 0 || first.height <= 0) {
         throw new Error(
           "PDF canvas 렌더 검증 실패: pageContainers=" +
           document.querySelectorAll(".page-container").length +
           ", canvases=" + canvases.length +
           ", firstCanvas=" + (first ? first.width + "x" + first.height : "missing") +
           ", pdfStatusHidden=" + statusHidden
         );
       }
     }
     ```

   **하이라이트 오버레이**:
   - canvas와 같은 컨테이너에 `<div class="highlight-layer" style="position: absolute; inset: 0; pointer-events: none;">`. 그 안의 하이라이트 박스는 `pointer-events: auto`.
   - 좌표 변환: 현재 viewport scale 사용
     ```js
     const vp = pdfPage.getViewport({ scale: currentScale });
     const x = bbox[0] * currentScale;
     const y = bbox[1] * currentScale;
     const w = (bbox[2] - bbox[0]) * currentScale;
     const h = (bbox[3] - bbox[1]) * currentScale;
     ```
   - 박스 스타일: `background: rgba(R,G,B,0.30); border-radius: 2px; cursor: pointer; transition: background 0.15s;` 호버 시 alpha 0.45.
   - 색상 매핑:
     - novelty → `255, 235, 59` (노랑)
     - method → `33, 150, 243` (파랑)
     - results → `76, 175, 80` (초록)
     - limitations → `244, 67, 54` (빨강)
     - key_concepts → `156, 39, 176` (보라)
   - 하이라이트 박스 클릭 → 좌측 패널의 해당 section_id 카드로 단발성 스크롤(자동 동기화 아님).

   **fallback (안전망)**: PDF 디코딩, PDF.js 초기화, worker 생성/handshake, PDF 파싱, 첫 페이지 렌더링, canvas 검증 중 하나라도 실패하거나 10초 timeout에 걸리면 "PDF 업로드" 버튼과 함께 실패 단계/오류 메시지를 표시한다. 절대 `PDF 로딩 중...` 상태로 무한 대기하지 않는다.

5. **좌우 스왑**:
   - 컨테이너에 `class="swapped"` 토글. CSS Grid의 `grid-template-columns`가 그대로지만 두 패널 순서가 바뀌도록 `grid-column` 또는 `order` 속성을 변경.

6. **하이라이트 모드 전환**:
   - off: highlight-layer를 모두 `display: none`.
   - 5cat: highlights_5cat.json에서 박스 그림.
   - 3cat: highlights_3cat.json에서 박스 그림.
   - 카테고리 체크박스로 카테고리별 토글.

7. **데이터 임베드**:
   - `<script type="application/json" id="data-translation">...</script>` 형태로 모든 JSON을 HTML에 직접 임베드 (별도 fetch 불필요).
   - 이렇게 하면 단일 HTML 파일 + PDF 파일만 있으면 다른 파일 없이도 동작.

8. **스타일**:
   - 깔끔한 sans-serif 폰트 (`-apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif`).
   - 좌측 패널 배경: `#fafafa`, 카드 배경: `white`, 그림자 약하게.
   - 다크 모드는 이번 범위에서 제외.

9. **모든 코드와 데이터는 inline (외부 의존성 0)**:
   - PDF.js 라이브러리 코드 inline
   - PDF.js worker 코드 inline (Blob URL 패턴으로 워커 띄움)
   - PDF 본문 base64 inline
   - 모든 JSON(번역/설명/하이라이트) inline (`<script type="application/json">` 또는 JS 상수)
   - CSS도 `<style>` 인라인
   - 외부 fetch/CDN 호출 0. file:// 더블클릭만으로 작동, 인터넷 불필요.

10. **결과 파일 크기 + 렌더 검증**: 12MB PDF 기준 약 16-20MB HTML이 생성된다. 사용자는 이를 수용하기로 했다. 단, 파일 크기만으로 성공 판정하지 마라. `viewer.html`은 파일 크기 확인 후 실제 PDF canvas 렌더링까지 검증해야 한다. `PDF 로딩 중...` 상태가 10초 이상 지속되면 실패로 간주하고 builder는 HTML을 수정해야 한다.

**완료**: viewer.html을 저장하고 리더에게 보고.

## 리더 역할

모든 팀원이 완료되면:
1. 각 팀원의 보고 종합.
2. `{paper_folder}/viewer.html` 파일이 정상 생성되었는지 확인.
3. 최종 보고 전 다음 렌더 검증 조건을 확인:
   - 검증은 `file://{paper_folder}/viewer.html`을 실제 브라우저에서 열어 수행한다. 단순 HTML 정적 검사나 파일 크기 확인은 렌더 검증으로 인정하지 않는다.
   - `pageContainers >= 1`
   - `firstCanvas.width > 0`
   - `firstCanvas.height > 0`
   - `pdfStatusHidden === true`
   - 하이라이트 모드를 켜고 꺼도 PDF canvas가 유지됨
4. 사용자에게 다음 내용을 보고:
   - 생성된 파일 절대 경로
   - 발견된 섹션 수, 문단 수, 5cat/3cat 하이라이트 개수
   - PDF 렌더 검증 결과(`pageContainers`, `firstCanvas`, `pdfStatusHidden`)
   - 브라우저로 여는 방법 안내: `open "{paper_folder}/viewer.html"`

## 추가 지시

- 팀원이 다른 팀원의 결과가 필요하면 직접 메시지로 요청한다 (예: builder는 모든 팀원의 완료 후 시작).
- 팀원이 작업 중 막히면 즉시 리더에게 보고.
- 팀원이 PyMuPDF나 다른 의존성이 필요해서 설치한다면, `python3 -m pip install --user`만 사용. sudo 금지.
- 한 PDF에 figure나 표가 많아 텍스트 블록이 매우 많은 경우, highlighter는 figure/table 캡션 블록은 카테고리 후보에 포함하되 본문 외 잡음 블록(페이지 번호, 헤더, footer)은 제외한다.
- 부록(References, Appendix)은 번역/설명 대상에서 제외해도 된다. 단 highlights에는 포함 가능.
- 모든 작업은 `/Users/vladkim/Documents/Obsidian Vault/papers/{paper_folder}/` 안에서 한다. 다른 위치에 임시 파일을 만들지 마라.
- builder는 결과 HTML을 생성한 후 **반드시 file 크기와 실제 PDF canvas 렌더 상태를 함께 확인**하고 리더에게 보고: 너무 작으면(< 1MB) PDF base64 inline이 빠졌을 가능성이 높고, 크기가 정상이어도 `.page-container canvas`가 없거나 첫 canvas 크기가 0이면 PDF.js 초기화/worker/렌더링 실패다.
- 리더는 사용자에게 산출물 보고 시 다음을 강조: "viewer.html을 Finder에서 더블클릭하면 됩니다 (PDF가 자동으로 로드됨, 인터넷 불필요)".
