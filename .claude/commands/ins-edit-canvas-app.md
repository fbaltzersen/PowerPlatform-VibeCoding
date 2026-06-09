# /ins-edit-canvas-app

Edit an existing Power Platform Canvas App following the Inspirit365 quality framework.

## Instructions

### Step 1 — Fetch framework rules

Fetch and apply before doing anything else:
- https://raw.githubusercontent.com/fbaltzersen/PowerPlatform-VibeCoding/master/CLAUDE.md
- https://raw.githubusercontent.com/fbaltzersen/PowerPlatform-VibeCoding/master/canvas-apps/CLAUDE.md

### Step 2 — Ask the required questions (all mandatory before proceeding)

Ask these questions and wait for answers before touching any files:

1. **Which Power Platform environment?**
   - Environment URL (e.g. `https://org.crm.dynamics.com`) or display name
   - Is this Dev, Test, or Prod?

2. **Which Canvas App?**
   - App name or App ID

3. **Where is the source?**
   - A) Download fresh from Power Platform using PAC CLI (`pac canvas pack/unpack`)
   - B) Already unpacked locally — provide the folder path
   - C) Exists in a Git repository — provide the repo URL or local clone path

4. **Is there an existing CLAUDE.md and DEVLOG.md in the project?**
   - If yes: read both before making any changes
   - If no: create CLAUDE.md (from canvas-apps/CLAUDE.md framework) and DEVLOG.md (from template)

5. **What specifically needs to change?**
   - Describe the requirement in detail — what is the expected outcome?
   - Which screens are affected (if known)?

6. **Are there known constraints or dependencies?**
   - Other apps or flows that reference this app?
   - Specific Dataverse tables or columns involved?

### Step 3 — Read before changing

Before writing a single line of code:
- Read the existing `.pa.yaml` files for affected screens
- Read `App.pa.yaml` for global formulas, OnStart, and variables
- Read `DEVLOG.md` to understand previous decisions
- Identify any patterns already established (naming, delegation approach, variable strategy)
- Confirm your understanding of the existing structure with the user before proceeding

### Step 4 — Present a scoped change plan

Present a plan that covers:
- Exactly which files will be modified and why
- Whether any existing patterns need to be preserved or improved
- Any risks or side-effects of the change
- Wait for explicit approval before making any changes

### Step 5 — Make changes

Apply changes following all canvas-apps/CLAUDE.md rules:
- Follow existing naming conventions (do not rename existing controls unless explicitly asked)
- Preserve delegation patterns already in use
- Do not add unused controls, variables, or collections
- Use `/canvas-apps:canvas-app` skill for screen modifications

### Step 6 — Document

Update `DEVLOG.md` with an entry covering:
- What changed and why
- Alternatives considered
- Files modified
- Trade-offs or limitations
- Follow-up items

### Step 7 — Run checklist

Fetch and run: https://raw.githubusercontent.com/fbaltzersen/PowerPlatform-VibeCoding/master/canvas-apps/checklist.md

Report which items pass, which fail, and what must be fixed before the change is considered done.

---

## Source option details

### Option A — Download from Power Platform

```powershell
# Authenticate
pac auth create --url https://your-org.crm.dynamics.com

# List apps to find the correct one
pac canvas list

# Download and unpack
pac canvas unpack --msapp "AppName.msapp" --sources ./src
```

### Option B — Local folder

Verify the folder contains `.pa.yaml` files. If not, ask the user to unpack first using Option A.

### Option C — Git repository

```powershell
git clone <repo-url>
cd <repo-folder>
# Confirm CLAUDE.md and DEVLOG.md exist; create them if not
```
