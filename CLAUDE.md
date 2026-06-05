# Power Platform AI Quality Framework — Root Rules

You are assisting a Power Platform consulting team (Inspirit365) building Canvas Apps,
Code Apps, and PCF components for Dynamics 365 / Power Platform customers.

This file is automatically loaded by Claude Code for any project using this framework.
Rules in this file apply to ALL Power Platform development regardless of component type.

---

## Available Claude Code Skills (invoke proactively — do not ask the user to run these)

| Skill | When to use |
|-------|------------|
| `/canvas-apps:canvas-app` | Any Canvas App screen creation or modification |
| `/canvas-apps:add-data-source` | When user asks to connect to SharePoint, Dataverse, SQL, etc. |
| `/security-review` | Before every delivery; after any auth or data access change |
| `/code-review` | After implementing a feature; before committing |
| `/simplify` | When code has grown; after completing a feature |
| `/deep-research` | When best-practice guidance is needed on an unfamiliar topic |
| `/verify` | After implementing a feature to confirm it works |
| `/init` | When starting a new project without a CLAUDE.md |

---

## Component Type Decision Tree

Before writing any code, confirm which type the project needs.

```
Does the app need full custom React control over routing and architecture?
  YES → Code App (pac code / @microsoft/power-apps SDK)
  NO  → Is a custom UI control needed inside an existing app?
          YES → PCF Component (pac pcf)
          NO  → Canvas App (Power Fx, Power Apps Studio)
```

**Never start building before the type is confirmed.**
If unsure, recommend Canvas App first and explain why a Code App or PCF might be needed.

---

## Universal Rules (all component types)

### Continuous documentation — mandatory, non-negotiable

> This is the most critical documentation rule. It applies without exception on every project,
> every session, every change. The AI must maintain the project's DEVLOG.md automatically.
> The consultant must never need to ask for documentation to be written.

**Before reporting any work as done, Claude must:**

1. **Update `DEVLOG.md`** with an entry covering what changed, why, alternatives considered,
   files modified, trade-offs, and follow-up items. See the entry format in
   `documentation/dev-log-standard.md`.

2. **Create `DEVLOG.md`** if it does not exist yet, using the template at
   `documentation/templates/devlog-template.md`.

3. **Create or update an ADR** (`/documentation/decisions/ADR-XXX-title.md`) whenever the
   change involves an architectural decision (data source, component type, API pattern, etc.).

4. **Update `README.md`** whenever the change affects connectors, environment variables,
   deployment steps, or anything visible to a new developer inheriting the project.

**DEVLOG entry format (minimum required fields):**

```
## [YYYY-MM-DD] — [Short imperative title]

**Requirement:** [Paraphrase of the user's prompt — what was asked for]
**Implemented:** [What was built — name files, screens, formulas specifically]
**Reasoning:** [Why this approach — reference framework rules and/or MS Learn URLs]
**Alternatives considered:** [Table of alternatives and why rejected, if applicable]
**Files changed:** [List of modified files with one-line descriptions]
**Trade-offs / limitations:** [Known constraints or performance implications]
**Follow-up:** [Deferred items, or "None."]
**ADR:** [ADR-XXX or N/A]
```

**Documentation quality bar:** A consultant who was not in the session must be able to read
the DEVLOG and understand exactly what changed, why, and what to be careful about.
If an entry cannot meet this bar, the reasoning was not clear enough and needs to be
revisited before the work is considered done.

Full specification: `documentation/dev-log-standard.md`

---

### Solutions and ALM
- Always use a named Solution — never the default solution
- Always use Environment Variables for environment-specific values
- Always use Connection References — never hardcoded connections
- Run Solution Checker before every delivery (Canvas Apps)

### Code documentation
- Every screen / component / app must have a purpose statement in the README
- Complex logic must have a comment explaining **why**, not what
- Follow the dual-layer standard: consultant summary + technical specification

### Code quality
- No hardcoded URLs, text strings, or connection strings
- No commented-out code committed to source control
- No unused variables, collections, controls, or imports
- Before adding anything new, ask: is this already available in standard Power Apps?

### Microsoft documentation
When in doubt, fetch the authoritative Microsoft source rather than guessing.
Master index: see `documentation/standards.md` or the framework README.

---

## AI Behaviour: Plan-First, Foundation-First

### Step order — never skip steps

```
1. UNDERSTAND  → Ask the critical clarifying questions (see each CLAUDE.md)
2. PLAN        → Present architecture; wait for explicit approval before coding
3. FOUNDATION  → Project setup, types, shared utilities
4. CORE        → Business logic
5. UI          → Interface on top of finished logic
6. VERIFY      → Run checklist; invoke /security-review
```

### Red flags — push back immediately

- User requests something that already exists in standard Power Apps → explain the alternative
- User requests many screens/features at once → break it down, one at a time
- Code is growing without old code being cleaned up → flag and remove dead code
- User says "it probably works" without testing → ask for verification
- Any pattern that would break delegation in Canvas Apps → warn and propose the correct approach

### Scalability red flags — push back on ALL of these before writing any code

These patterns produce unscalable solutions that fail on real customer data volumes.
Identify them in the user's request or in existing code and propose the correct alternative.

| Anti-pattern | Why it fails | Correct alternative |
|---|---|---|
| "Fetch all [entity] records" | Tens of thousands of rows → memory crash, API rate limits | Add `$filter`, `$top`, `$select`; paginate |
| Query without `$select` | Returns every column — burns API execution time quota fast | Always specify only the columns you render |
| Client-side filtering after fetching all records | Full dataset in memory; delegation bypass | Move filter to `$filter` (server-side) |
| No pagination / `$top` | Dataverse returns up to 5,000 rows by default | Use `@odata.nextLink` cursor pagination or `$top` |
| API call in a loop per record | O(n) requests — 100 items = 100 API calls | Batch into a single request |
| `updateView` calls webAPI without `updatedProperties` guard (PCF) | API call fires on every property change | Guard: `if (!context.updatedProperties.includes('x')) return` |
| `notifyOutputChanged` on every keypress (PCF) | Floods the host app with recalculations | Debounce — minimum 300ms |
| Direct `fetch()` to Azure Function with hardcoded URL/key | Not portable, not secure, not ALM-compatible | Use a connector or receive endpoint via input property |

Reference: https://learn.microsoft.com/en-us/power-apps/developer/data-platform/api-limits
Reference: https://learn.microsoft.com/power-apps/developer/data-platform/query-antipatterns

---

## References

| Topic | URL |
|-------|-----|
| Power Platform Well-Architected | https://learn.microsoft.com/power-platform/well-architected/ |
| ALM overview | https://learn.microsoft.com/power-platform/alm/ |
| Solution concepts | https://learn.microsoft.com/en-us/power-platform/alm/solution-concepts-alm |
| Environment variables | https://learn.microsoft.com/en-us/power-apps/maker/data-platform/environmentvariables |
| Connection references | https://learn.microsoft.com/en-us/power-apps/maker/data-platform/create-connection-reference |
| CoE Starter Kit | https://learn.microsoft.com/power-platform/guidance/coe/starter-kit |
