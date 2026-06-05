# Fluent UI Usage Guide for PCF Components

---

## For consultants

Fluent UI is Microsoft's open-source design system and the component library used by Power Apps, Teams, and the rest of the Microsoft 365 shell. Using it in PCF components means your controls look and feel native to the platform without custom styling effort.

The most important practical rules:

- **Import from paths, not from the root package.** `import { Button } from '@fluentui/react'` pulls the entire library into your bundle. `import { Button } from '@fluentui/react/lib/Button'` imports only what you need. This is the single biggest lever for keeping bundle size under control.
- **Fluent UI components are accessible out of the box.** They implement keyboard navigation, focus management, and ARIA attributes. Use them for interactive elements rather than writing raw `<button>` or `<input>` elements, and you get accessibility for free.
- **Expose theming as input properties.** App makers cannot edit your component's CSS directly. Give them manifest input properties (e.g., `primaryColor`, `fontSize`) and apply them via Fluent UI's theming API at runtime.
- **Always scope CSS to the component namespace.** The PCF toolchain generates a unique namespace class. Every CSS rule you write must be nested under it. Never write global CSS rules — they will break Power Apps' own styling.

---

## Technical specification

### Why Fluent UI

Power Apps model-driven apps and canvas apps are built with Fluent UI internally. Components that do not use Fluent UI visually clash with surrounding controls and require significant manual effort to match platform typography, spacing, and color tokens.

Using Fluent UI (`@fluentui/react` v8) in PCF components provides:

