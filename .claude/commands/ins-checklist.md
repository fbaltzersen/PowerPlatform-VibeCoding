# /ins-checklist

Runs the pre-delivery quality checklist for the current Power Platform project.

## Instructions

1. Detect the component type from the project's CLAUDE.md or folder structure.
2. Fetch the relevant checklist:
   - Canvas App: https://raw.githubusercontent.com/fbaltzersen/PowerPlatform-VibeCoding/master/canvas-apps/checklist.md
   - Code App: https://raw.githubusercontent.com/fbaltzersen/PowerPlatform-VibeCoding/master/code-apps/checklist.md
   - PCF: https://raw.githubusercontent.com/fbaltzersen/PowerPlatform-VibeCoding/master/code-components/checklist.md
3. Go through every item in the checklist against the current project state.
4. Report: which items pass, which fail, and what needs to be fixed before delivery.
5. For any failing item, provide the specific fix needed — not just "fix this".
6. After the checklist is complete, run `/security-review` automatically.
