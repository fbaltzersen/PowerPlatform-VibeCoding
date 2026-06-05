# Screen Documentation Template

## For consultants

Copy the comment block below into the `OnVisible` property of each canvas app screen (as a comment above any formula), or paste it into the screen's description field.
Fill in every field. Leave a field blank only if it genuinely does not apply — use `None` in that case.
Update the block whenever the screen changes.

---

## How to use this template

1. Copy the block between the `---` markers below.
2. Paste it as a comment at the top of the screen's `OnVisible` property:

```
// ============================================================
// SCREEN: [paste block here]
// ============================================================
Set(ctxSomething, ...); // actual OnVisible formula starts here
```

3. Alternatively, paste it into the screen's **Description** property in the Properties pane.

---

## Comment block (copy from here)

```
// ============================================================
// SCREEN NAME:       [Screen display name, e.g. "Home Screen"]
// SCHEMA NAME:       [Internal name used in code, e.g. "scrHome"]
// ============================================================
//
// PURPOSE:
//   [1–3 sentences describing what this screen is for and
//    what the user accomplishes here.]
//
// DATA SOURCES READ:
//   - [DataSourceName] — [which table/list/entity, what is queried]
//   - [DataSourceName] — [which table/list/entity, what is queried]
//   (None)
//
// GLOBAL VARIABLES READ (Set by other screens):
//   - gbl[Name]  : [Type]  — [What it holds, where it is set]
//   - gbl[Name]  : [Type]  — [What it holds, where it is set]
//   (None)
//
// GLOBAL VARIABLES WRITTEN (Set on this screen):
//   - gbl[Name]  : [Type]  — [What value is set and when]
//   (None)
//
// CONTEXT VARIABLES (local to this screen):
//   - ctx[Name]  : [Type]  — [What it controls, e.g. "Controls dialog visibility"]
//   - ctx[Name]  : [Type]  — [What it controls]
//   (None)
//
// COLLECTIONS WRITTEN:
//   - col[Name]  — Source: [DataSource / formula]
//                  When: [OnVisible / on button press / etc.]
//                  Purpose: [Why this collection is needed]
//   (None)
//
// NAVIGATION SOURCES (screens that navigate TO this screen):
//   - [ScreenName] — via [button/link/Navigate call, e.g. "Back button"]
//   - [ScreenName] — via [trigger]
//   (None — entry point / app start)
//
// NAVIGATION TARGETS (screens this screen navigates TO):
//   - [ScreenName] — triggered by [button/action, e.g. "Save button"]
//   - [ScreenName] — triggered by [action]
//   (None — dead end / modal)
//
// DELEGATION NOTES:
//   [Describe any delegation limits relevant to this screen, e.g.
//    "Filter on [Column] is non-delegable; collection is capped at 2000 rows.
//     Pre-filtered by [DelegableColumn] to reduce the risk of data loss."]
//   (No delegation concerns on this screen)
//
// KNOWN ISSUES / WORKAROUNDS:
//   [Describe any open issues, platform limitations, or temporary workarounds
//    implemented on this screen. Include a link to the related ADR if applicable.]
//   (None)
//
// LAST UPDATED:  [YYYY-MM-DD]
// UPDATED BY:    [Name]
// ============================================================
```

---

## Field reference

| Field | Guidance |
|---|---|
| SCREEN NAME | The human-readable display name shown in the app navigation |
| SCHEMA NAME | The internal `scr` prefixed name used in `Navigate()` calls and formulas |
| PURPOSE | Business purpose — what the user does here, not what controls are present |
| DATA SOURCES READ | Every data source queried in `OnVisible`, gallery `Items`, or combo box `Items` on this screen |
| GLOBAL VARIABLES READ | Variables set by *other* screens and read here via `Set()` |
| GLOBAL VARIABLES WRITTEN | Variables this screen sets via `Set()` for consumption by other screens |
| CONTEXT VARIABLES | Variables set via `UpdateContext()` scoped to this screen only |
| COLLECTIONS WRITTEN | Collections populated via `Collect()` or `ClearCollect()` on this screen |
| NAVIGATION SOURCES | Which screens have a `Navigate(ThisScreen, ...)` call pointing here |
| NAVIGATION TARGETS | Which screens this screen navigates to, and what triggers the navigation |
| DELEGATION NOTES | Any non-delegable operations and the mitigation strategy used |
| KNOWN ISSUES | Open bugs, platform limitations, or temporary workarounds on this screen |
| LAST UPDATED | Date the screen or this block was last reviewed/modified |
| UPDATED BY | The name of the person who last updated the block |
