# Quality Checklist — Self-Review

Before reporting completion, verify every item in the relevant mode's section. Fix and re-verify if any check fails.

---

## Document Mode

### Source Traceability
- [ ] Every source file's content verified (not filename-based assumption)
- [ ] Source content mapping table built and verified in Phase D1
- [ ] Every metadata callout `source` matches verified mapping
- [ ] Non-academic files excluded and documented
- [ ] Missing sources marked as `원문 미보유`
- [ ] Non-core topic policy documented in Dashboard

### Coverage
- [ ] Every topic from Phase D2 checklist has a concept note
- [ ] Every enumerated category member has its own note
- [ ] No source topic missing or underrepresented

### Tags
- [ ] All tags: English kebab-case, from registry only
- [ ] Tags stored as multi-select property values in Sections Index DB
- [ ] Detail tags co-attached with parent domain tags

### Structure & Formatting
- [ ] Every concept note has metadata callout at top (`Source`, `Part`, `Keywords`)
- [ ] Every concept note has comparison table + exam/test patterns section
- [ ] Process/flow topics have ASCII diagrams (in code blocks)
- [ ] Notes are concise (tables > prose)
- [ ] Simplified statements include exception caveats
- [ ] Tables use `<table header-row="true">` HTML syntax, not markdown pipes
- [ ] Toggle block children are tab-indented

### Dashboard
- [ ] Dashboard page: inline Concepts Tracker DB + Sections Index DB + Quick Reference + Exam Traps + Weak Areas + Tag Index
- [ ] Dashboard links to every concept note AND practice page via page mentions
- [ ] Weak Areas link to relevant concept notes AND Exam Traps via `<mention-page>`
- [ ] Exam Traps exists with per-topic toggle blocks and bidirectional page mentions
- [ ] Inline database views display correctly on Dashboard page

### Quick Reference
- [ ] All key formulas and condition expressions included
- [ ] Every section links to concept note via `<mention-page url="...">Note</mention-page>`

### Practice — Active Recall
- [ ] Every topic section has a practice page (8+ questions)
- [ ] All answers use `<details><summary>정답 보기</summary>` toggle blocks — never immediately visible
- [ ] Hints: `<details color="blue_bg"><summary>힌트</summary>` toggle; Summary: `<details color="gray_bg"><summary>요약</summary>` toggle
- [ ] Toggle block children are tab-indented
- [ ] `## Related Concepts` with page mentions in every practice page
- [ ] Question type diversity: ≥60% recall, ≥20% application, ≥2 analysis per file

### Interlinking
- [ ] Every concept note has `## Related Notes`
- [ ] Page mentions (`<mention-page url="...">`) used for all cross-references
- [ ] 2-pass cross-referencing completed (all page mentions have valid URLs)
- [ ] Siblings reference each other; concept ↔ practice cross-linked
- [ ] Exam Traps ↔ Concept notes bidirectionally linked via page mentions

### Notion Workspace Boundary
- [ ] No source files accessed outside CWD
- [ ] All generated content lives under the StudyVault root page in Notion
- [ ] No absolute local file paths in note content
- [ ] External URLs accessed only via WebFetch, not file paths

### Notion-Specific
- [ ] Concepts Tracker DB schema matches spec (7 properties: Concept, Area, Attempts, Correct, Last Tested, Status, Error Note)
- [ ] Sections Index DB schema matches spec (6 properties: Section, Order, Source, Tags, Notes, Practice)
- [ ] Batch page creation used where possible (`notion-create-pages` supports up to 100/call)

---

## Codebase Mode

### Project Coverage
- [ ] All major modules/domains identified and documented
- [ ] Architecture pattern documented with ASCII diagram
- [ ] Request flow traced end-to-end
- [ ] Data flow documented (input → processing → persistence → output)
- [ ] External dependencies and integrations listed

### Module Completeness
- [ ] Every module has a dedicated Notion page with metadata callout (`module`, `path`, `keywords`)
- [ ] Every module note includes: Purpose, Key Files, Public Interface, Internal Flow, Dependencies
- [ ] Configuration section lists relevant env vars / config keys
- [ ] Testing section includes commands and patterns

### Tags
- [ ] All tags: English kebab-case, from registry only
- [ ] Tags stored as multi-select property values in Sections Index DB
- [ ] Tags cover: `arch-*`, `module-*`, `pattern-*`, `api-*`

### Dashboard
- [ ] Dashboard page: inline Concepts Tracker DB + Sections Index DB + Module Map + API Surface + Getting Started + Onboarding Path
- [ ] Dashboard links to every module note and exercise page via page mentions
- [ ] Quick Reference: key commands, env setup, file locations, debugging tips
- [ ] Getting Started section is actionable (copy-paste commands)
- [ ] Inline database views display correctly on Dashboard page

### Onboarding Exercises
- [ ] Minimum 5 exercises per major module
- [ ] Exercise types: code reading (trace), configuration, debugging, extension
- [ ] All answers use `<details><summary>정답 보기</summary>` toggle blocks
- [ ] Toggle block children are tab-indented
- [ ] Exercises reference relevant module notes via `<mention-page url="...">`

### Interlinking
- [ ] Every module note has `## Related Notes`
- [ ] Page mentions (`<mention-page url="...">`) used for all cross-references
- [ ] 2-pass cross-referencing completed (all page mentions have valid URLs)
- [ ] Dependent modules cross-linked bidirectionally
- [ ] Architecture notes reference specific module implementations
- [ ] Exercises link back to the modules they cover

### Notion Workspace Boundary
- [ ] No references to files outside the project directory for source scanning
- [ ] All generated content lives under the StudyVault root page in Notion
- [ ] No hardcoded absolute paths in note content

### Notion-Specific
- [ ] Concepts Tracker DB schema matches spec (7 properties: Concept, Area, Attempts, Correct, Last Tested, Status, Error Note)
- [ ] Sections Index DB schema matches spec (6 properties: Section, Order, Source, Tags, Notes, Practice)
- [ ] Tables use `<table header-row="true">` HTML syntax, not markdown pipes
- [ ] Toggle block children are tab-indented
- [ ] Batch page creation used where possible (`notion-create-pages` supports up to 100/call)
