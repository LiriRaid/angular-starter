import { ComponentFixture, TestBed } from '@angular/core/testing';
import { signal } from '@angular/core';
import { ThemeService } from '@core/theme/theme.service';
import { SaThemeColorPicker } from './sa-theme-color-picker';

type MockPopoverPanel = { togglePopover: () => void; hidePopover: () => void };

type SaThemeColorPickerInternals = {
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

describe('SaThemeColorPicker', () => {
  let fixture: ComponentFixture<SaThemeColorPicker>;
  let component: SaThemeColorPicker;
  let internals: SaThemeColorPickerInternals;
  let themeService: ThemeServiceMock;

  beforeEach(async () => {
    TestBed.overrideComponent(SaThemeColorPicker, {
      set: {
        imports: [],
        template: '',
      },
    });

    await TestBed.configureTestingModule({
      imports: [SaThemeColorPicker],
      providers: [{ provide: ThemeService, useClass: ThemeServiceMock }],
    }).compileComponents();

    themeService = TestBed.inject(ThemeService) as unknown as ThemeServiceMock;
    fixture = TestBed.createComponent(SaThemeColorPicker);
    component = fixture.componentInstance;
    internals = component as unknown as SaThemeColorPickerInternals;
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

    it('retorna el propio elemento si ya tiene la clase sa-btn', () => {
      const el = document.createElement('button');
      el.classList.add('sa-btn');
      expect(internals.resolveTriggerElement({ currentTarget: el } as unknown as MouseEvent)).toBe(el);
    });

    it('busca un descendiente .sa-btn si el elemento no lo es', () => {
      const wrapper = document.createElement('div');
      const inner = document.createElement('button');
      inner.classList.add('sa-btn');
      wrapper.appendChild(inner);
      expect(internals.resolveTriggerElement({ currentTarget: wrapper } as unknown as MouseEvent)).toBe(inner);
    });
  });

  describe('posición del panel', () => {
    let scroller: HTMLElement;
    let trigger: HTMLElement;
    let panel: HTMLElement;
    const setRect = (el: HTMLElement, rect: { top: number; left: number; width: number; height: number }): void => {
      vi.spyOn(el, 'getBoundingClientRect').mockReturnValue({ ...rect, bottom: rect.top + rect.height, right: rect.left + rect.width, x: rect.left, y: rect.top, toJSON: () => ({}) } as DOMRect);
    };
    const reposition = (): void => (component as unknown as { positionPanel: () => void }).positionPanel();
    const arrowX = (): number => parseFloat(panel.style.getPropertyValue('--color-picker-arrow-x'));
    const viewport = (width: number, height = 800): void => {
      vi.spyOn(document.documentElement, 'clientWidth', 'get').mockReturnValue(width);
      vi.spyOn(document.documentElement, 'clientHeight', 'get').mockReturnValue(height);
    };

    beforeEach(() => {
      scroller = document.createElement('div');
      scroller.style.overflowY = 'auto';
      trigger = document.createElement('button');
      scroller.appendChild(trigger);
      panel = document.createElement('div');
      Object.defineProperty(panel, 'offsetWidth', { value: 240, configurable: true });
      Object.defineProperty(panel, 'offsetHeight', { value: 200, configurable: true });
      document.body.append(scroller, panel);

      const target = component as unknown as { triggerElement: HTMLElement | null; getPanelElement: () => HTMLElement };
      target.triggerElement = trigger;
      vi.spyOn(target, 'getPanelElement').mockReturnValue(panel);
    });

    afterEach(() => {
      scroller.remove();
      panel.remove();
      vi.restoreAllMocks();
    });

    it.each([1200, 1600])('centra el panel bajo el disparador sin correrlo a mano en un viewport de %ipx', (width) => {
      viewport(width);
      setRect(scroller, { top: 0, left: 0, width, height: 800 });
      setRect(trigger, { top: 100, left: 580, width: 40, height: 40 });

      reposition();

      expect(parseFloat(panel.style.left)).toBe(480); // 600 (centro del disparador) - 120 (mitad del panel)
      expect(parseFloat(panel.style.top)).toBe(148); // bottom (140) + gap (8)
      expect(arrowX()).toBe(120);
      expect(panel.dataset['placement']).toBe('bottom');
    });

    it('cerca del borde derecho se corre lo justo para verse y la flecha sigue apuntando al centro del disparador', () => {
      viewport(1000);
      setRect(scroller, { top: 0, left: 0, width: 1000, height: 800 });
      setRect(trigger, { top: 20, left: 940, width: 40, height: 40 });

      reposition();

      expect(parseFloat(panel.style.left)).toBe(748); // 1000 - 240 - 12 de margen
      expect(arrowX()).toBe(212); // centro del disparador (960) - left (748)
    });

    it('abre hacia arriba cuando abajo no hay lugar', () => {
      viewport(1000, 400);
      setRect(scroller, { top: 0, left: 0, width: 1000, height: 400 });
      setRect(trigger, { top: 330, left: 480, width: 40, height: 40 });

      reposition();

      expect(panel.dataset['placement']).toBe('top');
      expect(parseFloat(panel.style.top)).toBe(122); // top (330) - alto (200) - gap (8)
    });

    it('sigue al disparador cuando se mueve con el scroll del contenedor, no se queda en la posición donde se abrió', () => {
      viewport(1000);
      setRect(scroller, { top: 0, left: 0, width: 1000, height: 800 });
      setRect(trigger, { top: 300, left: 480, width: 40, height: 40 });
      reposition();
      expect(parseFloat(panel.style.top)).toBe(348);

      setRect(trigger, { top: 220, left: 480, width: 40, height: 40 });
      reposition();

      expect(parseFloat(panel.style.top)).toBe(268);
    });

    it('cuando el scroll saca el disparador del contenedor, cierra el panel en vez de dejarlo flotando', () => {
      viewport(1000);
      setRect(scroller, { top: 80, left: 0, width: 1000, height: 600 });
      setRect(trigger, { top: 20, left: 480, width: 40, height: 40 });
      Object.assign(panel, { hidePopover: vi.fn() });

      reposition();

      expect((panel as unknown as { hidePopover: () => void }).hidePopover).toHaveBeenCalled();
      expect(panel.dataset['positioned']).toBeUndefined();
    });

    it('un disparador sin tamaño (oculto o desmontado) no cierra el panel al abrirse', () => {
      viewport(1000);
      setRect(trigger, { top: 0, left: 0, width: 0, height: 0 });
      Object.assign(panel, { hidePopover: vi.fn() });

      reposition();

      expect((panel as unknown as { hidePopover: () => void }).hidePopover).not.toHaveBeenCalled();
      expect(panel.dataset['positioned']).toBe('true');
    });
  });
});
