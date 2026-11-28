import { mkdir, mkdtemp, readFile, rm, stat, writeFile } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { afterEach, beforeEach, describe, expect, it } from 'vitest';
import { run } from '../src/main.js';
import { createFakeIo } from './helpers/fake-io.js';
import { createStarterProject } from './helpers/starter-project.js';

let cwd: string;
let project: string;

beforeEach(async () => {
  cwd = await mkdtemp(join(tmpdir(), 'sa-generate-'));
  project = await createStarterProject(cwd, ['--icons', 'none']);
});

afterEach(async () => {
  await rm(cwd, { recursive: true, force: true });
});

const exists = (path: string): Promise<boolean> =>
  stat(path).then(
    () => true,
    () => false,
  );
const read = (file: string): Promise<string> => readFile(join(project, file), 'utf8');

async function generate(args: string[], folder = project) {
  const fake = createFakeIo({ cwd: folder });
  const code = await run(['generate', ...args], fake.io);
  return { code, out: fake.out(), err: fake.err() };
}

describe('sa generate feature', () => {
  it('creates the feature folder with its component, routes and spec', async () => {
    const result = await generate(['feature', 'billing']);
    expect(result.code, result.err).toBe(0);
    for (const file of [
      'billing.ts',
      'billing.html',
      'billing.css',
      'billing.routes.ts',
      'billing.spec.ts',
    ]) {
      expect(await exists(join(project, 'src/app/features/billing', file)), file).toBe(true);
    }
    const component = await read('src/app/features/billing/billing.ts');
    expect(component).toContain("selector: 'app-billing'");
    expect(component).toContain('export class Billing');
    expect(await read('src/app/features/billing/billing.routes.ts')).toContain(
      'export const BILLING_ROUTES: Routes',
    );
    expect(result.out).toContain('src/app/features/billing/billing.routes.ts');
  });

  it('registers the lazy route in app.routes.ts', async () => {
    await generate(['feature', 'billing']);
    const routes = await read('src/app/app.routes.ts');
    expect(routes).toContain("path: 'billing'");
    expect(routes).toContain(
      "import('@features/billing/billing.routes').then((m) => m.BILLING_ROUTES)",
    );
    expect(routes).toContain("path: 'home'");
  });

  it('adds the feature to the navigation tree with the Starter Angular routing', async () => {
    await generate(['feature', 'user-profiles']);
    const tree = await read('src/app/features/app-shell/navigation/navigation.data.ts');
    expect(tree).toContain("id: 'user-profiles'");
    expect(tree).toContain("title: 'User profiles'");
    expect(tree).toContain("link: '/user-profiles'");
    expect(tree).toContain("id: 'home'");
  });

  it('registers the lazy route inside the layout route when the project has the application shell', async () => {
    await mkdir(join(cwd, 'shell'));
    const withShell = await createStarterProject(join(cwd, 'shell'), ['--app-shell', 'starter']);
    const result = await generate(['feature', 'billing'], withShell);
    expect(result.code, result.err).toBe(0);
    const routes = await readFile(join(withShell, 'src/app/app.routes.ts'), 'utf8');
    expect(routes.indexOf("path: 'billing'")).toBeGreaterThan(routes.indexOf('children: ['));
    expect(routes.match(/loadComponent/g)).toHaveLength(1);
    expect(
      await readFile(
        join(withShell, 'src/app/features/app-shell/navigation/navigation.data.ts'),
        'utf8',
      ),
    ).toContain("link: '/billing'");
  });

  it('names the class and the routes after the feature', async () => {
    await generate(['feature', 'user-profiles']);
    expect(await read('src/app/features/user-profiles/user-profiles.ts')).toContain(
      'export class UserProfiles',
    );
    expect(await read('src/app/features/user-profiles/user-profiles.routes.ts')).toContain(
      'USER_PROFILES_ROUTES',
    );
  });

  it('works without the navigation tree when the project has the default Angular routing', async () => {
    const other = await mkdtemp(join(tmpdir(), 'sa-generate-angular-'));
    try {
      const folder = await createStarterProject(other, ['--routing', 'angular']);
      const result = await generate(['feature', 'billing'], folder);
      expect(result.code, result.err).toBe(0);
      expect(await readFile(join(folder, 'src/app/app.routes.ts'), 'utf8')).toContain(
        "path: 'billing'",
      );
      expect(await exists(join(folder, 'src/app/features/app-shell/navigation'))).toBe(false);
    } finally {
      await rm(other, { recursive: true, force: true });
    }
  });

  it('uses the selector prefix of the project', async () => {
    const prefixed = await mkdtemp(join(tmpdir(), 'sa-generate-prefix-'));
    try {
      const folder = await createStarterProject(prefixed, ['--prefix', 'acme']);
      const result = await generate(['feature', 'billing'], folder);
      expect(result.code, result.err).toBe(0);
      expect(await readFile(join(folder, 'src/app/features/billing/billing.ts'), 'utf8')).toContain(
        "selector: 'acme-billing'",
      );
    } finally {
      await rm(prefixed, { recursive: true, force: true });
    }
  });

  it('is also reachable as `g`', async () => {
    const fake = createFakeIo({ cwd: project });
    expect(await run(['g', 'feature', 'billing'], fake.io)).toBe(0);
  });

  it.each(['Billing', 'my feature', '1billing', 'billing_x'])(
    'rejects the name %s',
    async (name) => {
      const result = await generate(['feature', name]);
      expect(result.code).toBe(2);
      expect(result.err).toContain('lowercase');
    },
  );

  it('never overwrites a feature that already exists', async () => {
    await mkdir(join(project, 'src/app/features/billing'), { recursive: true });
    await writeFile(join(project, 'src/app/features/billing/mine.ts'), 'keep');
    const result = await generate(['feature', 'billing']);
    expect(result.code).toBe(2);
    expect(result.err).toContain('already exists');
    expect(await read('src/app/features/billing/mine.ts')).toBe('keep');
  });

  it('needs the Screaming architecture', async () => {
    const plain = await mkdtemp(join(tmpdir(), 'sa-generate-plain-'));
    try {
      const folder = await createStarterProject(plain, ['--architecture', 'angular-default']);
      const result = await generate(['feature', 'billing'], folder);
      expect(result.code).toBe(2);
      expect(result.err).toContain('Screaming');
    } finally {
      await rm(plain, { recursive: true, force: true });
    }
  });

  it('shows what it would create with --dry-run and creates nothing', async () => {
    const result = await generate(['feature', 'billing', '--dry-run']);
    expect(result.code).toBe(0);
    expect(result.out).toContain('Dry run');
    // A tree of what it would write: `+` for the files it creates and `~` for the ones it adapts.
    expect(result.out).toContain('billing/');
    expect(result.out).toContain('+ billing.ts');
    expect(result.out).toContain('~ app.routes.ts');
    expect(result.out).toMatch(/Would create 5 files and update \d files?\./);
    expect(await exists(join(project, 'src/app/features/billing'))).toBe(false);
  });
});

