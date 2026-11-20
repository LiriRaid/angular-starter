import type { StarterOptions } from './config/schema.js';

/**
 * Compatibility matrix. `as new` runs exactly this Angular CLI version. It is raised only after the
 * generation tests pass against the new release.
 */
export const ANGULAR_CLI_VERSION = '22.3.0';

export interface IconPackage {
  /** npm package added to the generated project's dependencies. */
  name: string;
  /** Version range tested with the Angular version above. */
  version: string;
  docs: string;
}

/** Icon libraries by id (see `ICONS` in the config schema). `none` and planned ones have no entry. */
export const ICON_PACKAGES: Readonly<Partial<Record<StarterOptions['icons'], IconPackage>>> = {
  lucide: {
    name: '@lucide/angular',
    version: '^1.76.0',
    docs: 'https://lucide.dev/guide/angular/getting-started',
  },
};

/** Packages the native components import (modal: overlay and portal, reorder-list: drag and drop). */
export const COMPONENT_PACKAGES: Readonly<Record<string, string>> = {
  '@angular/cdk': '^22.3.0',
};

/** Same range the Angular CLI declares for the version above, since this CLI runs it. */
export const SUPPORTED_NODE_RANGE = '^22.22.3 || ^24.15.0 || >=26.0.0';

export function isSupportedNode(version: string): boolean {
  const match = /^v?(\d+)\.(\d+)\.(\d+)/.exec(version);
  if (!match) return false;

  const major = Number(match[1]);
  const minor = Number(match[2]);
  const patch = Number(match[3]);
  const atLeast = (minMinor: number, minPatch: number): boolean =>
    minor > minMinor || (minor === minMinor && patch >= minPatch);

  if (major >= 26) return true;
  if (major === 24) return atLeast(15, 0);
  if (major === 22) return atLeast(22, 3);
  return false;
}

/** Returns a negative number, zero or a positive number, like `Array.prototype.sort` comparators. */
export function compareVersions(a: string, b: string): number {
  const left = parseVersion(a);
  const right = parseVersion(b);
  for (let index = 0; index < 3; index++) {
    const difference = (left[index] ?? 0) - (right[index] ?? 0);
    if (difference !== 0) return difference;
  }
  return 0;
}

function parseVersion(version: string): number[] {
  return version
    .replace(/^v/, '')
    .split('.')
    .slice(0, 3)
    .map((part) => Number.parseInt(part, 10) || 0);
}
