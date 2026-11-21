# ADR-0012: Every variant in the UI System and the components synced with the reference apps

- Status: accepted
- Date: 2026-11-21
- Deciders: project maintainer

## Context

The UI System (ADR-0010) lists the installed `as-` components with one preview each. That hides what
makes a component useful: the sizes of the button, the `in` / `on` / `over` modes and the types of the
field, the positions of the tooltip, the popover and the drawer, the states of the toggle and the
checkbox, the types of the toast. The drawer of the catalog also opened inside the content area, clipped
by the container, instead of over the whole page like the modal does.

The components themselves come from the maintainer's two applications, Omni Inbox (native components)
and YaloAtiendo Chat (wrappers over PrimeNG, improved after Omni was left aside). Before the catalog
shows every option, the components have to be the same in both applications and in the blueprints.

## Decision

1. **Components synced first.** A comparison of the components both applications share found that
   YaloAtiendo wraps PrimeNG on purpose while Omni and the blueprints are native, and that Omni is
   richer in API in most of them. Only what YaloAtiendo has and Omni lacks was ported, reimplemented
   natively and never copying PrimeNG code: the drawer (header, content and footer zones, `density`,
   `flush`, `closeIcon`, `closeLabel`, `styleClass`, and a panel mounted through the CDK overlay so it is
   a child of `<body>` and paints over the whole page), the select (`optionIconSize`, `hideOptionLabel`,
   `accentColor`, `panelStyleClass`), the modal (`titleDotColor`) and the button (`rounded`). The date
   inputs and the pill tabs of YaloAtiendo stay out: Omni solves dates with a separate datepicker and its
   tabs are `rounded-xl` by design. YaloAtiendo is left as it is; the differences are reported.
2. **The same pieces in the blueprints.** The blueprints of `drawer`, `select`, `modal` and `button` get
   the same change, renamed to `as-`, with their specs.
3. **One list of variants per component, in data.** Each entry of the catalog gets `variants`: an id, a
   chip name, a group (`Tamaños`, `Severidades`, `Modos`, `Tipos`, `Posición`, `Estados`…) and the
   properties that component receives. The preview paints every variant at once, grouped, and the
   code of a variant is generated from the same properties (`ui-system.code.ts`), so what is seen and
   what is copied cannot differ. Components without a dynamic setup (checkbox, tooltip, popover, tabs,
   divider) have their own template per variant; the rest go through `NgComponentOutlet`.
4. **The code follows the chosen variant.** A chip under each preview chooses a variant (the first by
   default); the code block shows its snippet (`size="xsmall"`), and a list shows the code of all of them.
5. **Overlays open over the page, with switches.** Modal and drawer have one button per variant (width
   and shape; the five positions and two widths) and switches for what they accept (footer, close
   button, closing by clicking outside or with Escape, compact density, flush, icon or dot in the title).
   The switches change the panel that opens and its code. The toast has a button per type and per
   position that calls `AlertService`.
6. **The variants are not tokens.** They live only in the catalog. The tokens of the UI tab (radius,
   button size, density, font size) stay CSS variables that the end user changes without touching
   code, and every preview follows them as before; the variants never read or write them.

## Alternatives considered

- **One variant at a time behind a selector.** Less noise, but the point is to compare variants side by
  side and to see all of them at once.
- **A code block under every variant.** Always visible, but the cards of the button and the field would
  be several screens tall; the chip plus a list of all the code keeps the card short.
- **Rewriting YaloAtiendo's wrappers as native components.** Another project: PrimeNG is deliberate
  there. Only a report of the differences is delivered.
- **Variants written by hand in the template.** The code would drift from the preview with every change;
  a data-driven catalog is checked by one spec.

## Consequences

- Positive: every option of every essential component is visible and copyable; the catalog is data, so
  adding a variant is one line and one spec; the drawer finally behaves like the modal.
- Negative: the catalog file grows (about 450 lines) and the page is longer; the components without a
  dynamic setup need a template case each.
- Follow-up: export `AsDrawerDensity` and `ButtonRounded` from the component manifest when the wizard
  work that owns it lands; variants for the components outside the essential collection.
