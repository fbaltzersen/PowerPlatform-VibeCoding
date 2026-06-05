# Code App Rules

This file is automatically loaded by Claude Code when working in a Code App project.
Code Apps are standalone React/Vue/HTML SPAs hosted and managed by Power Platform.

Reference: https://learn.microsoft.com/en-us/power-apps/developer/code-apps/overview

---

## Before writing any code — required clarifications

| Question | Why it matters |
|----------|----------------|
| Can this be solved with a Canvas App instead? | Code Apps require React/TS expertise and Power Apps **Premium** licenses per user |
| Which data sources are needed? | Affects connector choice and solution structure |
| How many concurrent users? | Affects performance architecture decisions |
| Are there external (B2B) users? | Azure B2B is supported but requires specific configuration |
| Is the team comfortable with React and TypeScript? | If not, recommend Canvas App |
| Is this SPA or does it need server-side rendering? | Code Apps support SPA only |

Present an architecture plan (component structure, routing, data sources) and wait for approval before coding.

---

## Architecture — critical understanding

> **For consultants:** A Code App is a regular React web app that Microsoft hosts for you
> inside Power Apps. Microsoft handles login, access control, and publishing. You write the
> React code and connect it to Power Platform data sources using a provided SDK.

### Components you work with

| Component | What it is | Rule |
|-----------|-----------|------|
| `power.config.json` | Auto-generated metadata | NEVER edit manually |
| `src/Services/` | Auto-generated connector service classes | NEVER edit manually |
| `src/Models/` | Auto-generated data model types | NEVER edit manually |
| `@microsoft/power-apps` SDK | npm package for connector access | Only way to call connectors |
| Power Apps Host | Auth, app loading, DLP enforcement | Do not reimplement — use as-is |

### Regenerate services when data sources change

```bash
pac code add-data-source -a "shared_commondataservice" -t "accounts"
# Services and Models are regenerated automatically — never write them manually
```

Reference: https://learn.microsoft.com/power-apps/developer/code-apps/architecture

---

## Foundation-first order

```
STEP 1 — Architecture plan (present, wait for approval)
  Component and routing structure
  Connector / data source list
  State management strategy

STEP 2 — Project setup
  Vite + React + TypeScript scaffold
  ESLint + Prettier configured
  npm install @microsoft/power-apps
  pac code init --displayName "AppName"
  (or npx powerapp init for CLI v1.0.4+)

STEP 3 — TypeScript interfaces
  Data model interfaces defined
  No implementation yet

STEP 4 — SDK and data sources
  pac code add-data-source for each connector
  Review generated Services and Models
  Do not edit auto-generated files

STEP 5 — App shell
  React Router setup with all routes defined
  FluentProvider with theme wrapping app root
  Shared layout component

STEP 6 — Feature implementation (one route at a time)
  One feature / route fully completed before the next
  pac code push to named Solution after each milestone

STEP 7 — Revision
  npm run lint — must pass with zero errors
  Bundle analyzed for unnecessary dependencies
  npm run build (production build) used for delivery
```

---

## React architecture rules

**Fluent UI version:** Always use v9 (`@fluentui/react-components`) — not v8 (`@fluentui/react`)

```tsx
// Correct — Fluent UI v9
import { FluentProvider, webLightTheme, Button } from '@fluentui/react-components';

// Wrong — Fluent UI v8 (for PCF, not Code Apps)
import { PrimaryButton } from '@fluentui/react';
```

**State management:**
- Server / async state: React Query (`@tanstack/react-query`)
- Global UI state: React Context API
- Local component state: `useState`
- Do NOT use Redux — it is overkill for Code Apps

**Routing:** React Router v6 for all navigation

**App root:**
```tsx
<FluentProvider theme={webLightTheme}>
  <QueryClientProvider client={queryClient}>
    <BrowserRouter>
      <App />
    </BrowserRouter>
  </QueryClientProvider>
</FluentProvider>
```

---

## TypeScript and code quality rules

- No `any` types — use `unknown` or proper type interfaces
- No `console.log` in production code (use structured logging if needed)
- No commented-out code committed
- No `useEffect` without a dependency array
- No inline styles when a CSS-in-JS class or stylesheet can be used
- ESLint must pass with zero errors before every delivery
- TypeScript strict mode recommended (`"strict": true` in tsconfig.json)

---

## Security rules

> **For consultants:** The code in a Code App is hosted on a public Microsoft endpoint.
> This means the code itself can be inspected. Never put secret values, personal data,
> or credentials in the code — they belong in the data sources, fetched after login.

- NEVER store in code: API keys, tokens, passwords, personal data, org data
- NEVER use `localStorage` / `sessionStorage` for sensitive data
- Auth is handled by the Power Apps Host — do not implement custom auth
- All sensitive data must be fetched via connectors after authentication
- Connection strings go in connection references — not in code

Reference: https://learn.microsoft.com/power-apps/developer/code-apps/system-limits-configuration

---

## ALM rules

- Always deploy to a named Solution: `pac code push --solutionName MySolution`
- Never use the default solution
- Use Connection References instead of direct connections
- Deploy with Power Platform Pipelines: Dev → Test → Prod
- **Known limitation (June 2025):** Code Apps do NOT support Power Platform Git integration
- **Known limitation:** Solution Packager is NOT supported for Code Apps
- Use a dedicated Git repo (Azure DevOps / GitHub) for source code version control

Reference: https://learn.microsoft.com/power-apps/developer/code-apps/how-to/alm

---

## Known platform limitations (always inform the consultant)

- Not available in Power Apps for Windows app
- Requires **Power Apps Premium** license per end user
- Does not support Power BI data integration
- Does not support SharePoint Forms integration
- SPA only — no server-side rendering
- `pac code` CLI commands will be deprecated — prefer `@microsoft/power-apps` npm CLI (v1.0.4+)

---

## References

| Topic | URL |
|-------|-----|
| Overview | https://learn.microsoft.com/en-us/power-apps/developer/code-apps/overview |
| Architecture | https://learn.microsoft.com/power-apps/developer/code-apps/architecture |
| ALM | https://learn.microsoft.com/power-apps/developer/code-apps/how-to/alm |
| Connect to data | https://learn.microsoft.com/power-apps/developer/code-apps/how-to/connect-to-data |
| npm quickstart (v1.0.4+) | https://learn.microsoft.com/power-apps/developer/code-apps/how-to/npm-quickstart |
| System limits | https://learn.microsoft.com/power-apps/developer/code-apps/system-limits-configuration |
| PAC CLI reference | https://learn.microsoft.com/power-platform/developer/cli/reference/code |
| @microsoft/power-apps npm | https://www.npmjs.com/package/@microsoft/power-apps |
| GitHub samples | https://github.com/microsoft/PowerAppsCodeApps |
| Fluent UI v9 | https://react.fluentui.dev/ |
