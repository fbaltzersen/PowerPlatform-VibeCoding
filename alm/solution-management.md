# Solution Management — Detailed ALM Guide

## For consultants

This guide explains how to manage solutions through the full lifecycle from development to production.
It covers the practical steps for environment setup, solution exports, environment variables, connection references, pipelines, and versioning.
Read this before you start any new Power Platform project.

---

## Technical specification

### 1. Environment strategy — three-tier model

```
Dev (unmanaged)  →  Test (managed)  →  Prod (managed)
```

**Dev environment**
- Developers and makers work here directly.
- Solutions are unmanaged, meaning all component definitions are editable.
- Should be provisioned per project (or per team for smaller engagements), not shared across projects.
- No live users or real data.

**Test environment**
- Receives managed solution imports only.
- Used for integration testing, regression testing, and user acceptance testing (UAT).
- Can contain anonymized or synthetic test data.
- Should mirror Prod configuration as closely as possible (same connector accounts, same environment variable values for the test tenant).

**Prod environment**
- Live environment serving real users and real data.
- Receives managed solution imports only, promoted from Test after sign-off.
- No direct maker access for development.
- Backup and DLP policies must be applied.

### 2. Managed vs unmanaged solutions

| Property | Unmanaged | Managed |
|---|---|---|
| Component editing | Allowed | Read-only (locked) |
| Deletion behavior | Deleting the solution does not delete components | Deleting the solution removes all managed components |
| Layering | Base layer | Sits on top of unmanaged layer |
| Recommended environment | Dev only | Test, Prod |

**Why this matters:** Importing an unmanaged solution into Prod allows makers to accidentally modify or delete components directly in production. Managed solutions prevent this and ensure all changes flow through the proper ALM pipeline.

### 3. Export unmanaged → import as managed

**Step-by-step:**

1. In the **Dev** environment, open the named solution.
2. Verify the solution version number has been incremented (see versioning conventions below).
3. Run Solution Checker and resolve Critical/High issues.
4. Export the solution:
   - Power Platform admin center or CLI: `pac solution export --name <SolutionName> --path ./export --managed`
   - This produces a managed `.zip` file directly.
   - Alternatively, export unmanaged and let the pipeline handle managed conversion.
5. Import to **Test**:
   - `pac solution import --path ./export/<SolutionName>_managed.zip`
   - Map connection references to the Test environment connections.
   - Set environment variable current values for Test.
6. Validate in Test, obtain sign-off.
7. Import the **same** managed zip to **Prod** — do not re-export from Dev for Prod.
8. Map connection references and set environment variable values for Prod.

> Always import the same artifact to both Test and Prod to guarantee what was tested is what was deployed.

### 4. Environment variables

**What they are:** Schema-defined key-value pairs stored in Dataverse, scoped per environment. The variable definition (name, type, default value) is part of the solution; the current value is set per environment and is not exported with the solution.

**Supported data types:** String, Number, Boolean, JSON, Data Source (SharePoint list reference).

**How to create:**

1. In the solution, select **New → More → Environment variable**.
2. Provide a display name, schema name (publisher-prefixed, e.g., `contoso_ApiBaseUrl`), data type, and optionally a default value.
3. Add the variable to the solution.
4. After importing to each environment, navigate to **Environment variables** and set the current value appropriate for that environment.

**How to reference:**

- **Power Automate:** Use the dynamic content picker; environment variables appear under the solution's data group.
- **Canvas Apps:** Use `LookUp(EnvironmentVariableValues, SchemaName = "contoso_ApiBaseUrl", Value)` or the newer `PowerApps.EnvironmentVariable("contoso_ApiBaseUrl")` syntax (check platform version).
- **Code Apps / PCF:** Read via Dataverse Web API: `GET /api/data/v9.2/environmentvariabledefinitions?$filter=schemaname eq 'contoso_ApiBaseUrl'&$expand=environmentvariablevalues`.

**Key rule:** If a value differs between Dev, Test, and Prod — it must be an environment variable. No exceptions.

### 5. Connection references

