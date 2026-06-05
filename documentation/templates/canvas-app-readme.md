# [AppName] — Canvas App

> **Project:** [ProjectName]
> **Customer:** [Customer]
> **Author:** [Author]
> **Created:** [Date]
> **Last updated:** [Date]
> **Solution name:** [SolutionName]
> **Publisher prefix:** [prefix]

---

## Overview

[Describe the purpose of this app in 2–4 sentences. Who uses it? What business problem does it solve? What is the primary workflow?]

**Environment URLs:**

| Environment | URL |
|---|---|
| Dev | [Dev environment URL] |
| Test | [Test environment URL] |
| Prod | [Prod environment URL] |

---

## Screens

| Screen name | Purpose | Primary data source |
|---|---|---|
| `HomeScreen` | [Purpose] | [Data source] |
| `DetailScreen` | [Purpose] | [Data source] |
| `EditScreen` | [Purpose] | [Data source] |
| `SettingsScreen` | [Purpose] | [Data source] |

[Add or remove rows as needed. For detailed per-screen documentation, see the screen documentation blocks inside the app or the `/documentation/screens/` folder.]

---

## Data Sources

| Data source | Type | Tables / Lists used | Purpose |
|---|---|---|---|
| [DataSourceName] | Dataverse / SharePoint / SQL / ... | [Table or list names] | [What it stores / provides] |
| [DataSourceName] | Dataverse / SharePoint / SQL / ... | [Table or list names] | [What it stores / provides] |

---

## Variables and Collections

### Global variables (`Set()`)

| Variable name | Type | Purpose | Set on screen |
|---|---|---|---|
| `gblCurrentUser` | Record | Logged-in user record | `AppOnStart` |
| `gblIsAdmin` | Boolean | Whether the current user is in the admin group | `AppOnStart` |
| [Add rows as needed] | | | |

### Collections (`Collect()` / `ClearCollect()`)

| Collection name | Source | Purpose | Populated on screen |
|---|---|---|---|
| `colUserRoles` | Dataverse | User role lookup used across all screens | `AppOnStart` |
| [Add rows as needed] | | | |

---

## Connectors Used

| Connector | Connection reference schema name | Authentication | Purpose |
|---|---|---|---|
| SharePoint | `[prefix]_SharePoint` | Service account OAuth | [Purpose] |
| Dataverse | `[prefix]_Dataverse` | Implicit (environment) | [Purpose] |
| Office 365 Users | `[prefix]_O365Users` | Service account OAuth | [Purpose] |
| [Add rows as needed] | | | |

---

## Known Limitations

| Limitation | Impact | Workaround | Reference |
|---|---|---|---|
| [Describe limitation] | [Who/what is affected] | [What the workaround is] | [Link if applicable] |
| [Describe limitation] | [Who/what is affected] | [What the workaround is] | [Link if applicable] |

---

## Deployment Instructions

### Prerequisites

- Power Platform CLI (`pac`) installed and authenticated
- Access to Dev, Test, and Prod environments
- Connection references mapped for each environment (see `/alm/connection-reference-map.json`)
- Environment variable values documented (see `/alm/environment-variables.md`)

### Deploy via Power Platform Pipelines (standard)

1. Open the `[SolutionName]` solution in the Dev environment.
2. Verify the solution version has been incremented.
3. Run Solution Checker; resolve all Critical and High issues.
4. In the solution, select **Pipelines → Deploy here**.
5. Select the **Test** stage and submit for deployment.
6. After Test validation and sign-off, promote to **Prod** using the same pipeline.

### Deploy via CLI (manual / emergency)

```bash
# Export managed solution from Dev
pac solution export --name [SolutionName] --path ./export --managed

# Import to Test
pac solution import --path ./export/[SolutionName]_managed.zip --environment [TestEnvUrl]

# Import to Prod (use the same artifact as Test)
pac solution import --path ./export/[SolutionName]_managed.zip --environment [ProdEnvUrl]
```

### Post-deployment checklist

- [ ] Set environment variable current values for the target environment
- [ ] Map all connection references to the correct service account connections
- [ ] Smoke-test the app with a test user account
- [ ] Verify delegation limits are not hit with production data volumes

---

## Contacts

| Role | Name | Email |
|---|---|---|
| Project lead | [Name] | [email] |
| Technical lead | [Name] | [email] |
| Customer contact | [Name] | [email] |
| Support / ops | [Name] | [email] |
