# Code Apps: Connector Patterns

---

## For consultants

Connectors are how your Code App talks to data. Instead of calling APIs directly, you declare which data sources the app needs, and the platform generates typed TypeScript service classes for you. Your React code then calls those generated services — never raw `fetch` or `axios` calls to external endpoints.

**The key things to remember:**

1. **Add data sources with a CLI command, not by writing code.** Running `pac code add-data-source` (or the npm CLI equivalent) updates `power.config.json` and regenerates the `src/Services/` and `src/Models/` folders automatically.

2. **Never edit `src/Services/` or `src/Models/` by hand.** They are overwritten every time you regenerate. Put all custom logic in your own files and import the generated services.

3. **Always use connection references, not direct connections.** Connection references allow the app to be moved between environments (dev → test → prod) without re-wiring connectors. This is an ALM requirement, not optional.

4. **The `pac code` commands are being deprecated.** From `@microsoft/power-apps` v1.0.4 onwards, use the npm CLI instead. The examples in this document show both.

**Supported connector types (examples):**
- Microsoft Dataverse
- SharePoint
- Azure SQL
- Azure Blob Storage
- Any certified or custom connector available in the environment

---

## Technical specification

### Adding a data source

#### Using PAC CLI (legacy, being deprecated)

```bash
# Dataverse
pac code add-data-source \
  --environment <environment-id> \
  --connector /providers/Microsoft.PowerApps/apis/shared_commondataservice

# SharePoint
pac code add-data-source \
  --environment <environment-id> \
  --connector /providers/Microsoft.PowerApps/apis/shared_sharepointonline

# Azure SQL
pac code add-data-source \
  --environment <environment-id> \
  --connector /providers/Microsoft.PowerApps/apis/shared_sql
```

#### Using npm CLI (preferred, v1.0.4+)

```bash
npx @microsoft/power-apps add-data-source \
  --environment <environment-id> \
  --connector <connector-id>
```

Both commands:
1. Add a connector declaration to `power.config.json`
2. Resolve the connector's schema from the environment
3. Regenerate `src/Services/` and `src/Models/` with typed classes and interfaces

