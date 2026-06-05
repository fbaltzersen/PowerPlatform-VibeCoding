# Code Apps: React Patterns

---

## For consultants

This document defines the React architecture standard for all Code Apps delivered on this framework. Following these patterns ensures consistent, maintainable, and performant code across the team.

**The non-negotiables:**

- **Fluent UI v9** (`@fluentui/react-components`) — not v8, not Material UI, not Ant Design. Fluent UI v9 is the Microsoft design system for Power Platform and Microsoft 365.
- **React Router** for all navigation — no manual `window.location` manipulation, no conditional rendering as a routing substitute.
- **TypeScript with no `any` types** — if you don't know the type, look it up or use a union/generic. `any` defeats the entire purpose of TypeScript.
- **React Query for server state** — loading, caching, and error handling of connector calls in one place, not scattered across `useEffect` hooks.
- **Context API for UI state** — theme preferences, selected tab, sidebar open/closed. Keep this separate from server data.

**Things that are never acceptable in delivered code:**
- `console.log` statements (use application telemetry instead)
- Inline styles (`style={{ color: 'red' }}`) — use Fluent UI's `makeStyles`
- `useEffect` without a dependency array (this is almost always a bug)
- Redux (not justified for the complexity level of typical Code Apps)

---

## Technical specification

### Fluent UI v9 setup

Install the correct package. Do not use the legacy v8 package (`@fluentui/react`).

```bash
npm install @fluentui/react-components
```

Wrap the entire app in `FluentProvider` at the root. This provides the theme token context for all Fluent components down the tree.

```tsx
// src/index.tsx
import React from 'react';
import ReactDOM from 'react-dom/client';
import { FluentProvider, webLightTheme } from '@fluentui/react-components';
import { App } from './App';

const root = ReactDOM.createRoot(document.getElementById('root')!);

root.render(
  <React.StrictMode>
    <FluentProvider theme={webLightTheme}>
      <App />
    </FluentProvider>
  </React.StrictMode>
);
```

Use `makeStyles` (from `@fluentui/react-components`) for all custom styling. It integrates with Fluent's design token system and produces atomic CSS classes.

```tsx
import { makeStyles, tokens } from '@fluentui/react-components';

const useStyles = makeStyles({
  container: {
    padding: tokens.spacingHorizontalL,
    backgroundColor: tokens.colorNeutralBackground1,
  },
  title: {
    fontSize: tokens.fontSizeBase500,
    fontWeight: tokens.fontWeightSemibold,
  },
});

export function MyComponent() {
  const styles = useStyles();
  return (
    <div className={styles.container}>
      <h1 className={styles.title}>Title</h1>
    </div>
  );
}
```

**Do not use inline styles.** Do not import CSS files for component-level styling. Use `makeStyles` exclusively.

