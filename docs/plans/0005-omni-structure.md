# Plan 0005: the structure of the reference application, without its business

Decision: [ADR-0007](../adr/0007-omni-structure-design-and-components.md). It replaces the design
base and the components of plan 0004 (steps 6 and 7), which were written from scratch.

## Steps

1. **Wizard and registry.** `default` flag in the registry; no `recommended` on architecture,
   routing and components; `requires.tailwind`; the Screaming docs point to ADR-0002; the
   collection is the "Essential component collection". `defaultOption`, `pick` in `resolve.ts`,
   `style: tailwind` accepted from a file. Specs first.
2. **Edits.** `edits/styles.ts` (`addDesignStyles`, `addComponentStyles`), `addTestSetupFile` in
   `edits/angular-json.ts`, `edits/planned.ts` (one place for "plan every edit, then write") used by
   every profile.
3. **Port.** Every generic file of the reference is copied with a rename (`omniinbox-` to `as-`,
   `OmniInbox` to `As`, `omni-` to `as-`) into `blueprints/design` and `blueprints/components/as-*`;
   the few spots that depended on business (avatar presence icons, the avatar accent, comments that
   named an employer) are patched, and the utilities that mirrored another product are written again.
4. **Profiles.** `designProfile` imports the design from `styles.css`, adds the theme initializer, the
   `LUCIDE_ICONS` provider and the test setup; `componentsProfile` adds the component files, their
   stylesheets, `@angular/cdk` and the barrel exports. The manifest declares `uses`, `exports` and
   `styles`; a spec checks `uses` against the imports of the code.
5. **Verification.** `ng build` and `ng test` on a generated project (the 479 specs of the
   components pass), then the opt-in end-to-end matrix (`AS_E2E=1`): CSR, SSR, Starter SSR, routing,
   `add`/`generate`, the essential and the full collections.

## Out of scope

Composer, document editor, business modals, authentication, interceptors, notifications, realtime,
`HttpClient`; translating the comments and texts of the ported components (follow-up).
