import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';
import { isOutOfBounds, resolveSide, visibleBounds, type IPanelBounds } from './panel-placement';

const rect = (top: number, left: number, width = 144, height = 48) => ({ top, left, bottom: top + height, right: left + width });
const content: IPanelBounds = { top: 80, left: 130, right: 1900, bottom: 1100 };
const sizeOf = (width: number, height: number) => ({ width, height });

describe('resolveSide', () => {
  const all = ['top', 'bottom', 'left', 'right'] as const;

  it('conserva el lado pedido cuando cabe dentro del contenedor', () => {
    expect(resolveSide({ preferred: 'bottom', allowed: all, trigger: rect(310, 998), size: sizeOf(288, 543), bounds: content })).toBe('bottom');
  });

  it('usa el lado contrario cuando solo cabe ese', () => {
    expect(resolveSide({ preferred: 'bottom', allowed: all, trigger: rect(981, 541), size: sizeOf(288, 543), bounds: content })).toBe('top');
  });

  it('ni arriba ni abajo: se va al costado en vez de taparse la propia ancla', () => {
    expect(resolveSide({ preferred: 'bottom', allowed: all, trigger: rect(554, 389), size: sizeOf(288, 543), bounds: content })).toBe('right');
  });

  it('mide el espacio contra el contenedor y no contra la ventana: con el header encima, arriba no cabe', () => {
    // La ancla está a 300 px del borde de la ventana, pero a solo 220 px del borde del contenedor (el header ocupa los primeros 80).
    expect(resolveSide({ preferred: 'top', allowed: ['top', 'bottom'], trigger: rect(300, 400), size: sizeOf(320, 190), bounds: content })).toBe('top');
    expect(resolveSide({ preferred: 'top', allowed: ['top', 'bottom'], trigger: rect(300, 400), size: sizeOf(320, 260), bounds: content })).toBe('bottom');
    expect(resolveSide({ preferred: 'top', allowed: ['top', 'bottom'], trigger: rect(300, 400), size: sizeOf(320, 260), bounds: { ...content, top: 0 } })).toBe('top');
  });

  it('al subir el scroll la misma ancla cambia de lado en cuanto deja de caber', () => {
    const size = sizeOf(320, 420);
    expect(resolveSide({ preferred: 'top', allowed: ['top', 'bottom'], trigger: rect(600, 400), size, bounds: content })).toBe('top');
    expect(resolveSide({ preferred: 'top', allowed: ['top', 'bottom'], trigger: rect(300, 400), size, bounds: content })).toBe('bottom');
  });

  it('con solo arriba y abajo permitidos nunca elige un costado, aunque no quepa ninguno', () => {
    const side = resolveSide({ preferred: 'top', allowed: ['top', 'bottom'], trigger: rect(554, 389), size: sizeOf(288, 900), bounds: content });
    expect(['top', 'bottom']).toContain(side);
  });

  it('si ningún lado cabe elige el que tiene más espacio', () => {
    expect(resolveSide({ preferred: 'top', allowed: ['top', 'bottom'], trigger: rect(200, 400), size: sizeOf(320, 2000), bounds: content })).toBe('bottom');
  });
});

describe('isOutOfBounds', () => {
  it('la ancla fuera por completo del contenedor (tapada por el header) está fuera; parcialmente visible, no', () => {
    expect(isOutOfBounds(rect(20, 400), content)).toBe(true);
    expect(isOutOfBounds(rect(60, 400), content)).toBe(false);
    expect(isOutOfBounds(rect(1200, 400), content)).toBe(true);
  });
});

describe('visibleBounds', () => {
  afterEach(() => {
    document.body.innerHTML = '';
    vi.restoreAllMocks();
  });

  it('sin contenedores con scroll es la ventana', () => {
    vi.spyOn(document.documentElement, 'clientWidth', 'get').mockReturnValue(1600);
    vi.spyOn(document.documentElement, 'clientHeight', 'get').mockReturnValue(900);
    const anchor = document.createElement('button');
    document.body.append(anchor);

    expect(visibleBounds(anchor)).toEqual({ top: 0, left: 0, right: 1600, bottom: 900 });
  });

  describe('un ancla que se escapa del scroller', () => {
    const scrollerBox = { top: 80, left: 130, right: 1500, bottom: 1000, width: 1370, height: 920 } as DOMRect;
    let scroller: HTMLElement;
    let anchor: HTMLElement;

    beforeEach(() => {
      vi.spyOn(document.documentElement, 'clientWidth', 'get').mockReturnValue(1600);
      vi.spyOn(document.documentElement, 'clientHeight', 'get').mockReturnValue(900);
      scroller = document.createElement('div');
      scroller.style.overflowY = 'auto';
      vi.spyOn(scroller, 'getBoundingClientRect').mockReturnValue(scrollerBox);
      anchor = document.createElement('button');
      scroller.append(anchor);
      document.body.append(scroller);
    });

    it('position: fixed no se recorta por ningún ancestro: son los límites de la ventana', () => {
      anchor.style.position = 'fixed';

      expect(visibleBounds(anchor)).toEqual({ top: 0, left: 0, right: 1600, bottom: 900 });
    });

    it('position: absolute dentro de un scroller que no es su bloque contenedor no se recorta por él', () => {
      anchor.style.position = 'absolute';

      expect(visibleBounds(anchor)).toEqual({ top: 0, left: 0, right: 1600, bottom: 900 });
    });

    it('position: absolute dentro de un scroller que sí es su bloque contenedor se recorta por él', () => {
      anchor.style.position = 'absolute';
      scroller.style.position = 'relative';

      expect(visibleBounds(anchor)).toEqual({ top: 80, left: 130, right: 1500, bottom: 900 });
    });
  });

  it('con un contenedor con scroll es la intersección de la ventana con él', () => {
    vi.spyOn(document.documentElement, 'clientWidth', 'get').mockReturnValue(1600);
    vi.spyOn(document.documentElement, 'clientHeight', 'get').mockReturnValue(900);
    const scroller = document.createElement('div');
    scroller.style.overflowY = 'auto';
    vi.spyOn(scroller, 'getBoundingClientRect').mockReturnValue({ top: 80, left: 130, right: 1500, bottom: 1000, width: 1370, height: 920 } as DOMRect);
    const anchor = document.createElement('button');
    scroller.append(anchor);
    document.body.append(scroller);

    expect(visibleBounds(anchor)).toEqual({ top: 80, left: 130, right: 1500, bottom: 900 });
  });
});
