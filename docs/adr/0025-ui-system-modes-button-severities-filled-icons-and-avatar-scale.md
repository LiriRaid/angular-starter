# ADR-0025: The mode of a field is a setting of its card; the button has its eight severities; icons can be filled; the avatar letters follow its size

- Status: accepted
- Date: 2026-11-25
- Deciders: project maintainer
- Refines: [ADR-0024](0024-ui-system-by-installed-components-budgets-and-project-readme.md) (the catalog of the UI System)

## Context

Trying the global CLI on a default Angular project and opening the UI tab of `/preference-design` showed four
problems in the generated project.

- The cards of `sa-input`, `sa-textarea` and `sa-select` multiplied every option by the three modes
  (`required`, `readonlyInput`, icons, `showClear`, `multiselect`… in `on`, `in` and `over`), so the card was a
  wall of chips.
- The severities of `sa-button` did not work. The type has the eight of PrimeNG (`primary`, `secondary`,
  `success`, `info`, `warn`, `help`, `danger`, `contrast`) but the stylesheet only knew four; the other four
  fell back on the primary colour. In dark, `success` and `danger` were never darkened on hover (Aura's
  400 → 300 → 200 ramp, and a global rule that forced white text over the dark ramp), the `text` variant of
  `success` and `danger` was painted as a solid block (`.dark .sa-btn-success` beat the base of `text`), and
  `outlined` by severity looked the same for every severity because an unlayered rule for plain `outlined`
  overrode the layered rules of each severity.
- An icon could only be a stroke: the filled star of the reference application is done with a utility class that
  the starter does not require.
- The letters of `sa-avatar` had a fixed caption size, so a 24 px avatar had almost the same letters as a 56 px
  one.

## Decision

1. **The mode is a setting of the card.** An entry of the catalog can declare `modes` (`on`, `in`, `over`, for the
   three fields). The card shows a row of chips `Modo variant`, every variant that does not fix its own mode is
   shown in the chosen one, and the code carries `variant="…"` only when it is not the default of the component.
   The group `Modos` stays, with the three modes side by side. The options of a field (`required`,
   `readonlyInput`, icons, `showClear`, `multiselect`…) exist once. A hand-written code may be a function of the
   properties, so the password example follows the mode.
2. **A severity is a block of custom properties.** Each of the eight classes `.sa-btn-<severity>` sets
   `--sa-sev`, `--sa-sev-hover`, `--sa-sev-active`, `--sa-sev-on` and `--sa-sev-ink`; the filled button, `outlined`,
   `text` and the focus ring are written once and read them, so the colour of a severity always wins and never
   mixes with another. Without a severity the button keeps the primary colour of the theme, with
   `var(--sa-sev, var(--sa-primary-color))`, and `primary` is the same colour spelled as a severity. The palette is
   Aura's: `info` sky, `warn` orange, `help` purple, `danger` red, `success` green, `contrast` surface-950 (white
   in dark). The solid ramp is the same in light and dark (500 → 600 → 700, darker on hover and on press, like the
   primary colour); only the ink of `outlined` and `text` is a tone lighter in dark. The tints are
   `color-mix` of the ink. `outlined secondary` is left as the neutral outlined button, which already looked right
   in light and follows the mode tokens in dark.
3. **Filled icons.** `sa-icon` has `filled` (the inside takes the colour of the stroke) and `fillColor` (a colour of
   its own, which wins over `filled`), applied as the CSS `fill` of the Lucide icon, so it works without Tailwind.
   The catalog shows them in a group `Relleno`.
4. **The letters follow the size.** `sa-avatar` picks the Tailwind size of the initials from its size, about a third of
   it (`text-[8px]` up to `text-5xl`, each class written out so that Tailwind finds it), an arbitrary size for the
   smallest ones, and a `calc` of the size when it is given in CSS. A `textClass` of the consumer that sets its own
   text size wins; the consumers of the starter (`sa-select`, `sa-tabs`, the user menu) no longer set one. The
   catalog shows sizes from 24 to 80.

## Alternatives considered

- **One toggle per mode** with `UiOption`: an option has two values and a mode has three.
- **Aura's dark ramp** (400 → 300 → 200, lighter on hover): it is what PrimeNG does, but it is the behaviour that
  was reported as wrong, and the primary colour of the starter already darkens in both modes.
- **A rule per severity and variant**: about 100 rules and the same specificity fights that caused the bugs.
- **`fill-current` as the only way**: it needs Tailwind and cannot give the fill a colour of its own.

## Consequences

- Positive: a card of a field has a third of the chips; every severity works in light and dark, in all variants and
  states, and none falls back on the primary colour; filled icons and proportional letters need no extra setup.
- Negative: `outlined`/`text` buttons with a severity now show that colour (before, an outlined `danger` was neutral
  until hover); `text secondary` and the avatars of `sa-select` (22 px, now 9 px letters) look different. A project
  made before keeps its files until `sa add` refreshes them.
- Follow-up: dark variants for the checkbox and toggle, if they need severities too.
