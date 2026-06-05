# Code Apps: API Scalability and Query Patterns

---

## For consultants

> Every call your Code App makes to Dataverse or an external API counts against a quota.
> Dataverse allows a maximum of **6,000 requests per 5-minute window per user** before
> returning a "429 Too Many Requests" error. On top of that, fetching all records from a
> large table can bring tens of thousands of rows to the browser, crash the app with memory
> pressure, and make every user wait while data loads.
>
> The rule is simple: **always filter, always paginate, always select only what you need.**
> When you connect to an Azure Function, always authenticate the call and never trust the input.

---

## Technical specification

### Dataverse service protection limits

Dataverse enforces three independent limits per user per 5-minute sliding window:

| Limit | Value |
|-------|-------|
| Number of requests | 6,000 |
| Combined execution time | 20 minutes (1,200 seconds) |
| Concurrent requests | 52 |

When a limit is exceeded, Dataverse returns `HTTP 429` with a `Retry-After` header indicating
how many seconds to wait. Client code must handle this response.

Reference: https://learn.microsoft.com/en-us/power-apps/developer/data-platform/api-limits

---

### OData query rules — mandatory for every list query

Every query against Dataverse **must** include all four of these:

| OData option | Rule | Why |
|---|---|---|
| `$select` | List only the columns your UI displays | Omitting returns every column — 50+ fields per row, hitting API execution limits fast |
| `$filter` | Always filter server-side | Never fetch all records and filter in the browser |
| `$top` or `maxpagesize` | Always cap the result | Dataverse returns up to 5,000 rows per request by default — unbounded queries cause memory pressure and slow UIs |
| `$orderby` | Always include a unique column (e.g., `entityid asc`) | Required for deterministic, overlap-free pagination |

References:
- https://learn.microsoft.com/power-apps/developer/data-platform/webapi/query/select-columns
- https://learn.microsoft.com/power-apps/developer/data-platform/webapi/query/page-results
- https://learn.microsoft.com/power-apps/developer/data-platform/query-antipatterns

---

### Scalable query pattern (React Query + generated service)

```typescript
// src/hooks/useAccountsPaged.ts
import { useInfiniteQuery } from '@tanstack/react-query';
import { DataverseService } from '../Services/DataverseService';

const PAGE_SIZE = 50;

export function useAccountsPaged(searchTerm?: string) {
  return useInfiniteQuery({
    queryKey: ['accounts', { searchTerm }],
    queryFn: ({ pageParam }) =>
      DataverseService.getAccounts({
        // 1. $select — only the columns needed in the list view
        select: ['accountid', 'name', 'emailaddress1', 'telephone1'],
        // 2. $filter — server-side; startswith() is delegatable
        filter: searchTerm
          ? `statecode eq 0 and startswith(name, '${searchTerm}')`
          : 'statecode eq 0',
        // 3. $top — cap the page size
        top: PAGE_SIZE,
        // 4. $orderby — unique column last for deterministic paging
        orderby: 'name asc,accountid asc',
        // 5. Cursor — use @odata.nextLink token from previous page
        skipToken: pageParam,
      }),
    // The next page token comes from @odata.nextLink in the response
    getNextPageParam: (lastPage) => lastPage.nextLink ?? undefined,
    initialPageParam: undefined,
  });
}
```

**Anti-pattern — never do this:**
```typescript
// ✗ WRONG: fetches every account in the environment, no filter, no column selection
const accounts = await DataverseService.getAccounts();
const filtered = accounts.filter(a => a.name.startsWith(search)); // client-side filter
```

---

### Pagination with @odata.nextLink

Dataverse does not support `$skip`. Use cursor-based pagination via `@odata.nextLink`.

```typescript
// Pattern: follow @odata.nextLink until it is absent
async function fetchAllPages<T>(
  firstPageFn: () => Promise<{ value: T[]; nextLink?: string }>
): Promise<T[]> {
  const all: T[] = [];
  let response = await firstPageFn();
  all.push(...response.value);

  while (response.nextLink) {
    // Use the nextLink URL directly — never modify or re-encode it
    response = await fetch(response.nextLink).then(r => r.json());
    all.push(...response.value);
  }
  return all;
}
```

> **Warning:** Fetching all pages is only appropriate for background data sync operations,
> not for UI list components. UI lists must use `useInfiniteQuery` with on-demand page loading.

---

### Handling 429 Too Many Requests

Always implement retry logic that respects the `Retry-After` header.

```typescript
// src/utils/retryWithBackoff.ts
export async function retryWithBackoff<T>(
  fn: () => Promise<T>,
  maxRetries = 3
): Promise<T> {
  for (let attempt = 0; attempt <= maxRetries; attempt++) {
    try {
      return await fn();
    } catch (error: unknown) {
      const isRateLimit =
        error instanceof Response && error.status === 429;

      if (!isRateLimit || attempt === maxRetries) throw error;

      // Respect the Retry-After header; fall back to exponential backoff
      const retryAfter =
        parseInt(error.headers.get('Retry-After') ?? '0', 10) ||
        Math.pow(2, attempt + 1);

      await new Promise((resolve) => setTimeout(resolve, retryAfter * 1000));
    }
  }
  throw new Error('Max retries exceeded');
}
```