Reference: [Connect to data in Code Apps](https://learn.microsoft.com/power-apps/developer/code-apps/how-to/connect-to-data)

---

### Generated folders

#### `src/Services/`

Contains one typed service class per declared data source. Example for Dataverse:

```typescript
// src/Services/DataverseService.ts  — AUTO-GENERATED, DO NOT EDIT
import { PowerAppsHost } from '@microsoft/power-apps';

export class DataverseService {
  static async getAccounts(): Promise<Account[]> { ... }
  static async createAccount(account: Partial<Account>): Promise<Account> { ... }
  // ... other generated operations
}
```

Each method is a typed async function that calls the connector through the Power Apps host. The host resolves the connection reference at runtime, adds the user's credentials, and proxies the request.

#### `src/Models/`

Contains TypeScript interfaces generated from the connector's entity/table schema. Example:

```typescript
// src/Models/account.ts  — AUTO-GENERATED, DO NOT EDIT
export interface Account {
  accountid: string;
  name: string;
  emailaddress1: string | null;
  // ... all fields from the Dataverse Account table
}
```

**Do not edit either folder.** Any manual change is overwritten the next time you run the add-data-source command or regenerate services.

---

### Regenerating services after schema changes

If the underlying data source schema changes (new columns added, table renamed, etc.), regenerate the service files:

```bash
# PAC CLI (legacy)
pac code refresh-data-source

# npm CLI (preferred)
npx @microsoft/power-apps refresh-data-source
```

After regeneration, review any TypeScript compilation errors in your own code caused by changed types.

---

### Connection references vs direct connections

| | Connection Reference | Direct Connection |
|---|---|---|
| Definition | A named pointer to a connection, resolved per environment | A hard-wired connection to a specific endpoint |
| ALM support | Yes — swap the target connection per environment | No — breaks when moving between environments |
| Required for production | Yes | Not acceptable |
| Configured in | Solution connection references | N/A for Code Apps |

**Rule:** all data sources in a Code App must be declared as connection references. The PAC CLI and npm CLI enforce this when you add a data source — they create a connection reference entry in `power.config.json` automatically. Never bypass this by calling external APIs directly from React code.

Reference: [Connect to Azure SQL](https://learn.microsoft.com/power-apps/developer/code-apps/how-to/connect-to-azure-sql)

---

### Using a generated service in React code

Import the generated service into your own component or hook. Never import it inside a generated file.

```typescript
// src/hooks/useAccounts.ts  — YOUR file, safe to edit
//
// SCALABILITY RULES — always apply:
//   1. $select — only request the columns you actually display
//   2. $filter — always filter server-side; never fetch all and filter client-side
//   3. $top / maxpagesize — never load unbounded result sets
//   4. $orderby — always include a unique column so paging is deterministic
//
// See code-apps/api-scalability.md for full patterns.

import { useQuery } from '@tanstack/react-query';
import { DataverseService } from '../Services/DataverseService';
import type { Account } from '../Models/account';

interface AccountListOptions {
  searchTerm?: string;
  pageSize?: number;
}

export function useAccounts({ searchTerm, pageSize = 50 }: AccountListOptions = {}) {
  return useQuery<Account[], Error>({
    queryKey: ['accounts', { searchTerm, pageSize }],
    queryFn: () =>
      DataverseService.getAccounts({
        // Always $select — never return all columns
        select: ['accountid', 'name', 'emailaddress1', 'telephone1'],
        // Always $filter — never load all records
        filter: searchTerm ? `startswith(name, '${searchTerm}')` : 'statecode eq 0',
        // Always $top — never unbounded
        top: pageSize,
        // Always $orderby with a unique column for deterministic paging
        orderby: 'name asc,accountid asc',
      }),
    // Keep previous data visible while next page loads
    placeholderData: (prev) => prev,
  });
}
```

```tsx
// src/features/accounts/AccountList.tsx  — YOUR file, safe to edit
import { Spinner, MessageBar, MessageBarBody } from '@fluentui/react-components';
import { useAccounts } from '../../hooks/useAccounts';

export function AccountList() {
  const { data: accounts, isLoading, isError, error } = useAccounts({ pageSize: 50 });

  if (isLoading) return <Spinner label="Loading accounts..." />;

  if (isError) {
    return (
      <MessageBar intent="error">
        <MessageBarBody>Failed to load accounts: {error.message}</MessageBarBody>
      </MessageBar>
    );
  }

  return (
    <ul>
      {accounts?.map((a) => (
        <li key={a.accountid}>{a.name}</li>
      ))}
    </ul>
  );
}
```

Key points:
- Use React Query (`@tanstack/react-query`) for all connector calls — caching, loading, and error states
- Always `$select` — returning unused columns wastes bandwidth and counts toward API limits
- Always `$filter` server-side — **never** fetch all records and filter in the browser
- Always `$top` or `maxpagesize` — unbounded queries can return up to 5,000 rows and hit service protection limits
- Always `$orderby` including a unique column — required for deterministic pagination
- Always type the response — no `any`
- Always handle loading and error states in the UI

> **Anti-pattern to avoid:** `DataverseService.getAccounts()` with no parameters returns every
> active account in the environment. On a large tenant this can be tens of thousands of records,
> hit Dataverse service protection limits, and crash the browser with memory pressure. Always
> add `$select`, `$filter`, and `$top` before calling any list query.

See `api-scalability.md` for full pagination, 429 retry, and Azure Function call patterns.

---

### Error handling for connector calls

Connector calls can fail for reasons outside your control: network issues, expired connections, DLP policy violations, permission errors. Always handle these explicitly.

```typescript
// src/hooks/useCreateAccount.ts
import { useMutation, useQueryClient } from '@tanstack/react-query';
import { DataverseService } from '../Services/DataverseService';
import type { Account } from '../Models/account';

export function useCreateAccount() {
  const queryClient = useQueryClient();

  return useMutation<Account, Error, Partial<Account>>({
    mutationFn: (newAccount) => DataverseService.createAccount(newAccount),
    onSuccess: () => {
      // Invalidate cache so the list re-fetches
      queryClient.invalidateQueries({ queryKey: ['accounts'] });
    },
    onError: (error) => {
      // Log to application insights, not console.log
      // See security.md — never log user data
    },
  });
}
```

Do not use bare `try/catch` with `console.log` for error handling. Use React Query's `onError` callback or error boundaries (see `react-patterns.md`).

---

### Deprecation notice: `pac code` commands

The `pac code` sub-commands (`add-data-source`, `push`, `create`, etc.) are scheduled for deprecation. Microsoft's current guidance is to migrate to the npm CLI provided by `@microsoft/power-apps` v1.0.4+.

Action for new projects: use the npm CLI from the start.
Action for existing projects: plan migration before the deprecation date published in the Power Platform release notes.

Reference: [PAC CLI code reference](https://learn.microsoft.com/power-platform/developer/cli/reference/code)

---

### References

- [Connect to data in Code Apps](https://learn.microsoft.com/power-apps/developer/code-apps/how-to/connect-to-data)
- [Connect to Azure SQL](https://learn.microsoft.com/power-apps/developer/code-apps/how-to/connect-to-azure-sql)
- [PAC CLI code reference](https://learn.microsoft.com/power-platform/developer/cli/reference/code)
