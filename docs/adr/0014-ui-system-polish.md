# ADR-0014: Polishing the UI System and the design preferences page

- Status: accepted
- Date: 2026-11-21
- Deciders: project maintainer

## Context

The UI System of ADR-0012 shows every variant of every component, and the maintainer reviewed it in a
generated project. What he found: the page that opens from the user menu also had an entry in the
sidebar and a native `<select>` with its arrow glued to the edge; some previews overlapped (the skeleton
rows and circles); the tooltip showed only one way to anchor it; the modal and the drawer padded their
content area, so a long content put the scrollbar inside the padding; the disabled toggle disappeared in
dark mode; the `contrast` toast kept the white text of the normal toasts in dark mode; the tabs of the
catalog each kept their own active tab; the field lacked the eye of the password and the flags of the
phone picker; and some inputs of the components were never shown.

## Decision

1. **The page is reached from the user menu only.** Its navigation entry is `hidden` (an option that the
   navigation tree already had): the page keeps its title and its breadcrumb, the sidebar does not list
   it. The edit helper of the tree writes `hidden: () => true` for an entry that asks for it.
2. **The sidebar width of Apariencia uses `as-select`**, which the shell already ships, disabled while
   the transparent layouts are under construction.
3. **The overlays leave the padding to the content.** `as-modal` gets `flush`, as the drawer has: the
   content area has no padding and the content brings its own, so the scrollbar sits at the edge of the
   panel. The catalog previews use `flush` and show it, with the padded inner `div`, in the code.
4. **Theme tokens only.** The disabled toggle gets a border and a dark track from `theme-styles.css`; the
   `contrast` toast takes the title and message colours from the colour of its type, the inverse of the
   theme.
5. **The catalog covers every input.** A spec reads the inputs of each component
   (`reflectComponentType`) and fails when one is in no variant, unless the entry lists it in `notShown`
   with the reason (templates, classes, accessible names). Each property that applies to the three
   modes of the field, the textarea and the select is shown in `in`, `on` and `over`, named with its
   mode (`required variant="on"`).
6. **The password has its eye and the phone has its flags.** The catalog uses the pattern of the login of
   the reference application (`lucideIcon` Eye / EyeOff, `iconClickable`, `(iconClick)`). The flags are
   the sprite of flag-icons (MIT) that the reference application serves; the `as-input` blueprint writes
   it to `public/assets/flags-sprite.svg`, where its template already looked for it, and the notices
   list it.
7. **The tooltip is shown in both ways**, on the whole button (the host) and on its text, in each
   position. The tabs share one active tab in the groups `Estilos` and `Tamaños`, keep one each in
   `Contenido`, and show icons, counters, tabs that overflow with arrows and tabs that fit.
8. **The previews collapse with the accordion animation** of `animations.css` (`as-collapse-grid` and
   `is-collapsed`), the one of the card (visibility toggle) and the one of the code of all the variants.

## Alternatives considered

- **Removing the page from the navigation tree.** It would lose the title and the breadcrumb; `hidden`
  already means exactly this.
- **Padding the preview content instead of making the modal flush.** The scrollbar stays inside the
  padded area, which is the problem; `flush` is what the drawer already does.
- **A built-in eye in `as-input` for `type="password"`.** It changes a component that the reference
  application uses with its own state; the catalog documents the pattern instead.
- **A new `fullWidth` input for the tabs that fit.** The rail already fills its container; a wider box
  shows it.

## Consequences

- Positive: the catalog cannot silently miss an input again; the overlays and the theme behave in both
  modes; a generated project with the input brings the flags.
- Negative: the sprite is 2 MB in `public/assets` and the page is longer.
- Follow-up: the same `flush` for the modal of the reference application; a `fullWidth` for the tabs if
  stretched tabs are wanted.
