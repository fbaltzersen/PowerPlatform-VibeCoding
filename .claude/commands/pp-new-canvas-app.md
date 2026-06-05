# /pp-new-canvas-app

Sets up a new Power Platform Canvas App project with the full Inspirit365 quality framework.

## Instructions

Fetch the following files from the framework repository and apply them to this project:

- Root rules: https://raw.githubusercontent.com/fbaltzersen/PowerPlatform-VibeCoding/master/CLAUDE.md
- Canvas App rules: https://raw.githubusercontent.com/fbaltzersen/PowerPlatform-VibeCoding/master/canvas-apps/CLAUDE.md
- Naming conventions: https://raw.githubusercontent.com/fbaltzersen/PowerPlatform-VibeCoding/master/canvas-apps/naming-conventions.md
- Power Fx patterns: https://raw.githubusercontent.com/fbaltzersen/PowerPlatform-VibeCoding/master/canvas-apps/power-fx-patterns.md
- DEVLOG template: https://raw.githubusercontent.com/fbaltzersen/PowerPlatform-VibeCoding/master/documentation/templates/devlog-template.md

After fetching, do the following in order:

1. Write `CLAUDE.md` to the current directory containing the Canvas App rules.
2. Create `DEVLOG.md` using the DEVLOG template.
3. Ask the mandatory Canvas App clarifying questions:
   - What is the data source? (Dataverse, SharePoint, SQL, API)
   - Which devices? (Mobile, tablet, desktop, or all?)
   - Who are the users? (Single role or multiple?)
   - Does an existing solution or component already exist?
   - Is this in an existing named Solution?
   - What is the absolute MVP scope?
4. Present an architecture plan (screen structure, data source mapping, global variables, navigation flow) and wait for explicit approval before building anything.
