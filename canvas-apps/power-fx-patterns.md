# Power Fx Patterns, Delegation, and Performance

---

## For consultants

Power Fx is the formula language that drives Canvas Apps. Writing Power Fx well is the single biggest lever you have over app performance and maintainability. Two concerns dominate every formula you write:

1. **Delegation** — whether the data source executes a filter/sort on its server, or whether Power Apps downloads all records and filters locally (capped at 500–2000 rows by default).
2. **Efficiency** — whether formulas repeat expensive calculations, whether screens load data serially instead of in parallel, and whether collections are built in anti-patterns that silently corrupt data.

This document collects the canonical patterns from Microsoft's official performance and delegation guidance. Apply all of them before delivery.

**References:**
- [Delegation overview](https://learn.microsoft.com/en-us/power-apps/maker/canvas-apps/delegation-overview)
- [Create performant apps overview](https://learn.microsoft.com/power-apps/maker/canvas-apps/create-performant-apps-overview)
- [Concurrent() function reference](https://learn.microsoft.com/en-us/power-platform/power-fx/reference/function-concurrent)

---

## Technical specification

### 1. Delegation

#### What delegation is

When a Canvas App calls a data source (e.g., Dataverse, SharePoint), Power Apps can either:

- **Delegate** the query to the server — the server filters, sorts, and returns only matching rows. The app receives the result set regardless of its size.
- **Not delegate** — Power Apps retrieves up to the configured row limit (default 500, max 2000) from the data source first, then applies the formula locally in the browser/client.

Non-delegated queries silently return incomplete results when the data set exceeds the row limit. There is no error — the app simply works on a partial dataset. This is one of the most common bugs in delivered Canvas Apps.

A blue underline in the formula bar indicates a delegation warning. **All delegation warnings must be resolved before delivery.**

#### Delegatable vs non-delegatable functions (Dataverse and SharePoint)

| Function / operation                     | Dataverse    | SharePoint     | Notes                                                        |
|------------------------------------------|:------------:|:--------------:|--------------------------------------------------------------|
| `Filter` with simple column comparisons  | Delegatable  | Delegatable    | Column must be indexed in SharePoint for large lists         |
| `Search`                                 | Delegatable  | Delegatable    | SharePoint: text columns only                                |
| `Sort` / `SortByColumns`                 | Delegatable  | Delegatable    |                                                              |
| `LookUp` with simple predicates          | Delegatable  | Delegatable    |                                                              |
| `CountRows`                              | Delegatable  | Not delegatable| Use `CountIf` on Dataverse                                   |
| `CountIf`                                | Delegatable  | Not delegatable|                                                              |
| `Sum`, `Average`, `Min`, `Max`           | Delegatable  | Not delegatable| Dataverse only                                               |
| `StartsWith`                             | Delegatable  | Delegatable    |                                                              |
| `EndsWith`                               | Not delegatable | Not delegatable | Move to server-side computed column                        |
| `In` operator (text search)              | Not delegatable | Not delegatable |                                                            |
| `IsBlank` inside Filter                  | Not delegatable | Not delegatable | Use `= Blank()` instead on Dataverse                       |
| Complex nested `If` inside Filter        | Not delegatable | Not delegatable |                                                            |
| `Lower`, `Upper`, `Trim` inside Filter   | Not delegatable | Not delegatable | Normalise data at source instead                           |
| `First` / `Last`                         | Not delegatable | Not delegatable | Use `Filter` + `Sort` with `Top N` on Dataverse            |

> **Rule:** if your filter predicate calls any non-delegatable function, the entire `Filter` is non-delegatable. Break complex predicates into a delegatable primary filter that reduces the record count, then apply non-delegatable transformations on the smaller local result.

---

### 2. Concurrent() — parallel data loading

`Concurrent()` executes multiple formulas simultaneously. Use it in `App.OnStart` or `Screen.OnVisible` to load independent data sources in parallel rather than serially.

#### Without Concurrent (serial — slow)

```powerfx
// Each ClearCollect waits for the previous one to finish.
ClearCollect(colEmployees, Employees);
ClearCollect(colDepartments, Departments);
ClearCollect(colProjects, Projects);
```

If each call takes 800 ms, the screen waits 2 400 ms before becoming usable.

#### With Concurrent (parallel — fast)

```powerfx
Concurrent(
    ClearCollect(colEmployees, Employees),
    ClearCollect(colDepartments, Departments),
    ClearCollect(colProjects, Projects)
);
```

All three calls fire simultaneously. Total wait time is the slowest single call, not the sum.

**Rules for Concurrent():**
- Each argument must be independent (no argument should read data written by another argument in the same `Concurrent` call).
- Works with `Set()`, `ClearCollect()`, `Collect()`, `UpdateContext()`.
- Not supported in user event handlers that require sequential side-effects (e.g., a chain where step 2 depends on the result of step 1).

---

### 3. With() — avoiding duplicate calculations

`With()` binds the result of an expression to a named value within a local scope. Use it whenever a formula would otherwise compute the same sub-expression more than once.

#### Without With (repetitive — fragile)

```powerfx
// LookUp executes three times — three round trips to the data source.
If(
    LookUp(Orders, OrderID = varSelectedID).Status = "Approved",
    LookUp(Orders, OrderID = varSelectedID).ApprovedBy,
    LookUp(Orders, OrderID = varSelectedID).RequestedBy
)
```

#### With With (computed once — efficient)

```powerfx
With(
    { selectedOrder: LookUp(Orders, OrderID = varSelectedID) },
    If(
        selectedOrder.Status = "Approved",
        selectedOrder.ApprovedBy,
        selectedOrder.RequestedBy
    )
)
```

The lookup executes exactly once. `selectedOrder` is a local alias, not a variable — it does not pollute global or screen scope.

---

### 4. App.Formulas — centralising reusable logic

`App.Formulas` (introduced with named formulas) allows you to define expressions that are evaluated lazily and cached. Unlike `App.OnStart`, named formulas recalculate automatically when their dependencies change, and they do not execute until their value is first needed.

```powerfx
// In App.Formulas:
ActiveUserEmail = User().Email;
CurrentUserRecord = LookUp(SystemUsers, 'Primary Email' = ActiveUserEmail);
IsAdminUser = CurrentUserRecord.'System Administrator';
```

These can now be referenced anywhere in the app by name (`IsAdminUser`, `CurrentUserRecord`) without re-computing the lookup on every use.

**When to use App.Formulas vs App.OnStart:**

| Concern                              | App.Formulas                         | App.OnStart                                  |
|--------------------------------------|--------------------------------------|----------------------------------------------|
| Computed values derived from data    | Preferred — lazy, auto-refreshes     | Acceptable if result must be cached early    |
| ClearCollect into a collection       | Not supported                        | Required                                     |
| Set() a global variable              | Not supported                        | Required                                     |
| Expression used on multiple screens  | Preferred — single definition        | Use Set() to store in a global variable      |
| Authentication / user context        | Preferred                            | Acceptable                                   |

---

### 5. OnStart vs OnVisible loading strategy

| Property        | When it runs                                 | Use for                                                    |
|-----------------|----------------------------------------------|------------------------------------------------------------|
| `App.OnStart`   | Once when the app is launched                | App-wide data (user record, global config, master tables)  |
| `Screen.OnVisible` | Every time the screen becomes visible     | Screen-specific data that may have changed since last visit |

**Anti-pattern:** loading all data in `App.OnStart` makes initial load slow even for users who never visit certain screens. Load screen-specific data in `Screen.OnVisible` instead. Combine with a `locIsLoading` context variable and an overlay to prevent users from interacting with stale or empty data:

```powerfx
// Screen.OnVisible
UpdateContext({ locIsLoading: true });
ClearCollect(colScreenData, Filter(Orders, AssignedTo = varCurrentUser.Email));
UpdateContext({ locIsLoading: false });
```

---

### 6. ForAll anti-patterns

`ForAll` iterates over a table and executes a formula for each row. It is frequently misused.

#### Never use ClearCollect inside ForAll

```powerfx
// WRONG — ClearCollect clears the collection on every iteration.
ForAll(
    colSourceItems,
    ClearCollect(colResult, { ID: ThisRecord.ID, Name: ThisRecord.Name })
)
// Result: colResult contains only the last row.
```

```powerfx
// CORRECT — Clear once, then Collect inside ForAll.
Clear(colResult);
ForAll(
    colSourceItems,
    Collect(colResult, { ID: ThisRecord.ID, Name: ThisRecord.Name })
)
```

Better still — if the transformation is a pure column mapping, use `AddColumns` or build the table inline without ForAll:

```powerfx
// BEST — no loop, no collection mutation.
ClearCollect(
    colResult,
    AddColumns(colSourceItems, "DisplayName", Upper(Name))
)
```

#### ForAll is not guaranteed to be sequential

Do not rely on ForAll to process rows in a specific order for side-effects (e.g., numbering). Power Apps may batch or parallelise iterations internally.

#### Avoid Patch inside ForAll for large datasets

Each `Patch` inside `ForAll` sends an individual API call. For bulk writes, prefer `Patch(DataSource, colItemsToWrite)` with a table argument, which batches the operation.

```powerfx
// AVOID for large sets — N API calls
ForAll(colItems, Patch(Orders, LookUp(Orders, ID = ThisRecord.ID), { Status: "Closed" }));

// PREFER — single batched call
Patch(Orders, colItemsWithUpdates);
```

---

### 7. Switch() vs nested If()

For multi-branch logic on a single expression, `Switch()` is more readable and slightly more efficient than deeply nested `If()`.

#### Nested If (hard to read, error-prone)

```powerfx
If(
    varStatus = "New", "badge-blue",
    If(
        varStatus = "InProgress", "badge-yellow",
        If(
            varStatus = "Closed", "badge-green",
            "badge-grey"
        )
    )
)
```

#### Switch (clear, maintainable)

```powerfx
Switch(
    varStatus,
    "New",        "badge-blue",
    "InProgress", "badge-yellow",
    "Closed",     "badge-green",
                  "badge-grey"   // default
)
```

Use `If()` for boolean/conditional logic. Use `Switch()` when branching on the value of a single expression with three or more cases.

---

### 8. Summary checklist

- [ ] No delegation warnings (blue underlines) in any formula
- [ ] `App.OnStart` wraps independent `ClearCollect` calls in `Concurrent()`
- [ ] Screen-specific data loaded in `Screen.OnVisible`, not `App.OnStart`
- [ ] Repeated sub-expressions replaced with `With()` or named formulas in `App.Formulas`
- [ ] No `ClearCollect` inside `ForAll`
- [ ] `Patch(DataSource, table)` used for bulk writes instead of `Patch` inside `ForAll`
- [ ] `Switch()` used instead of deeply nested `If()` for multi-case value logic
