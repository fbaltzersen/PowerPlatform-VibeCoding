# PCF Lifecycle Methods — init, updateView, destroy

---

## For consultants

A PCF component has three mandatory lifecycle methods. Understanding what belongs in each one is the most common source of bugs in delivered components.

- **`init`** runs once when the component is first added to the page. This is where you set up state, subscribe to resize events, and render the initial UI.
- **`updateView`** runs every time a property changes or the framework decides a refresh is needed. It can run many times. Always check `updatedProperties` to find out what actually changed, and skip work that is not relevant.
- **`destroy`** runs when the component is removed from the page (navigation, form close, record delete). You must clean up everything you created — event listeners, WebSocket connections, React trees.

The most common bugs seen in production PCF components:

- **Memory leaks from missing destroy().** An event listener added in `init` that is never removed in `destroy` keeps a reference to the component alive after it is gone, leaking memory on every form open.
- **Unnecessary re-renders from not checking updatedProperties.** If `updateView` always re-renders regardless of what changed, the component flickers and performs poorly.
- **Calling notifyOutputChanged on every keypress.** This triggers a Dataverse save attempt (in some configurations) and causes visible lag. Debounce it.

---

## Technical specification

### Lifecycle overview

```
Component loaded by Power Apps
         |
         v
    ┌─────────┐
    │  init() │  ← Called once. Initialize state, render first UI, subscribe to resize.
    └────┬────┘
         |
         v
  ┌─────────────┐
  │ updateView()│  ← Called on every property change or framework refresh.
  │  (repeating)│     Check updatedProperties. Re-render only what changed.
  └──────┬──────┘
         |
   (component removed from page)
         |
         v
   ┌──────────┐
   │ destroy()│  ← Called once on unload. Clean up all resources.
   └──────────┘
```

---

### init()

**Purpose:** One-time initialization. The `init` method receives the PCF context, the output-changed callback, the persisted state dictionary, and the host container `HTMLDivElement`. This is the only time the container reference is provided.

**What to do in init:**

- Render the initial React tree via `ReactDOM.render`
- Store `notifyOutputChanged` and `context` references for later use
- Call `context.mode.trackContainerResize(true)` if the component must respond to size changes
- Initialize any internal state that persists across `updateView` calls
- Begin any one-time asynchronous operations (e.g., fetching lookup data via `context.webAPI`)

**What not to do in init:**

- Do not perform work that depends on final property values — properties are available but may not yet reflect the record's committed state
- Do not assume the container has a non-zero size — dimensions are provided in `updateView`

**Code example:**

```typescript
import { IInputs, IOutputs } from './generated/ManifestTypes';
import React from 'react';
import ReactDOM from 'react-dom';
import { MyComponent } from './components/MyComponent';

export class SampleControl implements ComponentFramework.StandardControl<IInputs, IOutputs> {

  private _container: HTMLDivElement;
  private _notifyOutputChanged: () => void;
  private _context: ComponentFramework.Context<IInputs>;

  public init(
    context: ComponentFramework.Context<IInputs>,
    notifyOutputChanged: () => void,
    state: ComponentFramework.Dictionary,
    container: HTMLDivElement
  ): void {
    this._container = container;
    this._notifyOutputChanged = notifyOutputChanged;
    this._context = context;

    // Subscribe to container resize events so updateView receives
    // allocatedWidth and allocatedHeight when the container changes size
    context.mode.trackContainerResize(true);

    // Render initial UI
    ReactDOM.render(
      React.createElement(MyComponent, {
        value: context.parameters.sampleProperty.raw ?? '',
        onChange: this._handleChange,
        width: context.mode.allocatedWidth,
        height: context.mode.allocatedHeight,
      }),
      this._container
    );
  }

  private _handleChange = (newValue: string): void => {
    this._outputValue = newValue;
    this._debouncedNotify();
  };

  private _outputValue: string = '';
}
```