describe('sa generate component', () => {
  it('creates a component inside a feature', async () => {
    await generate(['feature', 'billing']);
    const result = await generate(['component', 'invoice-card', '--feature', 'billing']);
    expect(result.code, result.err).toBe(0);
    const file = 'src/app/features/billing/invoice-card/invoice-card.ts';
    expect(await read(file)).toContain("selector: 'app-invoice-card'");
    expect(await read(file)).toContain('export class InvoiceCard');
    expect(
      await exists(join(project, 'src/app/features/billing/invoice-card/invoice-card.spec.ts')),
    ).toBe(true);
  });

  it('creates a shared component and exports it from the barrel', async () => {
    const result = await generate(['component', 'invoice-card', '--shared']);
    expect(result.code, result.err).toBe(0);
    expect(
      await exists(join(project, 'src/app/shared/components/invoice-card/invoice-card.ts')),
    ).toBe(true);
    expect(await read('src/app/shared/components/index.ts')).toContain(
      "export { InvoiceCard } from './invoice-card/invoice-card';",
    );
  });

  it('needs to know where the component lives', async () => {
    const result = await generate(['component', 'invoice-card']);
    expect(result.code).toBe(2);
    expect(result.err).toContain('--feature');
    expect(result.err).toContain('--shared');
  });

  it('refuses a feature that does not exist', async () => {
    const result = await generate(['component', 'invoice-card', '--feature', 'missing']);
    expect(result.code).toBe(2);
    expect(result.err).toContain('"missing"');
  });

  it('refuses --feature and --shared together', async () => {
    const result = await generate(['component', 'x', '--feature', 'home', '--shared']);
    expect(result.code).toBe(2);
  });
});

