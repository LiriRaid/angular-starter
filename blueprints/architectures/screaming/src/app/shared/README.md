# shared

Reusable pieces with no business knowledge.

- `components/`: reusable UI components, exported from `components/index.ts` (`@shared/components`).
  A component used by one feature stays in that feature.
- Directives, pipes, utilities and models are added here only when two or more features use them.
- `shared` may import from `core/`, never from `features/`.
- Import with the `@shared/*` alias.
