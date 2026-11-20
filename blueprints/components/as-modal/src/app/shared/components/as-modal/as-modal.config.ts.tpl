type Rect = { left: number; top: number; width: number; height: number };

/** Nueva posición del <dialog> mientras se arrastra desde el header — null en un eje significa
 *  "no actualizar esa coordenada" (el usuario se salió del viewport en esa dirección, el drag
 *  handler original se queda quieto en ese eje hasta que vuelva a entrar). */
export function computeDragPosition(rect: Rect, deltaX: number, deltaY: number, viewportWidth: number, viewportHeight: number): { left: number | null; top: number | null } {
  const leftPos = rect.left + deltaX;
  const topPos = rect.top + deltaY;

  return {
    left: leftPos >= 0 && leftPos + rect.width < viewportWidth ? leftPos : null,
    top: topPos >= 0 && topPos + rect.height < viewportHeight ? topPos : null,
  };
}

/** Igual que computeDragPosition pero para el handle de resize (esquina inferior derecha):
 *  null en un eje significa "no actualizar ese tamaño" (crecería fuera del viewport). */
export function computeResizeSize(rect: Rect, deltaX: number, deltaY: number, viewportWidth: number, viewportHeight: number): { width: number | null; height: number | null } {
  const newWidth = rect.width + deltaX;
  const newHeight = rect.height + deltaY;

  return {
    width: rect.left + newWidth < viewportWidth ? newWidth : null,
    height: rect.top + newHeight < viewportHeight ? newHeight : null,
  };
}
