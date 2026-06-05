# [ComponentName] — PCF Component

> **Project:** [ProjectName]
> **Customer:** [Customer]
> **Author:** [Author]
> **Created:** [Date]
> **Last updated:** [Date]
> **Repository:** [Git repo URL]
> **Solution name:** [SolutionName]
> **Namespace:** [namespace]
> **Component name (schema):** [ComponentSchemaName]

---

## Overview

[Describe the purpose of this PCF component in 2–4 sentences. What does it render or control? Why was a PCF component needed instead of using built-in controls? What business problem does it solve?]

**Component type:** Field component / Dataset component

**Supported platforms:**

| Platform | Supported | Notes |
|---|---|---|
| Canvas Apps | Yes / No | [Any canvas-specific notes] |
| Model-driven Apps | Yes / No | [Any model-driven-specific notes] |
| Power Pages | Yes / No | [Any Power Pages-specific notes] |

---

## Input / Output Properties

| Property name | Type | Input / Output | Required | Default | Description |
|---|---|---|---|---|---|
| `[PropertyName]` | SingleLine.Text / Whole.None / TwoOptions / ... | Input | Yes / No | [default] | [What this property controls] |
| `[PropertyName]` | SingleLine.Text / Whole.None / TwoOptions / ... | Output | Yes / No | [default] | [What this property exposes] |
| [Add rows as needed] | | | | | |

> Property types follow the PCF manifest type system. See https://learn.microsoft.com/en-us/power-apps/developer/component-framework/manifest-schema-reference/property for valid types.

---

## Dependencies

### npm packages

| Package | Version | Purpose |
|---|---|---|
| [package-name] | [version] | [Purpose] |
| [package-name] | [version] | [Purpose] |

### External dependencies

| Dependency | Version | Notes |
|---|---|---|
| [CDN script / external API / etc.] | [version] | [Notes] |

### Build tooling requirements

| Dependency | Required version | Notes |
|---|---|---|
| Node.js | `>= [X.X.X]` | Use the version in `.nvmrc` or `package.json engines` |
| npm | `>= [X.X.X]` | Comes with Node |
| Power Platform CLI (`pac`) | `>= [X.X.X]` | Install: `dotnet tool install --global Microsoft.PowerApps.CLI.Tool` |
| .NET SDK | `>= [X.X]` | Required by PAC CLI |

---

## Local Development

### 1. Clone and install

```bash
git clone [repo URL]
cd [ComponentName]
npm install
```

### 2. Authenticate with PAC CLI

```bash
pac auth create --url [DevEnvironmentUrl]
pac auth select --index [N]
```

### 3. Start the test harness

```bash
npm start
```

This opens the PCF test harness at `http://localhost:8181`. Use the property panel on the left to simulate input property values and observe component behaviour.

### 4. Development notes

[Add any project-specific development notes: how to configure mock data, how to test edge cases, any known test harness limitations, etc.]

---

## Build and Deploy

### Build

```bash
npm run build
```

The build output is placed in `out/controls/[ComponentSchemaName]/`.

### Push to Dev environment (iterative development)

```bash
pac pcf push --publisher-prefix [prefix]
```

This packages the component and pushes it directly to the authenticated Dev environment. Use this for rapid iteration during development.

### Package for solution deployment

```bash
# Create a solution project (first time only)
pac solution init --publisher-name [PublisherName] --publisher-prefix [prefix]
pac solution add-reference --path [path-to-component]

# Build the solution package
dotnet build
```

The managed `.zip` is produced in `bin/Release/`. Import this to Test and Prod via Power Platform Pipelines or `pac solution import`.

### Deploy via Power Platform Pipelines (standard)

1. Commit the built component to the `[SolutionName]` solution in the Dev environment (via `pac pcf push` or solution import).
2. Follow the standard pipeline deployment process described in `/alm/solution-management.md`.

---

## Known Limitations

| Limitation | Impact | Workaround | Reference |
|---|---|---|---|
| [Describe limitation] | [Impact] | [Workaround] | [Link if applicable] |
| [Describe limitation] | [Impact] | [Workaround] | [Link if applicable] |

---

## Contacts

| Role | Name | Email |
|---|---|---|
| Project lead | [Name] | [email] |
| Technical lead | [Name] | [email] |
| Customer contact | [Name] | [email] |
| Support / ops | [Name] | [email] |
