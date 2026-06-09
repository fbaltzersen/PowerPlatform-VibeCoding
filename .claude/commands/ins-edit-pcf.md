# /ins-edit-pcf

Edit an existing Power Platform PCF Code Component following the Inspirit365 quality framework.

## Instructions

### Step 1 — Fetch framework rules

Fetch and apply before doing anything else:
- https://raw.githubusercontent.com/fbaltzersen/PowerPlatform-VibeCoding/master/CLAUDE.md
- https://raw.githubusercontent.com/fbaltzersen/PowerPlatform-VibeCoding/master/code-components/CLAUDE.md
- https://raw.githubusercontent.com/fbaltzersen/PowerPlatform-VibeCoding/master/code-components/api-scalability.md

### Step 2 — Ask the required questions (all mandatory before proceeding)

1. **Which Power Platform environment and solution?**
   - Environment URL or display name
   - Solution name (components live inside solutions)
   - Is this Dev, Test, or Prod? (never edit in Prod — confirm)

2. **Which PCF component?**
   - Component namespace and name (e.g. `Inspirit365.AzureMapsControl`)
   - Is it a field component or dataset component?
   - Target platform: Canvas, Model-driven, or both?

3. **Where is the source code?**
   - A) Clone from Git repository — provide repo URL or local clone path (preferred)
   - B) Already exists locally — provide folder path
   - C) Download from environment using PAC CLI (`pac pcf push` deploys but does not download — see note below)

4. **Is there an existing CLAUDE.md and DEVLOG.md in the project?**
   - If yes: read both before making any changes
   - If no: create CLAUDE.md (from code-components/CLAUDE.md framework) and DEVLOG.md (from template)

5. **What specifically needs to change?**
   - Describe the requirement — what is the expected outcome?
   - Does the manifest (input/output properties) need to change?
   - Which lifecycle method(s) are affected: init, updateView, destroy?

6. **Are there known constraints?**
   - Node.js and PAC CLI versions?
   - Apps currently using this component that could be affected by breaking changes?
   - Any input/output property changes that would break existing canvas app formulas?

### Step 3 — Read before changing

Before writing any code:
- Read `ControlManifest.Input.xml` — understand all input/output properties
- Read `index.ts` — understand the full lifecycle implementation
- Read all `.tsx` React component files
- Read `DEVLOG.md` to understand previous decisions
- Run `npm install` if `node_modules` is absent
- Run `npm start` to verify the test harness works before making changes
- Identify which apps currently use this component — changes to property names or types are breaking

### Step 4 — Assess breaking change risk

Flag immediately if the requested change would:
- Rename, remove, or change the type of an existing input/output property
- Change how `notifyOutputChanged` is called
- Change the component namespace or name

If any of these apply, inform the user that all Canvas Apps or Model-driven forms using this
component must be updated, and ask how to proceed.

### Step 5 — Present a scoped change plan

Cover:
- Manifest changes (if any) and their impact on consuming apps
- Which lifecycle methods will be modified
- Whether the React component tree changes
- Wait for explicit approval before writing code

### Step 6 — Make changes

Apply changes following all code-components/CLAUDE.md rules:
- `npm run lint` must pass before and after changes
- Use release build for deployment: `npm run build -- --flag Release`
- Never deploy a development build to Dataverse
- All new `webAPI` calls must include `$select`, `$filter`, `$top`, `$orderby`
- No new `any` types introduced

### Step 7 — Document

Update `DEVLOG.md` covering what changed, why, breaking change assessment, alternatives considered, files modified, trade-offs, and follow-up items.

### Step 8 — Run checklist

Fetch and run: https://raw.githubusercontent.com/fbaltzersen/PowerPlatform-VibeCoding/master/code-components/checklist.md

---

## Source option details

### Option A — Git repository (preferred for ALM)

```powershell
git clone <repo-url>
cd <component-folder>
npm install
npm start   # verify test harness before making changes
```

### Option B — Local folder

Verify `ControlManifest.Input.xml`, `index.ts`, and `package.json` exist.
Run `npm install` if needed, then `npm start` to verify.

### Option C — No existing source

> **Important:** PAC CLI does not support downloading PCF source code from Dataverse.
> `pac pcf push` deploys TO the environment but there is no `pac pcf pull`.
> If no source code exists (no Git repo, no local folder), the component must be
> rebuilt from scratch using `pac pcf init`.
> Inform the user of this limitation before proceeding.
> Ask whether to rebuild or whether source code can be found elsewhere.
