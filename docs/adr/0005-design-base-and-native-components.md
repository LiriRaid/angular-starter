# ADR-0005: Design base and native `as-` components

- Status: accepted
- Date: 2026-11-19
- Deciders: project maintainer

## Context

The reference application ships, besides its business features, a complete design layer: tokens and
palettes, light and dark theme, typography, animations, about thirty reusable components, and
utilities. The goal is a generated project "like the reference, without the business": the
developer only builds business. Studying the reference showed three obstacles: its components use
Tailwind utility classes (`w-full`, `rounded-lg`, custom `text-caption-*`) so they cannot be copied
as they are; business services and models sit in `shared/` next to the reusable pieces
(ADR-0002 already corrected this); and core holds authentication, interceptors and API
configuration that a starter must not impose.

## Decision

1. **Scope.** The design layer is generated only when the stylesheet is CSS or Tailwind CSS
   (maintainer decision: SCSS, Sass and Less projects get no design styles and no components). It
   needs the Screaming architecture. It is plain CSS with custom properties: it does not depend on
   Tailwind, and with Tailwind a small mapping file exposes the tokens as Tailwind theme values.
2. **Global styles** live in `src/styles/` as plain `.css` files (tokens, theme, base elements,
   typography, scrollbars, animations) imported by one entry `src/styles/design.css`, which is added
   to the `styles` array of `angular.json` (edited with `jsonc-parser`) after `styles.css`. With
   Tailwind, `styles.css` additionally imports `tailwind.css` (dark variant on `.dark` and the token
   mapping), appended after the existing `@import 'tailwindcss'`.
3. **Theme service** in `core/theme`: `ThemeService` (light/dark, primary and surface palettes,
   persisted preference, SSR-safe), palettes, storage and `provideThemeInitializer()`, registered in
   `app.config.ts` through `ts-morph`. Tokens: `--as-primary-50..950`, `--as-surface-0..950`, and
   semantic aliases (`--as-bg`, `--as-text`, `--as-border`, ...) switched by `.dark`.
4. **Icons**: `core/icons` holds the Lucide registration (`provideAsIcons`, a curated list the
   developer extends) and `shared/components/as-icon` (names from Lucide, or a registered SVG);
   every component renders icons through `as-icon` only.
5. **Components** carry the reserved selector prefix `as-` (`as-button`, `as-input`, ...), live in
   `shared/components/<name>/` and are exported by the `@shared/components` barrel. They are
   standalone, OnPush, signals (`input()`/`output()`), styled with their own CSS files over the
   tokens, accessible, and each has a spec. Collections: `recommended` (icon, button, input,
   textarea, checkbox, toggle, select, avatar, divider, skeleton, tooltip, modal, drawer, toast,
   tabs, popover) and `all` (recommended plus table, search, datepicker, section-nav,
   selectable-item, reorder-list, preview, media-preview, theme-color-picker, weekly-schedule).
   The application's own components keep the project's `--prefix`.
6. **Utilities** in `shared/utils` (initials, escape-html, file size, relative time, date format,
   safe timeout, slugify, id, download, overlay dismiss, panel placement, smooth scroll,
   responsive action size) with their specs, `shared/directives` and `shared/pipes` only when a
   component needs them (tooltip directive; small pipes over the utilities).
7. **Not generated**: authentication, guards, interceptors, API configuration, notifications,
   realtime, domain models and services, the rich-text composer and document editor (heavy
   dependency), contact and ticket modals, admin sections, phone and WhatsApp helpers. No business
   feature: `features/` keeps `home` (the first lazy route) and, with the starter routing,
   `features/app-shell/navigation`.
8. **Root composition.** The Angular welcome page is removed: `app.html`/`app.css` are deleted,
   `app.ts` gets an inline `<router-outlet />` template and `OnPush` (edited with `ts-morph`), and
   `app.spec.ts` tests that. The developer composes the shell in `app.*` (it is their code).
9. **Dependency rules** of ADR-0002 hold: components import `core` (the icon registration token) and
   nothing from `features`; the design files never import from the application.

## Alternatives considered

- Copy the components with Tailwind classes: rejected, they would only work with Tailwind and
  would break the CSS-only profile.
- Components in four stylesheet formats: rejected by the maintainer ("do not kill ourselves");
  SCSS, Sass and Less projects simply do not get the design layer.
- Styles inside `styles.css` by text edit: rejected, `angular.json` `styles` is the supported seam
  and keeps the developer's file untouched.
- A published component package: rejected, the developer owns the code and may change the design
  (no runtime dependency on this CLI, ADR-0001).
- Bring Omni's business `shared` services/models: rejected, ADR-0002.

## Consequences

- Positive: a new project has tokens, theme, utilities and a tested component set from minute one;
  every file is the developer's to change.
- Negative: a sizeable blueprint to maintain and test; the components are a reimplementation, not a
  copy, so they can drift from the reference.
- Follow-up: App Shell (layouts, sidebar, header, drawer) reading these tokens; typed icon names;
  `as add components` for existing projects (ADR-0006).
