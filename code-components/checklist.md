# Pre-Delivery Quality Checklist — PCF Code Components

Run this checklist before every deployment to a customer environment. All mandatory items must be checked. Recommended items should be addressed unless there is a documented reason to skip.

---

## Mandatory

- [ ] **`npm run lint` passes with zero errors.**
  ESLint must report no errors against the TypeScript and React ruleset. Warnings must be reviewed and either resolved or explicitly accepted with a comment.

- [ ] **Release build used — `npm run build -- --flag Release`.**
  The solution package must contain a release build, not a development build. Development builds are larger, unminified, and may behave differently in production environments. Never deploy a development build to Dataverse.

- [ ] **No `any` types in TypeScript.**
  The `@typescript-eslint/no-explicit-any` ESLint rule is set to `error`. All types must be explicit. If a type from an external library is unknown, use `unknown` and narrow it with a type guard rather than casting to `any`.

- [ ] **No `console.log` statements.**
  The `no-console` ESLint rule is set to `error`. Debug logging left in production components pollutes the browser console for Power Apps users and may inadvertently leak sensitive data from Dataverse records.

- [ ] **No direct DOM manipulation outside the component container.**
  All DOM operations must be scoped to the container `HTMLDivElement` provided by PCF's `init` method. Manipulating elements outside the container (e.g., `document.body`, `document.getElementById`) breaks other controls and is not supported by the PCF sandbox.

- [ ] **`destroy()` cleans up: event listeners, WebSockets, and `ReactDOM.unmountComponentAtNode`.**
  Every resource acquired in `init` or `updateView` must be released in `destroy`. Specifically: DOM event listeners must be removed, WebSocket connections must be closed, and `ReactDOM.unmountComponentAtNode(container)` must be called to trigger React's internal cleanup and prevent memory leaks.

- [ ] **`updateView()` checks `updatedProperties` before re-rendering.**
  The method must inspect `context.updatedProperties` and return early if no relevant properties have changed. Unconditional re-renders on every `updateView` call cause visible flickering and unnecessary React reconciliation work.

- [ ] **Fluent UI path-based imports used — not full library import.**
  All Fluent UI imports use the deep path form: `import { X } from '@fluentui/react/lib/X'`. The barrel import `import { X } from '@fluentui/react'` is not permitted as it pulls the entire library into the bundle.

- [ ] **CSS scoped to component namespace — no global CSS rules.**
  Every CSS rule in the component's stylesheet is nested under the auto-generated namespace class (e.g., `.SampleNamespace\.ComponentName`). There are no top-level element selectors (`button`, `input`, `div`) or class selectors that could leak into the host Power Apps shell.

- [ ] **`React.memo` wraps the root component.**
  The root React component rendered into the PCF container is wrapped with `React.memo`. This prevents full component tree re-renders when `updateView` is called with unchanged props.

- [ ] **Tested in both model-driven app and canvas app (if the component targets both).**
  Behavior differences exist between model-driven and canvas app hosts (e.g., `context.webAPI` availability, property update frequency, container sizing). Both hosting surfaces must be tested before delivery if the component manifest does not restrict it to one type.

- [ ] **Accessibility: keyboard navigation works and ARIA attributes are set.**
  All interactive elements are reachable and operable via keyboard alone (Tab to focus, Enter/Space to activate, Escape to dismiss). Screen reader testing or review with a linter such as `eslint-plugin-jsx-a11y` should confirm that required `aria-label`, `role`, and `aria-*` attributes are present on any custom interactive elements not provided by Fluent UI.

- [ ] **Input properties allow app maker styling (color, size).**
  The component does not hardcode colors, font sizes, or spacing that an app maker would reasonably need to adjust. These values are exposed as manifest input properties of type `SingleLine.Text` or `Whole.Number` and applied via Fluent UI theming or CSS custom properties at runtime.

- [ ] **Bundle size reviewed — no unnecessary libraries.**
  The built output (`out/controls/<ComponentName>/bundle.js`) has been reviewed for size. Common causes of oversized bundles: importing from `@fluentui/react` root instead of paths, including charting or data-grid libraries that are not needed, and including `lodash` in full instead of individual function imports.

---

## Recommended

- [ ] **`context.webAPI` availability checked before use.**
  Code that calls `context.webAPI` is guarded with `if (context.webAPI) { ... }`. This makes the component safe to drop into canvas apps (where `webAPI` is `undefined`) without runtime errors.

- [ ] **Virtual PCF React controls used when possible (shared platform libraries).**
  For components that run only in model-driven apps and require React, the Virtual PCF control type (`ReactControl`) should be used. Virtual controls share the platform's React and Fluent UI instances rather than bundling their own copies, significantly reducing bundle size and preventing React version conflicts. See the `feature-pcf-virtual-controls` manifest attribute.

- [ ] **Responsive layout handled via `trackContainerResize` and `allocatedWidth` / `allocatedHeight`.**
  `context.mode.trackContainerResize(true)` is called in `init`, and the component reads `context.mode.allocatedWidth` and `context.mode.allocatedHeight` in `updateView` to adapt its layout. Components that ignore container size render incorrectly in narrow columns or when the form is resized.