Reference: [Fluent UI React v9](https://react.fluentui.dev/)

---

### React Router setup

Install React Router v6+:

```bash
npm install react-router-dom
```

Configure routing in the app root. All navigation targets must be declared here — no ad hoc routing elsewhere.

```tsx
// src/App.tsx
import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { AppShell } from './components/AppShell';
import { AccountsPage } from './features/accounts/AccountsPage';
import { ContactsPage } from './features/contacts/ContactsPage';
import { NotFoundPage } from './features/NotFoundPage';

const queryClient = new QueryClient();

export function App() {
  return (
    <QueryClientProvider client={queryClient}>
      <BrowserRouter>
        <Routes>
          <Route path="/" element={<AppShell />}>
            <Route index element={<Navigate to="/accounts" replace />} />
            <Route path="accounts" element={<AccountsPage />} />
            <Route path="contacts" element={<ContactsPage />} />
            <Route path="*" element={<NotFoundPage />} />
          </Route>
        </Routes>
      </BrowserRouter>
    </QueryClientProvider>
  );
}
```

Use `<Link>` and `useNavigate()` for all navigation. Never use `window.location.href` or `window.location.replace`.

---

### State management

#### Rule: separate server state from UI state

| State type | What belongs here | Tool |
|---|---|---|
| Server state | Data fetched from connectors: lists of records, individual records, mutations | React Query (`@tanstack/react-query`) |
| UI state | Theme, sidebar open/closed, active tab, modal visibility, form dirty state | React Context API |
| Local component state | Input value, hover state, toggle | `useState` |

Do not use Redux. Its boilerplate is not justified for typical Code App complexity. If you feel the need for Redux, the component is probably doing too much — split it.

#### React Query (server state)

```bash
npm install @tanstack/react-query
```

Configure the `QueryClient` once at the app root (see Router setup above). Then use hooks for all connector interactions:

```typescript
// src/hooks/useAccounts.ts
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { DataverseService } from '../Services/DataverseService';
import type { Account } from '../Models/account';

export function useAccounts() {
  return useQuery<Account[], Error>({
    queryKey: ['accounts'],
    queryFn: DataverseService.getAccounts,
    staleTime: 5 * 60 * 1000, // 5 minutes
  });
}

export function useDeleteAccount() {
  const queryClient = useQueryClient();
  return useMutation<void, Error, string>({
    mutationFn: DataverseService.deleteAccount,
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['accounts'] });
    },
  });
}
```

#### Context API (UI state)

```tsx
// src/context/AppContext.tsx
import { createContext, useContext, useState, type ReactNode } from 'react';

interface AppContextValue {
  isSidebarOpen: boolean;
  toggleSidebar: () => void;
}

const AppContext = createContext<AppContextValue | null>(null);

export function AppProvider({ children }: { children: ReactNode }) {
  const [isSidebarOpen, setIsSidebarOpen] = useState(true);

  return (
    <AppContext.Provider
      value={{
        isSidebarOpen,
        toggleSidebar: () => setIsSidebarOpen((prev) => !prev),
      }}
    >
      {children}
    </AppContext.Provider>
  );
}

export function useAppContext(): AppContextValue {
  const ctx = useContext(AppContext);
  if (!ctx) throw new Error('useAppContext must be used within AppProvider');
  return ctx;
}
```

---

### Component structure

Organise by feature, not by type. Do not create a flat `components/` folder with hundreds of files.

```
src/
├── components/              # Shared, reusable components
│   ├── AppShell/
│   │   ├── AppShell.tsx
│   │   └── index.ts
│   ├── ErrorBoundary/
│   │   ├── ErrorBoundary.tsx
│   │   └── index.ts
│   └── LoadingPage/
│       └── LoadingPage.tsx
├── features/
│   ├── accounts/
│   │   ├── AccountsPage.tsx      # Route-level component
│   │   ├── AccountList.tsx
│   │   ├── AccountCard.tsx
│   │   └── useAccounts.ts        # Feature-scoped hook
│   └── contacts/
│       ├── ContactsPage.tsx
│       └── ...
├── hooks/                        # Shared hooks
├── context/                      # Context providers
├── Services/                     # AUTO-GENERATED — do not edit
├── Models/                       # AUTO-GENERATED — do not edit
└── App.tsx
```

Each feature folder owns its page component, child components, and feature-specific hooks. Shared utilities go in `hooks/` or `context/` at the top level.

---

### TypeScript standards

**No `any` types.** If you do not know the type:
- Check the generated `src/Models/` interfaces
- Use a union type (`string | number`)
- Use a generic (`Array<T>`)
- Use `unknown` and narrow with a type guard

```typescript
// BAD
function processRecord(record: any) {
  return record.name;
}

// GOOD
import type { Account } from '../Models/account';

function processAccount(account: Account): string {
  return account.name;
}
```

Enable strict mode in `tsconfig.json`:

```json
{
  "compilerOptions": {
    "strict": true,
    "noImplicitAny": true,
    "strictNullChecks": true
  }
}
```

Define explicit interfaces for all component props. Do not use inline type literals for anything used in more than one place.

```typescript
// src/features/accounts/AccountCard.tsx
interface AccountCardProps {
  account: Account;
  onSelect: (id: string) => void;
  isSelected: boolean;
}

export function AccountCard({ account, onSelect, isSelected }: AccountCardProps) {
  // ...
}
```

---

### Performance patterns

Use these only where there is a demonstrated need — premature optimisation adds complexity without benefit.

#### `React.memo`

Prevents re-render of a component when its parent re-renders but its own props have not changed. Use for list item components that render many times.

```tsx
import { memo } from 'react';

export const AccountCard = memo(function AccountCard({
  account,
  onSelect,
  isSelected,
}: AccountCardProps) {
  // Only re-renders when account, onSelect, or isSelected changes
});
```

#### `useCallback`

Stabilises a function reference so it does not trigger re-renders in child components that receive it as a prop.

```tsx
import { useCallback } from 'react';

export function AccountsPage() {
  const handleSelect = useCallback((id: string) => {
    // navigate or update state
  }, []); // dependency array — add any values used inside the function

  return <AccountList onSelect={handleSelect} />;
}
```

#### `useMemo`

Caches an expensive computed value. Use for filtering or sorting large arrays.

```tsx
import { useMemo } from 'react';

export function AccountList({ searchTerm }: { searchTerm: string }) {
  const { data: accounts } = useAccounts();

  const filtered = useMemo(
    () => accounts?.filter((a) => a.name.toLowerCase().includes(searchTerm.toLowerCase())) ?? [],
    [accounts, searchTerm]
  );

  return (/* render filtered */);
}
```

**Rule:** always provide a dependency array for `useEffect`, `useCallback`, and `useMemo`. A missing dependency array on `useEffect` causes an infinite loop or stale closure bugs.

---

### ESLint and Prettier configuration

The project scaffold from `pac code create` includes a base ESLint config. Extend it with these rules:

```json
// .eslintrc.json
{
  "extends": [
    "react-app",
    "react-app/jest",
    "plugin:@typescript-eslint/recommended"
  ],
  "rules": {
    "@typescript-eslint/no-explicit-any": "error",
    "no-console": "error",
    "react-hooks/exhaustive-deps": "error",
    "react/no-danger": "error"
  }
}
```

```json
// .prettierrc
{
  "semi": true,
  "singleQuote": true,
  "trailingComma": "all",
  "printWidth": 100,
  "tabWidth": 2
}
```

CI must run `npm run lint` and fail on any error. Zero warnings treated as errors is the standard (`--max-warnings 0`).

---

### Prohibited patterns

| Pattern | Why prohibited | Correct alternative |
|---|---|---|
| `console.log(...)` | Leaks debug info, sometimes PII, in production | Application Insights SDK or remove |
| `style={{ ... }}` inline styles | Bypasses Fluent token system, inconsistent theming | `makeStyles` from `@fluentui/react-components` |
| `useEffect(() => { ... })` with no dependency array | Runs on every render — almost always a bug | Add `[]` or correct dependencies |
| `import { something } from '@fluentui/react'` (v8) | Deprecated package, conflicts with v9 | `@fluentui/react-components` (v9) |
| `any` type | Defeats TypeScript type safety | Explicit interface or union type |
| Redux | Unjustified complexity | React Query + Context API |
| `window.location.href = ...` | Bypasses React Router, breaks browser history | `useNavigate()` from `react-router-dom` |

---

### References

- [Fluent UI React v9 documentation](https://react.fluentui.dev/)
- [Code Apps overview](https://learn.microsoft.com/en-us/power-apps/developer/code-apps/overview)
