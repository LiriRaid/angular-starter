import { ComponentFixture, TestBed } from '@angular/core/testing';
import { signal } from '@angular/core';
import { ThemeService } from '@core/theme/theme.service';
import { AsThemeColorPicker } from './as-theme-color-picker';

type MockPopoverPanel = { togglePopover: () => void; hidePopover: () => void };

type AsThemeColorPickerInternals = {
  toggle: (panel: MockPopoverPanel, event: MouseEvent) => void;
  selectPrimary: (key: string, panel: MockPopoverPanel) => void;
  selectSurface: (key: string) => void;
  onPanelShow: () => void;
  onPanelHide: () => void;
  isPanelOpen: { (): boolean };
  pickerButtonClass: () => string;
  onOutsidePointerDown: (event: PointerEvent) => void;
  onEscapeKeyDown: (event: KeyboardEvent) => void;
  isEventInsidePicker: (event: Event) => boolean;
  resolveTriggerElement: (event: MouseEvent) => HTMLElement | null;
  getVisualOffsetX: () => number;
  clamp: (value: number, min: number, max: number) => number;
  getPanelLeft: (params: { triggerCenterX: number; panelWidth: number; viewportWidth: number }) => number;
  getPanelTop: (params: { panel: HTMLElement; triggerRect: DOMRect; panelHeight: number; viewportHeight: number }) => number;
};

class ThemeServiceMock {
  readonly primaryColorKey = signal('black');
  readonly surfaceColorKey = signal('neutral');

  applyColor = vi.fn((key: string) => {
    this.primaryColorKey.set(key);
  });

  applySurface = vi.fn((key: string) => {
    this.surfaceColorKey.set(key);
  });
}

function makeDomRect(overrides: Partial<DOMRect> = {}): DOMRect {
  return { x: 0, y: 0, width: 0, height: 0, top: 0, left: 0, right: 0, bottom: 0, toJSON: () => '', ...overrides } as DOMRect;
}

