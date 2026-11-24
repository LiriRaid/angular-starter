import { mkdir, mkdtemp, readFile, rm, writeFile } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { afterEach, beforeEach, describe, expect, it } from 'vitest';
import { writeGeneratedWorkspace } from '../../../tests/helpers/generated-workspace.js';
import { appShellProfile } from '../app-shell/app-shell.js';
import { screamingProfile } from '../architectures/screaming.js';
import { BLUEPRINTS_ROOT, listBlueprintFiles } from '../blueprint.js';
import { designProfile } from '../design/design.js';
import { starterRoutingProfile } from '../routing/starter.js';
import { presenceProfile } from './presence.js';

const PRESENCE_BLUEPRINT = join(BLUEPRINTS_ROOT, 'presence');
const CORE = 'src/app/core/presence';
const MENU = 'src/app/features/app-shell/layout/sidebar/user-menu';

let project: string;

beforeEach(async () => {
  project = await mkdtemp(join(tmpdir(), 'sa-presence-'));
  await writeGeneratedWorkspace(project);
  const base = { targetDir: project, name: 'demo', prefix: 'app' };
  await screamingProfile.apply(base);
  await starterRoutingProfile.apply(base);
  await designProfile.apply(base);
  await appShellProfile.apply(base);
});

afterEach(async () => {
  await rm(project, { recursive: true, force: true });
});

const read = (file: string): Promise<string> => readFile(join(project, file), 'utf8');
const apply = (prefix = 'app') =>
  presenceProfile.apply({ targetDir: project, name: 'demo', prefix });

