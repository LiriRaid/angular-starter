// Vitest runs this once before the test files: the CLI resolves its blueprints from the package.
export async function setup() {
  await import('./sync-blueprints.mjs');
}
