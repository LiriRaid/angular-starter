# shared/components

Reusable UI components with no business knowledge. They are the generic part of the reference
application, renamed with the `sa-` prefix, and they are yours: edit them freely.

Import them from the barrel, never from a component's folder:

```ts
import { SaButton, SaIcon } from '@shared/components';
```

```html
<sa-button label="Save" icon="Check" (onClick)="save()" />
```

Each folder holds one component with its template, stylesheet and spec. A component can import the
ones it needs (`sa-button` draws its icon with `sa-icon`), so a folder you delete may be used by another
one. The stylesheets that do not belong to one component (`src/styles/components`) are imported from
`styles.css`, which only imports those of the components that exist.

A component that one feature alone uses stays in that feature (`sa generate component <name> --feature
<feature>`); `sa generate component <name> --shared` creates one here and exports it from the barrel.

## What this project has

The list below is rewritten every time components are added (`sa add components`); write your own notes
outside of it.

<!-- as:generated -->
<!-- /as:generated -->
