# Continuous Development Documentation Standard

## For consultants

> When you build with AI assistance, decisions happen fast. A screen is added, a data source
> is changed, a pattern is chosen over another — and three weeks later, nobody remembers why.
> This standard ensures that every meaningful change made during vibe-coding is automatically
> recorded in the project, together with the reasoning behind it.
>
> You do not need to write this documentation yourself. The AI maintains it for you as part of
> every development session. The result is a project where any consultant — or your future self —
> can open `DEVLOG.md` and understand the full history of decisions without reading through chat logs.

---

## What this produces

Every project using this framework will have a `DEVLOG.md` at its root that contains:

- A chronological log of every meaningful change
- The user's requirement or prompt that triggered the change
- The reasoning the AI applied (including alternatives it evaluated)
- The architectural and implementation choices made
- Known limitations, trade-offs, and follow-up items

This file is the single source of truth for **why the project is the way it is**.

---

## AI obligation — mandatory behavior

This section contains binding instructions for the AI. These rules apply to every development
session, on every project that uses this framework.

### Rule 1: DEVLOG.md is always up to date before the session ends

After any change that:
- Adds or removes a screen, component, control, or module
- Modifies data access patterns (queries, connectors, API calls)
- Changes navigation, state management, or app architecture
- Implements a new feature or fixes a reported bug
- Involves a design decision where more than one approach was possible

...the AI must add an entry to `DEVLOG.md` **before** reporting the work as done.

Do not batch entries. Write one entry per meaningful change, as each change is completed.

### Rule 2: If DEVLOG.md does not exist, create it

When starting work in a project that has no `DEVLOG.md`, create it using the template in
`documentation/templates/devlog-template.md` before making any other changes.

### Rule 3: The entry must capture the prompt context

The entry must include a paraphrase of what the user asked for — not the literal prompt text,
but the requirement or intent behind it. A reader who was not in the session must be able to
understand what prompted this change.

### Rule 4: Record alternatives considered

If the AI evaluated more than one approach and chose one, the rejected alternatives and the
reason for rejection must be recorded. This prevents future consultants from re-evaluating
the same options and arriving at the same dead ends.

### Rule 5: Flag deferred decisions and known issues

If a change has a known limitation, a performance concern, or a follow-up that should be
addressed later, it must appear in the entry's **Follow-up** field. It is better to record
"this needs to be revisited when the data volume exceeds X" than to leave a silent risk.

### Rule 6: ADRs are triggered automatically

When a change involves an architectural decision (data source choice, component type selection,
navigation strategy, API call pattern), the AI must also create or update an ADR in
`/documentation/decisions/`. The ADR number is referenced in the DEVLOG entry.

### Rule 7: README.md is kept in sync

If a change affects the public interface of the solution (new screens visible to users, changed
connector requirements, new environment variables, changed deployment steps), the AI must update
`README.md` in the same session, not later.

---

## DEVLOG.md entry format

Each entry uses this structure. All fields are required unless marked optional.

```markdown
## [YYYY-MM-DD] — [Short imperative description of the change]

**Requirement:** [Paraphrase of the user's prompt / requirement in 1–3 sentences]

**Implemented:**
[What was built or changed. Be specific — name the file, screen, component, or formula.]

**Reasoning:**
[Why this approach was chosen. Include the principles or constraints that drove the decision.
Reference the relevant framework rule (e.g., "delegation rule in canvas-apps/CLAUDE.md") or
Microsoft documentation URL where applicable.]

**Alternatives considered:** [optional if only one approach was viable]
| Alternative | Reason rejected |
|---|---|
| [Approach A] | [Why it was not chosen] |
| [Approach B] | [Why it was not chosen] |

**Files changed:**
- `[path/to/file]` — [one-line description of the change]
- `[path/to/file]` — [one-line description of the change]

**Trade-offs / limitations:**
[Any known performance implications, platform constraints, or compromises made.]

**Follow-up:**
[Deferred work, known risks, or future improvements. If none, write "None."]

**ADR:** [ADR-XXX if an architectural decision was recorded, otherwise "N/A"]
```