describe('AsThemeColorPicker', () => {
  let fixture: ComponentFixture<AsThemeColorPicker>;
  let component: AsThemeColorPicker;
  let internals: AsThemeColorPickerInternals;
  let themeService: ThemeServiceMock;

  beforeEach(async () => {
    TestBed.overrideComponent(AsThemeColorPicker, {
      set: {
        imports: [],
        template: '',
      },
    });

    await TestBed.configureTestingModule({
      imports: [AsThemeColorPicker],
      providers: [{ provide: ThemeService, useClass: ThemeServiceMock }],
    }).compileComponents();

    themeService = TestBed.inject(ThemeService) as unknown as ThemeServiceMock;
    fixture = TestBed.createComponent(AsThemeColorPicker);
    component = fixture.componentInstance;
    internals = component as unknown as AsThemeColorPickerInternals;
    fixture.detectChanges();
  });

  it('delegates trigger clicks to the popover panel', () => {
    const panel: MockPopoverPanel = { togglePopover: vi.fn(), hidePopover: vi.fn() };
    const clickEvent = new MouseEvent('click');

    internals.toggle(panel, clickEvent);

    expect(panel.togglePopover).toHaveBeenCalled();
  });

  it('applies a primary color and hides the panel', () => {
    const panel: MockPopoverPanel = { togglePopover: vi.fn(), hidePopover: vi.fn() };

    internals.selectPrimary('blue', panel);

    expect(themeService.applyColor).toHaveBeenCalledWith('blue');
    expect(themeService.primaryColorKey()).toBe('blue');
    expect(panel.hidePopover).toHaveBeenCalled();
  });

  it('applies a surface color without closing the panel', () => {
    internals.selectSurface('slate');

    expect(themeService.applySurface).toHaveBeenCalledWith('slate');
    expect(themeService.surfaceColorKey()).toBe('slate');
  });

  describe('estado del panel', () => {
    it('onPanelShow marca isPanelOpen en true', () => {
      internals.onPanelShow();
      expect(internals.isPanelOpen()).toBe(true);
    });

    it('onPanelHide marca isPanelOpen en false', () => {
      internals.onPanelShow();
      internals.onPanelHide();
      expect(internals.isPanelOpen()).toBe(false);
    });

    it('pickerButtonClass incluye el modificador --active solo mientras el panel está abierto', () => {
      expect(internals.pickerButtonClass()).not.toContain('theme-picker-trigger--active');
      internals.onPanelShow();
      expect(internals.pickerButtonClass()).toContain('theme-picker-trigger--active');
    });
  });

  describe('cierre por click afuera / Escape', () => {
    it('onOutsidePointerDown no hace nada si el panel está cerrado', () => {
      expect(() => internals.onOutsidePointerDown({ target: document.body } as unknown as PointerEvent)).not.toThrow();
      expect(internals.isPanelOpen()).toBe(false);
    });

    it('onOutsidePointerDown cierra el panel si el click fue fuera del picker', () => {
      internals.onPanelShow();
      internals.onOutsidePointerDown({ target: document.body } as unknown as PointerEvent);
      expect(internals.isPanelOpen()).toBe(false);
    });

    it('onEscapeKeyDown cierra el panel al presionar Escape', () => {
      internals.onPanelShow();
      internals.onEscapeKeyDown({ key: 'Escape' } as KeyboardEvent);
      expect(internals.isPanelOpen()).toBe(false);
    });

    it('onEscapeKeyDown ignora otras teclas', () => {
      internals.onPanelShow();
      internals.onEscapeKeyDown({ key: 'Enter' } as KeyboardEvent);
      expect(internals.isPanelOpen()).toBe(true);
    });
  });

  describe('isEventInsidePicker', () => {
    it('retorna false sin target', () => {
      expect(internals.isEventInsidePicker({ target: null } as unknown as Event)).toBe(false);
    });

    it('retorna false cuando no hay panel ni trigger registrados', () => {
      expect(internals.isEventInsidePicker({ target: document.body } as unknown as Event)).toBe(false);
    });
  });

  describe('resolveTriggerElement', () => {
    it('retorna null sin currentTarget', () => {
      expect(internals.resolveTriggerElement({ currentTarget: null } as unknown as MouseEvent)).toBeNull();
    });

    it('retorna el propio elemento si ya tiene la clase as-btn', () => {
      const el = document.createElement('button');
      el.classList.add('as-btn');
      expect(internals.resolveTriggerElement({ currentTarget: el } as unknown as MouseEvent)).toBe(el);
    });

    it('busca un descendiente .as-btn si el elemento no lo es', () => {
      const wrapper = document.createElement('div');
      const inner = document.createElement('button');
      inner.classList.add('as-btn');
      wrapper.appendChild(inner);
      expect(internals.resolveTriggerElement({ currentTarget: wrapper } as unknown as MouseEvent)).toBe(inner);
    });
  });

  describe('clamp', () => {
    it('respeta el rango cuando el valor ya está dentro', () => {
      expect(internals.clamp(5, 0, 10)).toBe(5);
    });

    it('limita al mínimo', () => {
      expect(internals.clamp(-5, 0, 10)).toBe(0);
    });

    it('limita al máximo', () => {
      expect(internals.clamp(50, 0, 10)).toBe(10);
    });
  });

  describe('getVisualOffsetX', () => {
    it('retorna 45 en viewports anchos (>=1557px)', () => {
      Object.defineProperty(document.documentElement, 'clientWidth', { value: 1600, configurable: true });
      expect(internals.getVisualOffsetX()).toBe(45);
    });

    it('retorna -35 en viewports angostos', () => {
      Object.defineProperty(document.documentElement, 'clientWidth', { value: 1200, configurable: true });
      expect(internals.getVisualOffsetX()).toBe(-35);
    });
  });

  describe('getPanelLeft', () => {
    it('centra el panel respecto al trigger dentro del margen del viewport', () => {
      Object.defineProperty(document.documentElement, 'clientWidth', { value: 1200, configurable: true });
      const left = internals.getPanelLeft({ triggerCenterX: 600, panelWidth: 200, viewportWidth: 1200 });
      // 600 - 100 + (-35 offset en viewport angosto) = 465
      expect(left).toBe(465);
    });

    it('no deja que el panel se salga por la izquierda', () => {
      Object.defineProperty(document.documentElement, 'clientWidth', { value: 1200, configurable: true });
      const left = internals.getPanelLeft({ triggerCenterX: 0, panelWidth: 200, viewportWidth: 1200 });
      expect(left).toBe(12); // viewportMargin
    });
  });

  describe('getPanelTop', () => {
    it('ubica el panel debajo del trigger cuando hay espacio', () => {
      const panel = document.createElement('div');
      const top = internals.getPanelTop({ panel, triggerRect: makeDomRect({ top: 100, bottom: 120 }), panelHeight: 200, viewportHeight: 800 });
      expect(top).toBe(128); // bottom(120) + gap(8)
      expect(panel.dataset['placement']).toBe('bottom');
    });

    it('ubica el panel arriba del trigger cuando no cabe abajo', () => {
      const panel = document.createElement('div');
      const top = internals.getPanelTop({ panel, triggerRect: makeDomRect({ top: 700, bottom: 720 }), panelHeight: 200, viewportHeight: 800 });
      expect(top).toBe(492); // top(700) - panelHeight(200) - gap(8)
      expect(panel.dataset['placement']).toBe('top');
    });
  });
});
