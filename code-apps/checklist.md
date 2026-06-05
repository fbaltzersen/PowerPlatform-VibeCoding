# Code Apps: Pre-Delivery Quality Checklist

Use this checklist before handing over any Code App to a client or deploying to a production environment. All mandatory items must be checked. Recommended items should be checked unless there is a documented reason for the exception.

---

## Mandatory

These items are non-negotiable. A delivery that fails any mandatory check must not be handed over.

### Code quality

- [ ] **ESLint passing with zero errors** — run `npm run lint` (or `npm run lint -- --max-warnings 0`) and confirm clean output. No suppressed errors with `// eslint-disable`.
- [ ] **Production build used** — the deployed app must be built with `npm run build`. Never deploy a dev server (`npm start`) to any non-local environment.
- [ ] **No `any` types in TypeScript** — search the codebase for `: any` and `as any`. The ESLint rule `@typescript-eslint/no-explicit-any: error` must be enabled and passing.
- [ ] **No `console.log` statements** — the ESLint rule `no-console: error` must be enabled and passing. No debug output left in source code.

### Security

- [ ] **No sensitive data in source code** — the compiled bundle is publicly accessible. Verify that no tokens, API keys, passwords, personal data, or organisational data appear in any source file. See `security.md`.
- [ ] **All data sources use connection references** — confirm in `power.config.json` that every declared connector is backed by a connection reference, not a direct connection.

### Platform compliance

- [ ] **App deployed to a named Solution** — the app must be inside a named, managed-friendly Solution. It must not be in the Default Solution. This is required for ALM (moving between environments).
- [ ] **`power.config.json` not manually edited** — verify via git history that all changes to this file were made by `pac code` CLI commands or the npm CLI, not by hand.
- [ ] **`src/Services/` and `src/Models/` not manually edited** — verify via git history that these folders contain only auto-generated content. No custom logic may be added to these files.

### UI framework

- [ ] **Fluent UI v9 (`@fluentui/react-components`) used throughout** — confirm that `@fluentui/react` (v8) is not in `package.json`. All UI components must come from `@fluentui/react-components` or your own components built on it.
- [ ] **`FluentProvider` wraps the app root** — confirm in `src/index.tsx` (or equivalent entry point) that `FluentProvider` is the outermost wrapper, with a theme passed explicitly.

### Navigation and state

- [ ] **React Router handles all navigation** — no `window.location.href`, `window.location.replace`, or `window.history.pushState` calls in source code. All routing via `<Link>`, `<Navigate>`, or `useNavigate()`.

### Dependencies

- [ ] **Bundle analyzed — no unnecessary dependencies** — run `npx source-map-explorer build/static/js/*.js` (or equivalent) and confirm that the bundle does not include packages that are not used, or packages that duplicate platform-provided functionality (e.g., `msal`, `axios` when only connector calls are needed).

### Testing

- [ ] **Tested with real Power Apps authentication (not mocked)** — the app must be pushed with `pac code push` and tested inside the real Power Apps player, signed in with an Entra ID account that has appropriate permissions. Local dev server testing alone is not sufficient for delivery.

---

## Recommended

These items represent best practice. Document any exceptions with a reason.

### Server state management

- [ ] **React Query (`@tanstack/react-query`) used for server state** — all connector calls should go through React Query hooks (`useQuery`, `useMutation`) rather than raw `useEffect` + `useState` patterns. This provides consistent loading, error, and caching behaviour.

### Resilience

- [ ] **Error boundaries implemented** — at minimum, an error boundary wraps the main content area so that a connector failure or rendering error does not crash the entire app. See `react-patterns.md`.
- [ ] **Loading states shown during connector calls** — every data-fetching operation must display a loading indicator (e.g., Fluent UI `Spinner`) while the request is in flight. Users must never see a blank screen without explanation.

### TypeScript

- [ ] **TypeScript strict mode enabled** — `tsconfig.json` should include `"strict": true`. This enables `noImplicitAny`, `strictNullChecks`, and related checks that prevent a wide class of runtime errors.

---

## Completing the checklist

Sign and date this checklist when all mandatory items are checked. Attach it to the delivery documentation.

| | |
|---|---|
| Completed by | |
| Date | |
| Environment deployed to | |
| Solution name | |
| Exceptions noted | |
