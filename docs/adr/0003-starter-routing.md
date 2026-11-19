# ADR-0003: Angular Starter Routing

- Status: accepted
- Date: 2026-11-19
- Deciders: project maintainer

## Context

`as new --routing starter` must add, on top of the Screaming profile (ADR-0002), the navigation model
of the reference code base: one navigation tree that describes what the product offers, and the
services that read it. The reference keeps the tree in `features/app-shell`, the `BreadcrumbService`
in `core/navigation` (it reads the tree through an injection token) and a `TitleStrategy` in
`features/app-shell` that imports the tree directly, so the tree has two readers with two ways of
reaching it. Its breadcrumb code also repeats the "best matching item" search three times and reads
`router.url` outside the reactive graph. Its tree carries business permissions and a typed icon
union, which a generic starter cannot reproduce. The application shell (sidebar, header, layouts)
is a later phase and is out of scope here.

## Decision

1. **One tree, many readers.** A `NavigationGroup[]` (groups → items → children, any depth) feeds
   page titles, breadcrumbs and, later, the sidebar. An item has `id`, `title`, `link`, `icon`
   (plain string), `type` (`basic` | `collapsable`), `description`, `permission` (opaque string),
   `hidden(item)` and `children`. `filterNavigation(tree, canAccess)` returns the visible tree for
   a sidebar; no authentication is generated. Business permissions of the reference are not copied.
2. **Placement** (`src/app`):
   - `core/navigation/` — `navigation.types.ts`, `breadcrumb.types.ts`, `navigation.utils.ts` (pure
     functions: URL matching, breadcrumb building, filtering), `navigation.tokens.ts`
     (`NAV_TREE_TOKEN`, `NAV_APP_NAME_TOKEN`), `breadcrumb.service.ts`,
     `navigation-title.strategy.ts` and `navigation.providers.ts`. It imports nothing from
     `features/` or `shared/`.
   - `features/app-shell/navigation/navigation.data.ts` — the product's tree, with plain string
     links (no imports of other features). The location is the one reserved by ADR-0002; the shell
     itself arrives later.
   - `app.config.ts` (composition root) calls `provideNavigation(APP_NAVIGATION, { appName })`, which
     registers the tokens, the `TitleStrategy` and `BreadcrumbService`. The token inverts the
     dependency, so `core` never reaches the tree.
3. **Each feature keeps owning its routes** (`<feature>.routes.ts`, children and sub-children
   included); `app.routes.ts` only loads them. The tree describes navigation, it does not replace
   routes. Layout routes (`empty`/`main`, `data.layout`) are not generated: nothing reads them yet,
   and the App Shell phase restructures `app.routes.ts` when it adds the layout components.
4. **Matching.** An item matches a URL when the URL equals its link or continues it after a `/`.
   The match with the longest link wins, deepest on a tie; the first on a full tie. (The reference
   takes the deepest first match, so a shorter sibling link listed earlier wins; this fixes it.)
   Hidden items still match, so titles and breadcrumbs work for pages the sidebar does not list.
5. **Titles.** `<item title | route title> | <appName>`, `appName` being the project name; the
   `<meta name="description">` gets `item.description` or a default. Tree title wins over route title.
6. **Breadcrumbs.** `BreadcrumbService.breadcrumbs` is a single `computed` over a URL signal and an
   optional dynamic crumb (`setDynamicLabel`, `setDynamicCrumb`, `clearDynamicLabel`, cleared on
   each navigation). Order: group label (unless hidden or equal to the first item), the item chain,
   the dynamic crumb. An unmatched URL falls back to humanized segments.
7. **Requirement.** `routing: starter` requires `architecture: screaming`. The capability declares
   `requiresArchitecture`; `as new` rejects other combinations (exit 2) and the wizard offers
   `starter` only when the chosen architecture supports it.
8. **Generation.** Blueprint `blueprints/routing/starter/` (`.tpl` files, `__PROJECT_NAME__`); a new
   stage `apply-routing` runs after `apply-architecture`. It copies the blueprint without
   overwriting and edits `app.config.ts` through `ts-morph` (`addProvider`), computing the edit
   before writing anything. Generated specs cover the services; `ng test` runs them.

## Alternatives considered

- Everything in `core/navigation`, tree included: rejected, the tree is product data and ADR-0002
  keeps product logic out of `core`.
- Reference layout (title strategy in `features/app-shell` importing the tree): rejected, two
  readers reach the tree in two ways and the strategy cannot be tested with another tree.
- Per-feature navigation fragments assembled at the root: rejected, groups cross features and one
  readable file is easier to edit.
- Starter routing on `angular-default` with relative imports: rejected, a second structural style
  without a decision (needs aliases and the app-shell location).
- Layout route groups without components, or placeholder layout components: rejected, dead `data`
  today, a fragile "wrap existing routes" edit, and shell scope creep.
- Three providers written into `app.config.ts`: rejected, three edits and more noise in a user file.

## Consequences

- Positive: titles and breadcrumbs work on a fresh project; the App Shell only adds a sidebar
  that reads the same tree; the title and breadcrumb logic is pure and tested in the CLI and in the
  generated project.
- Negative: the capability only works with Screaming until another profile declares support; `icon`
  is an untyped string until the icon component exists.
- Follow-up: App Shell (layouts, sidebar, header) reading `filterNavigation`; typed icon names with
  the native `as-icon`; permission evaluation with an auth capability.