Source: [init — Microsoft Learn](https://learn.microsoft.com/power-apps/developer/component-framework/reference/control/init)

---

### updateView()

**Purpose:** Called by the framework whenever the component's input properties change, the record is refreshed, or the container size changes (if `trackContainerResize` was enabled). It is not called on a fixed interval — it is event-driven, but it can fire frequently.

**What to do in updateView:**

- Check `context.updatedProperties` to determine what actually changed
- Only re-render or recompute if a relevant property changed
- Update the React tree via `ReactDOM.render` with new props (React's reconciler handles diffing)
- Read `context.mode.allocatedWidth` and `context.mode.allocatedHeight` if responding to resize

**What not to do in updateView:**

- Do not perform unconditional re-renders — always guard with `updatedProperties`
- Do not re-initialize state that was set up in `init`
- Do not call `notifyOutputChanged` from within `updateView` — this creates a feedback loop
- Do not access `context.webAPI` in updateView for operations that are not truly update-triggered

**updatedProperties guard pattern:**

```typescript
public updateView(context: ComponentFramework.Context<IInputs>): void {
  this._context = context;

  const updated = context.updatedProperties;

  // Only re-render if a property the component actually uses has changed
  const relevantChange =
    updated.includes('sampleProperty') ||
    updated.includes('allocatedWidth') ||
    updated.includes('allocatedHeight');

  if (!relevantChange) {
    return; // Nothing relevant changed — skip re-render
  }

  ReactDOM.render(
    React.createElement(MyComponent, {
      value: context.parameters.sampleProperty.raw ?? '',
      onChange: this._handleChange,
      width: context.mode.allocatedWidth,
      height: context.mode.allocatedHeight,
    }),
    this._container
  );
}
```

Source: [updateView — Microsoft Learn](https://learn.microsoft.com/power-apps/developer/component-framework/reference/control/updateview)
Source: [updatedProperties — Microsoft Learn](https://learn.microsoft.com/power-apps/developer/component-framework/reference/updatedproperties)

---

### destroy()

**Purpose:** Called once when the component is removed from the DOM — on page navigation, form close, or record deletion. This is the last opportunity to release resources.

**What must be cleaned up:**

| Resource | Cleanup action |
|---|---|
| React component tree | `ReactDOM.unmountComponentAtNode(this._container)` |
| DOM event listeners | `element.removeEventListener(type, handler)` |
| WebSocket connections | `socket.close()` |
| `setInterval` / `setTimeout` handles | `clearInterval(handle)` / `clearTimeout(handle)` |
| Subscription objects (RxJS, etc.) | `subscription.unsubscribe()` |
| ResizeObserver | `observer.disconnect()` |

Failing to call `ReactDOM.unmountComponentAtNode` causes React's internal state and effect cleanup (`useEffect` return functions) to never run, leaking memory and potentially causing orphaned async operations to call `setState` on unmounted components (which produces React warnings and can crash the host app).

**Code example:**

```typescript
public destroy(): void {
  // 1. Unmount the React tree — triggers useEffect cleanup functions
  ReactDOM.unmountComponentAtNode(this._container);

  // 2. Remove any DOM event listeners added in init
  if (this._resizeObserver) {
    this._resizeObserver.disconnect();
    this._resizeObserver = null;
  }

  // 3. Close any open connections
  if (this._webSocket) {
    this._webSocket.close();
    this._webSocket = null;
  }

  // 4. Cancel debounce timers
  if (this._debounceTimer) {
    clearTimeout(this._debounceTimer);
    this._debounceTimer = null;
  }
}
```

Source: [destroy — Microsoft Learn](https://learn.microsoft.com/power-apps/developer/component-framework/reference/control/destroy)

---

### notifyOutputChanged() — debounce pattern

`notifyOutputChanged` signals to the Power Apps framework that the component has a new output value. In model-driven apps, this can trigger form dirty-state tracking. Calling it on every keystroke in a text field causes:

- Excessive dirty-state change events
- Degraded typing performance (especially in model-driven forms)
- Potential race conditions with autosave

**Debounce pattern:**

```typescript
private _debounceTimer: ReturnType<typeof setTimeout> | null = null;
private _pendingOutputValue: string = '';

private _handleChange = (newValue: string): void => {
  this._pendingOutputValue = newValue;

  if (this._debounceTimer) {
    clearTimeout(this._debounceTimer);
  }

  // Wait 300ms of inactivity before notifying the framework
  this._debounceTimer = setTimeout(() => {
    this._outputValue = this._pendingOutputValue;
    this._notifyOutputChanged();
    this._debounceTimer = null;
  }, 300);
};

public getOutputs(): IOutputs {
  return {
    sampleProperty: this._outputValue,
  };
}
```

---

### Null safety in updateView

PCF properties are typed as nullable. When `updateView` is called early in the component's lifecycle, or when a record field has no value, `context.parameters.propertyName.raw` may be `null`. Always guard against null before using a value.

```typescript
public updateView(context: ComponentFramework.Context<IInputs>): void {
  // Null-safe access — provide a sensible default
  const rawValue = context.parameters.sampleProperty.raw ?? '';

  // Also check the property state
  if (context.parameters.sampleProperty.error) {
    // Handle error state (e.g., show validation message)
    console.error(context.parameters.sampleProperty.errorMessage);
    return;
  }

  ReactDOM.render(
    React.createElement(MyComponent, { value: rawValue }),
    this._container
  );
}
```

---

### context.webAPI — check availability before use

`context.webAPI` is available in model-driven apps and provides access to Dataverse operations (create, retrieve, update, delete). It is **not available in canvas apps**.

Before using `context.webAPI`, verify it exists:

```typescript
public init(
  context: ComponentFramework.Context<IInputs>,
  notifyOutputChanged: () => void,
  state: ComponentFramework.Dictionary,
  container: HTMLDivElement
): void {
  if (context.webAPI) {
    // Safe to use webAPI — running in a model-driven app
    context.webAPI
      .retrieveMultipleRecords('account', '?$select=name&$top=10')
      .then((result) => {
        this._accounts = result.entities.map((e) => e['name'] as string);
        this._notifyOutputChanged();
      })
      .catch((error) => {
        console.error('Failed to retrieve accounts:', error.message);
      });
  }
  // If webAPI is not available (canvas app), use input properties instead
}
```

For cross-platform components that target both model-driven and canvas apps, rely exclusively on input properties for data and avoid `context.webAPI`.

---

### Never interact with formContext directly

PCF components do not have access to the Xrm object model (`Xrm.Page`, `formContext`) by design. Attempting to access these via `(window as any).Xrm` or similar patterns:

- Creates an undocumented dependency on the host page structure
- Breaks when the component is used outside a model-driven form (canvas app, portal, Teams app)
- Is not supported and may break without notice on platform updates

If a component needs to respond to form-level events, expose output properties and let the form's business rules or Power Automate flows react to them.

---

### Never deploy development builds to Dataverse

The PCF CLI produces two build modes:

| Mode | Command | Output |
|---|---|---|
| Development | `npm run build` | Unminified, includes source maps and debug tooling |
| Release | `npm run build -- --flag Release` | Minified, optimized, no debug tooling |

Development builds are significantly larger and may contain code paths that behave differently in production. Only release builds should be packaged and deployed to Dataverse environments.

```bash
# Correct — release build
npm run build -- --flag Release

# Wrong — development build (do not deploy)
npm run build
```

Source: [Code components best practices — Microsoft Learn](https://learn.microsoft.com/power-apps/developer/component-framework/code-components-best-practices)

---

## References

- [init — PCF reference — Microsoft Learn](https://learn.microsoft.com/power-apps/developer/component-framework/reference/control/init)
- [updateView — PCF reference — Microsoft Learn](https://learn.microsoft.com/power-apps/developer/component-framework/reference/control/updateview)
- [destroy — PCF reference — Microsoft Learn](https://learn.microsoft.com/power-apps/developer/component-framework/reference/control/destroy)
- [updatedProperties — PCF reference — Microsoft Learn](https://learn.microsoft.com/power-apps/developer/component-framework/reference/updatedproperties)
- [Code components best practices — Microsoft Learn](https://learn.microsoft.com/power-apps/developer/component-framework/code-components-best-practices)
