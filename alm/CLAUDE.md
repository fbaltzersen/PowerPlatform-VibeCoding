# ALM Rules — Power Platform

## For consultants

These are the non-negotiable rules for how we manage solutions and deployments in Power Platform projects.
Follow them on every engagement, regardless of project size.

**Core rules at a glance:**

1. Always work inside a named solution — never the Default Solution.
2. Three environments: Dev (unmanaged) → Test (managed) → Prod (managed).
3. Every environment-specific value (URLs, IDs, flags) goes in an Environment Variable.
4. Use Connection References instead of hardcoded connections.
5. Deploy via Power Platform Pipelines — not manual export/import.
6. Code Apps live in their own Git repo (PP Git integration does not support Code Apps as of June 2025).
7. PCF components and Canvas Apps use PP Git integration where available.
8. Run Solution Checker before every deployment to Test or Prod.

---

## Technical specification

### 1. Solution hygiene

- Every component (app, flow, table, environment variable, connection reference, etc.) **must** belong to a named, publisher-prefixed solution.
- Never develop in or export from the Default Solution.
- Use a consistent publisher prefix across the project (e.g., `contoso`).
- Segment solutions by domain if the project is large (e.g., `Contoso_Core`, `Contoso_Sales`), with patch solutions for hotfixes.

### 2. Environment strategy

| Environment | Solution type | Purpose |
|---|---|---|
| Dev | Unmanaged | Active development, component editing |
| Test | Managed | Integration testing, UAT, validation |
| Prod | Managed | Live production workloads |

- Unmanaged solutions allow direct editing of components.
- Managed solutions are read-only in the target environment, preventing ad-hoc changes.
- Always export from Dev as **unmanaged**, then import to Test/Prod as **managed**.
- Never import unmanaged solutions into Test or Prod.

### 3. Environment variables

- Use Environment Variables for **all** environment-specific configuration: API endpoints, SharePoint site URLs, email addresses, feature flags, record GUIDs.
- Create the variable definition in the solution; set the current value per environment during or after deployment.
- Reference environment variables in canvas apps via `LookUp(EnvironmentVariableValues, ...)` or directly in Power Automate flows via the dynamic content picker.
- Do **not** hardcode environment-specific strings anywhere in formulas, flow actions, or code.

Reference: https://learn.microsoft.com/en-us/power-apps/maker/data-platform/environmentvariables

### 4. Connection references

- All connectors (SharePoint, Dataverse, Teams, custom connectors, etc.) must be represented as Connection References inside the solution.
- Never embed a personal connection directly in a flow or app.
- When importing to Test/Prod, map each connection reference to the appropriate service account or managed identity connection for that environment.
- In canvas apps, bind the connector to the connection reference; in Power Automate, the connection reference is resolved automatically at import time.

### 5. Deployment — Power Platform Pipelines

- Use Power Platform Pipelines (Host environment + pipeline configuration) to automate Dev → Test → Prod promotions.
- Pipelines enforce: pre-deployment Solution Checker, managed-solution export, connection reference mapping, and deployment approval gates.
- Manual export/import is only acceptable for initial project bootstrap or emergency hotfixes; document any manual deployment in the project log.

Reference: https://learn.microsoft.com/en-us/power-platform/alm/pipelines

### 6. Source control

| Component type | Source control approach |
|---|---|
| Canvas Apps | PP Git integration (Power Apps → Git sync) |
| PCF components | PP Git integration or dedicated repo |
| Code Apps | Separate Git repo (PP Git integration not supported as of June 2025) |
| Dataverse customizations | Solution zip committed via pipeline artifact |

- Code Apps must be maintained in a standard Git repository with a `pac code push` workflow.
- Never rely solely on environment backups as source of truth — code must be in Git.

### 7. Solution Checker

- Run Solution Checker against the solution before every deployment to Test or Prod.
- Fix all **Critical** and **High** severity issues before proceeding.
- Accept **Medium** issues only with documented justification.
- Solution Checker results must be included in the deployment PR or pipeline run artifact.

---

## References

- ALM overview: https://learn.microsoft.com/power-platform/alm/
- Power Platform Pipelines: https://learn.microsoft.com/en-us/power-platform/alm/pipelines
- Solution concepts: https://learn.microsoft.com/en-us/power-platform/alm/solution-concepts-alm
- Environment variables: https://learn.microsoft.com/en-us/power-apps/maker/data-platform/environmentvariables
