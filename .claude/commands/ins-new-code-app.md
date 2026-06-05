# /ins-new-code-app

Sets up a new Power Platform Code App project with the full Inspirit365 quality framework.

## What this command does

1. Fetches the latest framework rules from the PowerPlatform-VibeCoding repository
2. Writes the correct CLAUDE.md into the current project folder
3. Creates an initial DEVLOG.md from the framework template
4. Asks the mandatory pre-development clarifying questions
5. Presents an architecture plan before writing any code

## Instructions

Fetch the following files from the framework repository and apply them to this project:

- Root rules: https://raw.githubusercontent.com/fbaltzersen/PowerPlatform-VibeCoding/master/CLAUDE.md
- Code App rules: https://raw.githubusercontent.com/fbaltzersen/PowerPlatform-VibeCoding/master/code-apps/CLAUDE.md
- Architecture guide: https://raw.githubusercontent.com/fbaltzersen/PowerPlatform-VibeCoding/master/code-apps/architecture.md
- API scalability: https://raw.githubusercontent.com/fbaltzersen/PowerPlatform-VibeCoding/master/code-apps/api-scalability.md
- DEVLOG template: https://raw.githubusercontent.com/fbaltzersen/PowerPlatform-VibeCoding/master/documentation/templates/devlog-template.md

After fetching, do the following in order:

1. Write `CLAUDE.md` to the current directory containing the Code App rules (from the fetched content above).
2. Create `DEVLOG.md` in the current directory using the DEVLOG template. Fill in today's date and leave the session entries section ready for the first entry.
3. Ask the mandatory Code App clarifying questions before proceeding:
   - Can this be solved with a Canvas App instead? (Code Apps require Premium licenses)
   - Which data sources are needed?
   - How many concurrent users are expected?
   - Are there external (B2B) users?
   - Is the team comfortable with React and TypeScript?
4. Present an architecture plan based on the answers and wait for explicit approval before writing any code.
