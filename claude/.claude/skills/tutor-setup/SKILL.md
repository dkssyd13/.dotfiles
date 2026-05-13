---
name: tutor-setup
description: >
  Transforms knowledge sources into a Notion StudyVault. Two modes:
  (1) Document Mode — PDF/text/web sources → study notes with practice questions.
  (2) Codebase Mode — source code project → onboarding vault for new developers.
  Mode is auto-detected based on project markers in CWD.
argument-hint: "[source-path-or-url]"
allowed-tools: Read, Glob, Grep, Bash, WebFetch, mcp__plugin_Notion_notion__notion-create-database, mcp__plugin_Notion_notion__notion-create-pages, mcp__plugin_Notion_notion__notion-create-view, mcp__plugin_Notion_notion__notion-fetch, mcp__plugin_Notion_notion__notion-search, mcp__plugin_Notion_notion__notion-update-page, mcp__plugin_Notion_notion__notion-move-pages, mcp__plugin_Notion_notion__notion-update-data-source
---

# Tutor Setup — Knowledge to Notion StudyVault

## Notion Workspace Rule (ALL MODES)

> **Source scanning uses CWD** — PDFs, code, and local files are read from the current working directory and its subdirectories.
> **Output goes to Notion** — all generated notes, databases, and dashboards are created in the Notion workspace under a "StudyVault" root page.
> Before creating anything, **search for an existing "StudyVault" page** via `notion-search`. If found, ask the user before overwriting or creating a new one.
> **NEVER modify Notion pages outside the StudyVault root page.**

## Mode Detection

On invocation, detect mode automatically:

1. **Check for project markers** in CWD:
   - `package.json`, `pom.xml`, `build.gradle`, `Cargo.toml`, `go.mod`, `Makefile`,
     `*.sln`, `pyproject.toml`, `setup.py`, `Gemfile`
2. **If any marker found** → **Codebase Mode**
3. **If no marker found** → **Document Mode**
4. **Tie-break**: If `.git/` is the sole indicator and no source code files (`*.ts`, `*.py`, `*.java`, `*.go`, `*.rs`, etc.) exist, default to Document Mode.
5. Announce detected mode and ask user to confirm or override.

---

## Document Mode

> Transforms knowledge sources (PDF, text, web, epub) into study notes.
> Templates: [templates.md](references/templates.md)

### Phase D1: Source Discovery & Extraction

1. **Auto-scan CWD** for `**/*.pdf`, `**/*.txt`, `**/*.md`, `**/*.html`, `**/*.epub` (exclude `node_modules/`, `.git/`, `dist/`, `build/`). Present for user confirmation.
2. **Extract text (MANDATORY tools)**:
   - **PDF → `pdftotext` CLI ONLY** (run via Bash tool). NEVER use the Read tool directly on PDF files — it renders pages as images and wastes 10-50x more tokens. Convert to `.txt` first, then Read the `.txt` file.
     ```bash
     pdftotext "source.pdf" "/tmp/source.txt"
     ```
   - If `pdftotext` is not installed, install it first: `brew install poppler` (macOS) or `apt-get install poppler-utils` (Linux).
   - URL → WebFetch
   - Other formats (`.md`, `.txt`, `.html`) → Read directly.
3. **Read extracted `.txt` files** — understand scope, structure, depth. Work exclusively from the converted text, never from the raw PDF.
4. **Source Content Mapping (MANDATORY for multi-file sources)**:
   - Read **cover page + TOC + 3+ sample pages from middle/end** for EVERY source file
   - **NEVER assume content from filename** — file numbering often ≠ chapter numbering
   - Build verified mapping: `{ source_file → actual_topics → page_ranges }`
   - Flag non-academic files and missing sources
   - Present mapping to user for verification before proceeding

### Phase D2: Content Analysis

1. Identify topic hierarchy — sections, chapters, domain divisions.
2. Separate concept content vs practice questions.
3. Map dependencies between topics.
4. Identify key patterns — comparisons, decision trees, formulas.
5. **Full topic checklist (MANDATORY)** — every topic/subtopic listed. Drives all subsequent phases.

> **Equal Depth Rule**: Even a briefly mentioned subtopic MUST get a full dedicated note supplemented with textbook-level knowledge.

6. **Classification completeness**: When source enumerates categories ("3 types of X"), every member gets a dedicated note. Scan for: "types of", "N가지", "categories", "there are N".
7. **Source-to-note cross-verification (MANDATORY)**: Record which source file(s) and page range(s) cover each topic. Flag untraceable topics as "source not available".

