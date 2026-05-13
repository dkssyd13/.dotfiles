# Codebase Mode — Onboarding Vault Workflow

> Generates a StudyVault that helps new developers understand and navigate a source code project.
> Source scanning uses CWD. Output goes to Notion.

## Phase C1: Project Exploration

1. **Scan project structure**: `Glob` for source files, config files, test files. Build a file tree.
2. **Identify tech stack**: Detect languages, frameworks, build tools, package managers from config files.
3. **Read key files**: README, CONTRIBUTING, entry points (`main.*`, `index.*`, `app.*`), config files.
4. **Map project layout**: Record directory purposes (e.g., `src/`, `test/`, `config/`, `scripts/`).
5. **Present findings** to user for confirmation before proceeding.

## Phase C2: Architecture Analysis

1. **Identify architectural patterns**: layered, hexagonal, microservice, monolith, serverless, etc.
2. **Map module boundaries**: Which directories/packages form distinct modules or domains?
3. **Trace request flow**: For a typical request (HTTP, event, CLI), trace the path through the code.
4. **Identify key abstractions**: Interfaces, base classes, shared utilities, middleware, interceptors.
5. **Map dependencies**: Internal module dependencies + external service integrations.
6. **Document data flow**: How data enters, transforms, persists, and exits the system.
7. **Build architecture summary**: Create a concise diagram (ASCII) + description for the vault.

## Phase C3: Tag Standard

Define tag vocabulary before creating notes:
- **Format**: English, lowercase, kebab-case
- **Categories**: `arch-*` (architecture), `module-*` (modules), `pattern-*` (patterns), `config-*` (config), `api-*` (API), `test-*` (testing)
- **Storage**: Tags are stored as **multi-select property values** on the Sections Index database — NOT as inline hashtags in page content.
- **Registry**: Only registered tags allowed. Present registry to user for approval.

## Phase C4: Vault Structure (Notion Pages & Databases)

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
6. **Create child pages** under StudyVault root:
   - `01-Architecture` — System overview, request flow, data flow
   - `02-<Module1>` through `NN-<ModuleN>` — One page per module/domain
   - `NN+1-DevOps` — Build, deploy, CI/CD, environment config
   - `NN+2-Exercises` — Onboarding exercises
7. **Populate Sections Index** with one row per section, filling Order, Source, Tags, and Notes count.

## Phase C5: Dashboard

Build the Dashboard page with inline database views and subpages:

1. **Inline Concepts Tracker** — embed via `<database url="..." inline="true">Concepts Tracker</database>`
2. **Inline Sections Index** — embed via `<database url="..." inline="true">Sections Index</database>`
3. **Module Map** — `<table header-row="true">` with module name, purpose, entry point, and page mentions to module notes
4. **API Surface** — `<table header-row="true">` with method, path, module, and page mentions to API notes
5. **Getting Started subpage** — setup instructions, dev workflow, key commands
6. **Tag Index** — references multi-select values from the Sections Index database
7. **Onboarding Path** — recommended reading order with page mentions:
   `<mention-page url="...">System Architecture</mention-page>` → `<mention-page url="...">Request Flow</mention-page>` → module deep dives → exercises
8. **Quick Reference subpage** — key commands, environment setup, file locations, debugging tips — all using `<table header-row="true">` syntax and page mentions to relevant module notes

## Phase C6: Module Notes

One Notion subpage per module/domain, under the corresponding section page. Per [codebase-templates.md](codebase-templates.md). Key rules:

- **No YAML frontmatter** — metadata in a callout at the top of the page:
  ```
  <callout icon="📋" color="gray_bg">
  	Module: <name> | Path: <relative-path> | Keywords: <3-5 English keywords>
  </callout>
  ```
- **Purpose**: What this module does (1-3 sentences)
- **Key Files**: `<table header-row="true">` — important files with descriptions
- **Public Interface**: `<table header-row="true">` — exported functions/classes/endpoints
- **Internal Flow**: How data moves through this module (ASCII diagram in code block)
- **Dependencies**: `<table header-row="true">` — what this module depends on + what depends on it
- **Configuration**: `<table header-row="true">` — relevant env vars, config keys
- **Testing**: How to run tests for this module, test patterns used
- **Related Notes**: Page mentions to related modules and architecture notes —
  `<mention-page url="{{page_url}}">Other Module</mention-page>`

For API-heavy modules, create separate API note subpages per [codebase-templates.md](codebase-templates.md).

## Phase C7: Onboarding Exercises

Create exercise subpages under the Exercises section page. Per [codebase-templates.md](codebase-templates.md).

- **Code Reading**: "Trace what happens when X occurs" — answer in toggle block
- **Configuration**: "How would you change Y?" — answer with file paths + snippets
- **Debugging**: "Where would you look if Z breaks?" — answer with investigation steps
- **Extension**: "How would you add feature W?" — answer with architectural approach
- Minimum 5 exercises per major module
- All answers use toggle blocks with tab-indented children:
  ```
  <details>
  <summary>정답 보기</summary>
  	Answer content here (TAB-INDENTED)
  </details>
  ```
- Hints use colored toggle blocks:
  ```
  <details color="blue_bg">
  <summary>힌트</summary>
  	Hint content here (TAB-INDENTED)
  </details>
  ```
- Learning summary at end uses:
  ```
  <details color="gray_bg">
  <summary>학습 포인트 요약</summary>
  	<table header-row="true">
  		<tr><td>Topic</td><td>Key Takeaway</td></tr>
  		<tr><td>...</td><td>...</td></tr>
  	</table>
  </details>
  ```

## Phase C8: Interlinking

All cross-links use page mentions. **2-pass strategy**: create all pages first (collect page IDs/URLs), then add cross-references in a second pass.

1. **Related Notes section** on every module note — add page mentions to related modules using collected page IDs
2. **Dashboard links** — Dashboard page mentions every module note + exercise page
3. **Cross-link modules** that depend on each other via page mentions
4. **Architecture notes** reference specific module implementations via page mentions
5. **Exercises** reference the modules they cover via page mentions in Related Modules section
6. **Quick Reference** links to relevant module notes via page mentions

## Phase C9: Self-Review (MANDATORY)

Verify against [quality-checklist.md](quality-checklist.md) **Codebase Mode** section. Fix and re-verify until all checks pass.
