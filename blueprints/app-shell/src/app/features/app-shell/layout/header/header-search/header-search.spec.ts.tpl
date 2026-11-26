import { ComponentFixture, TestBed } from '@angular/core/testing';
import { provideRouter, Router } from '@angular/router';
import { NavigationGroup } from '@core/navigation/navigation.types';
import { LayoutService } from '../../../services/layout.service';
import { HeaderSearch } from './header-search';

const TREE: readonly NavigationGroup[] = [
  {
    label: 'General',
    items: [
      { id: 'home', title: 'Inicio', link: '/home', icon: 'Home' },
      { id: 'users', title: 'Usuarios', link: '/users', icon: 'Users' },
      { id: 'secret', title: 'Secreto', link: '/secret', hidden: () => true },
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
          { id: 'notifications', title: 'Notificaciones', link: '/settings/notifications' },
        ],
      },
    ],
  },
];

class LayoutServiceMock {
  readonly getNavigationGroups = vi.fn(() => TREE);
}

describe('HeaderSearch', () => {
  let fixture: ComponentFixture<HeaderSearch>;
  let component: HeaderSearch;
  let router: Router;

  const host = (): HTMLElement => fixture.nativeElement as HTMLElement;
  const options = (): HTMLElement[] => Array.from(host().querySelectorAll<HTMLElement>('[role="option"]'));

  const search = async (text: string): Promise<void> => {
    host().querySelector('.header-search')?.dispatchEvent(new Event('focusin', { bubbles: true }));
    component.control.setValue(text);
    await fixture.whenStable();
  };

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [HeaderSearch],
      providers: [provideRouter([]), { provide: LayoutService, useClass: LayoutServiceMock }],
    }).compileComponents();
    router = TestBed.inject(Router);
    vi.spyOn(router, 'navigateByUrl').mockResolvedValue(true);
    fixture = TestBed.createComponent(HeaderSearch);
    component = fixture.componentInstance;
    await fixture.whenStable();
  });

  it('shows a search field and no list until something is typed', () => {
    expect(host().querySelector('sa-search')).not.toBeNull();
    expect(host().querySelector('[role="listbox"]')).toBeNull();
  });

  it('lists the pages of the navigation that match what is typed', async () => {
    await search('usu');
    expect(options().map((option) => option.textContent?.trim())).toEqual([expect.stringContaining('Usuarios')]);
  });

  it('finds the pages inside a folder and says which folder holds them', async () => {
    await search('notific');
    expect(options()).toHaveLength(1);
    expect(options()[0].textContent).toContain('Notificaciones');
    expect(options()[0].textContent).toContain('Configuración');
  });

  it('never lists the hidden pages', async () => {
    await search('secreto');
    expect(options()).toHaveLength(0);
  });

  it('says so when nothing matches', async () => {
    await search('zzz');
    expect(host().textContent).toContain('Sin resultados');
  });

  it('goes to the page that is chosen and clears the field', async () => {
    await search('inicio');
    options()[0].click();
    await fixture.whenStable();
    expect(router.navigateByUrl).toHaveBeenCalledWith('/home');
    expect(component.control.value).toBe('');
    expect(host().querySelector('[role="listbox"]')).toBeNull();
  });

  it('chooses with the keyboard: the arrows move, Enter goes and Escape closes', async () => {
    await search('configuracion');
    const wrapper = host().querySelector('.header-search') as HTMLElement;
    expect(options().length).toBeGreaterThan(1);
    wrapper.dispatchEvent(new KeyboardEvent('keydown', { key: 'ArrowDown', bubbles: true }));
    wrapper.dispatchEvent(new KeyboardEvent('keydown', { key: 'Enter', bubbles: true }));
    expect(router.navigateByUrl).toHaveBeenCalledTimes(1);

    await search('inicio');
    wrapper.dispatchEvent(new KeyboardEvent('keydown', { key: 'Escape', bubbles: true }));
    await fixture.whenStable();
    expect(component.control.value).toBe('');
    expect(host().querySelector('[role="listbox"]')).toBeNull();
  });
});
