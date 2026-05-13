---
name: paper-scout
description: "HuggingFace, Arxiv, Top-Tier Conference에서 주목할 만한 최신 논문을 찾아 PDF로 다운로드하는 에이전트 팀을 생성한다. /paper-scout 또는 '논문 스카우트', '이번 주 논문', '최신 논문 찾아줘' 등의 요청에 사용."
---

# 중요: 에이전트 팀을 만들어서 아래 작업을 수행해. tmux 분할 창으로 팀원들을 spawn해.

절대로 Task tool이나 subagent로 실행하지 마라. 반드시 에이전트 팀(agent team)으로 만들어야 한다. 각 팀원은 tmux 분할 창(tmux pane)에서 독립적으로 실행되어야 한다.

## 목표

HuggingFace Papers trending, Arxiv 신규 논문, 최근 3년 Top-Tier Conference에서 주목할 만한 논문(best papers, oral/spotlight, 화제 논문)을 찾고, arxiv에서 PDF를 다운로드하여 `raw/papers/` 디렉토리에 저장한다.

## 사전 준비

- `mkdir -p raw/papers/` 디렉토리가 없으면 생성
- 각 팀원은 파일명 충돌을 방지하기 위해 `{source}_{arxiv_id}.pdf` 형식으로 저장 (예: `trend_2401.12345.pdf`, `cvpr_2401.12345.pdf`)
- 이미 `raw/papers/`에 존재하는 arxiv ID는 스킵

## 팀 구성 (4명의 팀원을 spawn)

### trend-scout (HuggingFace Papers 트렌드 논문 수집)

HuggingFace Papers에서 현재 화제인 논문을 수집한다.

작업:
1. `https://huggingface.co/papers` 페이지에서 trending 논문 목록을 가져온다
2. upvote 수, 댓글 수 등을 기준으로 주목도가 높은 논문을 선별한다
3. 각 논문의 arxiv ID를 추출하고, `https://arxiv.org/pdf/{arxiv_id}`에서 PDF 다운로드
4. `raw/papers/trend_{arxiv_id}.pdf`로 저장
5. 완료되면 찾은 논문 목록(제목, arxiv ID, upvote 수, 한 줄 요약)을 리더에게 보고

### arxiv-scout (Arxiv 주간 신규 논문 탐색)

이번 주 arxiv 신규 논문 중 주목할 만한 것을 찾는다.

작업:
1. arxiv.org의 최근 논문을 다음 카테고리에서 탐색:
   - **cs.CV** (Computer Vision and Pattern Recognition)
   - **cs.LG** (Machine Learning)
   - **cs.CL** (Computation and Language)
   - **cs.AI** (Artificial Intelligence)
2. 다음 키워드 중심으로 검색:
   - 3D reconstruction
   - visual foundation models
   - efficient vision transformers
   - LLM architecture
   - multimodal models
3. 인용 수, 저자 명성, 제목/초록 기반으로 주목도 판단
4. 선별한 논문의 PDF를 `https://arxiv.org/pdf/{arxiv_id}`에서 다운로드
5. `raw/papers/arxiv_{arxiv_id}.pdf`로 저장
6. 완료되면 찾은 논문 목록(제목, arxiv ID, 카테고리, 키워드, 한 줄 요약)을 리더에게 보고

### cv-conf-scout (CV 컨퍼런스 Best/Notable 논문 수집)

최근 3년간 주요 CV 컨퍼런스의 best paper 및 주목할 논문을 수집한다.

담당 컨퍼런스:
- **CVPR** (IEEE/CVF Conference on Computer Vision and Pattern Recognition) — 매년
- **ICCV** (International Conference on Computer Vision) — 홀수년 (2023, 2025)
- **ECCV** (European Conference on Computer Vision) — 짝수년 (2024, 2026)

작업:
1. 각 컨퍼런스의 최근 3년 개최분에서 best paper, best paper honorable mention, oral, spotlight 논문 목록 수집
2. 각 논문의 arxiv 버전을 찾아서 PDF 다운로드 (`https://arxiv.org/pdf/{arxiv_id}`)
3. `raw/papers/cvpr_{arxiv_id}.pdf`, `raw/papers/iccv_{arxiv_id}.pdf`, `raw/papers/eccv_{arxiv_id}.pdf`로 저장
4. arxiv에 없는 논문은 스킵하고 목록에 "(no arxiv)" 표시
5. 완료되면 컨퍼런스별 논문 목록(제목, arxiv ID, 수상/선정 카테고리)을 리더에게 보고

참고: 격년 컨퍼런스는 해당 연도만 확인. ICCV 2024는 없음, ECCV 2023/2025는 없음.

### ml-conf-scout (ML 컨퍼런스 Best/Notable 논문 수집)

최근 3년간 주요 ML 컨퍼런스의 best paper 및 주목할 논문을 수집한다.

담당 컨퍼런스:
- **NeurIPS** (Conference on Neural Information Processing Systems) — 매년
- **ICML** (International Conference on Machine Learning) — 매년
- **ICLR** (International Conference on Learning Representations) — 매년

작업:
1. 각 컨퍼런스의 최근 3년 개최분에서 best paper, outstanding paper, oral, spotlight 논문 목록 수집
2. 특히 vision, multimodal, foundation model, LLM architecture 관련 논문에 우선순위
3. 각 논문의 arxiv 버전을 찾아서 PDF 다운로드 (`https://arxiv.org/pdf/{arxiv_id}`)
4. `raw/papers/neurips_{arxiv_id}.pdf`, `raw/papers/icml_{arxiv_id}.pdf`, `raw/papers/iclr_{arxiv_id}.pdf`로 저장
5. arxiv에 없는 논문은 스킵하고 목록에 "(no arxiv)" 표시
6. 완료되면 컨퍼런스별 논문 목록(제목, arxiv ID, 수상/선정 카테고리)을 리더에게 보고

## 리더 역할

모든 팀원이 완료되면:
1. 각 팀원의 보고를 종합
2. `raw/papers/` 디렉토리의 중복 PDF 제거 (같은 arxiv ID가 다른 source prefix로 존재할 수 있음 → 하나만 남기고 삭제)
3. 최종 논문 리스트를 `raw/papers/INDEX.md`에 저장:
   - 소스별로 그룹핑 (HuggingFace Trending / Arxiv / CVPR / ICCV / ECCV / NeurIPS / ICML / ICLR)
   - 각 논문: 제목, arxiv ID, PDF 파일명, 한 줄 설명
   - 총 수집 논문 수 표시

## 추가 지시

- 팀원들이 서로의 발견에 대해 의견이 있으면 직접 메시지를 보내라 (예: 같은 논문을 다른 소스에서도 발견한 경우)
- PDF 다운로드 실패 시 3회 재시도 후 스킵하고 보고에 "(download failed)" 표시
- 네트워크 도메인 제한으로 접근이 안 되는 사이트가 있으면 즉시 리더에게 보고
