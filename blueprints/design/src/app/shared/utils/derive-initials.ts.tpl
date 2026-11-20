/**
 * Up to two capital letters that stand for a name: the first letters of its first two words, or the
 * first two letters of a single word ("Ada Lovelace" is "AL", "Plato" is "PL").
 */
export function deriveInitials(name: string): string {
  const words = name.trim().split(/\s+/).filter(Boolean);
  const [first, second] = words;
  if (first === undefined) return '';
  return (second === undefined ? first.slice(0, 2) : `${first.charAt(0)}${second.charAt(0)}`).toUpperCase();
}
