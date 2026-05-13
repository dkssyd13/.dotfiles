# Codebase Mode — Templates Reference

## Page Hierarchy

```
StudyVault (root page)
├── Dashboard (page with inline DBs)
│   ├── Quick Reference (subpage)
│   └── Getting Started (subpage)
├── 01-Architecture (page)
│   ├── System Architecture (subpage)
│   ├── Request Flow (subpage)
│   └── Data Flow (subpage)
├── 02-<Module1> (page)
│   └── module notes (subpages)
├── ...
├── NN-DevOps (page)
│   └── build/deploy/CI notes (subpages)
└── NN+1-Exercises (page)
    └── exercise files (subpages)
```

## Dashboard MOC Template

```markdown
# <Project Name> — Onboarding Map

## Architecture Overview
- Pattern: <architectural pattern>
- Tech stack: <languages, frameworks, key libraries>
- <mention-page url="{{page_url}}">System Architecture</mention-page>
- <mention-page url="{{page_url}}">Request Flow</mention-page>

## Module Map

<table header-row="true">
	<tr><td>Module</td><td>Purpose</td><td>Key Entry Point</td><td>Notes</td></tr>
	<tr><td><name></td><td><1-line purpose></td><td><code><path></code></td><td><mention-page url="{{page_url}}">Module Note</mention-page></td></tr>
</table>

## API Surface

<table header-row="true">
	<tr><td>Method</td><td>Path / Command</td><td>Module</td><td>Notes</td></tr>
	<tr><td>GET</td><td><code>/endpoint</code></td><td><module></td><td><mention-page url="{{page_url}}">API Note</mention-page></td></tr>
</table>

## Getting Started
1. Prerequisites: ...
2. Install: `<install command>`
3. Configure: copy `.env.example` → `.env`
4. Run: `<run command>`
5. Test: `<test command>`

## Tag Index

References multi-select values from the Sections Index database:

<table header-row="true">
	<tr><td>Tag</td><td>Description</td><td>Rule</td></tr>
	<tr><td>arch-*</td><td>Architecture concepts</td><td>Top-level pattern tags</td></tr>
	<tr><td>module-*</td><td>Module-specific</td><td>One per module</td></tr>
</table>

## Onboarding Path

<callout icon="📖" color="blue_bg">
	Recommended reading order for new developers:
</callout>

1. <mention-page url="{{page_url}}">System Architecture</mention-page> — big picture
2. <mention-page url="{{page_url}}">Request Flow</mention-page> — how a request moves through the system
3. <mention-page url="{{page_url}}">Module A</mention-page> → <mention-page url="{{page_url}}">Module B</mention-page> → ... — module deep dives
4. <mention-page url="{{page_url}}">Exercises</mention-page> — hands-on practice
```

## Quick Reference Template

```markdown
# Quick Reference

## Key Commands

<table header-row="true">
	<tr><td>Action</td><td>Command</td></tr>
	<tr><td>Install deps</td><td><code><command></code></td></tr>
	<tr><td>Run dev</td><td><code><command></code></td></tr>
	<tr><td>Run tests</td><td><code><command></code></td></tr>
	<tr><td>Build</td><td><code><command></code></td></tr>
	<tr><td>Lint</td><td><code><command></code></td></tr>
</table>

## Environment Setup
1. ...

## Important File Locations

<table header-row="true">
	<tr><td>File / Dir</td><td>Purpose</td></tr>
	<tr><td><code><path></code></td><td><description></td></tr>
</table>

## Common Debugging

<table header-row="true">
	<tr><td>Symptom</td><td>Where to Look</td><td>Note</td></tr>
	<tr><td><problem></td><td><code><file/log></code></td><td><mention-page url="{{page_url}}">Module Note</mention-page></td></tr>
</table>
```

## Module Note Template

