---
name: course-practice-problems
description: >
  Generates study/practice problem sets for graduate-school courses based on lecture materials
  (PDFs, slides, notes) living in the current working directory. Saves problems and solutions
  as markdown files under a `practice/` folder inside the course directory, so problem sets
  accumulate over the semester. Uses a team of Opus teammate agents (one per chapter, plus a
  reviewer) to ensure coverage and correctness. Use this skill whenever the user asks to
  create practice problems, exercises, exam-prep questions, or problem sets scoped to a
  chapter, week, or topic of course material — including phrases like "연습문제 만들어줘",
  "예시문제", "3주차 문제 내줘", "SQL 문제 만들어줘", "시험 대비 문제", "이 과목에 대해서
  문제를 만들어줘", "practice problems", "exercises for chapter X", "make me problems for
  the midterm". Prefer this skill over ad-hoc generation whenever the user wants problems
  tied to specific course material — it keeps an index, separates problems from solutions
  for self-study, covers all concepts in a chapter, and validates correctness via a dedicated
  reviewer agent. (Distinct from the `tutor` skill, which runs live Notion-based quizzes;
  this skill writes reusable offline practice files.)
---

# Course Practice Problem Generator

Generates practice problem sets for graduate-school courses. Assumes the user is running
Claude Code from inside a course directory (e.g. `ADB/`, `ACN/`, `CVA/`) that contains
lecture materials (numbered PDFs, slides, notes) at the root.

Output: markdown files checked into a `practice/` folder inside the course directory, with
problems and solutions in **separate** files for self-study. Problem sets accumulate over
the semester.

## Architecture: Team of Opus agents

This skill does not generate problems itself. It orchestrates a **team of Opus teammates**
(via `TeamCreate` + `Agent` with `team_name`, never plain subagents):

- **`chapter-<N>`** — one teammate per target chapter. Reads that chapter's PDF end-to-end
  (including visuals on every page), drafts problems + solutions, writes to staging.
- **`combiner`** — spawned only when the user wants a multi-chapter integration set. Reads
  all target PDFs directly (independent of chapter-agent output) and writes cross-chapter
  synthesis problems to staging.
- **`reviewer`** — spawned after all drafters finish. Reads every staged file and every
  source PDF to validate coverage, correctness, difficulty, format mix, de-duplication, and
  language. Sends revision requests to drafters (max 2 rounds per drafter).