describe('presence profile', () => {
  it('creates the client logic, the contract and its two transports under core/presence', async () => {
    await apply();
    for (const file of [
      'presence.types.ts',
      'presence.transport.ts',
      'in-memory-presence.transport.ts',
      'web-socket-presence.transport.ts',
      'presence.service.ts',
      'live-presence.service.ts',
      'presence.providers.ts',
      'README.md',
    ]) {
      await expect(read(`${CORE}/${file}`), file).resolves.toBeTypeOf('string');
    }
    expect(await read(`${CORE}/presence.service.ts`)).toContain('class PresenceService');
    expect(await read(`${CORE}/presence.transport.ts`)).toContain('PRESENCE_TRANSPORT');
    expect(await read(`${CORE}/presence.providers.ts`)).toContain('providePresence');
  });

  it('ships a spec for every piece that has logic', async () => {
    await apply();
    for (const file of [
      `${CORE}/presence.service.spec.ts`,
      `${CORE}/live-presence.service.spec.ts`,
      `${CORE}/in-memory-presence.transport.spec.ts`,
      `${CORE}/web-socket-presence.transport.spec.ts`,
      `${CORE}/presence.providers.spec.ts`,
      `${MENU}/user-status.spec.ts`,
    ]) {
      await expect(read(file), file).resolves.toContain("describe('");
    }
  });

  it('documents the server side in docs/presence.md', async () => {
    await apply();
    const doc = await read('docs/presence.md');
    for (const topic of [
      'presence:snapshot',
      'presence:set',
      'PATCH',
      'presence:manual:',
      'presence:timer:',
      'presence:disconnect:',
      'TTL',
      'grace',
      'ioredis',
    ]) {
      expect(doc, topic).toContain(topic);
    }
    expect(doc).toContain('```ts');
  });

  it('wires the provider, the stylesheet and the user menu', async () => {
    await apply('shop');
    const config = await read('src/app/app.config.ts');
    expect(config).toContain('providePresence()');
    expect(config).toContain("from '@core/presence/presence.providers'");

    const styles = await read('src/styles.css');
    expect(styles).toContain("@import './styles/features/presence-styles.css';");
    expect(styles.indexOf('presence-styles.css')).toBeGreaterThan(
      styles.indexOf('user-menu-styles.css'),
    );
    expect(styles.indexOf('presence-styles.css')).toBeLessThan(styles.indexOf('animations.css'));
    expect(await read('src/styles/features/presence-styles.css')).toContain('.um-status-trigger');

    const html = await read(`${MENU}/user-menu.html`);
    expect(html).toContain('mode="presence"');
    expect(html).toContain('statusMenu.statusSubPanelPos()');
    const menu = await read(`${MENU}/user-menu.ts`);
    expect(menu).toContain("import { UserStatusMenu } from './user-status';");
    expect(menu).toContain('readonly statusMenu = new UserStatusMenu(');
    expect(await read(`${MENU}/user-status.ts`)).toContain('class UserStatusMenu');
  });

  it('keeps the status labels in Spanish like the rest of the shell', async () => {
    await apply();
    const status = await read(`${MENU}/user-status.ts`);
    for (const label of ['En línea', 'Ausente', 'Ocupado', 'Invisible', 'Para siempre']) {
      expect(status).toContain(label);
    }
  });

  it('brings no business of the reference: no authentication, HTTP client or vendor socket', async () => {
    for (const file of await listBlueprintFiles(PRESENCE_BLUEPRINT)) {
      const text = await readFile(join(PRESENCE_BLUEPRINT, file), 'utf8');
      expect(text, file).not.toMatch(
        /omni|yalo|gabriel|AuthService|HttpClient|ActionCable|anycable|rails|gsap/i,
      );
    }
  });

  it('keeps the layer rules: core imports neither features nor shared', async () => {
    await apply();
    for (const file of await listBlueprintFiles(PRESENCE_BLUEPRINT)) {
      if (!file.startsWith('src/app/core/')) continue;
      const text = await read(file.replace(/\.tpl$/, ''));
      expect(text, file).not.toMatch(/from '@(features|shared)\//);
    }
  });

  it('uses the selector prefix of the project and leaves no unresolved placeholder', async () => {
    await apply('shop');
    for (const file of await listBlueprintFiles(PRESENCE_BLUEPRINT)) {
      const generated = file.replace(/\.tpl$/, '');
      expect(await read(generated), generated).not.toMatch(/__[A-Z_]+__/);
    }
  });

  it('adds its card to the welcome page when there is one', async () => {
    await apply();
    expect(await read('src/app/features/home/home.data.ts')).toContain("id: 'presence'");
  });

  it('does not need the welcome page: a project whose home was replaced is left alone', async () => {
    await rm(join(project, 'src/app/features/home/home.data.ts'));
    await expect(apply()).resolves.toBeUndefined();
  });

  it('writes nothing when the user menu does not have the expected shape', async () => {
    const html = join(project, MENU, 'user-menu.html');
    await writeFile(html, '<p>my own menu</p>\n');
    await expect(apply()).rejects.toThrow(/user-menu\.html/);
    expect(await readFile(html, 'utf8')).toBe('<p>my own menu</p>\n');
    await expect(read(`${CORE}/presence.service.ts`)).rejects.toThrow();
    expect(await read('src/app/app.config.ts')).not.toContain('providePresence');
    expect(await read('src/styles.css')).not.toContain('presence-styles');
  });

  it('writes nothing when app.config.ts does not have the expected shape', async () => {
    await writeFile(join(project, 'src/app/app.config.ts'), 'export const appConfig = {};\n');
    await expect(apply()).rejects.toThrow(/app\.config\.ts/);
    await expect(read(`${CORE}/presence.service.ts`)).rejects.toThrow();
    expect(await read(`${MENU}/user-menu.html`)).not.toContain('um-status-trigger');
  });

  it('refuses to overwrite a folder that already exists', async () => {
    await mkdir(join(project, CORE), { recursive: true });
    await writeFile(join(project, CORE, 'presence.service.ts'), '// mine\n');
    await expect(apply()).rejects.toThrow(/overwrite/);
    expect(await read(`${CORE}/presence.service.ts`)).toBe('// mine\n');
    expect(await read(`${MENU}/user-menu.html`)).not.toContain('um-status-trigger');
  });

  it('lists the files the verification stage must find', () => {
    expect(presenceProfile.requiredFiles).toEqual(
      expect.arrayContaining([
        'src/app/core/presence/presence.service.ts',
        'src/app/core/presence/presence.providers.ts',
        'src/app/features/app-shell/layout/sidebar/user-menu/user-status.ts',
        'src/styles/features/presence-styles.css',
        'docs/presence.md',
      ]),
    );
  });
});
