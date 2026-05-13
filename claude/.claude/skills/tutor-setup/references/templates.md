# Templates Reference (Notion Enhanced Markdown)

## Vault Page Hierarchy

```
StudyVault (root page)
├── Dashboard (page)
│   ├── Concepts Tracker (inline database)
│   ├── Sections Index (inline database)
│   ├── Quick Reference (subpage)
│   └── Exam Traps (subpage)
├── 01-<Topic1> (section page)
│   ├── Concept Note A (subpage)
│   ├── Concept Note B (subpage)
│   └── <Topic1> Practice (subpage)
├── 02-<Topic2> (section page)
│   ├── Concept Note C (subpage)
│   └── <Topic2> Practice (subpage)
└── ...
```

All content lives as Notion pages and databases. Tags are stored as multi-select property values in the Sections Index database, never as inline hashtags.

---

## Dashboard Page Template

```notion
# <Subject> Study Map

<callout icon="📚" color="blue_bg">
	Exam/certification info (if applicable). Domain weights or topic importance.
</callout>

## Concepts Tracker

<database url="{{concepts_tracker_url}}" inline="true">Concepts Tracker</database>

## Sections Index

<database url="{{sections_index_url}}" inline="true">Sections Index</database>

---

## Topic Map

<table header-row="true" fit-page-width="true">
	<tr>
		<td>Section</td>
		<td>Source</td>
		<td>Notes</td>
		<td>Status</td>
	</tr>
	<tr>
		<td>Topic 1</td>
		<td>Part 1</td>
		<td><mention-page url="{{page_url}}">Note 1</mention-page>, <mention-page url="{{page_url}}">Note 2</mention-page></td>
		<td>[ ]</td>
	</tr>
</table>

## Practice Notes

<table header-row="true" fit-page-width="true">
	<tr>
		<td>문제셋</td>
		<td>문항 수</td>
		<td>링크</td>
	</tr>
	<tr>
		<td>Topic 1</td>
		<td>N문제</td>
		<td><mention-page url="{{page_url}}">Topic 1 Practice</mention-page></td>
	</tr>
</table>

## Study Tools

<table header-row="true" fit-page-width="true">
	<tr>
		<td>도구</td>
		<td>설명</td>
		<td>링크</td>
	</tr>
	<tr>
		<td>Exam Traps</td>
		<td>시험 함정/오답 포인트 모음</td>
		<td><mention-page url="{{page_url}}">Exam Traps</mention-page></td>
	</tr>
	<tr>
		<td>Quick Reference</td>
		<td>전체 치트시트</td>
		<td><mention-page url="{{page_url}}">Quick Reference</mention-page></td>
	</tr>
</table>

## Tag Index

<table header-row="true" fit-page-width="true">
	<tr>
		<td>Tag</td>
		<td>관련 주제</td>
		<td>규칙</td>
	</tr>
	<tr>
		<td><code>tag-name</code></td>
		<td>Brief description</td>
		<td>상위/도메인/세부/기법/유형</td>
	</tr>
</table>

Tags are stored as multi-select values in the Sections Index database. This table serves as a human-readable reference only.

**태그 규칙**: <1-line summary of hierarchy rule>

## Weak Areas

- [ ] Area needing review → <mention-page url="{{page_url}}">Relevant Note</mention-page> → <mention-page url="{{page_url}}">Exam Traps</mention-page>

## Non-core Topic Policy

<table header-row="true" fit-page-width="true">
	<tr>
		<td>Source</td>
		<td>Content</td>
		<td>Handling</td>
	</tr>
	<tr>
		<td>&lt;file&gt;</td>
		<td>&lt;description&gt;</td>
		<td>**Excluded** — reason</td>
	</tr>
</table>
```

---

## Quick Reference Subpage Template

- Created as a **subpage of Dashboard**
- **Every section heading MUST include a page mention** to the corresponding concept note
- One-line summary table per concept/term using `<table>` syntax
- Grouped by category
- All key formulas and condition expressions
- "Must-know formulas/patterns" section at bottom with page mentions to related notes

