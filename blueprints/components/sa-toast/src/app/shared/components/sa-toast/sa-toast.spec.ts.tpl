import { TestBed } from '@angular/core/testing';

import { SaToast } from './sa-toast';
import { AlertService } from '@shared/services';
import { EAsToastType, type IAsToastAction, type ToastItem } from './sa-toast.types';

type SaToastInternals = {
  formattedMessage: (raw: string) => string;
  toastIcon: (msg: ToastItem) => string;
  actionSeverity: (action: IAsToastAction) => string | undefined;
  showProgressBar: (msg: ToastItem) => boolean;
  toastDuration: (msg: ToastItem) => string;
  itemStyle: (i: number, id: string) => Record<string, string>;
  close: (id: string) => void;
  executeAction: (action: IAsToastAction, id: string) => void;
  layouts: () => { y: number; scaleX: number; opacity: number; z: number }[];
  hovered: { set: (v: boolean) => void };
};

function makeItem(overrides: Partial<ToastItem> = {}): ToastItem {
  return {
    id: 'a1',
    type: EAsToastType.Info,
    title: 'Título',
    message: 'Mensaje',
    duration: 4000,
    persistent: false,
    position: 'top-center',
    ...overrides,
  };
}

describe('SaToast', () => {
  let alertService: AlertService;
  let internals: SaToastInternals;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [SaToast],
    }).compileComponents();

    const fixture = TestBed.createComponent(SaToast);
    alertService = TestBed.inject(AlertService);
    internals = fixture.componentInstance as unknown as SaToastInternals;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(internals).toBeTruthy();
  });

  it('should format message with bold tags', () => {
    expect(internals.formattedMessage('Hola {{mundo}}')).toBe('Hola <strong>mundo</strong>');
  });

  it('should format message without placeholders unchanged', () => {
    expect(internals.formattedMessage('Sin formato')).toBe('Sin formato');
  });

  it('escapa el HTML del mensaje y del dato entre llaves: solo {{…}} sale en negrita', () => {
    expect(internals.formattedMessage('<img src=x onerror=alert(1)> {{<b>Ana</b>}}')).toBe('&lt;img src=x onerror=alert(1)&gt; <strong>&lt;b&gt;Ana&lt;/b&gt;</strong>');
  });

  it('muestra un ícono para todos los tipos que expone el AlertService', () => {
    for (const type of Object.values(EAsToastType)) {
      expect(internals.toastIcon(makeItem({ type }))).toBeTruthy();
    }
  });

  describe('toastIcon', () => {
    it('retorna CheckCircle para success', () => {
      expect(internals.toastIcon(makeItem({ type: EAsToastType.Success }))).toBe('CheckCircle');
    });

    it('retorna CloseCircle para error', () => {
      expect(internals.toastIcon(makeItem({ type: EAsToastType.Error }))).toBe('CloseCircle');
    });

    it('retorna Info para warning', () => {
      expect(internals.toastIcon(makeItem({ type: EAsToastType.Warning }))).toBe('Info');
    });

    it('retorna Settings para loading', () => {
      expect(internals.toastIcon(makeItem({ type: EAsToastType.Loading }))).toBe('Settings');
    });

    it('retorna el ícono básico según el context para otros tipos', () => {
      expect(internals.toastIcon(makeItem({ type: EAsToastType.Secondary, context: 'edit' }))).toBe('Edit');
      expect(internals.toastIcon(makeItem({ type: EAsToastType.Secondary, context: 'create' }))).toBe('Add');
      expect(internals.toastIcon(makeItem({ type: EAsToastType.Secondary }))).toBe('Info');
    });
  });

  describe('actionSeverity', () => {
    it('retorna danger cuando el variant es danger', () => {
      expect(internals.actionSeverity({ label: 'Continuar', variant: 'danger', execute: () => {} })).toBe('danger');
    });

    it('retorna danger cuando el label sugiere una acción destructiva', () => {
      expect(internals.actionSeverity({ label: 'Eliminar cuenta', execute: () => {} })).toBe('danger');
    });

    it('retorna undefined para acciones normales', () => {
      expect(internals.actionSeverity({ label: 'Ver detalle', execute: () => {} })).toBeUndefined();
    });
  });

  describe('showProgressBar', () => {
    it('no muestra barra de progreso para toasts de loading', () => {
      expect(internals.showProgressBar(makeItem({ type: EAsToastType.Loading }))).toBe(false);
    });

    it('no muestra barra de progreso para toasts persistentes', () => {
      expect(internals.showProgressBar(makeItem({ persistent: true }))).toBe(false);
    });

    it('muestra barra de progreso en el caso normal', () => {
      expect(internals.showProgressBar(makeItem())).toBe(true);
    });
  });

  it('toastDuration formatea la duración en milisegundos', () => {
    expect(internals.toastDuration(makeItem({ duration: 3500 }))).toBe('3500ms');
  });

  describe('close / executeAction', () => {
    it('close remueve el mensaje del AlertService', () => {
      const spy = vi.spyOn(alertService, 'removeMessage');
      internals.close('a1');
      expect(spy).toHaveBeenCalledWith('a1');
    });

    it('executeAction remueve el mensaje y ejecuta la acción', () => {
      const spy = vi.spyOn(alertService, 'removeMessage');
      const execute = vi.fn();
      internals.executeAction({ label: 'Deshacer', execute }, 'a1');
      expect(spy).toHaveBeenCalledWith('a1');
      expect(execute).toHaveBeenCalled();
    });
  });

  describe('itemStyle', () => {
    it('aplica la transición de salida cuando el id está en leavingIds', () => {
      alertService.messages.set([makeItem({ id: 'a1' }), makeItem({ id: 'a2' })]);
      alertService.leavingIds.set(new Set(['a1']));

      const style = internals.itemStyle(0, 'a1');

      expect(style['opacity']).toBe('0');
      expect(style['pointer-events']).toBe('none');
    });

    it('retorna el layout apilado normal cuando el toast no está saliendo', () => {
      alertService.messages.set([makeItem({ id: 'a1' }), makeItem({ id: 'a2' })]);

      const style = internals.itemStyle(1, 'a2');

      expect(style['transform']).toContain('scaleX');
      expect(style['opacity']).not.toBe('0');
    });
  });

  describe('layouts', () => {
    it('sin hover, apila con offset fijo (GAP) y opacidad decreciente', () => {
      alertService.messages.set([makeItem({ id: 'a1' }), makeItem({ id: 'a2' }), makeItem({ id: 'a3' })]);

      const layouts = internals.layouts();

      expect(layouts[0]).toEqual({ y: 0, scaleX: 1, opacity: 1, z: 10 });
      expect(layouts[1].y).toBe(8);
      expect(layouts[1].opacity).toBeCloseTo(0.85);
      expect(layouts[2].scaleX).toBeCloseTo(0.92);
    });

    it('en top position, el offset es positivo hacia abajo; en bottom, negativo hacia arriba', () => {
      alertService.toastPosition.set('bottom-center');
      alertService.messages.set([makeItem({ id: 'a1' }), makeItem({ id: 'a2' })]);

      const layouts = internals.layouts();

      expect(layouts[1].y).toBe(-8);
    });
  });
});
