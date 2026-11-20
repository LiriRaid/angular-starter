import type { CapabilityOption } from '../config/capabilities.js';
import type { Choice } from './prompter.js';

/**
 * Turns registry options into prompt choices that explain themselves, like the prompts of `ng new`:
 * the label (with a badge such as "Recommended"), then the documentation of what gets installed in
 * a bracket, both in aligned columns; the description is the line shown while the choice is
 * highlighted.
 */
export function formatChoices(
  options: readonly CapabilityOption[],
  badge?: (option: CapabilityOption) => string | undefined,
): Choice<string>[] {
  const labels = options.map((option) => {
    const text = badge?.(option) ?? (option.recommended ? 'Recommended' : undefined);
    return text ? `${option.label} (${text})` : option.label;
  });
  const labelWidth = Math.max(0, ...labels.map((label) => label.length));
  const docsWidth = Math.max(0, ...options.map((option) => option.docs?.length ?? 0));

  return options.map((option, index) => {
    const label = labels[index] ?? option.label;
    const name = option.docs
      ? `${label.padEnd(labelWidth)}  [ ${option.docs.padEnd(docsWidth)} ]`
      : label;
    return { value: option.id, name, description: option.description };
  });
}
