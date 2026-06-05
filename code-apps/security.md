# Code Apps: Security

---

## For consultants

The single most important security fact about Code Apps is this: **the compiled JavaScript bundle is publicly accessible**. Anyone with the URL can read your source code. The Power Platform protects your data — not your code.

This means the security model is split:

- **Code (public):** UI logic, component structure, routing, configuration values that are not sensitive. Anyone can read this. That is fine and expected.
- **Data (protected):** records from Dataverse, SharePoint, SQL, or any other connector. This is protected by Entra ID authentication, the Power Apps host, and the connector's own permissions. No one can access this without a valid authenticated session.

**The rule:** never put anything in your code that would be harmful if a stranger read it.

**You must never put in code:**
- API keys, client secrets, or bearer tokens
- Passwords or connection strings
- Personal data (names, email addresses, phone numbers)
- Organisational data (account names, financials, HR records)
- Internal URLs, environment IDs, or tenant IDs that reveal infrastructure

**You must never implement your own authentication.** The Power Apps host handles Entra ID sign-in. If you add your own `msal` calls or token handling, you are duplicating something the platform already does — and almost certainly doing it less securely.

**localStorage and sessionStorage** may only be used for non-sensitive UI preferences (e.g., "user prefers dark mode", "sidebar was open"). Never store tokens, user data, or any record content in browser storage.

---

## Technical specification

### Public endpoint — what this means in practice

When a Code App is pushed to the platform, the compiled bundle (HTML, CSS, JavaScript) is deployed to the Power Apps CDN. This endpoint is reachable without authentication. This is by design: the host must load the JavaScript before it can authenticate the user.

Consequence: **static analysis of your JavaScript bundle reveals all code, string literals, and imported constants.** Modern minification does not prevent this — it only makes it harder to read, not impossible.

The following categories of content are therefore unsafe in source code:

| Category | Examples | Risk |
|---|---|---|
| Secrets | API keys, OAuth client secrets, SAS tokens | Immediate credential theft |
| Passwords | Hard-coded passwords, default credentials | Immediate account compromise |
| Personal data | Names, email addresses, phone numbers, national IDs | GDPR / privacy violation |
| Organisational data | Customer records, financial data, HR data | Data breach |
| Internal infrastructure | Internal API base URLs, environment GUIDs, tenant IDs | Reconnaissance attack surface |

Reference: [Code Apps system limits and configuration](https://learn.microsoft.com/power-apps/developer/code-apps/system-limits-configuration)

---

### Authentication: what the host manages

The Power Apps host implements the full Entra ID (Azure AD) authentication flow before your code runs:

1. User navigates to the app URL
2. Host checks for a valid Entra ID session
3. If no session: redirects to Microsoft login, completes OAuth 2.0 / OIDC flow
4. Host injects the authenticated `PowerAppsHost` context into your app
5. Your React code starts executing with the user already authenticated

Your code does not need to:
- Import `@azure/msal-browser` or `@azure/msal-react`
- Call `loginPopup` or `loginRedirect`
- Store or refresh tokens
- Check `isAuthenticated` before rendering

If you find yourself doing any of these things, stop. You are re-implementing what the platform already provides, and you will introduce inconsistencies.

**Do not implement your own authentication in a Code App.**

---

### Handling sensitive data correctly

All sensitive data must be retrieved via connectors **after** the host has authenticated the user. The connector call is proxied through the Power Apps gateway, which:
- Attaches the user's credentials to the upstream API call
- Enforces DLP (Data Loss Prevention) policies configured in the environment
- Enforces the connection reference's permissions

```typescript
// WRONG — hard-coded data in source code (visible in bundle)
const CUSTOMER_EMAIL = 'john.doe@contoso.com';

// WRONG — fetching data with your own authenticated HTTP call
const response = await fetch('https://internal-api.contoso.com/customers', {
  headers: { Authorization: `Bearer ${hardCodedToken}` },
});

// CORRECT — fetch via generated service after host authentication
import { DataverseService } from '../Services/DataverseService';

const customer = await DataverseService.getContact(contactId);
// contactId comes from routing/navigation, not a hard-coded value
```

---

### localStorage and sessionStorage

These are acceptable only for non-sensitive UI preferences where loss of the data has no security or privacy consequence.

**Permitted:**

```typescript
// UI preference — acceptable
localStorage.setItem('sidebar-collapsed', 'true');
localStorage.setItem('preferred-theme', 'dark');
```

**Not permitted:**

```typescript
// Token — never store in browser storage
localStorage.setItem('access-token', token);

// User data — never store in browser storage
localStorage.setItem('user-email', user.email);

// Record data — never store in browser storage
sessionStorage.setItem('selected-account', JSON.stringify(account));
```

If you need to pass record data between pages or components, use React Router's `state` parameter, React Query's cache, or React Context. These keep data in memory for the session lifetime and are not persisted to browser storage.

---

### Connection references for production environments

All data sources must be declared as connection references (see `connector-patterns.md`). This is also a security requirement:

- Connection references allow per-environment credential management — the development connection reference uses a developer account; the production connection reference uses a service account or managed identity
- Direct connections bake the connection into the app and cannot be swapped without re-publishing

Ensure that production connection references are configured with the minimum permissions required for the app to function (principle of least privilege).

---

### Code review security checklist

Before any code is committed, verify:

- [ ] No secrets, tokens, API keys, or passwords in any source file
- [ ] No personal data (names, emails, IDs) hard-coded anywhere
- [ ] No organisational data in source files or constants
- [ ] No custom authentication implementation (`msal`, manual token handling)
- [ ] No `fetch` or `axios` calls to external APIs — all data access via generated services
- [ ] localStorage / sessionStorage used only for non-sensitive UI preferences
- [ ] All data sources use connection references
- [ ] `power.config.json` contains no secrets (it should not — confirm by inspection)

---

### References

- [Code Apps system limits and configuration](https://learn.microsoft.com/power-apps/developer/code-apps/system-limits-configuration)
- [Code Apps overview](https://learn.microsoft.com/en-us/power-apps/developer/code-apps/overview)
