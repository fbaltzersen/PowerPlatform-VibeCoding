# PowerPlatform-VibeCoding

**A reusable AI Quality Framework for Power Platform consulting teams.**

This framework ensures that AI-assisted (Claude Code) development of Canvas Apps, PCF Code Components,
and Code Apps follows Microsoft best practices — automatically, without requiring the consultant to
ask the AI to follow standards.

---

## The problem this solves

AI-assisted development ("vibe-coding") accelerates delivery but without guardrails risks:

- Code that breaks Microsoft best practices (delegation, naming, API patterns)
- Unnecessary or duplicated code written without understanding
- Missing documentation that leaves solutions hard to hand over
- Architecture decisions made too late to fix cheaply

**This framework makes good practices automatic.** Copy one `CLAUDE.md` file into a project,
and Claude Code loads all relevant rules and follows them without being asked.

---

## The three component types

| Type | Language | Use when |
|------|----------|----------|
| **Canvas App** | Power Fx | Standard business apps — default choice |
| **PCF Component** | TypeScript + React | Custom UI control needed inside an existing app |
| **Code App** | React / TypeScript | Full custom app where Power Fx is insufficient |

Not sure which to use? Ask Claude Code — it applies the decision tree automatically.

---

## Quick start

### 1. Choose your component type (see table above)

### 2. Copy the right CLAUDE.md into your project root

```bash
# Canvas App
copy canvas-apps\CLAUDE.md <your-project>\CLAUDE.md

# Code App
copy code-apps\CLAUDE.md <your-project>\CLAUDE.md

# PCF Component
copy code-components\CLAUDE.md <your-project>\CLAUDE.md
```

Also copy the root `CLAUDE.md` (or merge its content) for shared Power Platform rules.

### 3. Open the project in Claude Code

Claude automatically loads the rules. Before generating any code, it will:
- Ask the mandatory clarifying questions
- Present an architecture plan and wait for approval
- Follow foundation-first development order

---

## Repository structure

```
CLAUDE.md                        Root rules (shared across all component types)
ONBOARDING.md                    Consultant onboarding guide

canvas-apps/
  CLAUDE.md                      Auto-loaded rules for Canvas App projects
  naming-conventions.md          Microsoft naming standard reference
  power-fx-patterns.md           Delegation, performance, anti-patterns
  data-patterns.md               Dataverse / SharePoint patterns
  checklist.md                   Pre-delivery quality checklist

code-apps/
  CLAUDE.md                      Auto-loaded rules for Code App projects
  architecture.md                SDK, power.config.json, runtime model
  connector-patterns.md          Generated services/models, connection references
  react-patterns.md              Fluent UI v9, routing, state management
  security.md                    What cannot be stored in code
  checklist.md                   Pre-delivery quality checklist

code-components/
  CLAUDE.md                      Auto-loaded rules for PCF projects
  react-typescript.md            React hooks, memo, optimization
  fluent-ui-guide.md             Path-imports, theming, accessibility
  pcf-lifecycle.md               init / updateView / destroy patterns
  checklist.md                   Pre-delivery quality checklist

alm/
  CLAUDE.md                      ALM rules
  solution-management.md         Environment strategy, pipelines, deployment

documentation/
  standards.md                   Documentation requirements
  templates/
    canvas-app-readme.md         Canvas App project README template
    code-app-readme.md           Code App project README template
    pcf-readme.md                PCF component README template
    screen-doc.md                Canvas App screen documentation template
```

---

## Microsoft documentation sources

All rules in this framework are sourced from official Microsoft documentation:

| Component | Primary source |
|-----------|---------------|
| Canvas Apps | https://learn.microsoft.com/power-apps/guidance/coding-guidelines/overview |
| Canvas performance | https://learn.microsoft.com/power-apps/maker/canvas-apps/create-performant-apps-overview |
| Code Apps | https://learn.microsoft.com/en-us/power-apps/developer/code-apps/overview |
| PCF components | https://learn.microsoft.com/power-apps/developer/component-framework/code-components-best-practices |
| Power Platform ALM | https://learn.microsoft.com/power-platform/alm/ |
| Well-Architected | https://learn.microsoft.com/power-platform/well-architected/ |

---

## Claude Code Skills used by this framework

The framework instructs Claude to invoke these skills proactively:

| Skill | Purpose |
|-------|---------|
| `/canvas-apps:canvas-app` | Canvas App creation and editing |
| `/canvas-apps:add-data-source` | Connecting to data sources |
| `/security-review` | Pre-delivery security audit |
| `/code-review` | Code quality review |
| `/simplify` | Remove unnecessary code |
| `/deep-research` | Look up authoritative guidance |
| `/verify` | Confirm a feature works |

---

## Contributing

When you discover a new best practice, a Microsoft update, or a pattern that worked well on
a customer project, submit a PR to this repository.

1. Fork the repo
2. Create a branch: `improvement/[topic]`
3. Update the relevant markdown file
4. Include the Microsoft Learn reference URL for any new rule
5. Open a PR with a description of why the rule was added

---

## Maintained by

Inspirit365 — https://www.inspirit365.com  
Repository: https://github.com/fbaltzersen/PowerPlatform-VibeCoding
