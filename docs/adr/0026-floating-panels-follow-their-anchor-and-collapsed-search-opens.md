# ADR-0026: Floating panels are centred on their anchor and follow it when a container scrolls; the collapsed search opens

- Status: accepted
- Date: 2026-11-25
- Deciders: project maintainer
- Refines: [ADR-0025](0025-ui-system-modes-button-severities-filled-icons-and-avatar-scale.md), which left `sa-search`, the popover and the colour picker out of scope

## Context

Opening the UI tab of `/preference-design` of a generated project showed three problems.

- `sa-search` with `mode="collapsed"` is a lone button that does nothing when pressed. In the reference application
  the parent decides the mode (the sidebar expands and focuses the field; the list of conversations shows its search
  below the magnifier), and the catalog did not wire it.
- The panel of `sa-theme-color-picker` started to the left of its button and its arrow pointed somewhere else. The
  picker added `+45` or `-35` px to its horizontal position depending on the width of the window, a correction that
  was tuned by hand against the header of the application it was copied from, and `sa-popover` with `actions` and
  `position="bottom"` subtracted `90` px at 1400 px or less for the same reason. In any other layout the panel was
  off its anchor.
- Only `sa-popover` hid its panel when a scroll container took its anchor out of sight. The colour picker, the
  datepicker and the select either measured against the whole window, or (the select) only repositioned on
  `resize`. Their panels are `position: fixed`, so on scroll they stayed stuck to the window instead of following
  the anchor.

## Decision

1. **A panel is centred on its anchor, always.** The hand-made horizontal corrections are gone. The panel is
   centred on the anchor and moved only as much as it needs to be visible, and the arrow keeps pointing at the
   centre of the anchor. The colour picker uses the same layout functions as `sa-popover`
   (`resolvePopoverPlacement` and `getPopoverPanelLayout`), so both behave the same in a header, a toolbar or a
   card. Nobody has to calibrate it for a new app shell.
2. **A panel follows its anchor.** While a panel of the popover, the colour picker, the datepicker or the select is
   open, the scroll of any container (listened to in the capture phase) and the `resize` reposition it. The space for
   top or bottom is measured against the visible area of the anchor (`visibleBounds`: the window clipped by every
   scrolling container around it), and when the anchor is no longer inside that area (`isAnchorOutOfView`) the panel
   closes instead of floating without an anchor. An anchor with no size (hidden or unmounted) is not measured, as
   `sa-popover` already did. `getSelectPanelLayout` and `buildDatepickerPanelLayout` take the optional `bounds`;
   without it they measure against the window, as before.
3. **One helper per job.** `isAnchorOutOfView` joins `visibleBounds`, `isOutOfBounds` and `resolveSide` in
   `panel-placement.ts`; `addNativeOverlayRepositionListeners` and its counterpart are the listening half of
   `native-overlay-dismiss.ts`, used by the select (whose `popover="auto"` panel is already closed by the browser on an
   outside click or Escape) and by the two functions that already listened to everything.
4. **The collapsed search opens.** `sa-search` keeps the contract of the reference (it emits
   `collapsedSearchClick`, the parent changes `mode`) and now puts the cursor in its field when the parent expands it
   after that click, so no parent has to look for the input. A change of mode that did not come from the button does
   not take the focus. The catalog wires the collapsed variant like the sidebar does: the button opens the field and
   focuses it, Escape closes it and clears it, and losing the focus with the field empty closes it; with text it stays
   open so it never hides an active filter. That variant has a control of its own, so what is typed in it does not
   appear in the other modes.

## Alternatives considered

- **Keep the offsets as an input** (`offsetX`) for each shell: the default would be right, but every shell would
  carry its own magic number, which is what went wrong.
- **Make `sa-search` open itself**: it would duplicate a state the sidebar already owns and break the contract of the
  reference.
- **Close the select on any scroll** (what PrimeNG does): the reference keeps the panel with the anchor and closes it
  only when the anchor leaves, which is the behaviour the user asked for.

## Consequences

- Positive: the panels of the picker and the popover are centred in any layout, light and dark; all four floating
  panels follow the anchor and close when it leaves its container; the collapsed search is usable without a parent.
- Negative: a popover with `actions` at the bottom is no longer shifted left at 1400 px or less (the shell that needs a
  shift can use `offsetX`); the colour picker now depends on `sa-popover.config` for its layout, as it already did for
  `clamp`.
- Follow-up: the country panel of the phone field in `sa-input` also uses `getSelectPanelLayout` and could follow its
  anchor the same way; the mention panel of the reference composer has no counterpart in the starter yet.
