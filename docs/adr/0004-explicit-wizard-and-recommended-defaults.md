# ADR-0004: Explicit wizard, one style list, three rendering strategies, recommended defaults

- Status: accepted
- Date: 2026-11-19
- Deciders: project maintainer

## Context

The wizard of `as new` showed only option names, asked for Tailwind CSS in a separate question after
marking plain CSS as the recommended format, offered two rendering strategies while a third
(`starter-ssr`) was only a planned id, and `--defaults` produced the plain Angular structure. The
official `ng new` prompts show, for every option, the name and the URL of the documentation of what
gets installed, aligned in columns; ours explained nothing. The capability registry (ADR-0001) is
the single source of the wizard, `--help` and `as list`, but it only carried `id`, `label` and
`available`.

## Decision

1. **The registry carries the explanation.** Every option declares `label`, a one-line `description`
   (what it is, how it looks, when to use it), `docs` (the official documentation of what is
   installed: Angular, Tailwind, Sass, Less, Lucide, the package managers; for Screaming, the
   article that names it; for Angular Starter pieces, this repository's ADR), `recommended` and
   `available`. The wizard, `--help` and `as list` only read it. Texts are in English.
2. **Wizard format.** Each choice is `label (Recommended)  [ docs ]`, label and bracket columns
   aligned per question, with the description shown on its own line while the choice is highlighted
   (the `description` of `@inquirer/prompts`). Planned options are never shown.
3. **One stylesheet list.** CSS, Tailwind CSS (Recommended), SCSS, Sass (indented), Less. The schema
   keeps `style` + `tailwind`: choosing "Tailwind CSS" is `style: css, tailwind: true`. `--style`
   and `--tailwind` keep working; `--style tailwind` is accepted as the same choice. There is no
   separate Tailwind question.
4. **Three rendering strategies**, each explained: Client-Side Rendering (Recommended, no SSR: back
   offices and apps behind a login), Default Angular SSR (`ng new --ssr`), and Angular Starter SSR +
   Incremental Hydration (`starter-ssr`: the default SSR plus `withIncrementalHydration()`,
   `withEventReplay()`, view transitions and a `@defer (hydrate on viewport)` example, taken from the
   maintainer's portfolio; for public, SEO-sensitive sites). Details in the plan, step 5.
5. **Recommended set and `--defaults`.** Recommended and preselected: Screaming, Angular Starter
   Routing, Tailwind CSS, Client-Side Rendering, Lucide Icons and the `recommended` component
   collection. `--defaults` and the preselection of the wizard are this set; Angular's own choices
   (`angular-default`, `routing: angular`, CSS, no icons, no components) stay one flag away.
   Defaults are derived from what was given so they never conflict: with `--style scss` the default
   for Tailwind and components is off; with `--architecture angular-default` the routing is Angular's
   and components are off.
6. **Requirements are declared in the registry** (`requires: { architecture, style, icons }`) and
   enforced by `resolveOptions` and the wizard: `routing: starter` needs `screaming`; `components`
   other than `none` need `screaming` (they live in `shared/components`), a CSS or Tailwind
   stylesheet (the design layer is plain CSS, ADR-0005) and `icons: lucide` (`as-icon`). The wizard
   forces what a choice implies instead of asking a question that could only end in an error.
7. **Planned options** (other architectures, other icon libraries) stay in the registry with
   `available: false`; `as list` marks them `(planned)`.

## Alternatives considered

- Keep Tailwind as a yes/no question: rejected, it contradicts the recommendation shown on the CSS
  line and costs a step; the stylesheet list of `ng new` already contains Tailwind.
- Change the schema to a single `style` enum with `tailwind` as a value: rejected, every existing
  `angular-starter.config.json` and flag would change for no gain; a mapping is enough.
- Keep `--defaults` as Angular's defaults: rejected by the maintainer; the product promise is a
  project ready to build business on.
- Static prerendering (`outputMode: static`, as the portfolio does) for `starter-ssr`: rejected by the
  maintainer; the server output mode of `ng new --ssr` is kept because a prerendered shell cannot
  serve dynamic, authenticated routes.
- Translate the wizard: rejected, the CLI texts are in English by decision.

## Consequences

- Positive: the user sees where each choice comes from and when to use it; one place to edit texts;
  `as list`, `--help` and the wizard cannot drift apart.
- Negative: more fields to maintain per option; `--defaults` generates much more than before
  (slower e2e, larger first commit); existing scripts relying on `--defaults` get a different project.
- Follow-up: `as add` and `as generate` (ADR-0006) reuse the same registry; the App Shell arrives in
  its own phase and will be a new registry entry.
