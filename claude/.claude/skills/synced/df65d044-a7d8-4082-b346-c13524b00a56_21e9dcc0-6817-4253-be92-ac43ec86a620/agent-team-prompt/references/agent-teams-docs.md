# Claude Code Agent Teams 공식 문서 (번들 레퍼런스)

> 이 파일은 https://code.claude.com/docs/ko/agent-teams 의 내용을 기반으로 작성됨.
> WebFetch로 최신 문서를 받는 데 실패했을 때 fallback으로 사용.

---

## 개요

에이전트 팀은 함께 작동하는 여러 Claude Code 인스턴스를 조율하는 기능.
- 한 세션이 **팀 리더** 역할
- **팀원(teammate)**들은 독립적으로 작동하며, 각각 자신의 컨텍스트 윈도우에서 작동
- 팀원들은 서로 직접 통신 가능 (subagent와의 핵심 차이)

## Subagent vs Agent Team

| | Subagents | Agent Teams |
|---|---|---|
| 컨텍스트 | 자신의 컨텍스트; 결과는 호출자에게 반환 | 자신의 컨텍스트; 완전히 독립적 |
| 통신 | 메인 에이전트에게만 보고 | 팀원들이 서로 직접 메시지 전송 |
| 조율 | 메인 에이전트가 모든 작업 관리 | 공유 작업 목록으로 자체 조율 |
| 최적 용도 | 결과만 중요한 집중된 작업 | 논의와 협업이 필요한 복잡한 작업 |
| 토큰 비용 | 낮음 | 높음 (각 팀원이 별도 인스턴스) |

## 활성화

```json
// settings.json
{
  "env": {
    "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS": "1"
  }
}
```

## 표시 모드

- **in-process**: 메인 터미널 내에서 실행. Shift+Down으로 팀원 순환.
- **tmux/iTerm2 분할 창**: 각 팀원이 자신의 창. `"teammateMode": "tmux"` 설정.
  - tmux 또는 it2 CLI 필요
  - `"auto"` (기본값): tmux 세션 내면 분할 창, 아니면 in-process

## 팀 시작 방법

자연어로 Claude에게 에이전트 팀을 만들도록 요청:

```
Create an agent team to explore this from different angles: one
teammate on UX, one on technical architecture, one playing devil's advocate.
```

핵심 키워드: "에이전트 팀을 만들어", "spawn teammates", "팀원을 생성"

## 팀원 및 모델 지정

```
Create a team with 4 teammates to refactor these modules in parallel.
Use Sonnet for each teammate.
```

## 계획 승인 요구

```
Spawn an architect teammate to refactor the authentication module.
Require plan approval before they make any changes.
```

## 팀원과 직접 대화

- In-process: Shift+Down으로 순환 → 입력으로 메시지
- 분할 창: 팀원 창 클릭

## 작업 할당

- 리더 할당: 리더에게 어느 작업을 어느 팀원에게 줄지 지시
- 자체 요청: 팀원이 다음 미할당 작업을 자체 선택

## 아키텍처

| 구성 요소 | 역할 |
|---|---|
| 팀 리더 | 팀을 만들고, 팀원들을 생성하며, 작업을 조율하는 메인 세션 |
| 팀원들 | 할당된 작업에서 각각 작동하는 별도 인스턴스 |
| 작업 목록 | 팀원들이 요청하고 완료하는 공유 작업 항목 |
| 메일박스 | 에이전트 간 통신을 위한 메시징 시스템 |

## 통신

- 자동 메시지 전달: 팀원 → 수신자 자동 전달
- 유휴 알림: 팀원 완료 시 리더에게 자동 알림
- 공유 작업 목록: 모든 에이전트가 작업 상태 확인 가능
- message: 특정 팀원 1명에게
- broadcast: 모든 팀원에게 (비용 증가, 드물게 사용)

## 사용 사례

1. **병렬 코드 검토**: 보안/성능/테스트 커버리지 각각 다른 팀원
2. **경쟁하는 가설로 디버깅**: 각 팀원이 다른 이론 조사, 서로 반박
3. **연구 및 검토**: 문제의 다양한 측면을 동시 조사
4. **교차 계층 조율**: 프론트엔드/백엔드/테스트 각각 다른 팀원

## 모범 사례

- 팀원에게 충분한 컨텍스트 제공 (생성 프롬프트에 작업별 세부 사항 포함)
- 3-5명의 팀원으로 시작
- 팀원당 5-6개의 작업 유지
- 파일 충돌 피하기 (각 팀원이 다른 파일 소유)
- 팀원들이 완료될 때까지 기다리기
- 모니터링 및 조율

## 제한 사항

- In-process 팀원과의 세션 재개 없음
- 작업 상태 지연 가능
- 종료가 느릴 수 있음
- 세션당 한 팀만
- 중첩된 팀 없음
- 리더 고정
- 분할 창은 tmux 또는 iTerm2 필요

## 정리

```
Clean up the team
```

항상 리더를 통해 정리. 팀원이 정리하면 안 됨.