```markdown
# <Module Name> (<Importance: ★~★★★>)

<callout icon="📋" color="gray_bg">
	Module: <module-name> | Path: <relative-path-from-project-root> | Keywords: <3-5 English keywords>
</callout>

## Purpose
<1-3 sentences: what this module does and why it exists>

## Key Files

<table header-row="true">
	<tr><td>File</td><td>Role</td></tr>
	<tr><td><code><relative-path></code></td><td><description></td></tr>
</table>

## Public Interface

<table header-row="true">
	<tr><td>Export</td><td>Type</td><td>Description</td></tr>
	<tr><td><code><name></code></td><td>function/class/endpoint</td><td><what it does></td></tr>
</table>

## Internal Flow

```text
<ASCII diagram showing data/control flow within this module>
```

## Dependencies

<table header-row="true">
	<tr><td>Direction</td><td>Module / Service</td><td>Via</td></tr>
	<tr><td><strong>Uses</strong></td><td><dependency></td><td><code><import/call></code></td></tr>
	<tr><td><strong>Used by</strong></td><td><dependent></td><td><code><import/call></code></td></tr>
</table>

## Configuration

<table header-row="true">
	<tr><td>Env Var / Config Key</td><td>Purpose</td><td>Default</td></tr>
	<tr><td><code><VAR></code></td><td><description></td><td><code><default></code></td></tr>
</table>

## Testing
- Run: `<test command for this module>`
- Pattern: <unit/integration/e2e>
- Coverage notes: ...

## Related Notes
- <mention-page url="{{page_url}}">Other Module</mention-page>
- <mention-page url="{{page_url}}">Architecture Note</mention-page>
```

## API Note Template

```markdown
# <Endpoint Group> API

<callout icon="📋" color="gray_bg">
	Module: <module-name> | Path: <relative-path> | Keywords: API, <endpoint-keywords>
</callout>

## Endpoints

<table header-row="true">
	<tr><td>Method</td><td>Path</td><td>Auth</td><td>Description</td></tr>
	<tr><td>GET</td><td><code>/path</code></td><td>required</td><td><description></td></tr>
</table>

## Request / Response

### <Endpoint Name>

**Request**:
```json
{
  "field": "type — description"
}
```

**Response (success)**:
```json
{
  "field": "type — description"
}
```

**Error cases**:

<table header-row="true">
	<tr><td>Status</td><td>Condition</td><td>Response</td></tr>
	<tr><td>400</td><td><condition></td><td><code>{ "error": "..." }</code></td></tr>
</table>

## Related Notes
- <mention-page url="{{page_url}}">Module Note</mention-page>
- <mention-page url="{{page_url}}">Other API Note</mention-page>
```

## Onboarding Exercise Template

```markdown
# <Topic> — Onboarding Exercises

## Related Modules
- <mention-page url="{{page_url}}">Module Note 1</mention-page>
- <mention-page url="{{page_url}}">Module Note 2</mention-page>

---

## Exercise 1 — Code Reading [trace]
> Trace what happens when <specific trigger>. List the files and functions involved in order.

<details>
<summary>정답 보기</summary>
	1. `<file>` → `<function>` — <what happens>
	2. `<file>` → `<function>` — <what happens>
	3. ...
</details>

---

## Exercise 2 — Configuration [config]
> How would you change <specific setting>? Which files need modification?

<details>
<summary>정답 보기</summary>
	- File: `<path>`
	- Change: <description>
	- Related env var: `<VAR>`
</details>

---

## Exercise 3 — Debugging [debug]
> If <symptom> occurs, where would you look first? Describe your investigation steps.

<details>
<summary>정답 보기</summary>
	1. Check `<file/log>` for ...
	2. Verify `<config>` is ...
	3. Common cause: ...
</details>

---

## Exercise 4 — Extension [extend]
> How would you add <new feature/endpoint>? Describe the files you'd create or modify.

<details>
<summary>정답 보기</summary>
	1. Create `<path>` — <purpose>
	2. Modify `<path>` — <what to add>
	3. Add test in `<path>` — <what to test>
	4. Register in `<path>` — <wiring>
</details>

---

<details color="gray_bg">
<summary>학습 포인트 요약</summary>
	<table header-row="true">
		<tr><td>Topic</td><td>Key Takeaway</td></tr>
		<tr><td><topic></td><td><insight></td></tr>
	</table>
</details>
```

## Formatting Rules

- **Cross-references**: `<mention-page url="{{page_url}}">Page Title</mention-page>` for all internal links
- **Callouts**: `<callout icon="💡" color="green_bg">` (tip), `<callout icon="❗" color="red_bg">` (important), `<callout icon="⚠️" color="orange_bg">` (warning) — children TAB-indented
- **Toggle blocks**: `<details><summary>Label</summary>` with TAB-indented children — for answers, hints, summaries
- **Tables**: `<table header-row="true">` with `<tr>` and `<td>` elements — no markdown pipe tables
- **Tags**: Multi-select property values on Sections Index database — NOT inline hashtags
- **No YAML frontmatter** — metadata in Sections Index DB properties or metadata callout at top of page
- ASCII diagrams for flows, architecture, and module interactions (in code blocks)
- **Bold** for critical terms and file paths in descriptions
- Code blocks with language hints for commands and snippets
- **Localization**: Toggle labels match team language. Korean: `정답 보기`, English: `View Answer`
