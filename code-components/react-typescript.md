# React and TypeScript Patterns for PCF Components

---

## For consultants

When building PCF (Power Apps Component Framework) code components, React and TypeScript are the recommended combination. TypeScript catches bugs at compile time rather than runtime, and React's functional component model with hooks keeps code predictable and easy to test.

The most important rules in practice:

- **Never use `any` types.** If TypeScript cannot infer a type, write it explicitly. Using `any` defeats the purpose of TypeScript and will fail the linting gate.
- **Use functional components with hooks, not class components.** Functional components are shorter, easier to read, and hooks replace everything lifecycle methods used to do.
- **Wrap every PCF root component in `React.memo`.** PCF calls `updateView` frequently. Without `React.memo`, the entire component tree re-renders even when nothing has changed.
- **Wrap event handlers in `useCallback`.** This keeps the handler reference stable between renders, preventing child components from re-rendering needlessly.
- **Wrap expensive calculations in `useMemo`.** If a value is derived from props or state through a costly operation, memoize it.
- **Never write arrow functions or `.bind()` calls directly in JSX.** These create a new function reference on every render, defeating memoization.
- **Never use inline styles.** Use scoped CSS class names instead — this keeps styles predictable and avoids collisions with the host app.
- **Always bundle dependencies.** Never load libraries via `<script>` tags. Everything must go through the webpack bundle that PCF tooling produces.

---

## Technical specification

### TypeScript strict typing — no `any` types

TypeScript's value in PCF components comes from its ability to surface type mismatches before the component reaches a Dataverse environment. The `any` type disables this protection entirely.

Enable strict mode in `tsconfig.json`:

```json
{
  "compilerOptions": {
    "strict": true,
    "noImplicitAny": true,
    "strictNullChecks": true,
    "strictFunctionTypes": true,
    "strictPropertyInitialization": true
  }
}
```

When the type of a value coming from PCF context is unclear, use the types exported by `@types/powerapps-component-framework` rather than falling back to `any`. For example:

```typescript
// Wrong
const value: any = context.parameters.sampleProperty.raw;

// Correct
const value: string | null = context.parameters.sampleProperty.raw;
```

Microsoft's official best practices state: "Avoid using the `any` type in TypeScript as this effectively disables type checking."

