# Power Platform AI Quality Framework — Consultant Onboarding

This framework ensures that AI-generated Power Platform code follows Microsoft best practices,
is well-documented, optimized, and easy to hand over to customers or other consultants.

---

## What this framework does

> **For consultants:** Instead of hoping the AI follows good practices, this framework
> makes good practices automatic. Copy one file into your project and the AI knows all
> the rules — naming conventions, performance patterns, documentation requirements,
> quality checklists — without you having to ask.

When you copy a `CLAUDE.md` file into your project root and open that project in Claude Code,
the AI automatically:
- Asks the right clarifying questions before writing any code
- Follows Microsoft naming standards
- Warns you when something breaks best practices
- Documents as it builds
- Runs security and code reviews before delivery

---

## Quick start (3 steps)

### Step 1 — Choose your component type

| I need to... | Use |
|---|---|
| Build a standard business app with low code | **Canvas App** |
| Add a custom UI control (e.g. map, calendar) inside an existing app | **PCF Component** |
| Build a fully custom React app hosted in Power Apps | **Code App** |

### Step 2 — Copy the right CLAUDE.md into your project

```
Canvas App project:
  Copy canvas-apps/CLAUDE.md  →  <your-project-root>/CLAUDE.md

Code App project:
  Copy code-apps/CLAUDE.md    →  <your-project-root>/CLAUDE.md

PCF project:
  Copy code-components/CLAUDE.md → <your-project-root>/CLAUDE.md
```

Also copy the root `CLAUDE.md` if you want the global Power Platform rules loaded too
(recommended — place it one level above, or merge the contents).

### Step 3 — Open the project in Claude Code and start

Open VS Code with Claude Code extension in the project folder.
The AI will automatically load the rules and ask clarifying questions before starting.

---

## What each folder contains

```
canvas-apps/
  CLAUDE.md              Rules Claude follows automatically
  naming-conventions.md  Microsoft naming standard with examples
  power-fx-patterns.md   Delegation, performance, anti-patterns
  data-patterns.md       Dataverse and SharePoint data patterns
  checklist.md           Pre-delivery quality checklist

code-apps/
  CLAUDE.md              Rules Claude follows automatically
  architecture.md        How Code Apps work (SDK, runtime, power.config.json)
  connector-patterns.md  How to add and use data sources
  react-patterns.md      React, Fluent UI v9, routing, state
  security.md            What cannot be stored in code
  checklist.md           Pre-delivery quality checklist

code-components/
  CLAUDE.md              Rules Claude follows automatically
  react-typescript.md    React hooks, performance, optimization
  fluent-ui-guide.md     Fluent UI imports, theming, accessibility
  pcf-lifecycle.md       init / updateView / destroy patterns
  checklist.md           Pre-delivery quality checklist

alm/
  CLAUDE.md              ALM rules for all component types
  solution-management.md Environment strategy, pipelines, deployment

documentation/
  standards.md           Documentation requirements
  templates/             README and screen documentation templates
```

---

## Before delivery — always run these

1. **Ask Claude:** "Run the pre-delivery checklist for this project"
2. **Canvas Apps:** Run Solution Checker in Power Apps + Power CAT Toolkit
3. **Code Apps / PCF:** `npm run lint` must pass with zero errors; use release build
4. **All types:** `/security-review` in Claude Code

---

## Useful Claude Code commands

You can type these directly in Claude Code chat:

| What to type | What happens |
|---|---|
| `Run the pre-delivery checklist` | Claude reviews the project against checklist.md |
| `Explain delegation in Power Apps` | Dual-layer explanation (plain + technical) |
| `Review this screen for best practices` | Code review against Microsoft guidelines |
| `What is the correct naming for this control?` | Answer from naming-conventions.md |
| `/security-review` | Full security audit of the project |
| `/code-review` | Code quality review |
| `/simplify` | Remove unnecessary code and optimize |

---

## Where to find authoritative guidance

All documentation in this framework links to the original Microsoft Learn sources.
When the AI generates code or explanations, it references these URLs directly.

Primary sources:
- Canvas App guidelines: https://learn.microsoft.com/power-apps/guidance/coding-guidelines/overview
- Code Apps overview: https://learn.microsoft.com/en-us/power-apps/developer/code-apps/overview
- PCF best practices: https://learn.microsoft.com/power-apps/developer/component-framework/code-components-best-practices
- Power Platform ALM: https://learn.microsoft.com/power-platform/alm/
- Well-Architected framework: https://learn.microsoft.com/power-platform/well-architected/

---

## Contributing to this framework

When you discover a new best practice, a Microsoft update, or a pattern that worked well
on a customer project, add it to the relevant file and submit a PR to the shared repository.

Repository: https://github.com/fbaltzersen/PowerPlatform-VibeCoding