describe('sa generate', () => {
  it('names the kinds it can generate', async () => {
    const result = await generate(['service', 'billing']);
    expect(result.code).toBe(2);
    expect(result.err).toContain('Unknown kind "service"');
    expect(result.err).toContain('feature');
    expect(result.err).toContain('component');
  });

  it('needs a project created by Starter Angular', async () => {
    const result = await generate(['feature', 'billing'], cwd);
    expect(result.code).toBe(2);
    expect(result.err).toContain('starter-angular.config.json');
  });
});

describe('sa generate component in a project that is not Screaming', () => {
  let plain: string;
  let folder: string;

  beforeEach(async () => {
    plain = await mkdtemp(join(tmpdir(), 'sa-generate-plain-'));
    folder = await createStarterProject(plain, ['--architecture', 'angular-default']);
  });

  afterEach(async () => {
    await rm(plain, { recursive: true, force: true });
  });

  it('creates the folder of the component below src/app, like ng generate component', async () => {
    const result = await generate(['component', 'invoice-card'], folder);
    expect(result.code, result.err).toBe(0);
    for (const file of ['ts', 'html', 'css', 'spec.ts']) {
      expect(await exists(join(folder, `src/app/invoice-card/invoice-card.${file}`)), file).toBe(
        true,
      );
    }
    const text = await readFile(join(folder, 'src/app/invoice-card/invoice-card.ts'), 'utf8');
    expect(text).toContain("selector: 'app-invoice-card'");
    expect(text).toContain('export class InvoiceCard');
  });

  it('puts it where --path says, below src/app', async () => {
    const result = await generate(['component', 'invoice-card', '--path', 'billing/ui'], folder);
    expect(result.code, result.err).toBe(0);
    expect(await exists(join(folder, 'src/app/billing/ui/invoice-card/invoice-card.ts'))).toBe(
      true,
    );
  });

  it.each([['../outside'], ['/abs'], ['a/../../b']])('refuses the path %s', async (path) => {
    const result = await generate(['component', 'invoice-card', '--path', path], folder);
    expect(result.code).toBe(2);
    expect(result.err).toContain('--path');
  });

  it('does not touch a component that exists', async () => {
    await mkdir(join(folder, 'src/app/invoice-card'), { recursive: true });
    await writeFile(join(folder, 'src/app/invoice-card/mine.ts'), 'keep');
    const result = await generate(['component', 'invoice-card'], folder);
    expect(result.code).toBe(2);
    expect(result.err).toContain('already exists');
  });

  it('says that features and the --feature and --shared places belong to Screaming', async () => {
    for (const args of [
      ['component', 'invoice-card', '--shared'],
      ['component', 'invoice-card', '--feature', 'billing'],
    ]) {
      const result = await generate(args, folder);
      expect(result.code).toBe(2);
      expect(result.err).toContain('Screaming');
    }
  });

  it('shows what it would create with --dry-run and creates nothing', async () => {
    const result = await generate(['component', 'invoice-card', '--dry-run'], folder);
    expect(result.code).toBe(0);
    expect(result.out).toContain('invoice-card/');
    expect(result.out).toContain('+ invoice-card.ts');
    expect(result.out).toContain('Would create 4 files.');
    expect(await exists(join(folder, 'src/app/invoice-card'))).toBe(false);
  });

  it('refuses --path in a Screaming project, where --feature and --shared decide', async () => {
    const result = await generate(['component', 'invoice-card', '--path', 'x']);
    expect(result.code).toBe(2);
    expect(result.err).toContain('--feature');
  });
});

describe('sa generate component --path with dot segments', () => {
  it('drops them, so the same folder has one spelling', async () => {
    const plain = await mkdtemp(join(tmpdir(), 'sa-generate-dot-'));
    try {
      const folder = await createStarterProject(plain, ['--architecture', 'angular-default']);
      const result = await generate(
        ['component', 'invoice-card', '--path', './billing/.', '--dry-run'],
        folder,
      );
      expect(result.code, result.err).toBe(0);
      expect(result.out).toContain('billing/');
      expect(result.out).toContain('invoice-card/');
      expect(result.out).toContain('+ invoice-card.ts');
    } finally {
      await rm(plain, { recursive: true, force: true });
    }
  });
});