### Phase D3: Tag Standard

Define tag vocabulary before creating notes:
- **Format**: English, lowercase, kebab-case (e.g., `data-hazard`)
- **Hierarchy**: top-level → domain → detail → technique → note-type
- **Registry**: Only registered tags allowed. Detail tags co-attach parent domain tag.
- **Storage**: Tags are stored as **multi-select property values** on the Sections Index database — NOT as inline hashtags in page content.

### Phase D4: Vault Structure (Notion Pages & Databases)

Create the StudyVault hierarchy in Notion:

1. **Search** for existing "StudyVault" page via `notion-search`. If found, confirm with user before proceeding.
2. **Create root "StudyVault" page** in the Notion workspace.
3. **Create "Dashboard" child page** under StudyVault.
4. **Create Concepts Tracker database** (inline on Dashboard):
   ```sql
   CREATE TABLE (
     "Concept"     TITLE,
     "Area"        SELECT('<dynamic>':default),
     "Attempts"    NUMBER,
     "Correct"     NUMBER,
     "Last Tested" DATE,
     "Status"      SELECT('🔴 Unresolved':red, '🟢 Resolved':green),
     "Error Note"  RICH_TEXT
   )
   ```
5. **Create Sections Index database** (inline on Dashboard):
   ```sql
   CREATE TABLE (
     "Section"   TITLE,
     "Order"     NUMBER,
     "Source"    RICH_TEXT,
     "Tags"      MULTI_SELECT('<dynamic>':default),
     "Notes"     NUMBER COMMENT 'concept note count',
     "Practice"  CHECKBOX COMMENT 'has practice page'
   )
   ```
6. **Create one child page per topic section** under StudyVault root (e.g., `01-<Topic1>`, `02-<Topic2>`).
7. **Populate Sections Index** with one row per section, filling Order, Source, Tags, and Notes count.

### Phase D5: Dashboard

Build the Dashboard page with inline database views and subpages:

1. **Inline Concepts Tracker** — embed via `<database url="..." inline="true">Concepts Tracker</database>`
2. **Inline Sections Index** — embed via `<database url="..." inline="true">Sections Index</database>`
3. **Quick Reference subpage**:
   - Every heading includes a page mention to the corresponding concept note: `<mention-page url="...">Concept Note</mention-page>`
   - All key formulas and summary tables using `<table header-row="true">` syntax
4. **Exam Traps subpage** (Document Mode only):
   - Per-topic trap points in toggle blocks: `<details color="red_bg"><summary>Trap: ...</summary>` with tab-indented children
   - Each trap links to its concept note via page mention
5. **Tag Index** — references multi-select values from the Sections Index database
6. **Weak Areas** — uses page mentions to link to relevant concept notes

### Phase D6: Concept Notes

Create concept notes as Notion subpages under each topic section page. Key rules:
- **No YAML frontmatter** — metadata (source, part, keywords) is stored in the Sections Index database properties or in a metadata callout at the top of the page:
  ```
  <callout icon="📋" color="gray_bg">
  	Source: source.pdf | Part: 3 | Keywords: data-hazard, pipeline
  </callout>
  ```
- **Cross-references**: Use page mentions instead of wikilinks — `<mention-page url="...">Related Concept</mention-page>`
  - **2-pass strategy**: Create ALL pages first (collect page IDs/URLs), THEN add cross-references in a second pass
- **Callout syntax**:
  - Tip → `<callout icon="💡" color="green_bg">`
  - Important → `<callout icon="❗" color="red_bg">`
  - Warning → `<callout icon="⚠️" color="orange_bg">`
- **Tables** → `<table header-row="true">` syntax with `<tr>` and `<td>` elements
- **source MUST match verified Phase D1 mapping** — never guess from filename
- If unavailable: `Source: 원문 미보유`
- Keep: comparison tables, ASCII diagrams (code blocks), bold terms
- **Simplification-with-exceptions**: general statements must note edge cases

### Phase D7: Practice Questions

Create practice pages as Notion subpages under each topic section page. Key rules:
- Every topic section MUST have a practice page (8+ questions)
- **Active recall**: answers use toggle blocks:
  ```
  <details>
  <summary>정답 보기</summary>
  	Answer content here (TAB-INDENTED)
  </details>
  ```
- Patterns use toggle blocks:
  - Hint → `<details color="blue_bg"><summary>힌트</summary>` with tab-indented children
  - Summary → `<details color="gray_bg"><summary>요약</summary>` with tab-indented children
