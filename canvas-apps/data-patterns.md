# Data Patterns for Canvas Apps

---

## For consultants

How your Canvas App talks to its data sources is the most consequential architectural decision you will make. The wrong pattern here causes silent data truncation (delegation), slow load times (retrieving all columns instead of only needed ones), confusing UX (no error feedback when a write fails), and data integrity issues (using the wrong write method for the scenario).

This document covers the canonical patterns for Dataverse and SharePoint connectors, write operations, error handling, lookups, and pagination. Apply these patterns on every engagement — they map directly to checklist gates.

**Reference:** [Optimized query data patterns](https://learn.microsoft.com/power-apps/maker/canvas-apps/optimized-query-data-patterns)

---

## Technical specification

### 1. Dataverse vs SharePoint — key differences

| Concern                          | Dataverse                                                        | SharePoint                                                        |
|----------------------------------|------------------------------------------------------------------|-------------------------------------------------------------------|
| Delegation support               | Full — Filter, Search, Sort, CountIf, Sum, Min, Max, Average     | Partial — Filter and Sort delegatable on indexed columns only     |
| Row limit behaviour              | Delegation eliminates the row limit for supported predicates     | Non-delegated queries capped at 500–2000 rows                     |
| Column retrieval                 | Returns only explicitly selected columns when using `ShowColumns` / explicit column references | Returns all columns by default — must use `ShowColumns` or column selection to narrow |
| Views                            | Dataverse views can be referenced directly as table filters       | SharePoint views not natively accessible as Power Apps filters     |
| Relationships / lookups          | Native relate/unrelate, polymorphic lookups, choices columns     | Manual lookup via separate list; no referential integrity         |
| Offline / caching                | Supported with Power Apps offline profile                        | Not supported                                                     |
| Transactions / rollback          | Supported via Dataverse API; not exposed natively in Power Fx    | Not supported                                                     |
| Governance and auditing          | Column-level security, audit log, DLP policies                   | SharePoint permissions model only                                 |

> **Rule:** for any app storing business data, prefer Dataverse. Use SharePoint only when the data already lives there or when Dataverse licensing is not in scope — and document this explicitly in the solution.

---

### 2. Column selection — only retrieve what you need

By default, most connectors return all columns for every row in a `Filter` or `Gallery` binding. This increases payload size, slows load times, and in Dataverse can cause implicit joins across related tables.

#### Anti-pattern: binding a gallery to an unfiltered table expression

```powerfx
// Retrieves ALL columns for ALL rows — slow, wasteful.
galOrders.Items = Orders
```

#### Correct pattern: explicit column selection

```powerfx
// Returns only the columns the gallery actually displays.
galOrders.Items = ShowColumns(
    Filter(Orders, Status <> "Cancelled"),
    "OrderNumber", "CustomerName", "OrderDate", "TotalAmount", "Status"
)
```

In Dataverse, use the **column selection** feature in the connector panel (Power Apps Studio > Data > select table > choose columns) in addition to `ShowColumns` in formulas. Connector-level column selection prevents the API call from fetching unneeded columns at all.

---

### 3. Server-side vs client-side filtering

**Server-side filtering** means the filter predicate is sent to the data source (delegated). The server returns only matching rows.

**Client-side filtering** means Power Apps downloads the row limit worth of records and then filters them in the browser. If the matching records fall outside the downloaded set, they are silently missing.

| Approach             | When the filter runs | Row limit applies | Correct usage                                      |
|----------------------|----------------------|-------------------|----------------------------------------------------|
| Server-side (delegated) | At the data source | No               | All production filter logic on large tables        |
| Client-side (non-delegated) | In the browser | Yes (500–2000)  | Only acceptable on small, bounded tables (< 500 rows) |

**Pattern: pre-filter with a delegated predicate, then refine locally**

When you need a non-delegatable function (e.g., `EndsWith`, `Lower`), apply a delegatable coarse filter first to reduce the result set, then apply the fine filter locally:

```powerfx
// Step 1 — delegatable: narrows to a manageable set.
ClearCollect(
    colActiveOrders,
    Filter(Orders, Status = "Active", AssignedRegion = varUserRegion)
);

// Step 2 — non-delegatable applied to local collection, which is small.
galOrders.Items = Filter(colActiveOrders, EndsWith(ReferenceCode, varSuffix))
```

---

### 4. Patch() vs EditForm — when to use each

| Scenario                                               | Recommended method  | Reason                                                                  |
|--------------------------------------------------------|---------------------|-------------------------------------------------------------------------|
| User fills in a form with multiple fields               | `EditForm` / `SubmitForm` | Handles validation, dirty state, field binding, and error display automatically |
| Programmatic write of one or a few specific fields      | `Patch()`           | Precise control; does not require a Form control to be present          |
| Creating a new record from formula logic (e.g., button) | `Patch(DataSource, Defaults(DataSource), { field: value })` | Clean creation pattern without a form |
| Bulk update of multiple records                         | `Patch(DataSource, colTable)` | Single batched API call                                                |
| Write that depends on complex conditional logic          | `Patch()` with `IfError()` | Full formula control; EditForm does not support conditional field mapping easily |

**EditForm write (standard pattern):**

```powerfx
// btnSave.OnSelect
SubmitForm(frmEditOrder);
// Form's OnSuccess:
Navigate(scrOrderList, ScreenTransition.Fade);
// Form's OnFailure:
Notify(frmEditOrder.Error, NotificationType.Error);
```

**Patch write (programmatic pattern):**

```powerfx
// btnApprove.OnSelect
Patch(
    Orders,
    LookUp(Orders, OrderID = varSelectedOrderID),
    {
        Status: "Approved",
        ApprovedBy: varCurrentUser.Email,
        ApprovedDate: Now()
    }
);
```

---

### 5. Error handling for Patch() using IfError()

`Patch()` does not surface errors to the user automatically. Wrap every `Patch()` call in `IfError()` to capture failures and provide user feedback.

```powerfx
// Full error-handling pattern for Patch()
IfError(
    Patch(
        Orders,
        LookUp(Orders, OrderID = varSelectedOrderID),
        {
            Status: "Submitted",
            SubmittedBy: varCurrentUser.Email,
            SubmittedDate: Now()
        }
    ),
    // Error branch — FirstError contains details of what went wrong.
    Notify(
        "Save failed: " & FirstError.Message,
        NotificationType.Error
    );
    false,  // propagate failure signal to calling context if needed
    // Success branch
    Notify("Order submitted successfully.", NotificationType.Success);
    Navigate(scrOrderList, ScreenTransition.Fade)
)
```

**Key points:**
- `FirstError.Message` contains the human-readable error text from the connector.
- `FirstError.Kind` contains the error category (e.g., `ErrorKind.Network`, `ErrorKind.Validation`).
- The success branch (third argument) runs only if no error occurred.
- Always provide a `Notify()` in both branches so users know whether the operation succeeded or failed.

---

### 6. Lookup pattern — LookUp vs Filter for single records

Use `LookUp` when you need exactly one record matching a unique predicate. Use `Filter` when you may get multiple records.

| Goal                                      | Correct function                                     |
|-------------------------------------------|------------------------------------------------------|
| Retrieve a single record by primary key   | `LookUp(Table, PrimaryKey = value)`                  |
| Retrieve a single record by unique field  | `LookUp(Table, UniqueField = value)`                 |
| Retrieve all records matching a condition | `Filter(Table, condition)`                           |
| Check whether any record exists           | `!IsEmpty(Filter(Table, condition))` or `CountIf(Table, condition) > 0` (Dataverse) |

```powerfx
// LookUp — returns a record, not a table.
Set(varSelectedOrder, LookUp(Orders, OrderID = galOrders.Selected.OrderID));

// Filter — returns a table (use where you need multiple records).
ClearCollect(colOpenOrders, Filter(Orders, Status = "Open", Owner = varCurrentUser.Email));

// ANTI-PATTERN: using First(Filter(...)) instead of LookUp
// First(Filter(Orders, OrderID = varID))  — avoid; LookUp is clearer and equally delegatable.
```

---

### 7. Pagination with IsEmpty / LoadData pattern

Canvas Apps support lazy-loading / infinite scroll for galleries via the `LoadData` and `SaveData` functions, and via the `OnScrollEnd` gallery property combined with `IsEmpty` guards.

The standard pagination pattern for large Dataverse or SharePoint tables uses the gallery's built-in page size combined with a "Load more" button backed by a collection append:

```powerfx
// Screen.OnVisible — load the first page.
ClearCollect(
    colOrders,
    FirstN(
        Filter(Orders, Status = varStatusFilter),
        50
    )
);
Set(varAllLoaded, false);

// btnLoadMore.OnSelect — append the next page.
Collect(
    colOrders,
    FirstN(
        Filter(
            Orders,
            Status = varStatusFilter,
            Not(OrderID In colOrders.OrderID)   // exclude already loaded records
        ),
        50
    )
);
// Hide the button when no new records were returned.
If(CountRows(colOrders) Mod 50 <> 0, Set(varAllLoaded, true));

// btnLoadMore.Visible
!varAllLoaded

// galOrders.Items
colOrders
```

**Alternative: IsEmpty guard before appending**

```powerfx
// Only show "Load more" if the last fetch returned a full page.
btnLoadMore.Visible = !varAllLoaded && !IsEmpty(colOrders)
```

> Note: `FirstN` is not delegatable for all connectors. On Dataverse, use `Filter` with server-side paging or Dataverse views to keep queries delegated. For SharePoint with large lists, implement indexed column filters to keep the base `Filter` delegated before applying `FirstN` locally.

---

### 8. Summary checklist

- [ ] All `Filter` / `LookUp` predicates are delegatable (no blue underlines)
- [ ] Only required columns retrieved from data sources (column selection applied)
- [ ] `Patch()` calls wrapped in `IfError()` with `Notify()` in both branches
- [ ] `EditForm` / `SubmitForm` used for user-facing multi-field forms
- [ ] `LookUp` used for single-record retrieval (not `First(Filter(...))`)
- [ ] Pagination implemented for galleries bound to tables with more than 500 rows
- [ ] Dataverse preferred over SharePoint for new business data storage