```notion
# Quick Reference

## <Category 1> → <mention-page url="{{page_url}}">Concept Note</mention-page>

<table header-row="true" fit-page-width="true">
	<tr>
		<td>Term/Concept</td>
		<td>Key Point</td>
	</tr>
	<tr>
		<td>Term A</td>
		<td>One-line summary</td>
	</tr>
</table>

## <Category 2> → <mention-page url="{{page_url}}">Concept Note</mention-page>

<table header-row="true" fit-page-width="true">
	<tr>
		<td>Term/Concept</td>
		<td>Key Point</td>
	</tr>
	<tr>
		<td>Term B</td>
		<td>One-line summary</td>
	</tr>
</table>

---

## Must-Know Formulas/Patterns

<table header-row="true" fit-page-width="true">
	<tr>
		<td>Formula/Pattern</td>
		<td>Description</td>
		<td>Related Note</td>
	</tr>
	<tr>
		<td><code>formula</code></td>
		<td>What it computes</td>
		<td><mention-page url="{{page_url}}">Concept Note</mention-page></td>
	</tr>
</table>
```

---

## Exam Traps Subpage Template

- Created as a **subpage of Dashboard**
- Traps use **red toggle blocks** (not callouts) so content is hidden by default

```notion
# Exam Traps (시험 함정 포인트)

<callout icon="⚠️" color="orange_bg">
	이 노트의 목적: 시험에서 자주 틀리거나 헷갈리는 포인트만 모은 **오답/함정 노트**입니다.
</callout>

## <Topic 1>

<details color="red_bg">
<summary>Trap: <Short description></summary>
	- What the trap is
	- Why it's confusing
	- The correct answer/approach
	- Related: <mention-page url="{{page_url}}">Related Concept Note</mention-page>
</details>

<details color="red_bg">
<summary>Trap: <Another trap></summary>
	- What the trap is
	- Why it's confusing
	- The correct answer/approach
	- Related: <mention-page url="{{page_url}}">Related Concept Note</mention-page>
</details>

---

## <Topic 2>

<details color="red_bg">
<summary>Trap: <Short description></summary>
	- What the trap is
	- Why it's confusing
	- The correct answer/approach
	- Related: <mention-page url="{{page_url}}">Related Concept Note</mention-page>
</details>

---

## Related

- <mention-page url="{{page_url}}">Dashboard</mention-page> → Weak Areas 섹션
- <mention-page url="{{page_url}}">Quick Reference</mention-page>
```

---

## Concept Note Template

- Created as a **subpage under its topic section page** (e.g., `01-<Topic1>`)
- **No YAML frontmatter** — metadata stored in a callout block at the top
- Cross-references use page mentions (filled in during Phase D8 interlinking pass)

```notion
<callout icon="📋" color="gray_bg">
	Source: <filename.pdf — MUST match verified Phase D1 mapping> | Part: <part number> | Keywords: keyword-1, keyword-2, keyword-3
</callout>

# <Title> (<Importance: ★~★★★>)

## Overview Table (한눈에 비교)

<table header-row="true" fit-page-width="true">
	<tr>
		<td>Item</td>
		<td>Key Point</td>
	</tr>
	<tr>
		<td>A</td>
		<td>...</td>
	</tr>
</table>

## <Concept 1>

Concise explanation (3-5 lines max).
- Bullet points for key facts
- Use **bold** for critical terms

---

## Exam/Test Patterns (시험 빈출 패턴)

<table header-row="true" fit-page-width="true">
	<tr>
		<td>Scenario/Keyword</td>
		<td>Answer</td>
	</tr>
	<tr>
		<td>"keyword X"</td>
		<td>**Solution Y**</td>
	</tr>
</table>

## Related Notes

- <mention-page url="{{page_url}}">Other Note 1</mention-page>
- <mention-page url="{{page_url}}">Other Note 2</mention-page>
```