- Visual consistency with the Power Apps shell without custom CSS
- Built-in support for high-contrast mode (Windows accessibility feature required by Microsoft's accessibility standards)
- Correct focus ring and keyboard navigation behavior for free
- Access to the platform's theme tokens (so the component respects tenant-level branding changes)

Install:

```bash
npm install @fluentui/react
```

---

### Path-based imports to reduce bundle size

`@fluentui/react` is a large library. Importing from the package root causes webpack to include every component, icon, and utility — most of which the component does not use. This inflates the bundle size and degrades load performance inside Power Apps.

**Wrong — full library import:**

```typescript
import { Button, TextField, Stack, IStackTokens } from '@fluentui/react';
```

This import pulls in the entire `@fluentui/react` library regardless of which exports are actually used, because side effects and re-exports at the package root prevent dead-code elimination.

**Correct — path-based imports:**

```typescript
import { DefaultButton, PrimaryButton } from '@fluentui/react/lib/Button';
import { TextField } from '@fluentui/react/lib/TextField';
import { Stack } from '@fluentui/react/lib/Stack';
import type { IStackTokens } from '@fluentui/react/lib/Stack';
```

Each path (`/lib/Button`, `/lib/TextField`, etc.) maps to an individual CommonJS module. Webpack only bundles the modules actually referenced.

**Bundle size comparison (approximate):**

| Import style | Approximate contribution to bundle |
|---|---|
| `from '@fluentui/react'` | ~1.2 MB (minified) |
| `from '@fluentui/react/lib/Button'` | ~40 KB (minified) |

---

### Tree-shaking alternative via tsconfig.json

If your build pipeline supports ES module tree-shaking (webpack 5 with `sideEffects: false` in `package.json`), you can configure TypeScript to emit ES2015 modules, which enables the bundler to eliminate unused exports automatically.

`tsconfig.json` settings for tree-shaking:

```json
{
  "compilerOptions": {
    "module": "ES2015",
    "moduleResolution": "node",
    "target": "ES5"
  }
}
```

Note: PCF's default build uses CommonJS modules. Switching to ES2015 modules requires verifying that the PCF CLI build output is still valid. Path-based imports are the safer and more broadly supported approach and should be preferred unless the build pipeline is known to support full tree-shaking.

---

### Accessibility

Fluent UI components implement the ARIA specification and WAI-ARIA authoring practices for their respective widget patterns. Using them for interactive elements means:

- Buttons (`DefaultButton`, `PrimaryButton`, `IconButton`) respond to `Enter` and `Space` key presses without additional code
- Text inputs (`TextField`, `SearchBox`) announce labels to screen readers via `aria-label` or `aria-labelledby`
- Dropdowns and comboboxes (`Dropdown`, `ComboBox`) implement the ARIA `listbox` pattern including arrow-key navigation
- Dialog and Panel components manage focus trapping automatically

```typescript
import { PrimaryButton } from '@fluentui/react/lib/Button';
import { TextField } from '@fluentui/react/lib/TextField';

// Both components are keyboard-accessible and screen-reader-friendly
// without any additional aria-* attributes required from the developer
const AccessibleForm: React.FC = () => (
  <div>
    <TextField label="Search term" />
    <PrimaryButton text="Search" />
  </div>
);
```

When you need a custom interactive element that has no Fluent UI equivalent, add the appropriate `role`, `aria-label`, `tabIndex`, and key event handlers manually.

---

### Theming — expose input properties for app maker customization

PCF component CSS is bundled and cannot be edited by app makers after deployment. The correct extensibility pattern is to expose customization options as input properties in the component manifest and apply them using Fluent UI's `createTheme` and `ThemeProvider` APIs at runtime.

**Manifest input properties (ControlManifest.Input.xml):**

```xml
<property name="primaryColor"
          display-name-key="PrimaryColor"
          description-key="PrimaryColor_Desc"
          of-type="SingleLine.Text"
          usage="input"
          required="false" />
<property name="fontSize"
          display-name-key="FontSize"
          description-key="FontSize_Desc"
          of-type="Whole.Number"
          usage="input"
          required="false" />
```

**Applying the theme in the component:**

```typescript
import { ThemeProvider, createTheme } from '@fluentui/react/lib/Theme';
import { PrimaryButton } from '@fluentui/react/lib/Button';
import React, { useMemo } from 'react';

interface IThemedComponentProps {
  primaryColor: string;
  fontSize: number;
}

const ThemedComponent: React.FC<IThemedComponentProps> = React.memo(({ primaryColor, fontSize }) => {

  const theme = useMemo(() => createTheme({
    palette: {
      themePrimary: primaryColor || '#0078d4',
    },
    defaultFontStyle: {
      fontSize: fontSize ? `${fontSize}px` : '14px',
    },
  }), [primaryColor, fontSize]);

  return (
    <ThemeProvider theme={theme}>
      <PrimaryButton text="Submit" />
    </ThemeProvider>
  );
});
```

---

### CSS scoping — always use the component namespace class

PCF tooling generates a unique namespace class name derived from the component's namespace and name as defined in the manifest. This class is applied to the root container element that PCF provides. All CSS rules written for a component must be nested under this class to prevent them from leaking into the host application.

**Pattern:**

```css
/* Correct — scoped to the component namespace */
.SampleNamespace\.ComponentName .errorText {
  color: #a4262c;
  font-weight: 600;
}

.SampleNamespace\.ComponentName .container {
  display: flex;
  flex-direction: column;
  gap: 8px;
}
```

The dot-escaped dot (`.`) in `.SampleNamespace\.ComponentName` is required because the class name contains a literal period character.

**Wrong — global CSS rule:**

```css
/* Do not write global rules — these affect the entire Power Apps shell */
.errorText {
  color: red;
}

button {
  background-color: blue;
}
```

Global rules applied inside a PCF component's CSS bundle affect all elements in the Power Apps page that match the selector. This breaks the host app's styling and is extremely difficult to debug.

**Applying the namespace class in TypeScript (index.ts):**

```typescript
public init(
  context: ComponentFramework.Context<IInputs>,
  notifyOutputChanged: () => void,
  state: ComponentFramework.Dictionary,
  container: HTMLDivElement
): void {
  // The container already has the namespace class applied by the framework.
  // Render directly into it — do not wrap in an additional div.
  ReactDOM.render(
    React.createElement(MyComponent, this.getProps(context, notifyOutputChanged)),
    container
  );
}
```

---

## References

- [Code components best practices — HTML browser UI development — Microsoft Learn](https://learn.microsoft.com/power-apps/developer/component-framework/code-components-best-practices#html-browser-user-interface-development)
- [Fluent UI — Get started for web — Microsoft developer portal](https://developer.microsoft.com/fluentui#/get-started/web)