- **Question type diversity**: ≥60% recall, ≥20% application, ≥2 analysis per file
- `## Related Concepts` with page mentions: `<mention-page url="...">Concept Name</mention-page>`

### Phase D8: Interlinking

Use page mentions to connect all notes. Strategy: collect page IDs/URLs during creation phases, then link in a dedicated pass.

1. **Related Notes section** on every concept note — add page mentions to related concepts using collected page IDs
2. **Dashboard links** — Dashboard page mentions every concept + practice page
3. **Cross-link concept ↔ practice** — each concept page mentions its practice page and vice versa; sibling concepts reference each other
4. **Quick Reference** — each section heading includes a page mention to its concept note
5. **Weak Areas → relevant notes + Exam Traps; Exam Traps → concept notes** — all via page mentions

### Phase D9: Self-Review (MANDATORY)

Verify against [quality-checklist.md](references/quality-checklist.md) **Document Mode** section. Fix and re-verify until all checks pass.

---

## Codebase Mode

> Generates a new-developer onboarding StudyVault from a source code project.
> Full workflow: [codebase-workflow.md](references/codebase-workflow.md)
> Templates: [codebase-templates.md](references/codebase-templates.md)

### Phase Summary

| Phase | Name | Key Action |
|-------|------|------------|
| C1 | Project Exploration | Scan files, detect tech stack, read entry points, map directory layout |
| C2 | Architecture Analysis | Identify patterns, trace request flow, map module boundaries and data flow |
| C3 | Tag Standard | Define `arch-*`, `module-*`, `pattern-*`, `api-*` tag registry as multi-select values |
| C4 | Vault Structure | Create StudyVault Notion page hierarchy with Dashboard, Architecture, per-module, DevOps, Exercises pages and databases |
| C5 | Dashboard | Dashboard page with inline Concepts Tracker + Sections Index DBs, Module Map, API Surface, Getting Started, Onboarding Path subpages + Quick Reference |
| C6 | Module Notes | Per-module Notion subpages: Purpose, Key Files, Public Interface, Internal Flow, Dependencies — using Notion callouts, tables, and page mentions |
| C7 | Onboarding Exercises | Code reading, configuration, debugging, extension exercises (5+ per major module) — answers in `<details><summary>정답 보기</summary>` toggle blocks |
| C8 | Interlinking | Cross-link modules, architecture ↔ implementations, exercises ↔ modules — all via page mentions with 2-pass strategy |
| C9 | Self-Review | Verify against [quality-checklist.md](references/quality-checklist.md) **Codebase Mode** section |

### Codebase Mode — Notion-Specific Details

**C3 Tag Standard**: Tags are stored as **multi-select property values** on the Sections Index database. Format: English, lowercase, kebab-case. No inline hashtags in page content.

**C4 Vault Structure**: Same Notion setup pattern as Document Mode D4:
1. Search for existing "StudyVault" page via `notion-search`
2. Create root "StudyVault" page
3. Create "Dashboard" child page with inline Concepts Tracker and Sections Index databases (same schemas as D4)
4. Create child pages: Architecture, per-module pages, DevOps, Exercises
5. Populate Sections Index with module/architecture entries

**C5 Dashboard**: Same pattern as D5 — inline database views + subpages (Module Map, API Surface, Getting Started, Onboarding Path, Quick Reference). All using page mentions and Notion table syntax.

**C6 Module Notes**: Notion subpages with:
- Metadata callout at top (no YAML frontmatter)
- Callouts: `<callout icon="💡" color="green_bg">`, `<callout icon="⚠️" color="orange_bg">`, etc.
- Tables: `<table header-row="true">` syntax
- Cross-references: `<mention-page url="...">` page mentions (2-pass strategy)
- Keep: code blocks, ASCII diagrams, comparison tables

**C7 Onboarding Exercises**: Answers and hints use toggle blocks:
- `<details><summary>정답 보기</summary>` for answers (tab-indented children)
- `<details color="blue_bg"><summary>힌트</summary>` for hints (tab-indented children)

**C8 Interlinking**: All cross-links via page mentions using IDs collected during page creation. 2-pass strategy: create all pages first, then add cross-references.

See [codebase-workflow.md](references/codebase-workflow.md) for detailed per-phase instructions.

---

## Language

- Match source material language (Korean → Korean notes, etc.)
- **Tags/keywords**: ALWAYS English
