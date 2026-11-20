/** Escapa un texto para ponerlo dentro de HTML (contenido o atributo entre comillas): `&`, `<`, `>`, `"` y `'`. */
export function escapeHtml(value: string): string {
  return value.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;').replace(/'/g, '&#39;');
}
