import { describe, expect, it } from 'vitest';
import { clamp, getPopoverPanelLayout, getPopoverSubPanelAnchor, resolvePopoverPlacement } from './sa-popover.config';

const CONFIG = {
  viewportMargin: 12,
  panelGap: 8,
  arrowMinOffset: 14,
  arrowOffsetX: 0,
  offsetX: 0,
  offsetY: 0,
  actionsOffsetX: 0,
};

function rect(partial: Partial<DOMRect>): DOMRect {
  return {
    top: 0,
    bottom: 0,
    left: 0,
    right: 0,
    width: 0,
    height: 0,
    x: partial.left ?? 0,
    y: partial.top ?? 0,
    toJSON: () => ({}),
    ...partial,
  } as DOMRect;
}

describe('clamp', () => {
  it('devuelve el valor si esta dentro del rango', () => {
    expect(clamp(50, 0, 100)).toBe(50);
  });

  it('devuelve el minimo si el valor es menor', () => {
    expect(clamp(-10, 0, 100)).toBe(0);
  });

  it('devuelve el maximo si el valor es mayor', () => {
    expect(clamp(150, 0, 100)).toBe(100);
  });
});

describe('getPopoverPanelLayout', () => {
  // Trigger centrado en un viewport 1000x800, panel 200x100, sin necesidad de clamping.
  const triggerRect = rect({ top: 300, bottom: 340, left: 400, right: 600, width: 200, height: 40 });
  const baseParams = { triggerRect, panelWidth: 200, panelHeight: 100, viewportWidth: 1000, viewportHeight: 800 };

  it('placement bottom: centra el panel debajo del trigger con la flecha apuntando arriba', () => {
    const layout = getPopoverPanelLayout({ ...baseParams, placement: 'bottom' }, CONFIG);

    expect(layout).toEqual({ top: 348, left: 400, bottom: null, arrowPosition: 'top', arrowX: 100, arrowY: null });
  });

  it('placement top: centra el panel arriba del trigger con la flecha apuntando abajo', () => {
    const layout = getPopoverPanelLayout({ ...baseParams, placement: 'top' }, CONFIG);

    expect(layout).toEqual({ top: 192, left: 400, bottom: 508, arrowPosition: 'bottom', arrowX: 100, arrowY: null });
  });

  it('placement top: el panel se ancla por su borde de abajo, pegado al botón aunque luego cambie de alto', () => {
    const tall = getPopoverPanelLayout({ ...baseParams, panelHeight: 100, placement: 'top' }, CONFIG);
    const taller = getPopoverPanelLayout({ ...baseParams, panelHeight: 160, placement: 'top' }, CONFIG);

    // Lo que queda entre el borde de abajo del panel y el de la ventana es el mismo: crece hacia arriba.
    expect(tall.bottom).toBe(508);
    expect(taller.bottom).toBe(508);
  });

  it('placement left: ubica el panel a la izquierda con la flecha apuntando a la derecha', () => {
    const layout = getPopoverPanelLayout({ ...baseParams, placement: 'left' }, CONFIG);

    expect(layout).toEqual({ top: 270, left: 192, bottom: null, arrowPosition: 'right', arrowX: null, arrowY: 50 });
  });

  it('placement right: ubica el panel a la derecha con la flecha apuntando a la izquierda', () => {
    const layout = getPopoverPanelLayout({ ...baseParams, placement: 'right' }, CONFIG);

    expect(layout).toEqual({ top: 270, left: 608, bottom: null, arrowPosition: 'left', arrowX: null, arrowY: 50 });
  });

  it('clampea top y left contra los bordes del viewport cuando el panel no entra', () => {
    const cornerTrigger = rect({ top: 5, bottom: 25, left: 5, right: 25, width: 20, height: 20 });
    const layout = getPopoverPanelLayout(
      { triggerRect: cornerTrigger, panelWidth: 300, panelHeight: 200, viewportWidth: 1000, viewportHeight: 800, placement: 'top' },
      CONFIG,
    );

    expect(layout.top).toBe(CONFIG.viewportMargin);
    expect(layout.left).toBe(CONFIG.viewportMargin);
  });
});

