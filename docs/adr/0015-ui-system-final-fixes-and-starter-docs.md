# ADR-0015: Final fixes of the UI System and the documentation of AS Starter inside the app

- Status: accepted
- Date: 2026-11-23
- Deciders: project maintainer

## Context

The maintainer reviewed a generated project (`InventorySystem`) after ADR-0012 and ADR-0014 and asked for
a last round of fixes before moving on to the layouts of the app shell. What he found:

- The welcome page sent "Angular documentation" and "Learn with tutorials" to angular.dev; he wants the
  documentation and the tutorials to be those of AS Starter, a page of ours in the style of Angular's.
- In dark mode the chips of the catalog (the variant names and the tokens under "Cambia con") were
  lighter than the fields they describe.
- The tag input (`isTagInput`) in `in` and `over` drew its label as a dark box inside the field, with
  only its top corners rounded, and its box was 2 to 4 px taller than a plain input, so a row of `over`
  fields did not line up.
- The textarea in `in` printed the text over the label (the text started at 10px, the label ends at
  26px), and a left or right icon covered the text. The `over` label moved right for a left icon even
  though it lives above the field.
- The tooltip on the whole button (the host) anchored `top` and `bottom` to the text line while `left`
  and `right` were correctly outside the button.
- The modal could always be dragged; the maintainer wants that to be a property.
- The tabs of the catalog shared the active tab inside Estilos and Tamaños (ADR-0014); he now wants
  every example to be independent.

Most of this was already improved in Omni Inbox and YaloAtiendo-Chat, or is better solved there first:
the components of the starter are ports of Omni's, so each fix is made in Omni (with its spec) and then
brought to the `as-*` blueprints.

## Decision

1. **The documentation is part of the welcome page.** `blueprints/welcome` brings `features/docs`: a side
   menu and one page per topic (getting started, design base, native components, app shell) and a
   tutorials page with numbered steps. The pages are data (`docs.data.ts`), each with its own lazy
   route (`/docs/<page>`, `/docs` opens the first) and a Documentation item in the navigation tree. The
   two cards become "AS Starter documentation" (`/docs`) and "Learn with tutorials" (`/docs/tutorials`);
   nothing on the page links to angular.dev. The docs go with the welcome page: a home the developer
   changed, or a `features/docs` they already have, is left alone together.
2. **Chips use the dark surface of the fields.** The variant chips and the token chips paint with
   `--app-control-surface-bg`; the chosen chip is marked by the primary colour of its text and border,
   not by a lighter background. Light and dark follow the token.
3. **Labels round on every corner.** The label background of `as-input` and `as-textarea` is `rounded-md`,
   as the select's. The `over` label no longer moves for a left icon.
4. **The tag input follows the variant.** In `in` and `over` its label uses the same classes as the other
   fields (inside above the text, or above the field) instead of a hard-coded dark box, and its box has
   the height of a plain input in each mode (40px, 54px in `in`).
5. **The textarea reserves its space.** In `in` the text starts under the label (24px, as the input); a
   left or right icon reserves its side; the icon lines up with the first line of text. The readonly
   select shows a chosen value in each mode of the catalog.
6. **The tooltip anchors to what the host paints.** An inline host (a component such as `as-button`) only
   reports its text line, so the directive anchors to the union of the host and its children; the text
   mode (the directive on a `span`) keeps the text.
7. **`as-modal` gets `draggable`** (default `true`, as before). With `false` the header does not move the
   panel and it keeps its centring; closing and resizing do not change. The catalog has a "Se puede
   mover" switch that writes `[draggable]="false"` in the code.
8. **The tabs of the catalog are independent.** `sharedGroups` and the shared active tab are removed;
   each example keeps its own.

## Alternatives considered

- **A page that only links to the repository documentation.** It keeps the app small but sends the
  developer out of the project; the maintainer chose documentation inside the app.
- **`draggable` false by default** (as in YaloAtiendo-Chat, whose modal has no drag at all). It changes
  every existing modal; the default stays as it is.
- **Fixing the tooltip with `display: inline-flex` on `as-button`.** It changes the layout of every
  button that sits in a line of text; anchoring the tooltip is local.
- **Reserving the label space of `over` even without a label.** It would change forms that rely on the
  field being flush; fields in a row line up because their boxes now have the same height.

## Consequences

- Positive: a generated project documents itself with AS Starter's own pages; the catalog and the
  components agree with Omni in the dark theme; the fixed behaviours have specs in Omni and in the
  blueprints.
- Negative: the welcome page now brings a `docs` feature that the developer deletes if not wanted
  (its README says how); the docs are English prose in data, to be edited by hand.
- Follow-up: translate or extend the pages as the starter grows (presence, routing); a search over the
  documentation if it gets long.