All teammates use the Opus model. The orchestrator (this skill's main flow) is the team
lead: spawns the team, assigns tasks, relays milestone updates to the user, and writes
final files. The team is **ephemeral** — created per invocation, torn down when done.

See `references/prompt-chapter-agent.md`, `references/prompt-combiner-agent.md`, and
`references/prompt-reviewer-agent.md` for the exact prompts to give each teammate.

## Workflow overview

Phase 1: **Setup** — first time in a course directory; confirm materials, scaffold.
Phase 2: **Generate** — clarify request, spawn team, delegate, review, assemble.

---

## Phase 1 — Setup (first-time in a course directory)

Skip this phase if `practice/index.md` already exists.

1. **List root-level course materials.** Look for PDFs, slide decks, and note files at the
   course root. Typical pattern: numbered files like `3_SQL.pdf`.
2. **Detect sample resources.** Look for sibling folders that may contain reusable context
   (sample databases, code repos, datasets). Examples: `db/`, `data/`, `code/`. If found,
   briefly explore and note any schema files or READMEs. These become shared context for
   problem generation.
3. **Propose a chapter map** to the user, including any detected sample resources. Wait
   for confirmation / corrections.
4. **Ask about language once.** Korean / English / mixed. Record the user's choice.
5. **Scaffold the directory**:
   ```
   practice/
   ├── index.md          # material map + sample resources + problem set catalog
   ├── log.md            # append-only generation log
   ├── presets.md        # difficulty presets (written on first use)
   ├── .staging/         # teammate drafts live here during generation
   ├── problems/
   └── solutions/
   ```
6. **Write `index.md`** with material map, sample resources, language preference, and an
   empty problem-set table.

Tell the user that the map is saved and won't be re-confirmed next time.

---

## Phase 2 — Generating a problem set

### Step 1 — Clarify the request

Ask (skip anything already specified):

1. **Scope**: single chapter, multiple chapters as a `combine` set, or a specific chapter
   range? Resolve against `index.md`.
2. **Difficulty preset**: pick from `presets.md` or define a new one (see "Difficulty
   presets" below). A new preset gets appended to `presets.md`.
3. **Hands-on format mix** (critical — never skip this question): explicitly ask which
   hands-on formats to include (SQL query writing, ER diagrams, normalization steps,
   relational-algebra expressions, calculations, proofs, code, etc.) and roughly how many.
   The available formats depend on the chapter — glance at the source PDF before asking so
   you can offer realistic options.
4. **Source fidelity**: stick to lecture examples, or blend in extensions? Default to
   70/30 blend if the user has no preference.
5. **Interactive mode** (only ask if chapter materials make it relevant — e.g. an SQL
   chapter with a sample DB, a programming chapter with runnable code): "Would you like
   interactive practice (you type a query/snippet, I run it and give feedback) in addition
   to the markdown file?" If yes, note it; the interactive session runs after the file is
   produced and its transcript is logged.

### Step 2 — Propose problem count, then confirm

Before spawning the team, read each target PDF yourself (lightly — just enough to count
distinct concept groups and gauge density). Propose a count per chapter. For a combine
set, propose a count of integration-focused problems separate from the per-chapter counts.

Show the user:
> Chapter 3 (SQL) covers ~6 concept groups: basic SELECT, joins, aggregation, subqueries,
> set ops, DDL. I'd suggest **10 problems** to touch each area with at least one hands-on
> SQL-writing problem per group. OK, or adjust?

Wait for confirmation before spawning anyone.

### Step 3 — Check for prior sets (avoid duplication)

Read `index.md` and any existing problem files for the same chapter + preset combination.
Extract the high-level problem list (topic/format per problem). Pass this list to the
chapter teammate as "already-covered material — generate non-duplicate problems". If no
prior set exists, skip this step.

### Step 4 — Spawn the team

1. `TeamCreate` with `team_name` like `<course>-practice-<date>-<slug>` (e.g.
   `adb-practice-2026-04-16-sql`).
2. For each target chapter, `TaskCreate` — one task per chapter + one for the combiner (if
   applicable) + one for the reviewer.
3. For each chapter, spawn `chapter-<N>` via the `Agent` tool with:
   - `team_name`: the team name
   - `name`: `chapter-<N>` (e.g. `chapter-3`)
   - `subagent_type`: `general-purpose`
   - `model`: `opus`
   - `prompt`: contents of `references/prompt-chapter-agent.md` with variables filled in
     (chapter number, topic, source PDF path, preset, problem count, hands-on mix,
     fidelity, language, sample-resources context, already-covered list, staging paths)
4. If combine set: spawn `combiner` similarly using
   `references/prompt-combiner-agent.md`.
5. Do **not** spawn the reviewer yet.
6. Assign tasks via `TaskUpdate(owner=…)`.

**Status to user**: "팀 스폰 — chapter-3 (Opus) 투입, PDF 읽기 시작."

### Step 5 — Drafters work

Chapter teammates read their PDF page-by-page (**always** use the `pages` parameter on
`Read`, and **always** read every page so visual content is captured — ER diagrams, query
plans, normalization tables, figures, etc. OCR may be missing or thin). They write drafts
to:

- `practice/.staging/<team_name>/ch<N>-problems.md`
- `practice/.staging/<team_name>/ch<N>-solutions.md`

Combiner writes to `combine-problems.md` and `combine-solutions.md` in the same staging
directory.

Drafters notify via `SendMessage` when done. Lead acknowledges; drafter goes idle.

**Status to user** as each drafter completes: "ch3 드래프트 완료 (10문제)."

### Step 6 — Reviewer loop

Once all drafters are done:

1. Spawn `reviewer` with `references/prompt-reviewer-agent.md`, passing: staging directory,
   source PDF paths, user's chosen preset/format mix/language, already-covered list.
2. Reviewer reads all staged files and source PDFs, produces a per-drafter findings
   report, and sends revision requests via `SendMessage` to any drafter with issues.
3. Drafter (still alive, idle) receives the message, revises the staged files, notifies
   reviewer.
4. Reviewer re-checks.

**Hard limit: 2 revision rounds per drafter.** If a drafter still fails after round 2,
reviewer reports the remaining issues to the lead. The lead surfaces them to the user
(concise summary) and asks how to proceed: accept as-is, manual fix, or skip.

**Status to user**: "리뷰 시작" / "이슈 N건 — ch3 수정 요청 중" / "ch3 1/2 재작성" /
"리뷰 통과".

### Step 7 — Assemble and save

Lead (orchestrator, not teammate) moves staged files to final locations:

- `practice/problems/<YYYY-MM-DD>-<slug>-<preset>.md`
- `practice/solutions/<YYYY-MM-DD>-<slug>-<preset>.md`

Slug rules:
- Single chapter: topic kebab-case (e.g. `sql`, `normalization`, `er-rdb`,
  `query-processing`, `relational-algebra`).
- Combine set: `combine-ch<A>-<B>` for a range (`combine-ch2-4`) or `combine-ch2+3+5` for
  non-contiguous.
- Collisions in same day: append `-v2`, `-v3`, etc.

Update `index.md` (problem-set table row) and append to `log.md`.

Delete `practice/.staging/<team_name>/`.

### Step 8 — Teardown

1. Send `shutdown_request` to each teammate.
2. After all shut down, `TeamDelete`.

### Step 9 — Interactive mode (optional)

If the user opted in during Step 1:
- For DB chapters with a sample DB: check whether `mysql` / `sqlite3` is on PATH. If
  present, ask for connection details; if not, offer the Docker one-liner or fall back to
  SQLite (converting the schema if needed).
- Run an interactive loop: the user types a query/answer, lead executes it against the
  sample DB, compares against the solution, gives feedback. Log the full transcript to
  `practice/sessions/<YYYY-MM-DD>-<slug>-<preset>.md`.

This is a lightweight extension — the team is already torn down by this point.

**Final status**: "저장 완료 — problems/…, solutions/…. index/log 업데이트함."

---

## Difficulty presets

On first use in a course directory, write `practice/presets.md` with the five built-in
presets below.

- **`easy`** — Concept check. Mostly MCQ, fill-in-the-blank, short-answer. Drawn directly
  from slides. Light on hands-on work.
- **`medium`** — Application. Short-answer + written explanation, plus simple hands-on
  exercises (one query at a time, one normalization step, a small diagram).
- **`hard`** — Synthesis. Multi-concept problems, modified situations, harder hands-on
  (multi-step queries, full ER designs, multi-table normalization).
- **`exam`** — Mimics a midterm/final. Time-budgeted per problem, mixed formats, realistic
  point distribution. Include estimated time per problem.
- **`mixed`** — Spread across easy / medium / hard in a single set.

Users may define and save new presets (format emphasis, concept scope, time budget, style
notes). Append to `presets.md` when defined.

---

## File formats

### Problem file (`practice/problems/<date>-<slug>-<preset>.md`)

```markdown
---
course: <Course name, e.g. ADB>
chapter: 3                    # single chapter — integer; combine set — list or "2-4"
topic: SQL                    # or "Combine (Ch 2-4)" for a combine set
preset: medium
source: 3_SQL.pdf             # list for combine sets
created: 2026-04-16
problem_count: 10
language: ko
---

# [Course] Chapter 3 — SQL (medium)

Based on `3_SQL.pdf`. Solutions: `../solutions/2026-04-16-sql-medium.md`.

> Shared context (schemas, data, etc.)

```sql
CREATE TABLE ...
```

## Problem 1 (Short answer)
…

## Problem 2 (SQL query writing)
…
```sql
-- your answer
```
```

### Solution file (`practice/solutions/<date>-<slug>-<preset>.md`)

Mirror of the problem file. Each problem followed by **Answer** and a brief **Why**
(2–3 sentences). Solutions are not a re-lecture.

### `practice/index.md`

```markdown
# Practice Index — <Course Name>

Language: <ko | en | mixed>

## Materials

| Chapter | Topic        | Source file              |
| ------- | ------------ | ------------------------ |
| 2       | ER / RDB     | 2_er-rdb.pdf             |
| 3       | SQL          | 3_SQL.pdf                |
| …       | …            | …                        |

## Sample resources

- `db/Elmasri-Database/Employee_Database_Script.sql` — Elmasri COMPANY schema. Use as the
  default concrete schema for SQL / relational-algebra / query-processing problems.

## Problem sets

| Date       | Slug          | Preset | Count | Chapters | File                                              |
| ---------- | ------------- | ------ | ----- | -------- | ------------------------------------------------- |
| 2026-04-16 | sql           | medium | 10    | 3        | problems/2026-04-16-sql-medium.md                 |
| 2026-05-01 | combine-ch2-4 | hard   | 8     | 2,3,4    | problems/2026-05-01-combine-ch2-4-hard.md         |
```

### `practice/log.md`

```
## [2026-04-16] generated | SQL ch3 | medium | 10 problems | team adb-practice-2026-04-16-sql
Notes: user asked for emphasis on joins and subqueries. 1 revision round on ch3.
```

---

## Principles

### Cover the chapter; don't cherry-pick
If a chapter introduces N distinct concepts, the set should touch all N. The estimate from
Step 2 exists exactly to calibrate this.

### Always read visuals, every page
Lecture PDFs often rely on diagrams and figures (ER diagrams, query plans, normalization
tables) that OCR can miss. Every chapter agent and the reviewer must read every page with
visuals included — never skim. This is the whole point of using Opus agents per chapter.

### Ask before you guess on hands-on formats
The difference between "describe normalization" and "apply 3NF to this relation" is the
difference between a useless set and a useful one. The user must choose the hands-on mix.

### Stay faithful to the source
When a problem is drawn directly from a lecture example, cite it inline — `(based on p.12)`
or `(variant of example 4.2)`. Helps the user flip back to the slide when stuck.

### Use sample resources as the concrete backdrop
When the course has a sample DB / code repo / dataset recorded in `index.md`, problems
that need a concrete backdrop should default to that resource rather than inventing a new
schema/dataset each time. Consistency across sets helps the user accumulate familiarity.

### Separate problems from solutions
Never put answers in the problem file. The solution file mirrors it and is linked from
the problem file header.

### Don't over-specify the solution in the problem text
A problem should state the **required result / behavior**, not the tools to produce
it. Do not mandate specific operators, keywords, library/API calls, identifier or
variable names, or solution strategies in the problem body — these leak parts of the
answer.

**Exception**: when the particular construct *is itself the learning target* of the
chapter/problem (e.g., a chapter's central operator, a specific design pattern, a
particular proof technique). In that case, mandating it is the point.

**Rule of thumb**: if removing the constraint still leaves a valid problem that tests
the same concept, the constraint is over-specification.

### Accumulate, don't duplicate
Before generation, read prior sets for the same chapter+preset and pass the covered-topic
list to the drafter. A second medium-SQL set should explore different angles, not
re-release similar questions.

### Match the material's language
Honor the `Language:` field in `index.md`. Don't override unless the user explicitly asks.

### Keep solutions short
2–3 sentences per problem is usually right. Step-by-step walkthroughs only for calculation
or proof-style problems where the steps are the point.

### Milestone-based status, not message relay
Report to the user only at team spawn, each drafter completion, reviewer start/end, each
revision round, and final save. One line each. Do not forward teammate messages verbatim.

### Teammates are Team Agents, not subagents
Every agent this skill uses must be spawned via `Agent` with `team_name` + `name` inside
a `TeamCreate`d team. Plain subagents (no team context) are **not** used by this skill.
