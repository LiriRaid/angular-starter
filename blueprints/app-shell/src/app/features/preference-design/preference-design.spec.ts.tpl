import { TestBed } from '@angular/core/testing';
import { DesignPreferencesService } from '@core/design-preferences/design-preferences.service';
import { PreferenceDesign } from './preference-design';

describe('PreferenceDesign', () => {
  let service: DesignPreferencesService;

  const render = async () => {
    const fixture = TestBed.createComponent(PreferenceDesign);
    await fixture.whenStable();
    return fixture;
  };

  beforeEach(async () => {
    localStorage.clear();
    await TestBed.configureTestingModule({ imports: [PreferenceDesign] }).compileComponents();
    service = TestBed.inject(DesignPreferencesService);
    service.initialize();
  });

  it('shows the title and the four tabs of the design preferences', async () => {
    const fixture = await render();
    const compiled = fixture.nativeElement as HTMLElement;
    expect(compiled.querySelector('h1')?.textContent).toContain('Preferencias de Diseño');
    expect(fixture.componentInstance.tabs.map((tab) => tab.label)).toEqual(['Apariencia', 'Tema', 'UI', 'Otros']);
    expect(compiled.querySelector('as-tabs')).not.toBeNull();
  });

  it('starts on the appearance tab: the floating wide layout is the only one that can be chosen', async () => {
    const fixture = await render();
    const cards = Array.from((fixture.nativeElement as HTMLElement).querySelectorAll<HTMLButtonElement>('.layout-card'));
    expect(cards).toHaveLength(6);
    expect(cards.filter((card) => !card.disabled)).toHaveLength(1);
    expect(cards.find((card) => !card.disabled)?.getAttribute('aria-pressed')).toBe('true');
    expect((fixture.nativeElement as HTMLElement).textContent).toContain('En construcción');
  });

  it('shows the tokens of the UI tab and applies one in real time', async () => {
    const fixture = await render();
    fixture.componentInstance.activeTab.set('ui');
    await fixture.whenStable();
    const compiled = fixture.nativeElement as HTMLElement;
    expect(compiled.textContent).toContain('Radio de bordes');
    const sharp = Array.from(compiled.querySelectorAll('button')).find((button) => button.textContent?.trim() === 'Recto');
    sharp?.click();
    expect(service.preferences().radius).toBe('sharp');
    expect(document.documentElement.style.getPropertyValue('--as-ui-radius-scale')).toBe('0.25');
  });

  it('turns the breadcrumb off from the other tab', async () => {
    const fixture = await render();
    fixture.componentInstance.activeTab.set('other');
    await fixture.whenStable();
    expect((fixture.nativeElement as HTMLElement).textContent).toContain('Mostrar breadcrumb');
    service.set('showBreadcrumb', false);
    expect(service.preferences().showBreadcrumb).toBe(false);
  });

  it('saves what is on screen and offers the changes only when there are some', async () => {
    const fixture = await render();
    const component = fixture.componentInstance;
    expect(service.hasChanges()).toBe(false);
    service.set('density', 'compact');
    expect(service.hasChanges()).toBe(true);
    component.save();
    expect(service.hasChanges()).toBe(false);
    expect(localStorage.getItem('__PROJECT_NAME__:design-preferences')).toContain('compact');
  });

  it('resets to the defaults', async () => {
    const fixture = await render();
    service.set('fontSize', 'large');
    fixture.componentInstance.reset();
    expect(service.preferences().fontSize).toBe('normal');
    expect(localStorage.getItem('__PROJECT_NAME__:design-preferences')).toBeNull();
  });
});
