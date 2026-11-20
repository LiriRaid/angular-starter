# ADR-0007: The structure of the reference application, without its business

- Status: accepted
- Date: 2026-11-19
- Deciders: project maintainer
- Supersedes: [ADR-0005](0005-design-base-and-native-components.md) and the recommended set of
  [ADR-0004](0004-explicit-wizard-and-recommended-defaults.md) (decision 5)

## Context

ADR-0005 delivered a design layer that was written from scratch next to the reference application:
a `design.css` registered in `angular.json`, plain CSS files named after what they hold
(`tokens.css`, `base.css`), a `core/icons` folder, and 26 components rewritten in a lighter form with
their own utilities. The maintainer's requirement was different and simpler: a generated project is
the reference application "100% the same, except the business". The rewrite drifted from it in the
folder layout, the file names, the way the stylesheets are wired, the components themselves and what
`core` and `shared` contain. The wizard also marked the architecture, the routing and the components
as "Recommended", while those are decisions about what the person wants to work with.

## Decision

1. **The structure is the reference's.** Same folders, same file names, same wiring. What is not
   business is ported file by file, renamed (`omniinbox-*` to `as-*`, `OmniInbox*` to `As*`,
   `--omni-*` to `--as-*`) and nothing else; it is not rewritten. Comments and texts of the ported
   components are kept as they are in the reference. Code that named an employer or another product
   as its origin (a handful of comments) is rewritten neutrally, and utilities whose reference
   implementation says it mirrors another company's code (`slugify`, the date and time formatters)
   are implemented again from scratch.
2. **Tailwind CSS is required.** The reference is Tailwind v4 native: `@import 'tailwindcss'`,
   `@custom-variant dark`, `@layer`, `@theme` for the typography scale, and utility classes in the
   component templates. The design base and the components therefore need `tailwind: true`
   (registry requirement `requires.tailwind`); SCSS, Sass, Less and plain CSS projects get neither.
   `components` and `--defaults` therefore pair with the recommended Tailwind CSS.
3. **Styles.** Everything under `src/styles/` is named `*-styles.css`; the global file is
   `src/styles.css`, which carries the imports (and no longer `angular.json`):

   ```
   src/styles.css                         @import 'tailwindcss'; @custom-variant dark ...; @layer ...; @imports
   src/styles/theme/theme-styles.css      tokens, semantic aliases, dark theme
   src/styles/base-elements-styles.css    base element rules
   src/styles/mixins-styles.css           shared selectors
   src/styles/scrollbar-styles.css        native scrollbars
   src/styles/typography/text-and-color-styles.css   @theme scale (Tailwind)
   src/styles/typography/typography-styles.css       text-<size>-<weight> classes
   src/styles/components/<name>-styles.css           one per component that needs it
   src/app/shared/animations/animations.css          animations, imported from styles.css
   ```

   The component stylesheets are imported only when their component is generated, which keeps the
   bundle to what the project uses. The `--app-*` semantic variables keep the reference name (they
   carry no brand); only the branded `--omni-*` ones become `--as-*`. The login, ecosystem and
   theme-button blocks of the reference are business and are not ported.

4. **Core.** `core/theme` (theme service, palettes, storage, initializer), `core/common/icons`
   (`lucide-icons`, `lucide-icons.provider`, `as-icons` for local SVG files) and, with the starter
   routing, `core/navigation`. The favicon tinting of the theme service is not ported (it depends
   on an asset of the reference). Not ported: authentication, guards, interceptors, API
   configuration, notifications, realtime, conversations, tickets, `HttpClient`.
5. **Shared.** `shared/animations`, `shared/utils` (the generic utilities with their specs),
   `shared/data` (accent and phone data), `shared/services/alert.service` with the toast and
   `shared/components`. Not ported: models, business services, `paginated-list.base` (it is tied to
   the API response shape), pipes, directives other than the tooltip.
6. **Components.** The 26 generic components of the reference with their specs: icon, button
   (with its ripple), input, textarea, checkbox, toggle, select, avatar, divider, skeleton,
   tooltip, modal, drawer, toast, tabs, popover (the `recommended` collection, 16) and table,
   search, datepicker, section-nav, selectable-item, reorder-list, preview, media-preview,
   theme-color-picker, weekly-schedule (`all`). Not ported: the composer and the document editor
   (chat and a rich-text dependency), `add-contact-modal`, `ticket-form-modal`,
   `admin-section` (business). The manifest declares what each component imports; a spec checks the
   declaration against the code.
7. **`app.config.ts`** receives `provideThemeInitializer()` and the `LUCIDE_ICONS` provider on top of
   what the architecture and the routing already add (zoneless, `withComponentInputBinding`, the
   title strategy). `app.ts` keeps the inline `<router-outlet />` and `OnPush`.
8. **The wizard no longer recommends the shape of the project.** Architecture, routing and
   components carry no "(Recommended)" badge and nothing is preselected; the registry's new
   `default` flag is what `--defaults` and the missing flags of a non-interactive run pick:
   Screaming, Angular Starter Routing and the `recommended` components. Rendering keeps Client-Side
   Rendering, the stylesheet keeps Tailwind CSS and the icons keep Lucide as recommended. The
   Screaming Architecture option points to this repository's ADR-0002, not to an article. The
   `recommended` component collection is labeled "Essential component collection" so the word does
   not read as a badge; its id is unchanged.
9. A `style: tailwind` written in a configuration file is accepted as the Tailwind CSS choice, as the
   `--style tailwind` flag already was.

## Alternatives considered

- Keep CSS-only components, rewriting the utility classes of every template: rejected, it is the
  same drift as ADR-0005 under another name and loses the reference's components.
- Keep `design.css` and `angular.json` as the seam: rejected, the maintainer wants `styles.css` to
  be where the design is imported, as in the reference.
- Rename every variable to `--as-*`: rejected, `--app-*` has no brand and keeping it keeps the
  equivalence one to one.
- Port the composer and the document editor: rejected, a chat composer and a rich-text editor with a
  heavy dependency do not belong in a starter that ships what every application needs.
- Translate the comments and texts of the ported components: not done in this change; it is a
  rewrite of the reference code, which the maintainer ruled out, and it is a follow-up if wanted.

## Consequences

- Positive: a generated project has the structure the maintainer already knows, components with
  the behavior and tests of the reference, and a stylesheet list that shows what is imported.
- Negative: the design needs Tailwind CSS; a project on another stylesheet format cannot use the
  collections. The comments and the default texts of some components (month names, validation
  messages) stay in the reference's language.
- Negative: the components come from a client-only application. The resize listeners of
  `as-input` and `as-select` are guarded for the server renderer; the rest of the browser globals
  of the components are not audited for server rendering (the theme service is, and uses attributes
  instead of `dataset`). Check a component on a server-rendered route before relying on it there.
- Follow-up: App Shell on top of `core/navigation` and the sidebar tokens already in the theme;
  texts and comments of the ported components in English; typed icon names.
