# /ins-new-pcf

Sets up a new Power Platform PCF Code Component project with the full Inspirit365 quality framework.

## Instructions

Fetch the following files from the framework repository and apply them to this project:

- Root rules: https://raw.githubusercontent.com/fbaltzersen/PowerPlatform-VibeCoding/master/CLAUDE.md
- PCF rules: https://raw.githubusercontent.com/fbaltzersen/PowerPlatform-VibeCoding/master/code-components/CLAUDE.md
- PCF lifecycle: https://raw.githubusercontent.com/fbaltzersen/PowerPlatform-VibeCoding/master/code-components/pcf-lifecycle.md
- PCF API scalability: https://raw.githubusercontent.com/fbaltzersen/PowerPlatform-VibeCoding/master/code-components/api-scalability.md
- Fluent UI guide: https://raw.githubusercontent.com/fbaltzersen/PowerPlatform-VibeCoding/master/code-components/fluent-ui-guide.md
- DEVLOG template: https://raw.githubusercontent.com/fbaltzersen/PowerPlatform-VibeCoding/master/documentation/templates/devlog-template.md

After fetching, do the following in order:

1. Write `CLAUDE.md` to the current directory containing the PCF rules.
2. Create `DEVLOG.md` using the DEVLOG template.
3. Ask the mandatory PCF clarifying questions:
   - Does this already exist in standard Power Apps controls?
   - Canvas, model-driven, or both?
   - Expected data volume?
   - Should the app maker be able to restyle it?
   - React + platform libraries (virtual PCF), or standalone bundle?
4. Present a manifest design (input/output properties, component structure) and wait for explicit approval before writing any code.
