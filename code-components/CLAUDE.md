# PCF Code Component Rules

This file is automatically loaded by Claude Code when working in a PCF project.
All rules are sourced from Microsoft official PCF documentation.

Reference: https://learn.microsoft.com/power-apps/developer/component-framework/code-components-best-practices

---

## Before writing any code — required clarifications

| Question | Why it matters |
|----------|----------------|
| Does this already exist in standard Power Apps controls? | Never build a PCF if a standard control covers the need |
| Canvas, model-driven, or both? | `context.webAPI` is NOT available in canvas apps |
| Expected data volume? | Affects virtual scrolling, pagination, performance strategy |
| Should the app maker be able to restyle it? | Requires input properties for color, size, theme |
| React + platform libraries, or standalone bundle? | Virtual controls share the platform's React instance — preferred |

Present a manifest design (input/output properties) and wait for approval before coding.

---

## Foundation-first order

```
STEP 1 — Manifest design (present, wait for approval)
  Input / output property names and types
  Component dimensions and resizing strategy
  Target platforms (canvas / model-driven / both)

STEP 2 — Project setup
  pac pcf init -n [Name] -ns [Namespace] -t [field|dataset] -fw react
  ESLint configured for TypeScript + React
  tsconfig.json updated: "module": "es2015", "moduleResolution": "node"

STEP 3 — Types and interfaces (no implementation yet)
  TypeScript interfaces for all data structures
  Props interface for the root React component

STEP 4 — PCF lifecycle (index.ts)
  init(), updateView(), destroy() stubs implemented
  No React rendering yet — logic only

STEP 5 — React components
  Root component wrapped in React.memo
  Fluent UI with path-based imports
  useCallback / useMemo for event handlers and computed values

STEP 6 — Revision
  npm run lint — must pass with zero errors
  Release build: npm run build -- --flag Release
  Bundle size reviewed
```

---

## Naming and structure

- Namespace: PascalCase company or project name (e.g. `Inspirit365`)
- Component name: PascalCase describing the control (e.g. `AzureMapsControl`)
- File structure: one component per folder matching the component name
- Manifest file: `ControlManifest.Input.xml` — defines all properties
- React root component file: `[ComponentName].tsx` or `[ComponentName]Component.tsx`

---

## PCF lifecycle rules

### init()
- All network requests and metadata fetching go here
- Call `context.mode.trackContainerResize(true)` if the component responds to size changes
- Store `notifyOutputChanged` and `container` references

### updateView()
- Always check `context.updatedProperties` before triggering a re-render
- Only call `ReactDOM.render` when a property that affects the UI has changed
- Handle null values — data may not be ready on the first call

```typescript
public updateView(context: ComponentFramework.Context<IInputs>): void {
  // Guard: only re-render when relevant properties changed
  const updated = context.updatedProperties;
  if (!updated.includes("value") && !updated.includes("disabled")) return;

  ReactDOM.render(
    React.createElement(MyComponent, {
      value: context.parameters.value.raw,
      disabled: context.mode.isControlDisabled,
      onChange: this.notifyOutputChanged,
    }),
    this.rootContainer
  );
}
```

Reference: https://learn.microsoft.com/power-apps/developer/component-framework/reference/updatedproperties

### destroy()
- Always call `ReactDOM.unmountComponentAtNode(this.rootContainer)`
- Remove all event listeners added outside the container element
- Close any open WebSockets

```typescript
public destroy(): void {
  ReactDOM.unmountComponentAtNode(this.rootContainer);
}
```

Reference: https://learn.microsoft.com/power-apps/developer/component-framework/reference/control/destroy

---

## TypeScript and React rules

- No `any` types — use `unknown` or proper type definitions
- All functional components wrapped in `React.memo`
- Event handlers defined with `useCallback` — never inline arrow functions in JSX
- Expensive computations wrapped in `useMemo`
- No `useEffect` without a dependency array
- ESLint must pass — no warnings, no errors

---

## Fluent UI import rules

> **For consultants:** Importing the full Fluent UI library in each component makes
> the bundle file large and slow to load. Always import only the specific component needed.

Wrong — imports the entire 2MB+ library:
```typescript
import { Button } from '@fluentui/react';
```

Correct — imports only the Button component:
```typescript
import { Button } from '@fluentui/react/lib/Button';
```

For React virtual controls (preferred for new components):
```typescript
// Uses the platform's shared React instance — no bundling needed
pac pcf init -n MyControl -ns MyNS -t field -fw react
```

Reference: https://learn.microsoft.com/power-apps/developer/component-framework/react-controls-platform-libraries

---

## CSS scoping

Always scope CSS to the component container. Never write global CSS rules.

```css
/* Correct — scoped to this component's container */
.Inspirit365\.AzureMapsControl .map-container {
  height: 400px;
}

/* Wrong — global rule that breaks the host app */
.map-container {
  height: 400px;
}
```

---

## Forbidden patterns

- Direct DOM manipulation outside the component container element
- Deploying development builds to Dataverse (always use release build)
- Using `context.webAPI` without checking it is available (unavailable in canvas apps)
- Accessing `formContext` directly — not supported across platforms
- Using `window.localStorage` or `window.sessionStorage` — not secure or reliable
- Synchronous network requests
- More than one call to `ReactDOM.render` per `updateView` execution
- Calling `notifyOutputChanged` on every keypress — debounce it

---

## References

| Topic | URL |
|-------|-----|
| Best practices | https://learn.microsoft.com/power-apps/developer/component-framework/code-components-best-practices |
| React controls + platform libraries | https://learn.microsoft.com/power-apps/developer/component-framework/react-controls-platform-libraries |
| init method | https://learn.microsoft.com/power-apps/developer/component-framework/reference/control/init |
| updateView method | https://learn.microsoft.com/power-apps/developer/component-framework/reference/control/updateview |
| destroy method | https://learn.microsoft.com/power-apps/developer/component-framework/reference/control/destroy |
| updatedProperties | https://learn.microsoft.com/power-apps/developer/component-framework/reference/updatedproperties |
| trackContainerResize | https://learn.microsoft.com/power-apps/developer/component-framework/reference/mode/trackcontainerresize |
| Debugging | https://learn.microsoft.com/power-apps/developer/component-framework/debugging-custom-controls |
| ALM for code components | https://learn.microsoft.com/power-apps/developer/component-framework/code-components-alm |
| Fluent UI React | https://developer.microsoft.com/fluentui#/get-started/web |
