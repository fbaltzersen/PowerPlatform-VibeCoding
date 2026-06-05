# Documentation Standards

## For consultants

Every deliverable we hand over must be understandable by someone who wasn't in the room when it was built.
These standards define the minimum documentation required for every Power Platform project.
"I'll document it later" is not acceptable — documentation is part of the definition of done.

**Quick checklist — every project must have:**

- [ ] A `README.md` in the project root (use the provided template)
- [ ] Screen documentation blocks for every canvas app screen
- [ ] Comments on any formula longer than two lines or using non-obvious logic
- [ ] An ADR for every significant design decision
- [ ] A data model document if custom Dataverse tables are used
- [ ] A connector list explaining which connectors are used and why
- [ ] A known limitations section documenting workarounds

---

## Technical specification

### 1. README.md — required for every project

Every project (canvas app, code app, PCF component, flow bundle) must have a `README.md` at the root of its repository or solution folder.

The README must be maintained throughout the project lifecycle — not written once and forgotten.

Templates are provided in `/documentation/templates/`:
- Canvas App: [`canvas-app-readme.md`](./templates/canvas-app-readme.md)
- Code App: [`code-app-readme.md`](./templates/code-app-readme.md)
- PCF Component: [`pcf-readme.md`](./templates/pcf-readme.md)

Minimum required sections: Overview, Data Sources, Connectors Used, Known Limitations, Deployment Instructions, Contacts.

### 2. Screen documentation blocks

Every screen in a canvas app must have a documentation block. Place it as a comment at the top of the screen's `OnVisible` property, or in the screen's description field where supported.

Use the screen documentation template: [`screen-doc.md`](./templates/screen-doc.md)

The block must cover:
- Screen name and purpose
- Data sources read on this screen
- Global variables read and written
- Context variables used
- Collections populated on this screen
- Navigation sources (which screens navigate here)
- Navigation targets (where this screen navigates to)
- Last updated date and author

### 3. Formula comments — why, not what

Add comments to formulas that:
- Are longer than approximately two lines
- Use `With()`, `ForAll()`, nested `If()`, or delegation-sensitive functions
- Implement non-obvious business logic
- Include a workaround for a platform limitation

**Comment style:**

```
// WHY: SharePoint returns max 500 rows by default.
// We use a StartIndex loop here because the list exceeds that limit
// and delegation is not supported for this connector in this context.
ForAll(
    Sequence(RoundUp(CountRows(spList) / 500, 0)),
    ...
)
```

Comment the **why** and the **tradeoffs**. The formula itself shows the **what**.

### 4. Architecture Decision Records (ADR)

Create an ADR for every significant design choice. "Significant" means:
- A choice that is hard or costly to reverse
- A choice where multiple valid alternatives existed
- A choice that future maintainers might question

