/** Genera un id único para uso client-side (entradas optimistas, adjuntos temporales, etc.) —
 *  usa `crypto.randomUUID()` cuando está disponible, con un fallback determinístico-random para
 *  entornos sin Web Crypto. `prefix`, si se pasa, se antepone con un guion (ej. `optimistic-...`). */
export function generateId(prefix?: string): string {
  const id = typeof crypto !== 'undefined' && 'randomUUID' in crypto ? crypto.randomUUID() : `${Date.now()}-${Math.random().toString(36).slice(2, 8)}`;
  return prefix ? `${prefix}-${id}` : id;
}
