# Naming Conventions for Canvas Apps

---

## For consultants

Consistent naming in Canvas Apps is not just a style preference — it is a prerequisite for maintainable apps, effective peer reviews, and reliable AI-assisted development. Microsoft's official guidance defines a prefix-based system where every control type, variable, screen, and collection carries a short prefix that makes its purpose immediately obvious without opening it.

When controls and variables are named correctly, Power Apps Studio's IntelliSense works better, AI tools like Copilot can reason about your app more accurately, and anyone reading the formula bar can tell at a glance what `varUserEmail` is versus what `colFilteredProducts` is.

The rule of thumb is simple: **prefix first, then a descriptive PascalCase name**. Never leave default names such as `Button1`, `Label3`, or `DataTable1` in a delivered app.

**Source:** [Microsoft Power Apps coding guidelines](https://learn.microsoft.com/power-apps/guidance/coding-guidelines/overview)

---

## Technical specification

### 1. Control prefix table

The following prefixes are defined in Microsoft's official Power Apps coding guidelines. All control names must use the prefix followed by a PascalCase descriptor.

| Control type   | Prefix  | Example                      |
|----------------|---------|------------------------------|
| Button         | `btn`   | `btnSubmitForm`              |
| Label          | `lbl`   | `lblPageTitle`               |
| Text Input     | `txt`   | `txtSearchQuery`             |
| Gallery        | `gal`   | `galProductList`             |
| Form           | `frm`   | `frmEditEmployee`            |
| Icon           | `ico`   | `icoNavigateBack`            |
| Date Picker    | `dte`   | `dteInvoiceDate`             |
| Dropdown       | `drp`   | `drpStatusFilter`            |
| Toggle         | `tog`   | `togActiveStatus`            |
| Checkbox       | `chk`   | `chkAcceptTerms`             |
| Image          | `img`   | `imgCompanyLogo`             |
| Video          | `vid`   | `vidOnboardingClip`          |
| Timer          | `tim`   | `timSessionExpiry`           |
| ComboBox       | `cmb`   | `cmbDepartmentSelect`        |
| ListBox        | `lst`   | `lstAvailableRoles`          |
| Radio          | `rad`   | `radPriorityLevel`           |
| Rating         | `rat`   | `ratCustomerSatisfaction`    |
| Slider         | `sld`   | `sldBudgetRange`             |
| Component      | `cmp`   | `cmpNavigationHeader`        |

> Controls within a gallery or form should still carry their prefix. For clarity, consider appending a context suffix, e.g., `lblGalProductName` for a label inside a products gallery.

---

### 2. Variable naming conventions

| Variable type      | Prefix  | Example                        | Scope                                       |
|--------------------|---------|--------------------------------|---------------------------------------------|
| Global variable    | `var`   | `varCurrentUser`               | Set with `Set()`. Available across all screens. |
| Context variable   | `loc`   | `locIsLoading`                 | Set with `UpdateContext()`. Screen-scoped only. |
| Collection         | `col`   | `colSelectedItems`             | Set with `Collect()` / `ClearCollect()`. Global scope. |

**Rules:**
- Never use a bare noun (`user`, `loading`, `items`) as a variable name.
- Boolean variables should read as a predicate: `varIsAdmin`, `locFormDirty`, not `varAdmin` or `locDirty`.
- Collections should be plural nouns: `colInvoices`, not `colInvoice`.

---

### 3. Screen naming conventions

All screens use the `scr` prefix followed by a PascalCase name reflecting the screen's function.

| Example screen name       | Purpose                            |
|---------------------------|------------------------------------|
| `scrHome`                 | App landing/home screen            |
| `scrProductDetail`        | Detail view for a single record    |
| `scrEditEmployee`         | Edit form for employee records     |
| `scrSettings`             | User or admin settings             |
| `scrOnboarding`           | First-run onboarding flow          |

---

### 4. Why naming matters for AI-assisted development

Power Apps Copilot and external AI tools (including Claude Code) reason about your app through the names and structure visible in formulas and YAML source. When controls carry meaningful prefixed names:

- Formula suggestions reference `galOrderList` rather than `Gallery3`, producing readable and accurate output.
- Copilot's "explain this formula" feature produces accurate descriptions because control roles are encoded in names.
- YAML source files (`.pa.yaml`) are diff-readable in version control, and meaningful names make PR reviews tractable.
- The Solution Checker and Power CAT App Audit Tool flag default-named controls as issues; pre-named controls pass without noise.

---

### 5. Correct vs. incorrect naming examples

#### Controls

| Incorrect (default)  | Incorrect (no prefix) | Correct              |
|----------------------|-----------------------|----------------------|
| `Button1`            | `SubmitButton`        | `btnSubmitForm`      |
| `Label3`             | `TitleLabel`          | `lblPageTitle`       |
| `Gallery2`           | `ProductsGallery`     | `galProductList`     |
| `DataTable1`         | `OrdersTable`         | `tblOrderSummary`    |
| `TextInput1`         | `SearchBox`           | `txtSearchQuery`     |

#### Variables

| Incorrect            | Correct                    |
|----------------------|----------------------------|
| `userRecord`         | `varCurrentUser`           |
| `loading`            | `locIsLoading`             |
| `items`              | `colFilteredItems`         |
| `boolAdmin`          | `varIsAdmin`               |
| `SelectedDept`       | `locSelectedDepartment`    |

#### Screens

| Incorrect            | Correct               |
|----------------------|-----------------------|
| `Screen1`            | `scrHome`             |
| `EditScreen`         | `scrEditEmployee`     |
| `Detail`             | `scrOrderDetail`      |

---

### 6. Naming inside components

Components are reusable controls. Their internal controls should still follow the prefix table. Input and output properties of a component use PascalCase without a prefix, because they form a public API:

```
// Component: cmpStatusBadge
// Internal label:       lblBadgeText       (follows prefix rule)
// Custom input property: StatusText        (PascalCase, no prefix — it is a property)
// Custom output property: OnBadgePressed   (PascalCase, event-style)
```

---

### 7. Reference

- Microsoft Power Apps Coding Guidelines: https://learn.microsoft.com/power-apps/guidance/coding-guidelines/overview
