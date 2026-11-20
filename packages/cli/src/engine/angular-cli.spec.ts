import { describe, expect, it } from 'vitest';
import { ANGULAR_CLI_VERSION } from '../compat.js';
import { DEFAULT_OPTIONS } from '../config/resolve.js';
import { buildNgCommand } from './angular-cli.js';

describe('buildNgCommand', () => {
  it('runs the tested Angular CLI version through npx', () => {
    const { command, args } = buildNgCommand('my-app', DEFAULT_OPTIONS);
    expect(command).toBe('npx');
    expect(args.slice(0, 4)).toEqual([
      '--yes',
      `@angular/cli@${ANGULAR_CLI_VERSION}`,
      'new',
      'my-app',
    ]);
  });

  it('passes every modelled option explicitly and never lets ng install or init git', () => {
    const { args } = buildNgCommand('my-app', DEFAULT_OPTIONS);
    expect(args).toEqual(
      expect.arrayContaining([
        '--defaults',
        '--interactive=false',
        '--skip-install',
        '--skip-git',
        '--routing',
        '--zoneless',
        '--ai-config=none',
        '--package-manager=npm',
        '--prefix=app',
        '--ssr=false',
      ]),
    );
  });

  it('uses the official Tailwind integration for the CSS format', () => {
    expect(buildNgCommand('a', { ...DEFAULT_OPTIONS, tailwind: true }).args).toContain(
      '--style=tailwind',
    );
  });

  it('keeps the chosen stylesheet format without Tailwind', () => {
    const options = { ...DEFAULT_OPTIONS, tailwind: false, style: 'scss' } as const;
    expect(buildNgCommand('a', options).args).toContain('--style=scss');
  });

  it('enables Angular SSR for the ssr rendering strategy', () => {
    const args = buildNgCommand('a', { ...DEFAULT_OPTIONS, rendering: 'ssr' }).args;
    expect(args).toContain('--ssr');
    expect(args).not.toContain('--ssr=false');
  });

  it('starts the Starter SSR strategy from the Angular SSR setup', () => {
    const args = buildNgCommand('a', { ...DEFAULT_OPTIONS, rendering: 'starter-ssr' }).args;
    expect(args).toContain('--ssr');
    expect(args).not.toContain('--ssr=false');
  });

  it('forwards the package manager and prefix', () => {
    const args = buildNgCommand('a', {
      ...DEFAULT_OPTIONS,
      packageManager: 'pnpm',
      prefix: 'acme',
    }).args;
    expect(args).toContain('--package-manager=pnpm');
    expect(args).toContain('--prefix=acme');
  });
});