Source: [Code components best practices](https://learn.microsoft.com/power-apps/developer/component-framework/code-components-best-practices)

---

### Functional components vs class components

Class components require boilerplate (`constructor`, `this`, lifecycle method names) and make it harder to share stateful logic between components. React hooks, available only in functional components, solve both problems.

**Recommended pattern — functional component:**

```typescript
import React, { useState, useCallback, useMemo } from 'react';

interface ISampleComponentProps {
  label: string;
  value: number;
  onChange: (newValue: number) => void;
}

const SampleComponent: React.FC<ISampleComponentProps> = React.memo(({ label, value, onChange }) => {
  const [localValue, setLocalValue] = useState<number>(value);

  const handleChange = useCallback((newVal: number) => {
    setLocalValue(newVal);
    onChange(newVal);
  }, [onChange]);

  return (
    <div>
      <label>{label}</label>
      <input type="number" value={localValue} onChange={(e) => handleChange(Number(e.target.value))} />
    </div>
  );
});

SampleComponent.displayName = 'SampleComponent';
export default SampleComponent;
```

**Avoid — class component:**

```typescript
// Do not use class components in new PCF development
class SampleComponent extends React.Component<ISampleComponentProps> {
  render() {
    return <div>{this.props.label}</div>;
  }
}
```

---

### React.memo — wrap every PCF root component

PCF's `updateView` method is called whenever any property in the control manifest changes, or when the framework decides a refresh is needed. Without `React.memo`, React re-renders the entire component tree on every such call, even if the values passed to the component are identical.

`React.memo` performs a shallow comparison of props. If props have not changed, the component is skipped.

```typescript
// Wrap the root component exported from index.ts
const MyPCFComponent: React.FC<IMyPCFComponentProps> = React.memo((props) => {
  // component body
});

export default MyPCFComponent;
```

For deep equality needs (e.g., object props), pass a custom comparison function as the second argument:

```typescript
const MyPCFComponent = React.memo(
  (props: IMyPCFComponentProps) => { /* ... */ },
  (prevProps, nextProps) => prevProps.selectedId === nextProps.selectedId
);
```

---

### useCallback — stable event handler references

Every function defined inside a React component body is recreated on each render. When that function is passed as a prop to a child component, the child sees a new prop reference and re-renders — even when `React.memo` is in use.

`useCallback` returns a memoized version of the function that only changes when its dependency array changes.

```typescript
const handleButtonClick = useCallback((itemId: string) => {
  props.notifyOutputChanged({ selectedId: itemId });
}, [props.notifyOutputChanged]);

// Pass to child without triggering unnecessary re-renders
return <ChildComponent onSelect={handleButtonClick} />;
```

**Wrong — creates a new function reference on every render:**

```typescript
return (
  <ChildComponent
    onSelect={(itemId) => props.notifyOutputChanged({ selectedId: itemId })}
  />
);
```

---

### useMemo — memoize expensive calculations

Use `useMemo` when a derived value requires significant computation and its inputs do not change on every render.

**Example — filtering and sorting a large dataset:**

```typescript
interface IRecord {
  id: string;
  name: string;
  score: number;
}

const SortedFilteredList: React.FC<{ records: IRecord[]; minScore: number }> = React.memo(({ records, minScore }) => {

  const visibleRecords = useMemo(() => {
    // Potentially expensive: filter + sort over hundreds of records
    return records
      .filter((r) => r.score >= minScore)
      .sort((a, b) => b.score - a.score);
  }, [records, minScore]); // Only recomputes when records or minScore changes

  return (
    <ul>
      {visibleRecords.map((r) => (
        <li key={r.id}>{r.name} — {r.score}</li>
      ))}
    </ul>
  );
});
```

Do not use `useMemo` for trivial computations (string concatenation, simple arithmetic). The overhead of memoization outweighs the benefit for simple operations.

---

### Avoid arrow functions and function binding in render

Inline arrow functions and `.bind()` calls in JSX create a new function instance on every render pass. This breaks `React.memo` and `useCallback` optimizations on child components.

```typescript
// Wrong — new function reference on every render
<button onClick={() => handleAction(item.id)}>Click</button>

// Wrong — .bind() has the same problem
<button onClick={handleAction.bind(this, item.id)}>Click</button>

// Correct — stable reference via useCallback
const handleClick = useCallback(() => {
  handleAction(item.id);
}, [item.id]);

<button onClick={handleClick}>Click</button>
```

When a handler needs to capture a loop variable (e.g., rendering a list), extract the item into a child component that receives the handler and the id as props, and wrap that child in `React.memo`.

---

### Avoid inline styles

Inline styles bypass the CSS scoping mechanism that PCF tooling provides, make theming impossible, and contribute to specificity conflicts with the host Power Apps shell.

```typescript
// Wrong
<div style={{ color: 'red', fontSize: '14px' }}>Text</div>

// Correct — use a CSS module or a scoped class name
<div className={styles.errorText}>Text</div>
```

Define styles in a `.css` file imported into the component. PCF tooling auto-generates a namespace wrapper to prevent leaking into the host app. See `fluent-ui-guide.md` for the CSS scoping pattern.

---

### Module imports — always bundle, never use SCRIPT tags

PCF components run inside the Power Apps shell, which does not guarantee any global libraries are present. Loading libraries via `<script>` tags or dynamic `document.createElement('script')` calls is unreliable and violates the PCF sandboxing contract.

All dependencies must be declared in `package.json` and imported as ES modules. The PCF build toolchain (webpack-based) bundles them into the component's output.

```typescript
// Correct — bundled import
import { Stack } from '@fluentui/react/lib/Stack';

// Wrong — do not inject script tags
const script = document.createElement('script');
script.src = 'https://cdn.example.com/library.js';
document.head.appendChild(script);
```

---

### ES5 vs ES6 target in tsconfig.json

PCF components must run in the browsers supported by Power Apps. The `target` field in `tsconfig.json` controls what JavaScript syntax TypeScript emits.

| Target | Use when |
|--------|----------|
| `ES5` | Default for new components; broadest browser compatibility including older Chromium-based Power Apps clients |
| `ES6` / `ES2015` | Acceptable when the component is confirmed to run only in modern evergreen browsers; enables native `class`, arrow functions, `const`/`let` in output |
| `ES2017`+ | Required if using `async`/`await` without a polyfill in the output |

The PCF toolchain defaults to `ES5`. Only upgrade the target after verifying the minimum browser requirements of the environments where the component will be deployed.

```json
{
  "compilerOptions": {
    "target": "ES5",
    "module": "CommonJS",
    "lib": ["ES2015", "DOM"],
    "jsx": "react",
    "strict": true
  }
}
```

---

### ESLint setup for TypeScript and React

Microsoft's official documentation recommends ESLint for static analysis of PCF components. The following commands install the required packages:

```bash
npm install --save-dev eslint @typescript-eslint/parser @typescript-eslint/eslint-plugin eslint-plugin-react eslint-plugin-react-hooks
```

Minimal `.eslintrc.json` configuration:

```json
{
  "parser": "@typescript-eslint/parser",
  "parserOptions": {
    "ecmaVersion": 2020,
    "sourceType": "module",
    "ecmaFeatures": {
      "jsx": true
    }
  },
  "settings": {
    "react": {
      "version": "detect"
    }
  },
  "extends": [
    "eslint:recommended",
    "plugin:@typescript-eslint/recommended",
    "plugin:react/recommended",
    "plugin:react-hooks/recommended"
  ],
  "rules": {
    "@typescript-eslint/no-explicit-any": "error",
    "react-hooks/rules-of-hooks": "error",
    "react-hooks/exhaustive-deps": "warn",
    "no-console": "error"
  }
}
```

Add the lint script to `package.json`:

```json
{
  "scripts": {
    "lint": "eslint . --ext .ts,.tsx"
  }
}
```

Run before every build:

```bash
npm run lint
```

Source: [Debugging custom controls](https://learn.microsoft.com/power-apps/developer/component-framework/debugging-custom-controls)

---

## References

- [Code components best practices — Microsoft Learn](https://learn.microsoft.com/power-apps/developer/component-framework/code-components-best-practices)
- [Debugging custom controls — Microsoft Learn](https://learn.microsoft.com/power-apps/developer/component-framework/debugging-custom-controls)
