# PCF Code Components: API and WebAPI Scalability Patterns

---

## For consultants

> A PCF component runs inside the browser as part of a Canvas or Model-driven app. Every
> time the component calls Dataverse through `context.webAPI`, it uses the same API quota
> as the rest of the app and the user session. Expensive or frequent calls slow down the
> whole page and can trigger "Too Many Requests" errors for the end user.
>
> The key rule: fetch only what you render, filter on the server, and call the API as
> infrequently as possible. The PCF framework already provides most of the data you need
> through bound properties — call `context.webAPI` only for data the framework cannot provide.

---

## Technical specification

### When NOT to use context.webAPI

Before writing a `context.webAPI` call, check whether the framework already provides the data:

| Data needed | Preferred source |
|-------------|-----------------|
| The value of a bound column | `context.parameters.<propertyName>.raw` |
| Related records in a dataset component | `context.parameters.dataset.records` |
| Current user info | `context.userSettings` |
| Environment / org info | `context.orgSettings` |
| Records of the same table already loaded by the form | Use `context.parameters` dataset or output properties |

**Only use `context.webAPI` for data that is genuinely not available through bound properties.**

Reference: https://learn.microsoft.com/power-apps/developer/component-framework/code-components-best-practices#limit-size-and-frequency-of-calls-to-the-webapi

---

### Dataverse service protection limits

PCF components call the same Dataverse endpoints as any other client. The same limits apply:

| Limit | Value (per user, per 5-minute window) |
|-------|--------------------------------------|
| Number of requests | 6,000 |
| Combined execution time | 20 minutes |
| Concurrent requests | 52 |

Each `context.webAPI.retrieveMultipleRecords()` call counts as one request. A gallery or
form that renders 20 PCF components — each making one API call — triggers 20 requests on
every `updateView`.

Reference: https://learn.microsoft.com/en-us/power-apps/developer/data-platform/api-limits

---

### WebAPI query rules — mandatory for every retrieveMultipleRecords call

```typescript
// ✗ WRONG: no select, no filter, no page size — fetches every column of every record
const result = await context.webAPI.retrieveMultipleRecords('account');

// ✓ CORRECT: select only needed columns, filter server-side, cap page size
const result = await context.webAPI.retrieveMultipleRecords(
  'account',
  '?$select=name,emailaddress1,telephone1' +
  '&$filter=statecode eq 0' +
  '&$top=50' +
  '&$orderby=name asc,accountid asc'
);
```

| OData option | Rule |
|---|---|
| `$select` | Always list only the columns rendered by the component |
| `$filter` | Always filter server-side — never fetch all and filter in JS |
| `$top` | Always cap the result — default returns up to 5,000 rows |
| `$orderby` | Always include a unique column for deterministic pagination |

---

### Call frequency rules

#### Never call webAPI inside updateView without a guard

`updateView` is called every time any bound property changes. A network call on every
`updateView` is a fast path to hitting rate limits.

```typescript
// ✗ WRONG: API call on every updateView
public updateView(context: ComponentFramework.Context<IInputs>): void {
  context.webAPI.retrieveMultipleRecords('account', '?$select=name&$top=10')
    .then(result => this.setState(result.entities));
}

// ✓ CORRECT: guard with updatedProperties; call only when relevant input changed
public updateView(context: ComponentFramework.Context<IInputs>): void {
  const updated = context.updatedProperties;

  // Only re-fetch when the filter input actually changed
  if (!updated.includes('filterValue') && this.dataLoaded) return;

  this.dataLoaded = true;
  context.webAPI.retrieveMultipleRecords(
    'account',
    `?$select=name,accountid` +
    `&$filter=statecode eq 0 and startswith(name,'${context.parameters.filterValue.raw}')` +
    `&$top=50` +
    `&$orderby=name asc,accountid asc`
  ).then(result => {
    this.cachedData = result.entities;
    this.renderComponent(context);
  });
}
```

#### Debounce user-triggered API calls

```typescript
private searchDebounceTimer: number | null = null;

private onSearchInput(value: string): void {
  if (this.searchDebounceTimer) window.clearTimeout(this.searchDebounceTimer);

  // Wait 300ms after the user stops typing before calling the API
  this.searchDebounceTimer = window.setTimeout(() => {
    this.fetchRecords(value);
  }, 300);
}
```

#### Do not call the API more than once per distinct input change

Cache the last query parameters and skip the call if nothing changed:

```typescript
private lastFilter: string | null = null;

private fetchRecords(filter: string): void {
  if (filter === this.lastFilter) return; // same query — skip
  this.lastFilter = filter;

  context.webAPI.retrieveMultipleRecords(
    'account',
    `?$select=name,accountid&$filter=${encodeURIComponent(filter)}&$top=50`
  ).then(/* ... */);
}
```

---

### notifyOutputChanged — debounce it

Every call to `notifyOutputChanged` triggers a re-evaluation of the host app's formulas.
On a busy form with many controls this is expensive.

