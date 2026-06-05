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

### Solutions and ALM
- Always use a named Solution — never the default solution
- Always use Environment Variables for environment-specific values
- Always use Connection References — never hardcoded connections
- Run Solution Checker before every delivery (Canvas Apps)

### Documentation
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
Master index: see `../documentation/standards.md` or the framework README.

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