**What they are:** Named placeholders for connector connections, stored inside the solution. They decouple the solution from any individual user's personal connection.

**How to create:**

1. In the solution, select **New → More → Connection reference**.
2. Choose the connector type (e.g., SharePoint, Dataverse, custom connector).
3. Assign a display name and schema name (e.g., `contoso_SharePointSites`).
4. Associate an initial connection (your personal Dev connection) for development purposes.

**Using in Canvas Apps:**

- When adding a data source to a canvas app, select the connection reference instead of creating a new personal connection.
- The connection reference is stored with the app inside the solution.

**Using in Power Automate flows:**

- When adding an action that requires a connector, select the connection reference from the solution context.
- At import time in Test/Prod, the pipeline prompts to map each connection reference to the appropriate service account connection for that environment.

**Deployment mapping:** Maintain a `connection-reference-map.json` (or equivalent pipeline configuration) that documents which service account connection each reference maps to in each environment.

### 6. Power Platform Pipelines — setup and usage

**Prerequisites:**
- A dedicated **host environment** (typically a Prod or central admin environment with a Dataverse database).
- Dataverse for Teams or full Dataverse license in the host environment.
- Pipeline configuration installed from AppSource into the host environment.

**Setup steps:**

1. In the host environment, open the **Power Platform Pipelines** app.
2. Create a new pipeline:
   - Name the pipeline (e.g., `Contoso Sales Pipeline`).
   - Add the Dev environment as the source.
   - Add Test as the first deployment stage.
   - Add Prod as the second deployment stage.
3. Configure each stage:
   - Enable pre-deployment Solution Checker validation.
   - Add approval gates for Prod deployment (require sign-off from a named approver).
4. In the Dev environment, open the solution and select **Pipelines → Deploy here**.
5. The pipeline exports, validates, and promotes the solution through each stage.

**CLI alternative:**

```bash
pac pipeline run --name "Contoso Sales Pipeline" --stage Test
```

**Artifacts:** Each pipeline run produces a versioned solution artifact. Store these in a pipeline-connected artifact store (Azure Artifacts, GitHub Releases, or SharePoint) for traceability.

### 7. Solution versioning conventions

Use semantic versioning: `MAJOR.MINOR.PATCH.BUILD`

| Segment | When to increment |
|---|---|
| MAJOR | Breaking changes to the data model or major feature overhaul |
| MINOR | New features, new screens, new tables |
| PATCH | Bug fixes, formula corrections, UI adjustments |
| BUILD | Automated CI build number (optional, pipeline-assigned) |

Examples:
- Initial release: `1.0.0.0`
- New feature added: `1.1.0.0`
- Bug fix on existing feature: `1.1.1.0`
- Breaking schema change: `2.0.0.0`

Always increment the version before exporting for deployment. Version the solution, not individual components.

### 8. Code Apps — limitations and workarounds

As of June 2025, Code Apps (Power Apps Code component framework apps built with `pac code`) have the following ALM limitations:

| Limitation | Detail |
|---|---|
| No PP Git integration | Code Apps cannot be synced to Git via the Power Platform Git integration feature |
| No solution packager support | `pac solution pack/unpack` does not support Code App artifacts |
| Manual source control required | The source code must be maintained in a standard Git repo manually |

**Recommended workflow for Code Apps:**

1. Maintain all source code in a dedicated Git repository (separate from the Power Platform solution repo).
2. Use `pac code push --environment <url>` to deploy the latest build to the target environment.
3. Tag Git commits with the deployment version and target environment (e.g., `v1.2.0-test`).
4. Document the deployment in the project log with commit hash, deployer, date, and environment.
5. Use Power Platform Pipelines for the surrounding solution (environment variables, connection references), but treat the Code App artifact as a separate deployment step.

Reference: https://learn.microsoft.com/power-apps/developer/code-apps/how-to/alm

---

## References

- ALM overview: https://learn.microsoft.com/power-platform/alm/
- Power Platform Pipelines: https://learn.microsoft.com/en-us/power-platform/alm/pipelines
- Code Apps ALM: https://learn.microsoft.com/power-apps/developer/code-apps/how-to/alm
