---
name: tutor
description: >
  Interactive quiz tutor for Notion StudyVault learning. Use when the user wants to:
  (1) Take a diagnostic assessment of their knowledge,
  (2) Study or review specific sections/topics,
  (3) Drill weak areas identified in previous sessions,
  (4) Check their learning progress or dashboard,
  or says things like "quiz me", "test me", "let's study", "/tutor", "학습", "퀴즈", "평가".
allowed-tools: Read, Grep, Bash, WebFetch, mcp__plugin_Notion_notion__notion-create-database, mcp__plugin_Notion_notion__notion-create-pages, mcp__plugin_Notion_notion__notion-create-view, mcp__plugin_Notion_notion__notion-fetch, mcp__plugin_Notion_notion__notion-search, mcp__plugin_Notion_notion__notion-update-page, mcp__plugin_Notion_notion__notion-update-data-source
---

# Tutor Skill

Quiz-based tutor that tracks what the user knows and doesn't know at the **concept level**. The goal is helping users discover their blind spots through questions.

## Notion Data Model

StudyVault lives entirely in Notion. Data is organized as follows:

```
StudyVault (root page in Notion)
├── 📊 Dashboard (page)
│   ├── [inline] Concepts Tracker DB    ← Per-concept progress rows
│   ├── [inline] Sections Index DB      ← Section metadata
│   └── Summary content (proficiency table, stats)
├── 01-SectionName (page)
│   ├── concept-note-1 (child page)
│   ├── concept-note-2 (child page)
│   └── ...
├── 02-SectionName (page)
│   └── ...
└── ...
```

### Concepts Tracker DB

| Property     | Type        | Notes                                                  |
|--------------|-------------|--------------------------------------------------------|
| Concept      | Title       | Concept name                                           |
| Area         | Select      | Section/area name (dynamic options)                    |
| Attempts     | Number      | Total times tested                                     |
| Correct      | Number      | Times answered correctly                               |
| Last Tested  | Date        | Date of last quiz                                      |
| Status       | Select      | `🔴 Unresolved` (red) or `🟢 Resolved` (green)        |
| Error Note   | Rich Text   | Confusion + key point for wrong answers                |

### Sections Index DB

| Property  | Type         | Notes                              |
|-----------|--------------|------------------------------------|
| Section   | Title        | Section name                       |
| Order     | Number       | Sort order                         |
| Source    | Rich Text    | Source material reference           |
| Tags      | Multi-Select | Dynamic tags                       |
| Notes     | Number       | Concept note count                 |
| Practice  | Checkbox     | Has practice page                  |

- **Dashboard page**: Contains summary proficiency table + stats as page content, plus the two inline databases for detailed tracking. Stays compact — no session logs, no per-question details.
- **Concepts Tracker rows**: One row per concept tested. Grows proportionally to unique concepts (bounded).
- **Section pages**: Contain concept notes as child pages. Read these for quiz content.

## Workflow

### Phase 0: Detect Language

Detect user's language from their message → `{LANG}`. All output and page content in `{LANG}`.

### Phase 1: Discover Vault

1. Use `notion-search` to find a page titled "StudyVault"
2. If not found → inform user that no StudyVault exists in Notion and **stop**
3. Use `notion-fetch` on the StudyVault page to list its child pages (section pages)
4. Find the "Dashboard" child page among children
   - If found → `notion-fetch` on Dashboard page to read current proficiency summary
   - Then locate the Concepts Tracker DB (inline on Dashboard) and `notion-search` with `data_source_url` to query existing progress rows
5. If Dashboard not found → create it from template (see Dashboard Creation Instructions below)

### Phase 2: Ask Session Type

**MANDATORY**: Use AskUserQuestion to let the user choose what to do. Analyze dashboard data to build context-aware options, then present them.

Query the Concepts Tracker DB to build per-area proficiency:
1. Use `notion-search` with the Concepts Tracker DB URL as `data_source_url` filter to get all concept rows
2. Group concepts by **Area** property
3. For each area, calculate: total attempts (sum), total correct (sum), rate = correct/attempts
4. Assign proficiency badges from rate: 🟥 0-39% · 🟨 40-69% · 🟩 70-89% · 🟦 90-100% · ⬜ no data (0 attempts)

Build options based on current state:

1. If unmeasured areas (⬜) exist → include "Diagnostic" option targeting those areas
2. If weak areas (🟥/🟨) exist → include "Drill weak areas" option naming the weakest area(s)
3. Always include "Choose a section" option so the user can pick any area
4. If all areas are 🟩/🟦 → include "Hard-mode review" option

Present these as an AskUserQuestion with header "Session" and concise descriptions showing which areas each option targets. The user MUST select before proceeding.

### Phase 3: Build Questions

