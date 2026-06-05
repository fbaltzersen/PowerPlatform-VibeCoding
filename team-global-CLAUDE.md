# Global Claude Code Configuration — Inspirit365

This file is installed to ~/.claude/CLAUDE.md by setup.ps1.
It applies to all Claude Code sessions on this machine.

Edit the name/email fields below after running setup.ps1.

---

## Context

You are working with a Power Platform consulting team (Inspirit365) that builds Canvas Apps,
PCF Code Components, and Code Apps (standalone React) for Dynamics 365 / Power Platform customers.
The team includes both pro developers and functional low-code consultants.

---

## Language

- Default response language: **English**
- Use Norwegian only if the user writes in Norwegian or the customer project explicitly requires it

---

## Framework: PowerPlatform-VibeCoding

Repository: https://github.com/fbaltzersen/PowerPlatform-VibeCoding

### At the start of any Power Platform development session

Determine the component type and fetch the relevant rules:

| Component type | Raw URL |
|---|---|
| Shared root rules | https://raw.githubusercontent.com/fbaltzersen/PowerPlatform-VibeCoding/master/CLAUDE.md |
| Canvas App | https://raw.githubusercontent.com/fbaltzersen/PowerPlatform-VibeCoding/master/canvas-apps/CLAUDE.md |
| Code App | https://raw.githubusercontent.com/fbaltzersen/PowerPlatform-VibeCoding/master/code-apps/CLAUDE.md |
| PCF Component | https://raw.githubusercontent.com/fbaltzersen/PowerPlatform-VibeCoding/master/code-components/CLAUDE.md |
| ALM rules | https://raw.githubusercontent.com/fbaltzersen/PowerPlatform-VibeCoding/master/alm/CLAUDE.md |

Supporting documents (fetch when needed):

| Topic | Raw URL |
|---|---|
| Canvas naming conventions | https://raw.githubusercontent.com/fbaltzersen/PowerPlatform-VibeCoding/master/canvas-apps/naming-conventions.md |
| Canvas Power Fx patterns | https://raw.githubusercontent.com/fbaltzersen/PowerPlatform-VibeCoding/master/canvas-apps/power-fx-patterns.md |
| Code App API scalability | https://raw.githubusercontent.com/fbaltzersen/PowerPlatform-VibeCoding/master/code-apps/api-scalability.md |
| Code App connector patterns | https://raw.githubusercontent.com/fbaltzersen/PowerPlatform-VibeCoding/master/code-apps/connector-patterns.md |
| Code App React patterns | https://raw.githubusercontent.com/fbaltzersen/PowerPlatform-VibeCoding/master/code-apps/react-patterns.md |
| Code App security | https://raw.githubusercontent.com/fbaltzersen/PowerPlatform-VibeCoding/master/code-apps/security.md |
| PCF lifecycle | https://raw.githubusercontent.com/fbaltzersen/PowerPlatform-VibeCoding/master/code-components/pcf-lifecycle.md |
| PCF API scalability | https://raw.githubusercontent.com/fbaltzersen/PowerPlatform-VibeCoding/master/code-components/api-scalability.md |
| PCF Fluent UI guide | https://raw.githubusercontent.com/fbaltzersen/PowerPlatform-VibeCoding/master/code-components/fluent-ui-guide.md |
| DEVLOG standard | https://raw.githubusercontent.com/fbaltzersen/PowerPlatform-VibeCoding/master/documentation/dev-log-standard.md |

---

## Power Platform Skills (invoke proactively — never ask the user to run these)

| Skill | When to invoke |
|-------|---------------|
| `/canvas-apps:canvas-app` | Canvas App screen creation or modification |
| `/canvas-apps:add-data-source` | Connecting to SharePoint, Dataverse, SQL, etc. |
| `/security-review` | Before every delivery; after auth or data access changes |
| `/code-review` | After implementing a feature; before committing |
| `/simplify` | When code has grown; after completing a feature |
| `/deep-research` | When best-practice guidance is needed on an unfamiliar topic |
| `/verify` | After implementing a feature to confirm it works |
| `/ins-new-code-app` | Start a new Code App project with full framework setup |
| `/ins-new-canvas-app` | Start a new Canvas App project with full framework setup |
| `/ins-new-pcf` | Start a new PCF project with full framework setup |
| `/ins-checklist` | Run pre-delivery quality checklist |

---

## Always

- Load the relevant framework CLAUDE.md before starting any Power Platform work
- Follow plan-first, foundation-first workflow
- Maintain DEVLOG.md during every development session
- Push back on patterns that break best practices

## Never

- Start writing code before clarifying requirements and presenting an architecture plan
- Deploy development builds to production
- Use the default Power Platform solution
- Fetch all records without $select, $filter, and $top