**ADR storage:** `/documentation/decisions/` (create the folder if it doesn't exist).

**Filename convention:** `ADR-001-<short-title>.md`, `ADR-002-<short-title>.md`, etc.

**Minimum ADR structure:**

```markdown
# ADR-001: [Title]

**Date:** YYYY-MM-DD
**Status:** Accepted | Superseded by ADR-XXX | Deprecated

## Context
What problem or situation prompted this decision?

## Decision
What was decided?

## Alternatives considered
What else was evaluated and why was it rejected?

## Consequences
What are the tradeoffs, risks, or follow-up actions from this decision?
```

Examples of decisions that require an ADR:
- Choosing Dataverse over SharePoint as a data store
- Using a custom connector instead of a standard connector
- Choosing a Code App over a canvas app for a given use case
- Delegating vs. loading full dataset into a collection

### 5. Data model documentation

If the project creates or modifies custom Dataverse tables, the following must be documented:

- Table name (display name and schema name)
- Table description and business purpose
- For each column: display name, schema name, data type, required/optional, description, valid values (for choice columns)
- Relationships: table, relationship type (1:N, N:N), foreign key column
- Security roles that have access to the table

Format: a markdown table or a dedicated data model document in `/documentation/data-model.md`.

### 6. Connector list

Every project must include a connector inventory. For each connector used:

| Connector | Purpose in this project | Why this connector was chosen | Authentication method | Notes |
|---|---|---|---|---|
| SharePoint | Document storage | Client already uses SharePoint Online | OAuth (service account) | |
| Dataverse | Core data store | Native Power Platform, strong security model | Implicit (environment security) | |

Include this table in the README or in a dedicated `/documentation/connectors.md`.

### 7. Known limitations and workarounds

Every project will have limitations — platform constraints, licensing boundaries, delegation limits, connector gaps.
Document them explicitly so future maintainers and customers understand them.

Format a limitations section like this:

```markdown
## Known Limitations

| Limitation | Impact | Workaround | Reference |
|---|---|---|---|
| SharePoint delegation stops at 2000 rows | Lists larger than 2000 items are not fully searchable | Pre-filter by a delegable column before applying non-delegable filter | [Delegation docs](https://learn.microsoft.com/...) |
```

Do not hide limitations. A customer who discovers an undocumented limitation during go-live loses trust.

### 9. Continuous development log (DEVLOG.md) — AI-maintained

> **For consultants:** This is the most important documentation rule in the framework.
> Every change the AI makes — every screen added, every formula changed, every architectural
> decision — is automatically recorded in `DEVLOG.md` at the project root. You do not write
> this yourself. The AI writes it for you. The result is a complete, readable history of why
> the project is the way it is.

Every project must have a `DEVLOG.md` at its root.

**AI obligation:** Claude must update `DEVLOG.md` after every meaningful change, before
reporting the work as done. This is not optional and is never deferred to "later".

See the full specification: [`documentation/dev-log-standard.md`](./dev-log-standard.md)

Template: [`documentation/templates/devlog-template.md`](./templates/devlog-template.md)

**Minimum content per DEVLOG entry:**

| Field | Required | Content |
|-------|----------|---------|
| Date | Yes | ISO date YYYY-MM-DD |
| Title | Yes | Short imperative description of what changed |
| Requirement | Yes | Paraphrase of the user's prompt — why was this done? |
| Implemented | Yes | Specific description — name files, screens, formulas |
| Reasoning | Yes | Why this approach — reference framework rules and/or Microsoft Learn URLs |
| Alternatives considered | When applicable | What was evaluated and why it was rejected |
| Files changed | Yes | List of modified files with one-line descriptions |
| Trade-offs / limitations | Yes | Platform constraints, performance implications, known gaps |
| Follow-up | Yes | Deferred items or "None." |
| ADR reference | When applicable | Link to ADR if an architectural decision was recorded |

**When a DEVLOG entry is required:**
- New screen, component, control, or route added
- Existing feature modified
- Data access pattern changed (query, connector, API call)
- Bug fixed — include root cause and fix
- Architectural or design decision made
- Configuration changed (environment variable, connector)

**When not required:** documentation-only changes with no behavioral impact.

### 8. Dual-layer standard

All project documentation written for this framework follows the dual-layer format:

1. **For consultants** — plain-language summary at the top. Answers: what is this, what do I need to do, what are the rules? Readable in 60 seconds.
2. **Technical specification** — detailed, precise, implementation-level content. Intended for developers and architects.

When writing new documentation for a project (not framework docs), apply the same principle:
- Start with a business-oriented summary (what does this app do, who uses it, what problem does it solve).
- Follow with technical detail (architecture, data model, deployment).

---

## References

- Power Platform ALM: https://learn.microsoft.com/power-platform/alm/
- Canvas App documentation best practices: https://learn.microsoft.com/en-us/power-apps/guidance/
- PCF documentation: https://learn.microsoft.com/en-us/power-apps/developer/component-framework/
