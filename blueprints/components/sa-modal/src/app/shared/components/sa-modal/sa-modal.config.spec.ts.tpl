import { describe, expect, it } from 'vitest';
import { computeDragPosition, computeResizeSize } from './sa-modal.config';

describe('computeDragPosition', () => {
  const rect = { left: 100, top: 80, width: 400, height: 300 };
  const viewportWidth = 1200;
  const viewportHeight = 900;

  it('mueve ambos ejes cuando el destino queda dentro del viewport', () => {
    const result = computeDragPosition(rect, 20, 10, viewportWidth, viewportHeight);
    expect(result).toEqual({ left: 120, top: 90 });
  });

  it('no actualiza left si el destino queda antes del borde izquierdo (left < 0)', () => {
    const result = computeDragPosition(rect, -150, 0, viewportWidth, viewportHeight);
    expect(result.left).toBeNull();
  });

  it('no actualiza left si el dialogo se saldria por el borde derecho', () => {
    const result = computeDragPosition(rect, 800, 0, viewportWidth, viewportHeight);
    expect(result.left).toBeNull();
  });

  it('no actualiza top si el destino queda antes del borde superior (top < 0)', () => {
    const result = computeDragPosition(rect, 0, -150, viewportWidth, viewportHeight);
    expect(result.top).toBeNull();
  });

  it('no actualiza top si el dialogo se saldria por el borde inferior', () => {
    const result = computeDragPosition(rect, 0, 700, viewportWidth, viewportHeight);
    expect(result.top).toBeNull();
  });
});

describe('computeResizeSize', () => {
  const rect = { left: 100, top: 80, width: 400, height: 300 };
  const viewportWidth = 1200;
  const viewportHeight = 900;

  it('crece ambos ejes cuando el nuevo tamaño entra en el viewport', () => {
    const result = computeResizeSize(rect, 50, 30, viewportWidth, viewportHeight);
    expect(result).toEqual({ width: 450, height: 330 });
  });

  it('no actualiza width si el nuevo ancho se saldria del viewport', () => {
    const result = computeResizeSize(rect, 800, 0, viewportWidth, viewportHeight);
    expect(result.width).toBeNull();
  });

  it('no actualiza height si el nuevo alto se saldria del viewport', () => {
    const result = computeResizeSize(rect, 0, 700, viewportWidth, viewportHeight);
    expect(result.height).toBeNull();
  });

  it('permite achicar (delta negativo) sin restricciones', () => {
    const result = computeResizeSize(rect, -100, -50, viewportWidth, viewportHeight);
    expect(result).toEqual({ width: 300, height: 250 });
  });
});
