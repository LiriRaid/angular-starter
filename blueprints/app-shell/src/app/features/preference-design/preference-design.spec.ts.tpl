import { signal } from '@angular/core';
import { TestBed } from '@angular/core/testing';
import { DesignPreferencesService, type DesignPreferences } from '@core/design-preferences/design-preferences.service';
import { DESIGN_PREFERENCES_STORE, type DesignPreferencesDocument, type DesignPreferencesStore } from '@core/design-preferences/design-preferences.store';
import { ENABLED_LAYOUT_MODES, LAYOUT_MODES } from '@core/design-preferences/layout-modes';
import { PreferenceDesign } from './preference-design';

class FakeStore implements DesignPreferencesStore {
  readonly canSave = signal(true);
  readonly saves: DesignPreferences[] = [];
  load = vi.fn(async (): Promise<DesignPreferencesDocument | null> => null);
  save = vi.fn(async (preferences: DesignPreferences): Promise<DesignPreferencesDocument> => {
    this.saves.push(preferences);
    return { version: `v${this.saves.length}`, preferences };
  });
}

describe('PreferenceDesign', () => {
  let service: DesignPreferencesService;
  let store: FakeStore;

  const render = async () => {
    const fixture = TestBed.createComponent(PreferenceDesign);
    await fixture.whenStable();
    return fixture;
  };

  const layoutCards = (fixture: { nativeElement: unknown }): HTMLButtonElement[] => Array.from((fixture.nativeElement as HTMLElement).querySelectorAll<HTMLButtonElement>('.layout-card'));

  beforeEach(async () => {
    store = new FakeStore();
    await TestBed.configureTestingModule({
      imports: [PreferenceDesign],
      providers: [{ provide: DESIGN_PREFERENCES_STORE, useValue: store }],
    }).compileComponents();
    service = TestBed.inject(DesignPreferencesService);
    await service.initialize();
  });

  it('shows the title and the four tabs of the design preferences', async () => {
    const fixture = await render();
    const compiled = fixture.nativeElement as HTMLElement;
    expect(compiled.querySelector('h1')?.textContent).toContain('Preferencias de Diseño');
    expect(fixture.componentInstance.tabs.map((tab) => tab.label)).toEqual(['Apariencia', 'Tema', 'UI', 'Otros']);
    expect(compiled.querySelector('sa-tabs')).not.toBeNull();
  });

  it('starts on the appearance tab with every layout listed and the enabled ones available', async () => {
    const fixture = await render();
    const cards = layoutCards(fixture);
    expect(cards).toHaveLength(LAYOUT_MODES.filter((mode) => !mode.built || ENABLED_LAYOUT_MODES.includes(mode.id)).length);
    expect(cards.filter((card) => !card.disabled)).toHaveLength(ENABLED_LAYOUT_MODES.length);
    expect(cards.filter((card) => card.getAttribute('aria-pressed') === 'true')).toHaveLength(1);
    expect(cards.find((card) => card.getAttribute('aria-pressed') === 'true')?.textContent).toContain('Flotante (ancho)');
  });

  it('marks the layouts that are not built yet as under construction', async () => {
    const fixture = await render();
    const pending = LAYOUT_MODES.filter((mode) => !mode.built).length;
    const text = (fixture.nativeElement as HTMLElement).textContent ?? '';
    expect(text.split('En construcción').length - 1).toBe(pending);
  });

  it('applies a layout in real time when its card is pressed', async () => {
    const fixture = await render();
    for (const id of ENABLED_LAYOUT_MODES) {
      const card = layoutCards(fixture).find((element) => element.dataset['layout'] === id);
      card?.click();
      await fixture.whenStable();
      expect(service.preferences().layout).toBe(id);
      expect(document.documentElement.getAttribute('data-layout')).toBe(id);
      expect(layoutCards(fixture).find((element) => element.dataset['layout'] === id)?.getAttribute('aria-pressed')).toBe('true');
    }
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
    expect(document.documentElement.style.getPropertyValue('--sa-ui-radius-scale')).toBe('0.25');
  });

  it('turns the breadcrumb off from the other tab', async () => {
    const fixture = await render();
    fixture.componentInstance.activeTab.set('other');
    await fixture.whenStable();
    expect((fixture.nativeElement as HTMLElement).textContent).toContain('Mostrar breadcrumb');
    service.set('showBreadcrumb', false);
    expect(service.preferences().showBreadcrumb).toBe(false);
  });

  it('saves what is on screen through the store and offers the changes only when there are some', async () => {
    const fixture = await render();
    const component = fixture.componentInstance;
    expect(service.hasChanges()).toBe(false);
    service.set('density', 'compact');
    expect(service.hasChanges()).toBe(true);
    await component.save();
    expect(service.hasChanges()).toBe(false);
    expect(store.saves[0].density).toBe('compact');
  });

  it('says the changes are for the whole platform and that the others will be told to reload', async () => {
    const fixture = await render();
    service.set('density', 'compact');
    await fixture.whenStable();
    const text = (fixture.nativeElement as HTMLElement).textContent ?? '';
    expect(text).toContain('Hay cambios sin guardar');
    expect(text).toContain('toda la plataforma');
  });

  it('does not offer to save to whoever the store does not allow', async () => {
    const fixture = await render();
    store.canSave.set(false);
    service.set('density', 'compact');
    await fixture.whenStable();
    const save = Array.from((fixture.nativeElement as HTMLElement).querySelectorAll('button')).find((button) => button.textContent?.includes('Guardar cambios'));
    expect(save?.disabled).toBe(true);
    expect((fixture.nativeElement as HTMLElement).textContent).toContain('No tienes permiso para guardar');
  });

  it('shows when the save did not go through', async () => {
    const fixture = await render();
    store.save.mockRejectedValueOnce(new Error('500'));
    service.set('density', 'compact');
    await fixture.componentInstance.save();
    await fixture.whenStable();
    expect((fixture.nativeElement as HTMLElement).textContent).toContain('No se pudo guardar');
  });

  it('resets to the defaults and saves them', async () => {
    const fixture = await render();
    service.set('fontSize', 'large');
    await fixture.componentInstance.reset();
    expect(service.preferences().fontSize).toBe('normal');
    expect(store.saves.at(-1)?.fontSize).toBe('normal');
  });
});
