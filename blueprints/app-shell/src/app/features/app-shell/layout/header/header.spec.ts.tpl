import { ComponentFixture, TestBed } from '@angular/core/testing';
import { NO_ERRORS_SCHEMA, signal } from '@angular/core';
import { provideRouter, Router } from '@angular/router';
import { Header } from './header';
import { LayoutService } from '../../services/layout.service';
import { BreadcrumbService } from '@core/navigation/breadcrumb.service';
import { ThemeService } from '@core/theme/theme.service';
import { DesignPreferencesService } from '@core/design-preferences/design-preferences.service';

class LayoutServiceMock {
  readonly state = signal('EXPANDED');
  readonly isOpen = vi.fn(() => true);
  readonly isMobile = vi.fn(() => false);
  readonly toggle = vi.fn();
  readonly collapseAll = vi.fn();
  readonly expandParentsOfActiveItem = vi.fn();
  readonly expandParentsIfNoManualExpansion = vi.fn();
}

class ThemeServiceMock {
  readonly mode = signal<'light' | 'dark'>('dark');
  readonly primaryColorKey = signal('black');
  readonly surfaceColorKey = signal('neutral');
  readonly toggleMode = vi.fn(() => {
    this.mode.update((mode) => (mode === 'dark' ? 'light' : 'dark'));
  });
  readonly applyColor = vi.fn();
  readonly applySurface = vi.fn();
}

describe('Header', () => {
  let fixture: ComponentFixture<Header>;
  let component: Header;
  let layoutService: LayoutServiceMock;
  let themeService: ThemeServiceMock;
  let router: Router;

  beforeEach(async () => {
    TestBed.overrideComponent(Header, {
      set: {
        imports: [],
        template: '',
      },
    });

    await TestBed.configureTestingModule({
      imports: [Header],
      providers: [
        provideRouter([]),
        { provide: LayoutService, useClass: LayoutServiceMock },
        { provide: ThemeService, useClass: ThemeServiceMock },
        {
          provide: BreadcrumbService,
          useValue: {
            breadcrumbs: signal([]),
          },
        },
      ],
    }).compileComponents();

    fixture = TestBed.createComponent(Header);
    component = fixture.componentInstance;
    layoutService = TestBed.inject(LayoutService) as unknown as LayoutServiceMock;
    themeService = TestBed.inject(ThemeService) as unknown as ThemeServiceMock;
    router = TestBed.inject(Router);
    fixture.detectChanges();
  });

  it('collapses folders before toggling the desktop sidebar', () => {
    component.toggleSidebar();

    expect(layoutService.collapseAll).toHaveBeenCalled();
    expect(layoutService.toggle).toHaveBeenCalledWith(router.url);
  });

  it('expands parents when opening the desktop sidebar', () => {
    layoutService.isOpen.mockReturnValue(false);

    component.toggleSidebar();

    expect(layoutService.expandParentsOfActiveItem).toHaveBeenCalledWith(router.url);
  });

  it('only toggles the mobile sidebar, without collapsing the folders', () => {
    layoutService.isMobile.mockReturnValue(true);

    component.toggleSidebar();

    expect(layoutService.toggle).toHaveBeenCalledWith(router.url);
    expect(layoutService.collapseAll).not.toHaveBeenCalled();
  });

  it('toggles the theme mode through ThemeService', () => {
    component.toggleTheme();

    expect(themeService.toggleMode).toHaveBeenCalled();
    expect(component.isDark()).toBe(false);
  });
});

describe('Header breadcrumb preference', () => {
  const render = async () => {
    // The real template, with its children as plain elements: only the breadcrumb slot matters here.
    TestBed.overrideComponent(Header, { set: { imports: [], schemas: [NO_ERRORS_SCHEMA] } });
    await TestBed.configureTestingModule({
      imports: [Header],
      providers: [
        provideRouter([]),
        { provide: LayoutService, useClass: LayoutServiceMock },
        { provide: ThemeService, useClass: ThemeServiceMock },
        { provide: BreadcrumbService, useValue: { breadcrumbs: signal([]) } },
      ],
    }).compileComponents();
    const fixture = TestBed.createComponent(Header);
    fixture.detectChanges();
    return fixture;
  };

  it('shows the breadcrumb and hides it when "Mostrar breadcrumb" is turned off', async () => {
    const fixture = await render();
    const element = fixture.nativeElement as HTMLElement;
    expect(element.querySelector('__PREFIX__-breadcrumb')).not.toBeNull();

    TestBed.inject(DesignPreferencesService).set('showBreadcrumb', false);
    fixture.detectChanges();
    expect(element.querySelector('__PREFIX__-breadcrumb')).toBeNull();
  });
});
