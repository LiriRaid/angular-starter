import { builtinModules } from 'node:module';

export const MAX_PROJECT_NAME_LENGTH = 214;

/** Same names `ng new` takes: `InventorySystem` and `my-project` both work. */
const PROJECT_NAME_PATTERN = /^[A-Za-z][A-Za-z0-9]*(-[A-Za-z0-9]+)*$/;

/** Returns a message describing the problem, or `undefined` when the name is valid. */
export function validateProjectName(name: string): string | undefined {
  if (name.length === 0) return 'Project name is required.';
  if (name.length > MAX_PROJECT_NAME_LENGTH) {
    return `Project name must be at most ${MAX_PROJECT_NAME_LENGTH} characters long.`;
  }
  if (!PROJECT_NAME_PATTERN.test(name)) {
    return 'Use letters, numbers and single hyphens, starting with a letter (for example "InventorySystem" or "my-project").';
  }
  if (builtinModules.includes(name)) {
    return `The name "${name}" is reserved by Node.js. Choose another one.`;
  }
  return undefined;
}
