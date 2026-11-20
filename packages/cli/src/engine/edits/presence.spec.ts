import { readFile } from 'node:fs/promises';
import { join } from 'node:path';
import { beforeAll, describe, expect, it } from 'vitest';
import { BLUEPRINTS_ROOT, renderTemplate } from '../blueprint.js';
import { addPresenceToUserMenuClass, addPresenceToUserMenuTemplate } from './presence.js';

const MENU = join(BLUEPRINTS_ROOT, 'app-shell/src/app/features/app-shell/layout/sidebar/user-menu');

let html: string;
let source: string;

beforeAll(async () => {
  const render = async (file: string): Promise<string> =>
    renderTemplate(await readFile(join(MENU, file), 'utf8'), { PREFIX: 'app' });
  html = await render('user-menu.html.tpl');
  source = await render('user-menu.ts.tpl');
});

describe('presence in the user menu template', () => {
  it('puts the presence dot on both avatars, each with the background of its surface', () => {
    const edited = addPresenceToUserMenuTemplate(html);
    const avatars = edited.match(/<as-avatar[^>]*>/g) ?? [];
    expect(avatars).toHaveLength(2);
    for (const avatar of avatars) {
      expect(avatar).toContain('mode="presence"');
      expect(avatar).toContain('[presenceStatus]="statusMenu.status()"');
    }
    expect(avatars[0]).toContain('class="um-card-avatar"');
    expect(avatars[0]).toContain('dotBackground="var(--app-sidebar-bg)"');
    expect(avatars[1]).toContain('dotBackground="var(--app-overlay-bg)"');
  });

  it('puts the status row between dividers, right before the preferences button', () => {
    const edited = addPresenceToUserMenuTemplate(html);
    const row = edited.indexOf('um-status-trigger');
    const preferences = edited.indexOf('label="Preferencias de Diseño"');
    expect(row).toBeGreaterThan(edited.indexOf('um-card'));
    expect(row).toBeLessThan(preferences);
    const between = edited.slice(row, preferences);
    expect(between.match(/<hr /g)).toHaveLength(1);
    expect(edited.slice(0, row)).toMatch(/<hr [^>]*\/>\s*<div class="$/);
    expect(edited).toContain('(mouseenter)="statusMenu.onStatusTriggerEnter()"');
    expect(edited).toContain('statusMenu.statusLabel()');
    expect(edited).toContain('>Estado<');
  });

  it('puts the sub-panels after the popover, where position: fixed is relative to the viewport', () => {
    const edited = addPresenceToUserMenuTemplate(html);
    const popoverEnd = edited.indexOf('</as-popover>');
    for (const marker of [
      'statusMenu.statusSubPanelPos()',
      'um-sub-panel--duration',
      'statusMenu.durationSubPanelPos()',
      'data-popover-sub-panel',
    ]) {
      expect(edited.indexOf(marker), marker).toBeGreaterThan(popoverEnd);
    }
    expect(edited).toContain('Volver en');
  });

  it('is idempotent', () => {
    const once = addPresenceToUserMenuTemplate(html);
    expect(addPresenceToUserMenuTemplate(once)).toBe(once);
  });

  it('keeps everything else of the template as it was', () => {
    const edited = addPresenceToUserMenuTemplate(html);
    expect(edited).toContain('openPreferences()');
    expect(edited).toContain('{{ appName }}');
    expect(edited.startsWith('<ng-template #userInfoTooltip>')).toBe(true);
  });

  it('works on a template with Windows line endings', () => {
    const edited = addPresenceToUserMenuTemplate(html.replaceAll('\n', '\r\n'));
    expect(edited).toContain('um-status-trigger');
    expect(edited.replaceAll('\r\n', '')).not.toContain('\n');
  });

  it.each([
    ['</as-popover>', 'the popover'],
    ['label="Preferencias de Diseño"', 'the preferences button'],
  ])('names the missing anchor when the template has no %s', (anchor, name) => {
    expect(() => addPresenceToUserMenuTemplate(html.replace(anchor, ''))).toThrow(
      new RegExp(`${name}`),
    );
  });

  it('names the avatars it expects', () => {
    expect(() => addPresenceToUserMenuTemplate('<as-popover></as-popover>')).toThrow(/as-avatar/);
  });
});

describe('presence in the user menu class', () => {
  it('imports the status menu and adds it next to the popover reference', () => {
    const edited = addPresenceToUserMenuClass(source);
    expect(edited).toContain("import { UserStatusMenu } from './user-status';");
    expect(edited).toMatch(
      /readonly statusMenu = new UserStatusMenu\(\(\) => this\.popoverRef\(\), \(\) => this\.popoverOpen\(\)\);/,
    );
    expect(edited).toContain('openPreferences(): void');
  });

  it('is idempotent', () => {
    const once = addPresenceToUserMenuClass(source);
    expect(addPresenceToUserMenuClass(once)).toBe(once);
  });

  it('names the class it expects', () => {
    expect(() => addPresenceToUserMenuClass('export class Other {}\n')).toThrow(/UserMenu/);
  });

  it('needs the popover reference the status menu reads', () => {
    expect(() =>
      addPresenceToUserMenuClass(
        source.replace('private readonly popoverRef = viewChild(AsPopover);', ''),
      ),
    ).toThrow(/popoverRef/);
  });
});
