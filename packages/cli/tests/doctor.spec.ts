import { describe, expect, it } from 'vitest';
import { ANGULAR_CLI_VERSION } from '../src/compat.js';
import type { CommandRunner } from '../src/engine/process.js';
import { run } from '../src/main.js';
import { createFakeIo } from './helpers/fake-io.js';

function runnerFor(answers: Record<string, string | Error>): CommandRunner {
  return async (command, args) => {
    const answer = answers[[command, ...args].join(' ')];
    if (answer === undefined) throw new Error(`${command} not found`);
    if (answer instanceof Error) throw answer;
    return { stdout: `${answer}\n`, stderr: '' };
  };
}

const HEALTHY = {
  'npx --version': '10.9.0',
  'npm --version': '11.12.1',
  'pnpm --version': '12.9.1',
  'git --version': 'git version 2.50.0',
  'npm view @angular/cli dist-tags.latest': ANGULAR_CLI_VERSION,
};

describe('as doctor', () => {
  it('reports a healthy environment', async () => {
    const fake = createFakeIo();
    const code = await run(['doctor'], fake.io, {
      run: runnerFor(HEALTHY),
      nodeVersion: '24.15.0',
    });
    expect(code).toBe(0);
    expect(fake.out()).toContain('Node.js');
    expect(fake.out()).toContain('latest');
    expect(fake.out()).toMatch(/pnpm 12\.9\.1/);
  });

  it('treats a missing optional package manager as a warning', async () => {
    const fake = createFakeIo();
    const code = await run(['doctor'], fake.io, {
      run: runnerFor(HEALTHY),
      nodeVersion: '24.15.0',
    });
    expect(code).toBe(0);
    expect(fake.out()).toMatch(/yarn.*not found/);
  });

  it('says why a package manager that is installed refuses to run, instead of calling it missing', async () => {
    const fake = createFakeIo();
    const refusal = Object.assign(new Error('Command failed with exit code 1: yarn --version'), {
      stderr:
        'This project is configured to use pnpm because package.json has a "packageManager" field',
    });
    const code = await run(['doctor'], fake.io, {
      run: runnerFor({ ...HEALTHY, 'yarn --version': refusal }),
      nodeVersion: '24.15.0',
    });
    expect(code).toBe(0);
    expect(fake.out()).toMatch(/yarn could not run: This project is configured to use pnpm/);
    expect(fake.out()).not.toMatch(/yarn.*not found/);
  });

  it('warns when a newer Angular CLI is available', async () => {
    const fake = createFakeIo();
    const answers = { ...HEALTHY, 'npm view @angular/cli dist-tags.latest': '23.0.0' };
    const code = await run(['doctor'], fake.io, {
      run: runnerFor(answers),
      nodeVersion: '24.15.0',
    });
    expect(code).toBe(0);
    expect(fake.out()).toContain('23.0.0');
    expect(fake.out()).toContain('newer');
  });

  it('does not fail when the registry cannot be reached', async () => {
    const fake = createFakeIo();
    const answers = { ...HEALTHY, 'npm view @angular/cli dist-tags.latest': new Error('offline') };
    const code = await run(['doctor'], fake.io, {
      run: runnerFor(answers),
      nodeVersion: '24.15.0',
    });
    expect(code).toBe(0);
    expect(fake.out()).toContain('Could not check');
  });

  it('fails when Node.js is not supported', async () => {
    const fake = createFakeIo();
    const code = await run(['doctor'], fake.io, { run: runnerFor(HEALTHY), nodeVersion: '20.0.0' });
    expect(code).toBe(1);
    expect(fake.out()).toContain('not supported');
  });

  it('fails when npx is missing', async () => {
    const fake = createFakeIo();
    const answers = { ...HEALTHY, 'npx --version': new Error('missing') };
    const code = await run(['doctor'], fake.io, {
      run: runnerFor(answers),
      nodeVersion: '24.15.0',
    });
    expect(code).toBe(1);
  });
});