```typescript
// ✗ WRONG: calls notifyOutputChanged on every keystroke
private onInputChange(value: string): void {
  this.currentValue = value;
  this.notifyOutputChanged(); // fires on every character
}

// ✓ CORRECT: debounce to call only when the user has finished typing
private debounceTimer: number | null = null;

private onInputChange(value: string): void {
  this.currentValue = value;

  if (this.debounceTimer) window.clearTimeout(this.debounceTimer);
  this.debounceTimer = window.setTimeout(() => {
    this.notifyOutputChanged();
  }, 300);
}
```

Reference: https://learn.microsoft.com/power-apps/developer/component-framework/code-components-best-practices#minimize-calls-to-notifyoutputchanged

---

### Pagination for dataset components

Dataset components receive records through `context.parameters.dataset`. Use the framework's
built-in paging — do not implement your own by calling `webAPI.retrieveMultipleRecords` for
each page.

```typescript
// Load the next page using the dataset API
public loadNextPage(): void {
  if (this.context.parameters.dataset.paging.hasNextPage) {
    this.context.parameters.dataset.paging.loadNextPage();
    // updateView will be called with the new page of records
  }
}

// Load the previous page
public loadPreviousPage(): void {
  if (this.context.parameters.dataset.paging.hasPreviousPage) {
    this.context.parameters.dataset.paging.loadPreviousPage();
  }
}
```

---

### Calling Azure Functions from a PCF component

PCF components can call external APIs through `context.webAPI` is not available in canvas,
or through a custom connector when embedded in a canvas app. Direct `fetch()` to Azure Functions
is technically possible but requires careful handling.

**Rules:**

1. **Never hardcode function URLs or keys** — use an input property to receive the endpoint
2. **Always use HTTPS** — never plain HTTP
3. **Always handle errors** — catch network failures and surface them via the UI, not `console.error`
4. **Never call in a loop per record** — batch the payload into a single call
5. **Check `context.webAPI` availability before use** — it is not available in canvas apps

```typescript
// ✗ WRONG: hardcoded URL, no error handling, called per record
for (const record of records) {
  await fetch('https://myfunc.azurewebsites.net/api/process?code=ABC123', {
    method: 'POST',
    body: JSON.stringify({ id: record.id }),
  });
}

// ✓ CORRECT: URL from input property, batched, error-handled
private async processRecords(records: IRecord[]): Promise<void> {
  const endpoint = this.context.parameters.functionEndpoint.raw;
  if (!endpoint) {
    this.setError('Function endpoint is not configured.');
    return;
  }

  try {
    const response = await fetch(endpoint, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ ids: records.map(r => r.id) }), // batched
    });

    if (!response.ok) {
      throw new Error(`Function returned ${response.status}`);
    }

    this.setData(await response.json());
  } catch (error) {
    this.setError(`Failed to process records: ${(error as Error).message}`);
  }
}
```

---

### AI scalability red flags — push back immediately

| Request | Problem | Correct approach |
|---|---|---|
| `retrieveMultipleRecords` without `$select` | Returns every column — execution time burns fast | Add `$select` with only the needed columns |
| `retrieveMultipleRecords` without `$filter` | Fetches entire table | Add server-side `$filter` |
| `retrieveMultipleRecords` without `$top` | Up to 5,000 rows by default | Add `$top` ≤ 50 for UI lists |
| API call inside `updateView` without `updatedProperties` guard | Calls on every property change | Guard with `context.updatedProperties.includes(...)` |
| `notifyOutputChanged` on every keystroke | Floods the host app with recalculations | Debounce to fire only after input is stable |
| `fetch()` in a loop per record | O(n) requests — hits limits immediately | Batch into a single request |
| Direct `fetch()` to Azure Function with hardcoded URL | Not portable, not secure | Use a connector or receive the URL via an input property |

---

### References

| Topic | URL |
|-------|-----|
| PCF best practices — WebAPI | https://learn.microsoft.com/power-apps/developer/component-framework/code-components-best-practices#limit-size-and-frequency-of-calls-to-the-webapi |
| PCF best practices — notifyOutputChanged | https://learn.microsoft.com/power-apps/developer/component-framework/code-components-best-practices#minimize-calls-to-notifyoutputchanged |
| Dataverse service protection limits | https://learn.microsoft.com/en-us/power-apps/developer/data-platform/api-limits |
| OData query overview | https://learn.microsoft.com/power-apps/developer/data-platform/webapi/query/overview |
| Select columns ($select) | https://learn.microsoft.com/power-apps/developer/data-platform/webapi/query/select-columns |
| Page results | https://learn.microsoft.com/power-apps/developer/data-platform/webapi/query/page-results |
| Query anti-patterns | https://learn.microsoft.com/power-apps/developer/data-platform/query-antipatterns |
| Interact with HTTP resources asynchronously | https://learn.microsoft.com/en-us/powerapps/developer/model-driven-apps/best-practices/business-logic/interact-http-https-resources-asynchronously |
| updatedProperties reference | https://learn.microsoft.com/power-apps/developer/component-framework/reference/updatedproperties |
| Dataset paging | https://learn.microsoft.com/power-apps/developer/component-framework/reference/paging |
