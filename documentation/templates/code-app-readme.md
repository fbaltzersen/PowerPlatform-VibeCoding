# [AppName] — Code App

> **Project:** [ProjectName]
> **Customer:** [Customer]
> **Author:** [Author]
> **Created:** [Date]
> **Last updated:** [Date]
> **Repository:** [Git repo URL]
> **Solution name:** [SolutionName] (surrounding solution — see ALM note below)

---

## Overview

[Describe the purpose of this Code App in 2–4 sentences. What does it do? Who uses it? Why was a Code App chosen over a canvas app for this use case?]

**ALM note:** Code Apps do not support Power Platform Git integration or the solution packager as of June 2025.
Source code is maintained in this Git repository. Deployment uses `pac code push`. See the Deployment section below.

**Environment URLs:**

| Environment | URL |
|---|---|
| Dev | [Dev environment URL] |
| Test | [Test environment URL] |
| Prod | [Prod environment URL] |

---

## Prerequisites

| Dependency | Required version | Notes |
|---|---|---|
| Node.js | `>= [X.X.X]` | Use the version in `.nvmrc` or `package.json engines` |
| npm | `>= [X.X.X]` | Comes with Node |
| Power Platform CLI (`pac`) | `>= [X.X.X]` | Install: `dotnet tool install --global Microsoft.PowerApps.CLI.Tool` |
| .NET SDK | `>= [X.X]` | Required by PAC CLI |
| [Any other tooling] | [version] | [Notes] |

Verify your setup:

```bash
node --version
pac --version
```

---

## Data Sources (Connectors)

| Connector | Connection reference schema name | Authentication | Purpose |
|---|---|---|---|
| Dataverse | `[prefix]_Dataverse` | Implicit (environment) | [Purpose] |
| SharePoint | `[prefix]_SharePoint` | Service account OAuth | [Purpose] |
| [Add rows as needed] | | | |

Connection references are defined in the surrounding `[SolutionName]` solution, not in the Code App artifact itself.
Map connection references per environment after importing the surrounding solution (see `/alm/connection-reference-map.json`).

---

## Project Structure

```
[AppName]/
├── src/
│   ├── index.ts          # App entry point
│   ├── [feature]/        # Feature modules
│   └── ...
├── public/               # Static assets
├── .env.example          # Environment variable template (do not commit .env)
├── package.json
├── tsconfig.json
└── README.md
```

[Adjust the structure to match the actual project. Describe any non-obvious folders.]

---

## Local Development

### 1. Clone the repository

```bash
git clone [repo URL]
cd [AppName]
```

### 2. Install dependencies

```bash
npm install
```

### 3. Configure local environment

```bash
cp .env.example .env
# Edit .env with your Dev environment values
```

See [Environment Variables / Connection References](#environment-variables--connection-references) for the full variable list.

### 4. Authenticate with PAC CLI

```bash
pac auth create --url [DevEnvironmentUrl]
pac auth select --index [N]
```

### 5. Start local development server

```bash
npm start
# or
pac code run
```

[Describe any additional setup steps, such as registering the app in Azure AD, seeding test data, etc.]

---

## Deployment

### Standard deployment via `pac code push`

```bash
# Authenticate if not already done
pac auth create --url [TargetEnvironmentUrl]

# Build the app
npm run build

# Push to the target environment
pac code push --environment [TargetEnvironmentUrl]
```

### Deployment checklist

- [ ] Increment the version in `package.json` before pushing to Test or Prod
- [ ] Tag the Git commit: `git tag v[X.Y.Z]-[env]` (e.g., `v1.2.0-test`)
- [ ] Import or update the surrounding `[SolutionName]` solution in the target environment
- [ ] Set environment variable values for the target environment
- [ ] Map connection references in the surrounding solution
- [ ] Smoke-test with a test user account
- [ ] Record the deployment in the project log: commit hash, deployer, date, environment

### Emergency rollback

```bash
# Check out the previously deployed commit
git checkout [previous-commit-hash]
npm run build
pac code push --environment [TargetEnvironmentUrl]
```

---

## Known Limitations

| Limitation | Impact | Workaround | Reference |
|---|---|---|---|
| No PP Git integration | Cannot use PP Git sync; source control is manual | Maintain in this Git repo; deploy via `pac code push` | https://learn.microsoft.com/power-apps/developer/code-apps/how-to/alm |
| No solution packager support | Cannot export/import via `pac solution pack` | Deploy Code App separately from the surrounding solution | See above |
| [Describe other limitations] | [Impact] | [Workaround] | [Reference] |

---

## Environment Variables / Connection References

### Environment variables (set in the surrounding Power Platform solution)

| Schema name | Type | Dev value | Test value | Prod value | Purpose |
|---|---|---|---|---|---|
| `[prefix]_ApiBaseUrl` | String | `https://dev-api...` | `https://test-api...` | `https://prod-api...` | Base URL for external API |
| `[prefix]_FeatureFlag` | Boolean | `true` | `true` | `false` | [Purpose] |
| [Add rows as needed] | | | | | |

### Local `.env` variables (development only — not committed to Git)

| Variable name | Example value | Purpose |
|---|---|---|
| `ENVIRONMENT_URL` | `https://[org].crm.dynamics.com` | Dev environment URL for local development |
| [Add rows as needed] | | |

**Note:** Never commit `.env` files. The `.env.example` file contains the variable names without values.

---

## Contacts

| Role | Name | Email |
|---|---|---|
| Project lead | [Name] | [email] |
| Technical lead | [Name] | [email] |
| Customer contact | [Name] | [email] |
| Support / ops | [Name] | [email] |
