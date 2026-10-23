# 3b1b 연출 원칙과 Manim 패턴

## 연출 원칙

1. **정의보다 질문을 먼저.** 첫 15초 안에 시청자가 답을 궁금해할 질문을 던집니다. "MDP는 다섯 개 요소로 이루어진다"로 시작하지 말고, "로봇이 지금 오른쪽으로 가야 할지 어떻게 알까요?"로 시작합니다.
2. **구체 → 일반.** 작은 숫자 예시 하나(상태 3개짜리 격자, 감마 0.9)를 끝까지 들고 갑니다. 영상 중간에 예시를 바꾸지 않습니다. 일반식은 예시를 충분히 본 뒤에 꺼냅니다.
3. **보여 주고 나서 이름 붙이기.** 그림으로 현상을 먼저 보여 주고, 그다음 수식을 쓰면서 수식의 각 조각을 방금 본 그림 요소와 **같은 색**으로 칠합니다. 보상이 노란 막대였다면 수식의 R도 노란색입니다.
4. **바꿔치지 말고 변형하기.** 화면을 지우고 새로 그리지 말고 `TransformMatchingTex`, `ReplacementTransform`, `.animate`로 이전 대상이 다음 대상으로 **변하는 것**을 보여 줍니다. 식을 정리하는 과정도 한 줄씩 변형합니다.
5. **초점은 한 번에 하나.** 지금 말하는 대상만 밝게 두고 나머지는 `set_opacity(0.25)`로 어둡게 합니다. `Indicate`, `Circumscribe`, `SurroundingRectangle`로 시선을 끕니다.
6. **화면 글자는 최소로.** 문장은 내레이션이 맡고, 화면에는 핵심어·수식·숫자만 둡니다. 화면 텍스트가 두 줄을 넘으면 다시 생각합니다.
7. **숨 쉴 틈.** 핵심 결과를 보여 준 직후에는 한 박자 쉽니다(`self.wait(0.8)` 또는 비트 `gap` 늘리기).
8. **움직이는 매개변수.** "감마가 커지면?", "학습률을 줄이면?" 같은 질문은 `ValueTracker` + `always_redraw`로 값을 연속으로 바꾸면서 보여 줍니다. 3b1b 영상이 기억에 남는 이유의 절반이 여기에 있습니다.
9. **오해를 정면으로.** 흔한 오해 하나를 골라 "이렇게 생각하기 쉽지만…" 하고 그림으로 반박합니다.
10. **끝에서 묶기.** 요약은 새 내용 없이 앞에서 쓴 그림을 축소해 한 화면에 모읍니다. 마지막에 다음 질문 하나를 던집니다.

## 시각 어휘 (강화학습·머신러닝)

| 개념 | 그림 |
|---|---|
| 상태·전이 (MDP) | 원(상태, `C_STATE`) + 곡선 화살표(`CurvedArrow`), 화살표 라벨에 확률·보상 |
| 격자 세계 | `Square` 격자. 칸 안에 값 숫자(`DecimalNumber`), 값 크기에 따라 칸 색을 보간(`interpolate_color`) |
| 정책 | 칸마다 화살표(`Arrow`, `C_POLICY`). 정책이 개선되면 화살표가 회전 |
| 백업 다이어그램 | Sutton & Barto 관례: 상태 = 속이 빈 원, 행동 = 검은 점. 트리를 위에서 아래로 그리고, 백업은 아래에서 위로 올라가는 애니메이션 |
| 이득·할인 | 보상 막대가 시간축을 따라 `γ^k`만큼 줄어드는 막대 그래프 |
| 반복 해법 (정책 평가, 가치 반복) | 격자 값이 스윕마다 갱신되는 장면을 몇 번 보여 주고, 나머지는 빨리 감기 + 오차 그래프(`Axes`) |
| 기댓값 | 가지마다 확률만큼 굵기·투명도를 준 뒤, 가중합이 한 점으로 모이는 애니메이션 |
| 탐험과 활용 | 슬롯머신 막대 + 추정치 막대 + 신뢰 구간 띠 |
| 함수 근사 | `Axes` 위 점들 + 곡선이 맞춰지는 애니메이션 |
| 경사 하강 | 등고선(`ParametricFunction`) 위를 내려가는 점 |

## Manim 패턴

```python
# 수식 단계 변형: 같은 조각 문자열이 서로 매칭된다
e1 = MathTex("G_t", "=", "R_{t+1}", "+", r"\gamma", "G_{t+1}")
e2 = MathTex("v_\\pi(s)", "=", r"\mathbb{E}_\pi[", "R_{t+1}", "+", r"\gamma", "G_{t+1}", "]")
self.play(TransformMatchingTex(e1, e2), run_time=b.part(0.5))

# 조각 색 (set_color_by_tex 대신 인덱스로)
for i in (2,): eq[i].set_color(C_REWARD)
eq[4].set_color(C_VALUE)

# 연속 매개변수
g = ValueTracker(0.5)
bars = always_redraw(lambda: make_bars(g.get_value()))
label = always_redraw(lambda: MathTex(rf"\gamma = {g.get_value():.2f}").to_corner(UR))
self.add(bars, label)
self.play(g.animate.set_value(0.99), run_time=b.remaining(0.8))

# 초점 이동
others = VGroup(*[m for m in grid if m is not target])
self.play(others.animate.set_opacity(0.25), Circumscribe(target), run_time=b.part(0.3))

# 격자 + 값
cells = VGroup(*[Square(1.0) for _ in range(16)]).arrange_in_grid(4, 4, buff=0)
vals = VGroup(*[DecimalNumber(0, num_decimal_places=1, font_size=28).move_to(c) for c in cells])

# 한글 + 수식 한 줄
line = VGroup(Ko("상태 가치", 34), MathTex(r"v_\pi(s)", color=C_VALUE)).arrange(RIGHT, buff=0.25)

# 교재 밖 라벨
self.add(Ko("교재 밖", 22, color=C_DIM).to_corner(DR))
```

## 씬 단위

- 씬 하나는 30초–2분, 생각 단위 하나입니다. 씬 사이를 넘어갈 때 화면 상태가 이어져야 하면, 다음 씬 첫 줄에서 같은 대상을 `self.add()`로 다시 놓고 시작합니다(씬은 따로 렌더되기 때문입니다).
- 씬 끝은 `FadeOut(*self.mobjects)`으로 정리하거나, 다음 씬 시작 화면과 같은 상태로 둡니다.
- 렌더 시간: `-q l`은 씬당 수 초에서 수십 초, `-q h`는 그 5–10배입니다. 초안은 항상 `-q l`로 렌더합니다.
