# ADR-0010: A routed wizard, the layout modes and the design preferences page

- Status: accepted
- Date: 2026-11-20
- Deciders: project maintainer

## Context

The wizard of `as new` filters its options through the `requires` of the registry (ADR-0004,
ADR-0008, ADR-0009), but the order of the questions and what each answer opens were never designed as
one flow: with `angular-default` the wizard still asks for icons, the shell is asked before anything
says what kind of project it is for, and the layout of the shell (one of the seven modes of the
maintainer's demo) is not a choice. The shell also opens the user preferences in a drawer, while the
demo shows them as a page with tabs (appearance, theme, UI, others) whose changes apply in real time.
The maintainer wants the first thing a developer chooses, the architecture, to decide what comes next,
a Backoffice that is complete before any other kind of project, and the design preferences as a route
that will grow into the UI System (the tokens of every component and a preview of each one).

## Decision

1. **A chained flow.** The questions are asked in this order and every answer decides what follows:
   architecture; routing; stylesheet; rendering; the purpose of Starter SSR; application shell; layout
   of the shell; presence; components; UI System; icons; package manager. With `angular-default` the
   only questions about the project are the stylesheet (CSS, Tailwind CSS, SCSS, Sass, Less) and the
   rendering (Client-Side Rendering, Default Angular SSR): no starter routing, shell, presence,
   components, UI System, icons or Starter SSR. With `screaming` everything opens, starting with the
   routing.
2. **`offeredWith`, next to `requires`.** `requires` stays what a project cannot be generated without
   (it is validated, and `as add` re-checks it). `offeredWith` is new and has the same shape but only
   decides what the wizard asks and what `--defaults` picks: it keeps the flow short without making an
   old project invalid. The Lucide icon library and Starter SSR are `offeredWith` the Screaming
   Architecture, so a project with `angular-default` is Angular's own unless a flag says otherwise.
3. **Three new categories** (and options of the same name in `angular-starter.config.json`, flags and
   `as list`): `ssrPurpose` (`--ssr-purpose`), `layout` (`--layout`) and `uiSystem` (`--ui-system`).
   Each has a `none` value that means "does not apply", valid only where the category does not (the
   purpose needs `rendering: starter-ssr`, the layout needs the shell, the UI System needs the shell
   and a component collection); the wizard never asks for a category that has a single possible value.
4. **The purpose of Starter SSR: `landing`, `ecommerce`, `backoffice`.** Each will have its own shell
   and variant; the App Shell that exists is the Backoffice one. Only `backoffice` can be generated.
   The shell still needs client-side rendering (ADR-0008 decision 10 stands): `backoffice` with Starter
   SSR is today Starter SSR with incremental hydration and no shell, and the shell for it is the next
   step, followed by the landing page and the ecommerce, whose components will bring their server-side
   adaptation, as in the maintainer's portfolio.
5. **The layout of the shell: six modes of the demo.** `wide-joined`, `compact-joined`, `floating-wide`
   (Recommended, the one that exists: a wide sidebar, header and content floating), `floating-compact`,
   `transparent-joined` and `transparent-floating`; the transparent sidebar's width (wide or compact) is
   a run-time preference of the design page, not a question. Only `floating-wide` is generated; the
   others are `available: false` in the registry until each one is built, one by one.
6. **Planned options are shown, not hidden, in the two new questions.** Every other question keeps the
   rule of ADR-0004 (only what can be generated is offered). The layout and the purpose are listed in
   full with the planned entries disabled and marked "(Under construction)", so a developer sees the
   map of the product and cannot choose what does not exist. `as list` marks them too.
7. **The wording of the components.** "Essential component collection" says it has 16 components and
   "All available components" says 26, listing what each adds.
8. **The design preferences are a route, not a drawer.** The "Preferencias" button of the user menu
   becomes "Preferencias de Diseño" and navigates to `/preference-design`, a feature of its own
   (`features/preference-design`) with a navigation entry and a breadcrumb. The page uses `as-tabs`
   with the tabs Apariencia, Tema, UI and Otros of the demo: the layout cards, the colour scheme and the
   light/dark mode apply in real time through `ThemeService` and the shell; Restablecer returns to the
   defaults and Guardar cambios stores what is not stored yet (the UI tokens and the toggles of Otros);
   the theme is stored as it changes, as `ThemeService` already does. The drawer
   (`layout/sidebar/user-preferences`) is removed. The edits of presence (ADR-0009) that anchor on the
   preferences button and on `</as-popover>` are updated to the new button.
9. **The UI System starts in the UI tab.** The UI tab of the page owns the design tokens of the
   components (radius, button size, density, font size) as CSS variables applied in real time and
   stored in `localStorage`; `uiSystem: starter` adds to the same page a catalog of the installed
   `as-` components with a preview of each one, its code and what the tokens change in it. It is not a
   separate application: it is the base the UI tab grows from, so it needs the shell and a collection.
   The first release previews the components of the essential collection; the rest of `all` are listed
   without a preview.
10. **Old projects keep working.** `findProject` fills what a configuration made before these options
    does not have (`ssrPurpose`, `layout`, `uiSystem`), so `as add` and `as config` work on it.
    `as add ui-system` adds that option to a project that has the shell and a collection; the layout
    and the purpose are decided by `as new`.

## Alternatives considered

- Make `requires` stricter instead of adding `offeredWith`: rejected, an existing project with
  `angular-default` and Lucide would become invalid for every `as add`.
- Ask the purpose for every rendering: rejected, it only means something for Starter SSR, where the
  future variants differ.
- Hide the planned layouts and purposes until they exist: rejected by the maintainer, the wizard shows
  the roadmap of the product.
- Make the shell server-renderable now so that a Backoffice can use Starter SSR: postponed by the
  maintainer; the Backoffice is finished first, client-side.
- A separate `/ui-system` application or route: rejected, the maintainer wants the tokens and the
  previews inside the tabs of the design preferences page.
- Keep the drawer next to the page: rejected, two places for the same preferences.

## Consequences

- Positive: the wizard reads as a path (a plain Angular project is two questions long); the roadmap of
  layouts and purposes is visible; the preferences are a page that can be linked, titled and extended;
  the UI tab is the seed of the UI System.
- Negative: three more options in the configuration, the flags and the registry; one more key
  (`offeredWith`); the shell loses the drawer and its component; a Backoffice with Starter SSR has no
  shell yet.
- Follow-up: the other five layout modes (one at a time), the transparent sidebar width, the shell for
  server rendering, the landing and the ecommerce variants, previews for the rest of the components,
  and `as add layout` if switching the mode of a generated project is ever needed.