---

## Example entry

```markdown
## 2025-06-10 — Add server-side filtered account search to scrAccountList

**Requirement:**
User asked to add a search box to the account list screen that filters accounts by name.

**Implemented:**
Added `txt_Search` text input to `scrAccountList`. Modified the gallery `gal_Accounts` Items
formula to use `Filter(Accounts, StartsWith(name, txt_Search.Text), statecode = 0)`. Updated
`App.OnStart` to pre-load only the first 50 accounts using `Concurrent()` with `$select` and
`$top=50`.

**Reasoning:**
`StartsWith()` is delegation-compatible with Dataverse, unlike `Search()` which is not fully
delegable. Using `Filter(... StartsWith(...))` pushes the filtering to the server. This ensures
the result set is always complete regardless of the delegation threshold (500/2000 rows).
Rule applied: `canvas-apps/CLAUDE.md` delegation rules.
Reference: https://learn.microsoft.com/en-us/power-apps/maker/canvas-apps/delegation-overview

**Alternatives considered:**
| Alternative | Reason rejected |
|---|---|
| `Search(Accounts, txt_Search.Text, "name")` | `Search()` is not delegable for all Dataverse columns — would silently return only the first 500 matches |
| Client-side filter on pre-loaded collection | Pre-loading all accounts is not scalable on tenants with 10,000+ accounts |

**Files changed:**
- `scrAccountList.pa.yaml` — added `txt_Search` control, updated `gal_Accounts` Items formula
- `App.pa.yaml` — updated OnStart to use `$select=name,accountid` and `$top=50`

**Trade-offs / limitations:**
Search is prefix-only (`StartsWith`). Substring search (e.g., searching for "smith" in "Blacksmith")
would require `Search()`, which is not delegable. If substring search is needed in the future,
a Dataverse view with a full-text search index should be considered.

**Follow-up:**
Clarify with customer whether prefix search is sufficient or full-text search is required.
If full-text, investigate Dataverse search API integration. See: https://learn.microsoft.com/en-us/power-apps/maker/canvas-apps/search-option

**ADR:** N/A — no new architectural decision; consistent with existing delegation strategy.
```

---

## When to create vs. update an entry

| Scenario | Action |
|---|---|
| New feature added | New entry |
| Existing feature modified | New entry (reference the original entry date if relevant) |
| Bug fixed | New entry — describe the root cause and the fix |
| Configuration change (environment variable, connector) | New entry |
| Documentation-only change | No entry required |
| Refactor that changes no behavior | New entry only if it reflects a design decision |

---

## DEVLOG.md vs. ADR

| | DEVLOG.md | ADR |
|---|---|---|
| **Purpose** | Chronological record of all changes and reasoning | Record of a single significant architectural decision |
| **Scope** | Every session | Only when a major, hard-to-reverse decision is made |
| **Format** | One entry per change | One file per decision |
| **Audience** | Team, future maintainers, customers | Architects, senior developers |
| **Maintained by** | AI — automatically during every session | AI — triggered when a decision qualifies |

Both are required. They serve different readers and different purposes.

---

## Documentation quality bar

Every entry in DEVLOG.md must meet this bar:
- A consultant who was not in the session can understand what changed and why
- A new consultant inheriting the project can build a complete mental model of the solution by reading DEVLOG.md from top to bottom
- The reasoning is linked to framework rules or Microsoft documentation — not just "it seemed like a good idea"

If an entry cannot meet this bar, the change is not fully understood and should not be committed.

---

## References

| Topic | URL |
|-------|-----|
| Architecture Decision Records (ADR) standard | https://adr.github.io/ |
| Microsoft documentation best practices | https://learn.microsoft.com/en-us/power-apps/guidance/ |
| Power Platform ALM | https://learn.microsoft.com/power-platform/alm/ |
| Canvas App coding guidelines | https://learn.microsoft.com/power-apps/guidance/coding-guidelines/overview |
