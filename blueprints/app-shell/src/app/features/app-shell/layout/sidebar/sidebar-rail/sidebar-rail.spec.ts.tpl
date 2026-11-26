import { ComponentFixture, TestBed } from '@angular/core/testing';
import { provideRouter, Router } from '@angular/router';
import { NAV_APP_NAME_TOKEN } from '@core/navigation/navigation.tokens';
import { NavigationGroup } from '@core/navigation/navigation.types';
import { LayoutService } from '../../../services/layout.service';
import { SidebarRail } from './sidebar-rail';

const TREE: readonly NavigationGroup[] = [
  {
    label: 'General',
    items: [
      { id: 'home', title: 'Inicio', link: '/home', icon: 'Home' },
      { id: 'users', title: 'Usuarios', link: '/users', icon: 'Users' },
      { id: 'secret', title: 'Secreto', link: '/secret', icon: 'Lock', hidden: () => true },
    ],
  },
  {
    label: 'Sistema',
    items: [
      {
        id: 'settings',
        title: 'Configuración',
        icon: 'Settings',
        children: [
          { id: 'general', title: 'General', link: '/settings/general' },
          { id: 'notifications', title: 'Notificaciones', link: '/settings/notifications', children: [{ id: 'email', title: 'Correo', link: '/settings/notifications/email' }] },
        ],
      },
    ],
  },
];

class LayoutServiceMock {
  readonly getNavigationGroups = vi.fn(() => TREE);
}

describe('SidebarRail', () => {
  let fixture: ComponentFixture<SidebarRail>;
  let router: Router;

  const host = (): HTMLElement => fixture.nativeElement as HTMLElement;
  const items = (): HTMLButtonElement[] => Array.from(host().querySelectorAll<HTMLButtonElement>('.rail-item'));
  const item = (title: string): HTMLButtonElement | undefined => items().find((button) => button.textContent?.includes(title));
  const subnavButtons = (): HTMLButtonElement[] => Array.from(host().querySelectorAll<HTMLButtonElement>('.rail-subnav button'));

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [SidebarRail],
      providers: [provideRouter([]), { provide: LayoutService, useClass: LayoutServiceMock }, { provide: NAV_APP_NAME_TOKEN, useValue: 'inventory' }],
    }).compileComponents();
    router = TestBed.inject(Router);
    vi.spyOn(router, 'navigateByUrl').mockResolvedValue(true);
    fixture = TestBed.createComponent(SidebarRail);
    await fixture.whenStable();
  });

  it('shows only the mark of the project as the logo', () => {
    const logo = host().querySelector('.rail-logo');
    expect(logo?.textContent?.trim()).toBe('I');
  });

  it('has no user menu: in the compact layouts it is in the header', () => {
    expect(host().querySelector('__PREFIX__-user-menu')).toBeNull();
  });

  it('shows every visible item of the navigation, with its icon above its label', () => {
    expect(items().map((button) => button.querySelector('.rail-label')?.textContent?.trim())).toEqual(['Inicio', 'Usuarios', 'Configuración']);
    expect(item('Inicio')?.querySelector('sa-icon')).not.toBeNull();
    const children = Array.from(item('Inicio')?.children ?? []).map((element) => element.tagName.toLowerCase());
    expect(children.indexOf('sa-icon')).toBeLessThan(children.indexOf('span'));
  });

  it('goes to the page of an item and marks it as the current one', async () => {
    item('Usuarios')?.click();
    expect(router.navigateByUrl).toHaveBeenCalledWith('/users');
    fixture.componentInstance.currentUrl.set('/users');
    await fixture.whenStable();
    expect(item('Usuarios')?.getAttribute('aria-current')).toBe('page');
    expect(item('Inicio')?.getAttribute('aria-current')).toBeNull();
  });

  describe('a folder', () => {
    it('opens a small navigation next to the rail with what it holds', async () => {
      expect(item('Configuración')?.getAttribute('aria-expanded')).toBe('false');
      item('Configuración')?.click();
      await fixture.whenStable();
      expect(item('Configuración')?.getAttribute('aria-expanded')).toBe('true');
      expect(host().querySelector('.rail-subnav')?.textContent).toContain('Configuración');
      expect(subnavButtons().map((button) => button.textContent?.trim())).toEqual(['General', 'Notificaciones', 'Correo']);
      expect(router.navigateByUrl).not.toHaveBeenCalled();
    });

    it('goes to the page that is chosen and closes', async () => {
      item('Configuración')?.click();
      await fixture.whenStable();
      subnavButtons()[1].click();
      await fixture.whenStable();
      expect(router.navigateByUrl).toHaveBeenCalledWith('/settings/notifications');
      expect(host().querySelector('.rail-subnav')).toBeNull();
    });

    it('closes when its item is pressed again, with Escape or with a click outside', async () => {
      item('Configuración')?.click();
      await fixture.whenStable();
      item('Configuración')?.click();
      await fixture.whenStable();
      expect(host().querySelector('.rail-subnav')).toBeNull();

      item('Configuración')?.click();
      await fixture.whenStable();
      document.dispatchEvent(new KeyboardEvent('keydown', { key: 'Escape' }));
      await fixture.whenStable();
      expect(host().querySelector('.rail-subnav')).toBeNull();

      item('Configuración')?.click();
      await fixture.whenStable();
      document.body.click();
      await fixture.whenStable();
      expect(host().querySelector('.rail-subnav')).toBeNull();
    });

    it('marks the folder as current while one of its pages is', async () => {
      fixture.componentInstance.currentUrl.set('/settings/notifications/email');
      await fixture.whenStable();
      expect(item('Configuración')?.getAttribute('aria-current')).toBe('true');
    });
  });
});