Configure React Query to use this pattern globally:

```typescript
const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      retry: (failureCount, error) => {
        // Retry on 429; do not retry on 403 or 404
        if (error instanceof Response && error.status === 429) return failureCount < 3;
        return false;
      },
      retryDelay: (attemptIndex, error) => {
        if (error instanceof Response) {
          const retryAfter = parseInt(error.headers.get('Retry-After') ?? '0', 10);
          if (retryAfter > 0) return retryAfter * 1000;
        }
        return Math.pow(2, attemptIndex) * 1000;
      },
    },
  },
});
```

---

### Azure Function call patterns

When a Code App calls an Azure Function (via a custom connector or direct HTTP), apply the same
scalability discipline as for Dataverse calls.

#### Authentication — always required

Never call an Azure Function without authentication. Use the Power Platform custom connector
so the Power Apps host manages the OAuth token automatically. Do not call Azure Functions
directly with `fetch()` using a hardcoded key or URL.

```typescript
// ✓ CORRECT: call through the generated connector service
import { MyFunctionService } from '../Services/MyFunctionService';
const result = await MyFunctionService.processOrder({ orderId });

// ✗ WRONG: direct fetch with hardcoded URL and key
const result = await fetch(
  'https://myfunc.azurewebsites.net/api/processOrder?code=ABC123',
  { method: 'POST', body: JSON.stringify({ orderId }) }
);
```

#### Input validation

Azure Functions must validate all input server-side regardless of what the client sends.
Never trust the client-side TypeScript type system as a security boundary.

#### Avoid chatty call patterns

Do not call an Azure Function once per list item. Batch the work:

```typescript
// ✗ WRONG: one call per item in a loop
for (const item of items) {
  await MyFunctionService.processItem({ id: item.id });
}

// ✓ CORRECT: one batched call
await MyFunctionService.processItems({ ids: items.map(i => i.id) });
```

#### Idempotency for mutations

Azure Functions that create or modify data should be idempotent. Pass a client-generated
idempotency key so that retries do not create duplicate records:

```typescript
import { v4 as uuidv4 } from 'uuid';

const idempotencyKey = uuidv4(); // generate once per user action

await MyFunctionService.createOrder({
  orderId: newOrderData.id,
  payload: newOrderData,
  idempotencyKey, // Azure Function uses this to detect and skip duplicate requests
});
```

---

### AI scalability red flags — push back on these immediately

When a user asks for any of the following, Claude must **stop and propose a scalable alternative**
before writing any code:

| User request | Problem | Correct approach |
|---|---|---|
| "Fetch all accounts / contacts / orders" | Unbounded — can return tens of thousands of rows | Add `$filter`, `$top`, and `$select`; use pagination |
| "Get all records and filter in the component" | Client-side filtering on a full dataset | Move the filter to `$filter` (server-side) |
| "Load all data on app start" | Blocks the UI; wastes API quota on data that may never be viewed | Load data on demand when the relevant view is opened |
| "Call the API in a loop for each item" | O(n) API calls — hits rate limits instantly on large datasets | Batch the calls into one request |
| "Store the response in state and reuse it forever" | Stale data, no invalidation | Use React Query with appropriate `staleTime` and cache invalidation |
| "No `$select` needed — we'll use all the fields anyway" | 50+ columns per row, execution time limit burns fast | Only select what is rendered |
| "Use `$skip` for pagination" | Dataverse does not support `$skip` | Use `@odata.nextLink` cursor-based pagination |
| Any query without `$orderby` on a unique column | Non-deterministic pagination — same records may appear on multiple pages | Always include `accountid asc` or similar unique column as the final sort key |

---

### $expand — use with caution

`$expand` joins related tables in one request. Useful but expensive.

```typescript
// ✓ Acceptable: one level of expand, $select on the expanded entity
?$select=name,accountid&$expand=primarycontactid($select=fullname,emailaddress1)

// ✗ Expensive: nested expand without $select on expanded entity
?$expand=primarycontactid,Opportunity_account($expand=opportunityid)
```

Rules:
- Always `$select` on expanded entities — never expand all columns
- Never expand more than two levels deep
- If the expanded data is needed independently, fetch it as a separate query

---

### References

| Topic | URL |
|-------|-----|
| Dataverse service protection limits | https://learn.microsoft.com/en-us/power-apps/developer/data-platform/api-limits |
| OData query overview | https://learn.microsoft.com/power-apps/developer/data-platform/webapi/query/overview |
| Select columns ($select) | https://learn.microsoft.com/power-apps/developer/data-platform/webapi/query/select-columns |
| Filter rows ($filter) | https://learn.microsoft.com/power-apps/developer/data-platform/webapi/query/filter-rows |
| Page results (@odata.nextLink) | https://learn.microsoft.com/power-apps/developer/data-platform/webapi/query/page-results |
| Order rows ($orderby) | https://learn.microsoft.com/power-apps/developer/data-platform/webapi/query/order-rows |
| Query anti-patterns | https://learn.microsoft.com/power-apps/developer/data-platform/query-antipatterns |
| OData performance optimization | https://learn.microsoft.com/power-apps/developer/data-platform/webapi/query/optimize-performance |
