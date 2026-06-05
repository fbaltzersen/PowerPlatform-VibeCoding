# Canvas App Rules

This file is automatically loaded by Claude Code when working in a Canvas App project.
All rules below are sourced from Microsoft official documentation.

Reference: https://learn.microsoft.com/power-apps/guidance/coding-guidelines/overview

---

## Before writing any code — required clarifications

Ask ALL of these before generating screens or formulas:

| Question | Why it matters |
|----------|----------------|
| What is the data source? (Dataverse, SharePoint, SQL, API) | Delegation rules differ by connector |
| Which devices? (Mobile, tablet, desktop, or all?) | Determines responsive layout strategy |
| Who are the users? (Single role or multiple?) | Affects navigation and access logic |
| Does an existing solution or component already exist? | Avoid rebuilding what already exists |
| Is this in an existing named Solution? | ALM — never use the default solution |
| What is the absolute MVP scope? | Prevents scope creep |

Present an architecture plan and wait for approval before building.

---

## Foundation-first order

```
STEP 1 — Architecture plan (present, wait for approval)
  Screen structure + purpose per screen
  Data source mapping
  Global variables and collections list
  Navigation flow

STEP 2 — App foundation (no UI yet)
  App.Formulas — all reusable calculations defined centrally
  App.OnStart — Concurrent() wrapping all global data calls
  Global variable and collection naming established

STEP 3 — Navigation shell
  Empty screens created with correct names
  Shared header/footer as components where relevant

STEP 4 — Screen by screen
  One screen fully completed (logic + UI + comment block)
  Verified against checklist before moving to next

STEP 5 — Revision pass
  Remove unused variables, collections, controls
  Consolidate duplicated formulas into App.Formulas
```

---

## Naming conventions

> **For consultants:** Consistent names make the app readable to anyone on the team.
> Microsoft defines a standard prefix system — follow it exactly.

| Element | Pattern | Example |
|---------|---------|---------|
| Screen | `scr` + PascalCase | `scrOrderList`, `scrHome` |
| Variable (global) | `var` + PascalCase | `varCurrentUser`, `varSelectedOrder` |
| Variable (context) | `loc` + PascalCase | `locIsLoading`, `locFormMode` |
| Collection | `col` + PascalCase | `colOrders`, `colUsers` |
| Button | `btn_` + Name | `btn_Save`, `btn_Cancel` |
| Label | `lbl_` + Name | `lbl_Title`, `lbl_Status` |
| Text input | `txt_` + Name | `txt_Search`, `txt_Email` |
| Gallery | `gal_` + Name | `gal_Orders`, `gal_Products` |
| Form | `frm_` + Name | `frm_OrderDetail` |
| Icon | `ico_` + Name | `ico_Back`, `ico_Menu` |
| Component | `cmp_` + Name | `cmp_Header`, `cmp_NavBar` |

Reference: https://learn.microsoft.com/power-apps/guidance/coding-guidelines/overview

---

## Power Fx rules

> **For consultants:** Power Apps has a "delegation" limit — by default it only retrieves
> 500 records from a data source (max 2000). Certain formulas bypass this limit and send
> the filter to Dataverse/SharePoint instead. Always use delegatable formulas.

### Delegation — always check

- `Filter(Table, Column = value)` — delegated ✓
- `Filter(Table, Left(Column, 3) = "ABC")` — NOT delegated ✗
- `Search(Table, text, "Column")` — delegation depends on connector; use `StartsWith` instead
- `Sort(Table, Column)` — delegated for indexed columns ✓
- `SortByColumns(Table, "Column", Ascending)` — preferred form ✓

Always prefer `StartsWith()` over `Left()` / `Mid()` for text filtering.

Reference: https://learn.microsoft.com/en-us/power-apps/maker/canvas-apps/delegation-overview
Delegation list by connector: https://learn.microsoft.com/en-us/power-apps/maker/canvas-apps/delegation-list

### Performance

- Use `Concurrent()` for all independent data calls at `App.OnStart` or `OnVisible`
- Minimize `App.OnStart` — defer non-critical data to `OnVisible`
- Use `With()` to avoid repeating the same calculation multiple times on one screen
- Never call `ClearCollect` or `Collect` inside a `ForAll` loop — batch in one operation
- Retrieve only the columns you need — avoid `ShowColumns` workarounds; use views in Dataverse

Reference: https://learn.microsoft.com/power-apps/maker/canvas-apps/create-performant-apps-overview
Reference: https://learn.microsoft.com/power-apps/maker/canvas-apps/fast-app-page-load

### Forbidden patterns

- No `UpdateContext` or `Set` inside a Gallery item — this triggers re-render loops
- No `ClearCollect` where delegation is sufficient — use server-side filtering
- No formulas that load the full table and then filter locally
- No circular references between controls

---

## Documentation requirements

Every screen must have a comment block at the top (use a Label set to invisible, or app comments):

```
Screen: scrOrderList
Purpose: Displays all active orders for the current user's region
Data sources: Orders (Dataverse), Users (Dataverse)
Global variables read: varCurrentUser, varRegion
Collections written: colOrders
Navigation from: scrHome (btn_Orders)
Navigation to: scrOrderDetail (gal_Orders OnSelect)
```

All formulas over 3 lines must have an inline comment explaining **why**, not what.

---

## Code optimization rules

- No unused controls on any screen (every control increases render time)
- No duplicate formulas — move to `App.Formulas` if used 2+ times
- No `Set()` or `UpdateContext()` for values that are never read
- No collections containing a single record — use a variable
- No commented-out code
- Maximum one level of nesting in `If()` chains — use `Switch()` instead

---

## References

| Topic | URL |
|-------|-----|
| Coding guidelines | https://learn.microsoft.com/power-apps/guidance/coding-guidelines/overview |
| Performance overview | https://learn.microsoft.com/power-apps/maker/canvas-apps/create-performant-apps-overview |
| Delegation overview | https://learn.microsoft.com/en-us/power-apps/maker/canvas-apps/delegation-overview |
| Delegation list | https://learn.microsoft.com/en-us/power-apps/maker/canvas-apps/delegation-list |
| Optimize page loads | https://learn.microsoft.com/power-apps/maker/canvas-apps/fast-app-page-load |
| Accessible canvas apps | https://learn.microsoft.com/en-us/power-apps/maker/canvas-apps/accessible-apps |
| Power Fx formula reference | https://learn.microsoft.com/en-us/power-platform/power-fx/formula-reference-canvas-apps |
| Concurrent function | https://learn.microsoft.com/en-us/power-platform/power-fx/reference/function-concurrent |
| Monitor tool | https://learn.microsoft.com/en-us/power-apps/maker/monitor-overview |
| Solution checker | https://learn.microsoft.com/en-us/power-apps/maker/data-platform/use-powerapps-checker |
| Power CAT Toolkit | https://marketplace.microsoft.com/product/dynamics-365/microsoftpowercatarch.powercattools |
| Coding standards PDF (2024) | https://www.microsoft.com/power-platform/blog/wp-content/uploads/2024/06/PowerApps-canvas-app-coding-standards-and-guidelines.pdf |
