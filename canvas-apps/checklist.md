# Pre-Delivery Quality Checklist — Canvas Apps

---

## For consultants

Run through this checklist before handing over any Canvas App to a client or moving it to production. The "Before delivery" section contains hard gates — items that must all pass before the app ships. The "Recommended" section contains quality improvements that significantly raise long-term maintainability, but which may be deferred with documented justification.

This checklist aligns with Microsoft's official coding guidelines, the Power CAT App Audit Tool, and the Power Platform Solution Checker.

---

## Before delivery (mandatory gates)

These items must all be completed. A "no" on any mandatory gate blocks delivery.

### Solution and environment

- [ ] App is in a named, managed-ready Solution — not the Default solution
- [ ] Connection references used throughout the solution (no hardcoded connector instances)
- [ ] Solution Checker has been run; zero critical issues, zero high-severity rule violations

### Naming and structure

- [ ] All controls follow the official prefix naming standard (btn, lbl, txt, gal, frm, ico, dte, drp, tog, chk, img, vid, tim, cmb, lst, rad, rat, sld, cmp)
- [ ] All screens use the `scr` prefix with a PascalCase descriptor
- [ ] All global variables use the `var` prefix, context variables use `loc`, collections use `col`
- [ ] No controls, variables, or collections left with default names (e.g., Button1, Label3, Collection1)
- [ ] No unused controls remaining on any screen
- [ ] No unused variables or collections defined anywhere in the app
- [ ] No commented-out code left in any formula

### Power Fx and performance

- [ ] Zero delegation warnings in any formula across all screens (no blue underlines in the formula bar)
- [ ] `App.OnStart` wraps all independent data-loading calls in `Concurrent()`
- [ ] No hardcoded text strings visible to end users (use variables, collections, or a translations table)
- [ ] No hardcoded URLs or environment-specific identifiers in formulas

### Data and writes

- [ ] Only necessary columns retrieved from each data source (column selection applied at connector and formula level)
- [ ] All `Patch()` calls wrapped in `IfError()` with user-facing `Notify()` in both success and error branches

### Screens and documentation

- [ ] Every screen has a comment block in its `OnVisible` or as a label set to `Visible = false`, documenting: purpose, data sources used, and variables written or read
- [ ] Responsive layout tested and confirmed functional on all target device types and orientations (as specified in the project scope)

### Accessibility

- [ ] All interactive controls (buttons, inputs, toggles, checkboxes, dropdowns, icons used as buttons) have a non-empty `AccessibleLabel` property
- [ ] Tab order (`TabIndex`) is logical and matches the visual reading order on every screen

---

## Recommended (quality improvements)

These items are not hard gates, but each one raised here represents a known source of bugs, maintenance burden, or user experience degradation. Deviations should be documented in the solution's handover notes.

### Architecture

- [ ] `App.Formulas` used for computed values reused across multiple screens (instead of recomputing in each screen's `OnVisible`)
- [ ] Screen-specific data loaded in `Screen.OnVisible` rather than all in `App.OnStart`, to reduce initial load time
- [ ] Components used for repeated UI patterns (navigation bars, headers, status badges, confirmation dialogs)
- [ ] Custom component properties (input/output) follow PascalCase naming and are documented in the component's description field

### Power Fx quality

- [ ] `With()` used to avoid computing the same sub-expression more than once in a single formula
- [ ] `Switch()` used instead of nested `If()` for multi-case value branching (three or more cases)
- [ ] No `ClearCollect()` inside `ForAll()` — use `Clear()` before the loop or a table expression instead
- [ ] `Patch(DataSource, table)` used for bulk writes instead of `Patch()` inside `ForAll()`

### Data

- [ ] `LookUp` used for single-record retrieval instead of `First(Filter(...))`
- [ ] Pagination or "Load more" pattern implemented for all galleries bound to tables that may exceed 500 rows
- [ ] Dataverse used as the primary data store for new business data (SharePoint use documented with justification if chosen)

### Error handling and resilience

- [ ] `EditForm` / `SubmitForm` used for all multi-field user-facing forms (with `OnFailure` wired to `Notify`)
- [ ] Loading states (`locIsLoading`) used on screens that fetch data on `OnVisible`, with an overlay or spinner preventing interaction during load
- [ ] App tested with a user account that has the minimum required permissions (not the maker account)

### Maintainability

- [ ] Environment variable or a configuration SharePoint list / Dataverse table used for values that differ between environments (base URLs, feature flags, lookup identifiers)
- [ ] All custom components have a `Description` property filled in explaining purpose and usage
- [ ] Solution version incremented and release notes added before each delivery

---

## Sign-off

| Role              | Name | Date | Status |
|-------------------|------|------|--------|
| Developer         |      |      |        |
| Technical reviewer|      |      |        |
| Client acceptance |      |      |        |