describe('resolvePopoverPlacement', () => {
  const viewportWidth = 1000;
  const viewportHeight = 800;

  it('mantiene la posicion preferida cuando hay espacio', () => {
    const triggerRect = rect({ top: 300, bottom: 340, left: 400, right: 600 });

    const result = resolvePopoverPlacement('top', triggerRect, 200, 100, viewportWidth, viewportHeight, CONFIG);

    expect(result).toBe('top');
  });

  it('voltea a la posicion opuesta cuando la preferida no tiene espacio pero la opuesta si', () => {
    const triggerRect = rect({ top: 5, bottom: 45, left: 100, right: 300 });

    const result = resolvePopoverPlacement('top', triggerRect, 200, 300, viewportWidth, viewportHeight, CONFIG);

    expect(result).toBe('bottom');
  });

  it('devuelve la posicion preferida si ninguna de las dos tiene espacio', () => {
    const triggerRect = rect({ top: 5, bottom: 45, left: 100, right: 300 });

    const result = resolvePopoverPlacement('top', triggerRect, 200, 1000, viewportWidth, viewportHeight, CONFIG);

    expect(result).toBe('top');
  });

  describe('con los límites visibles del contenedor del ancla', () => {
    // Un hilo con scroll bajo un header de 80 px: el ancla está a 300 px de la ventana, pero a 220 px del borde útil.
    const bounds = { top: 80, left: 0, right: viewportWidth, bottom: viewportHeight };
    const triggerRect = rect({ top: 300, bottom: 340, left: 400, right: 600 });

    it('arriba no cabe porque el header ocupa el borde del contenedor: voltea a abajo aunque la ventana tenga espacio', () => {
      expect(resolvePopoverPlacement('top', triggerRect, 200, 260, viewportWidth, viewportHeight, CONFIG)).toBe('top');
      expect(resolvePopoverPlacement('top', triggerRect, 200, 260, viewportWidth, viewportHeight, CONFIG, bounds)).toBe('bottom');
    });

    it('solo se mueve entre el lado pedido y su opuesto: nunca salta a un costado', () => {
      const tall = resolvePopoverPlacement('top', rect({ top: 20, bottom: 60, left: 400, right: 600 }), 200, 5000, viewportWidth, viewportHeight, CONFIG, bounds);

      expect(['top', 'bottom']).toContain(tall);
    });

    it('si ninguno de los dos cabe elige el que tiene más espacio libre', () => {
      expect(resolvePopoverPlacement('top', rect({ top: 150, bottom: 190, left: 400, right: 600 }), 200, 5000, viewportWidth, viewportHeight, CONFIG, bounds)).toBe('bottom');
    });
  });
});

describe('getPopoverSubPanelAnchor', () => {
  const viewportWidth = 1000;
  const viewportHeight = 800;
  const gap = 8;

  it('con position="left" siempre ancla a la izquierda del anchor', () => {
    const panelRect = rect({ bottom: 400 });
    const anchorRect = rect({ left: 850, right: 870 });

    const anchor = getPopoverSubPanelAnchor('left', panelRect, anchorRect, viewportWidth, viewportHeight, gap);

    expect(anchor).toEqual({ bottom: 400, right: viewportWidth - anchorRect.left + gap });
  });

  it('con position="right" siempre ancla a la derecha del anchor', () => {
    const panelRect = rect({ bottom: 300 });
    const anchorRect = rect({ left: 30, right: 50 });

    const anchor = getPopoverSubPanelAnchor('right', panelRect, anchorRect, viewportWidth, viewportHeight, gap);

    expect(anchor).toEqual({ bottom: 500, left: anchorRect.right + gap });
  });

  it('con position="top"/"bottom" ancla a la izquierda si el panel esta pegado al borde derecho', () => {
    const panelRect = rect({ left: 900, right: 980, bottom: 400 });
    const anchorRect = rect({ left: 850, right: 870 });

    const anchor = getPopoverSubPanelAnchor('bottom', panelRect, anchorRect, viewportWidth, viewportHeight, gap);

    expect(anchor).toEqual({ bottom: 400, right: viewportWidth - anchorRect.left + gap });
  });

  it('con position="top"/"bottom" ancla a la derecha si el panel esta pegado al borde izquierdo', () => {
    const panelRect = rect({ left: 20, right: 100, bottom: 300 });
    const anchorRect = rect({ left: 30, right: 50 });

    const anchor = getPopoverSubPanelAnchor('top', panelRect, anchorRect, viewportWidth, viewportHeight, gap);

    expect(anchor).toEqual({ bottom: 500, left: anchorRect.right + gap });
  });
});
