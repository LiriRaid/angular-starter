import { ComponentFixture, TestBed } from '@angular/core/testing';
import { signal } from '@angular/core';
import { provideRouter, Router } from '@angular/router';
import { NAV_APP_NAME_TOKEN } from '@core/navigation/navigation.tokens';
import { Sidebar } from './sidebar';
import { LayoutService } from '../../services/layout.service';
import { SidebarStatus } from '../enums/sidebar-status.enum';
import { DesignPreferencesService } from '@core/design-preferences/design-preferences.service';

class LayoutServiceMock {
  readonly state = signal(SidebarStatus.EXPANDED);
  readonly isMobile = signal(false);
  readonly isOpen = signal(true);
  readonly getNavigationGroups = vi.fn(() => []);
  readonly setOpen = vi.fn((open: boolean) => this.isOpen.set(open));
  readonly updateCurrentUrl = vi.fn();
  readonly handleNavigationChange = vi.fn();
  readonly expandParentsOfActiveItem = vi.fn();
  readonly expandParentsIfNoManualExpansion = vi.fn();
  readonly collapseAll = vi.fn();
  readonly onTransitionClosed = vi.fn();
  readonly setMobile = vi.fn((isMobile: boolean) => this.isMobile.set(isMobile));
}

describe('Sidebar', () => {
  let fixture: ComponentFixture<Sidebar>;
  let component: Sidebar;
  let layoutService: LayoutServiceMock;
  let router: Router;

  beforeEach(async () => {
    TestBed.overrideComponent(Sidebar, {
      set: {
        imports: [],
        template: '',
      },
    });

    await TestBed.configureTestingModule({
      imports: [Sidebar],
      providers: [provideRouter([]), { provide: LayoutService, useClass: LayoutServiceMock }, { provide: NAV_APP_NAME_TOKEN, useValue: 'inventory' }],
    }).compileComponents();

    fixture = TestBed.createComponent(Sidebar);
    component = fixture.componentInstance;
    layoutService = TestBed.inject(LayoutService) as unknown as LayoutServiceMock;
    router = TestBed.inject(Router);
  });

  it('muestra el nombre del proyecto como marca, con su inicial', () => {
    expect(component.brandTitle).toBe('inventory');
    expect(component.brandInitial).toBe('I');
  });

  it('isHidden oculta solo los items que lo piden con `hidden`', () => {
    expect(component.isHidden({ id: 'secret', title: 'Secret', hidden: () => true })).toBe(true);
    expect(component.isHidden({ id: 'home', title: 'Home', hidden: () => false })).toBe(false);
    expect(component.isHidden({ id: 'plain', title: 'Plain' })).toBe(false);
  });

  it('isActive marca el item cuyo link es la URL actual', () => {
    expect(component.isActive({ id: 'root', title: 'Root', link: '/' })).toBe(true);
    expect(component.isActive({ id: 'users', title: 'Users', link: '/users' })).toBe(false);
  });

  it('shows the sidebar on desktop only when the layout is expanded', () => {
    expect(component.isSidebarVisible()).toBe(true);

    layoutService.state.set(SidebarStatus.COLLAPSED);

    expect(component.isSidebarVisible()).toBe(false);
  });

  it('navigates to links and keeps the sidebar open on expanded desktop', () => {
    const navigateSpy = vi.spyOn(router, 'navigate').mockResolvedValue(true);

    component.navigate('/dashboard');

    expect(navigateSpy).toHaveBeenCalledWith(['/dashboard']);
    expect(layoutService.setOpen).not.toHaveBeenCalledWith(false);
  });

  it('closes the sidebar after navigating on mobile', () => {
    const navigateSpy = vi.spyOn(router, 'navigate').mockResolvedValue(true);
    layoutService.isMobile.set(true);

    component.navigate('/dashboard');

    expect(navigateSpy).toHaveBeenCalledWith(['/dashboard']);
    expect(layoutService.setOpen).toHaveBeenCalledWith(false);
  });

  it('un item con hijos y sin link abre y cierra sus hijos', () => {
    const folder = { id: 'settings', title: 'Settings', children: [{ id: 'general', title: 'General', link: '/settings/general' }], unfolded: false };

    component.unfolItem(folder);
    expect(folder.unfolded).toBe(true);

    component.unfolItem(folder);
    expect(folder.unfolded).toBe(false);
  });

  it('clears the temporary collapsed-search restore state when desktop closes externally', () => {
    layoutService.state.set(SidebarStatus.COLLAPSED);

    component.onCollapsedSearchClick();
    fixture.detectChanges();

    expect(component['restoreCollapsedAfterSearch']()).toBe(true);

    layoutService.setOpen(false);
    fixture.detectChanges();

    expect(component['restoreCollapsedAfterSearch']()).toBe(false);
    expect(component['collapseFoldersAfterCollapsedSearchNav']()).toBe(false);
  });

  describe('layout', () => {
    const preferences = (): DesignPreferencesService => TestBed.inject(DesignPreferencesService);

    it('is not compact in the default layout', () => {
      expect(component.compact()).toBe(false);
    });

    it('is compact in a compact layout and goes back with the next one', () => {
      preferences().set('layout', 'compact-joined');
      expect(component.compact()).toBe(true);
      preferences().set('layout', 'floating-wide');
      expect(component.compact()).toBe(false);
    });

    it('is the drawer of every layout on a small screen, compact or not', () => {
      preferences().set('layout', 'compact-joined');
      layoutService.isMobile.set(true);
      expect(component.compact()).toBe(false);
    });
  });
});