### Formatting Rules

- **Cross-references**: `<mention-page url="{{page_url}}">Page Name</mention-page>` for all internal links
- **Callouts** (non-collapsible):
  - Tip → `<callout icon="💡" color="green_bg">`
  - Important → `<callout icon="❗" color="red_bg">`
  - Warning → `<callout icon="⚠️" color="orange_bg">`
- **Tables**: Always use `<table header-row="true">` with `<tr>` and `<td>` elements — never markdown pipe tables
- Comparison tables over prose; **bold** for key vocabulary
- **Tags**: Stored as multi-select values in the Sections Index database. Never place inline hashtags in page content.

### Visualization Rule

Include ASCII diagrams (inside code blocks) when applicable:
- Processes/stages → timeline or sequence diagram
- Signal/data flow → flow DAG
- Strategy comparisons → quantitative table
- State-based behavior → state transition diagram

### Simplification-with-Exceptions Rule

General statements must check for edge cases — add a warning callout or page mention to exception details:
```notion
<callout icon="⚠️" color="orange_bg">
	Exception: <edge case description>. See <mention-page url="{{page_url}}">Exception Details</mention-page>.
</callout>
```

---

## Practice Question Template

- Created as a **subpage under its topic section page** (e.g., `01-<Topic1>`)
- **No YAML frontmatter** — metadata stored in a callout block at the top
- All answers hidden in toggle blocks; patterns in colored toggle blocks

```notion
<callout icon="📋" color="gray_bg">
	Source: <filename.pdf — MUST match verified Phase D1 mapping> | Part: <part number> | Keywords: practice, topic-keyword-1, topic-keyword-2
</callout>

# <Topic> Practice (N questions)

## Related Concepts

- <mention-page url="{{page_url}}">Concept Note 1</mention-page>
- <mention-page url="{{page_url}}">Concept Note 2</mention-page>

<details color="blue_bg">
<summary>핵심 패턴 (클릭하여 보기)</summary>
	<table header-row="true">
		<tr>
			<td>Keyword</td>
			<td>Answer</td>
		</tr>
		<tr>
			<td>pattern 1</td>
			<td>**Solution**</td>
		</tr>
	</table>
</details>

---

## Question 1 - <Short Label> [recall]

> Scenario summary in one line

<details>
<summary>정답 보기</summary>
	Answer text here with explanation.
</details>

---

## Question 2 - <Short Label> [application]

> Given this scenario, what would you do?

<details>
<summary>정답 보기</summary>
	Answer with applied reasoning.
</details>

---

## Question 3 - <Short Label> [analysis]

> Compare X and Y in this context. Which is better and why?

<details>
<summary>정답 보기</summary>
	Comparative analysis answer.
</details>

---

<details color="gray_bg">
<summary>패턴 요약 (클릭하여 보기)</summary>
	<table header-row="true">
		<tr>
			<td>Keyword</td>
			<td>Answer</td>
		</tr>
		<tr>
			<td>...</td>
			<td>...</td>
		</tr>
	</table>
</details>
```

### Practice Question Rules

- Every topic section MUST have a practice subpage (8+ questions)
- **Answer hiding**: ALL answers use `<details><summary>정답 보기</summary>` toggle blocks with tab-indented children
- **Patterns**: `<details color="blue_bg"><summary>핵심 패턴</summary>` (hint) and `<details color="gray_bg"><summary>패턴 요약</summary>` (summary) toggle blocks are MANDATORY
- **Question type diversity**: tag `[recall]`, `[application]`, `[analysis]` in heading
  - ≥60% recall, ≥20% application, ≥2 analysis per file
- Scenario in one `>` blockquote line; answer 1-3 lines in toggle block
- `## Related Concepts` with page mentions is MANDATORY: `<mention-page url="{{page_url}}">Concept Name</mention-page>`
