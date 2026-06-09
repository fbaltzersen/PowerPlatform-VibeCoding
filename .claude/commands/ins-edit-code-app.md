# /ins-edit-code-app

Edit an existing Power Platform Code App following the Inspirit365 quality framework.

## Instructions

### Step 1 — Fetch framework rules

Fetch and apply before doing anything else:
- https://raw.githubusercontent.com/fbaltzersen/PowerPlatform-VibeCoding/master/CLAUDE.md
- https://raw.githubusercontent.com/fbaltzersen/PowerPlatform-VibeCoding/master/code-apps/CLAUDE.md
- https://raw.githubusercontent.com/fbaltzersen/PowerPlatform-VibeCoding/master/code-apps/api-scalability.md

### Step 2 — Ask the required questions (all mandatory before proceeding)

1. **Which Power Platform environment?**
   - Environment URL or display name
   - Is this Dev, Test, or Prod? (never edit directly in Prod — confirm)

2. **Which Code App?**
   - App display name or ID
   - Run `pac code list` to discover if unknown

3. **Where is the source code?**
   - A) Clone from Git repository — provide repo URL or local clone path (preferred)
   - B) Already exists locally — provide folder path
   - C) No source available — must pull from environment using `pac code` CLI

4. **Is there an existing CLAUDE.md and DEVLOG.md in the project?**
   - If yes: read both before making any changes
   - If no: create CLAUDE.md (from code-apps/CLAUDE.md framework) and DEVLOG.md (from template)

5. **What specifically needs to change?**
   - Describe the requirement — what is the expected outcome?
   - Which routes, components, or data sources are affected?

6. **Are there known constraints?**
   - Node.js version, PAC CLI version, @microsoft/power-apps SDK version?
   - Connection references or environment variables that must be preserved?
   - Other apps or flows that depend on this app?

### Step 3 — Read before changing

Before writing any code:
- Read `package.json` for dependencies and scripts
- Read `power.config.json` for connector configuration (do not edit manually)
- Read `src/` structure to understand routing and component organisation
- Read `DEVLOG.md` to understand previous decisions and known limitations
- Run `npm install` if `node_modules` is absent
- Confirm your understanding of the existing structure with the user

### Step 4 — Present a scoped change plan

Present a plan covering:
- Exactly which files will change and why
- Whether existing patterns (state management, routing, data access) should be preserved
- Any risks, breaking changes, or side effects
- Wait for explicit approval before writing code

### Step 5 — Make changes

Apply changes following all code-apps/CLAUDE.md and api-scalability.md rules:
- Do not modify `src/Services/` or `src/Models/` manually
- All new queries must include `$select`, `$filter`, `$top`, `$orderby`
- No `any` types introduced
- ESLint must pass after changes: `npm run lint`

### Step 6 — Document

Update `DEVLOG.md` with an entry covering what changed, why, alternatives considered, files modified, trade-offs, and follow-up items.

### Step 7 — Run checklist

Fetch and run: https://raw.githubusercontent.com/fbaltzersen/PowerPlatform-VibeCoding/master/code-apps/checklist.md

Also run `/security-review` if the change touches auth, connectors, or data access.

---

## Source option details

### Option A — Git repository (preferred for ALM)

```powershell
git clone <repo-url>
cd <project-folder>
npm install
pac auth create --url https://your-org.crm.dynamics.com
pac code run   # start local dev server connected to environment
```

### Option B — Local folder

Verify `power.config.json` and `package.json` exist. Run `npm install` if needed.

### Option C — No existing source

```powershell
# List available code apps in the environment
pac auth create --url https://your-org.crm.dynamics.com
pac code list

# Note: pac code does not support pulling source from an environment.
# If no source exists, you must reconstruct the project from scratch.
# Inform the user of this limitation before proceeding.
```

> **Important:** Code Apps do not support downloading source from Power Platform the way
> Canvas Apps do. If no source code exists (no Git repo, no local folder), the app must
> be rebuilt. Always confirm with the user before proceeding in this case.