1. Use `notion-fetch` on the target section page(s) to get child note pages, then `notion-fetch` on each child page to read concept note content
2. If drilling weak area: query the Concepts Tracker DB filtered by Area = target area AND Status = "🔴 Unresolved" to find unresolved concepts — rephrase these in new contexts (don't repeat the same question)
3. Craft exactly 4 questions following `references/quiz-rules.md`

**CRITICAL**: Read `references/quiz-rules.md` before crafting ANY question. Zero hints allowed.

### Phase 4: Present Quiz

Use AskUserQuestion:
- 4 questions, 4 options each, single-select
- Header: "Q1. Topic" (max 12 chars)
- Descriptions: neutral, no hints

### Phase 5: Grade & Explain

1. Show results table (question / correct answer / user answer / result)
2. Wrong answers: concise explanation
3. Map each question to its area

### Phase 6: Update Notion

#### 1. Update Concepts Tracker DB

For each question answered:

- **New concept** (no existing row for this concept+area):
  Use `notion-create-pages` to add a row to the Concepts Tracker DB:
  ```
  parent: { data_source_id: "<concepts-tracker-db-id>" }
  properties:
    Concept (title): concept name
    Area (select): area name
    Attempts (number): 1
    Correct (number): 1 if correct, 0 if wrong
    Last Tested (date): today's date (YYYY-MM-DD)
    Status (select): "🟢 Resolved" if correct, "🔴 Unresolved" if wrong
    Error Note (rich_text): if wrong → "Confusion: {what user mixed up}\nKey point: {correct understanding}"
  ```

- **Existing 🔴 concept answered correctly**:
  Use `notion-update-page` on the existing row:
  ```
  properties:
    Attempts: previous + 1
    Correct: previous + 1
    Last Tested: today's date
    Status: "🟢 Resolved"
    (keep existing Error Note — learning history)
  ```

- **Existing 🟢 concept answered correctly** (no status change):
  Use `notion-update-page` on the existing row:
  ```
  properties:
    Attempts: previous + 1
    Correct: previous + 1
    Last Tested: today's date
  ```

- **Existing 🟢 concept answered wrong**:
  Use `notion-update-page` on the existing row:
  ```
  properties:
    Attempts: previous + 1
    Last Tested: today's date
    Status: "🔴 Unresolved"
    Error Note: updated with new confusion + key point
  ```

- **Existing 🔴 concept answered wrong again** (no status change):
  Use `notion-update-page` on the existing row:
  ```
  properties:
    Attempts: previous + 1
    Last Tested: today's date
    Error Note: updated with new confusion + key point
  ```

#### 2. Update Dashboard page

1. Query the Concepts Tracker DB to get all rows
2. Group by Area, calculate for each: total attempts, total correct, rate (correct/attempts), badge
3. Build the proficiency table and stats
4. Use `notion-update-page` on the Dashboard page to replace the proficiency section and stats section with updated content

Dashboard page content structure:

```
# Learning Dashboard

> Concept-based metacognition tracking.

---

## Proficiency by Area

<table header-row="true">
  <tr><td>Area</td><td>Correct</td><td>Wrong</td><td>Rate</td><td>Level</td></tr>
  (one row per area with calculated stats)
  <tr><td><b>Total</b></td><td><b>N</b></td><td><b>N</b></td><td><b>N%</b></td><td>badge</td></tr>
</table>

> 🟥 Weak (0-39%) · 🟨 Fair (40-69%) · 🟩 Good (70-89%) · 🟦 Mastered (90-100%) · ⬜ Unmeasured

---

## Stats

- **Total Questions**: N
- **Cumulative Rate**: N%
- **Unresolved Concepts**: N
- **Resolved Concepts**: N
- **Weakest Area**: area name
- **Strongest Area**: area name
```

The inline Concepts Tracker and Sections Index databases remain embedded on the page for detailed drill-down, but the summary table above is the readable overview.

## Dashboard Creation Instructions

When no Dashboard page exists, create it as follows:

1. **Create Dashboard page** as a child of the StudyVault page:
   - Title: "Learning Dashboard" (localized to `{LANG}`, e.g., "학습 대시보드")
   - Use `notion-create-pages` with parent = StudyVault page ID

2. **Create Concepts Tracker database** inline on the Dashboard page:
   - Use `notion-create-database` with parent = Dashboard page ID
   - Title: "Concepts Tracker"
   - Schema:
     ```
     Concept:     TITLE
     Area:        SELECT
     Attempts:    NUMBER
     Correct:     NUMBER
     Last Tested: DATE
     Status:      SELECT('🔴 Unresolved':red, '🟢 Resolved':green)
     Error Note:  RICH_TEXT
     ```

3. **Create Sections Index database** inline on the Dashboard page:
   - Use `notion-create-database` with parent = Dashboard page ID
   - Title: "Sections Index"
   - Schema:
     ```
     Section:  TITLE
     Order:    NUMBER
     Source:   RICH_TEXT
     Tags:     MULTI_SELECT
     Notes:    NUMBER
     Practice: CHECKBOX
     ```

4. **Add initial page content** to Dashboard via `notion-update-page`:
   - Title, description blockquote
   - Empty proficiency table (all areas ⬜, zeros)
   - Badge legend
   - Stats section (all zeros/dashes)

5. **Create "Unresolved" view** on Concepts Tracker DB:
   - Use `notion-create-view` with filter: Status = "🔴 Unresolved"

6. **Create "By Area" board view** on Concepts Tracker DB:
   - Use `notion-create-view` with group_by: Area

## Concepts Tracker Row Operations

### Creating a new concept row

Use `notion-create-pages` with:
- `parent`: `{ "data_source_id": "<concepts-tracker-db-id>" }`
- `properties`: Concept (title), Area (select), Attempts (number), Correct (number), Last Tested (date), Status (select), Error Note (rich_text)

### Updating an existing concept row

Use `notion-update-page` with the row's page ID:
- `properties`: only the fields that changed (Attempts, Correct, Last Tested, Status, Error Note)

### Error Note format

Rich text content:
```
**{concept name}**
- Confusion: {what the user mixed up}
- Key point: {the correct understanding}
```

For rows with multiple historical errors, append new entries (preserve learning history).

## Important Reminders

- ALWAYS read `references/quiz-rules.md` before creating questions
- NEVER include hints in option labels or descriptions
- NEVER use "(Recommended)" on any option
- Randomize correct answer position
- After grading, ALWAYS update concept rows in Concepts Tracker DB, then update Dashboard page proficiency table and stats
- Communicate in user's language
