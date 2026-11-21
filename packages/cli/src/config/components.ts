/**
 * The native components a project can ask for by id (ADR-0011). They are data of the configuration:
 * the manifest of the engine reads them, never the other way round.
 */

/** The essential collection (16). */
export const ESSENTIAL_COMPONENT_IDS: readonly string[] = [
  'icon',
  'button',
  'input',
  'textarea',
  'checkbox',
  'toggle',
  'select',
  'avatar',
  'divider',
  'skeleton',
  'tooltip',
  'modal',
  'drawer',
  'toast',
  'tabs',
  'popover',
];

/** What "all the components" adds to the essential collection (10 more). */
export const EXTRA_COMPONENT_IDS: readonly string[] = [
  'table',
  'search',
  'datepicker',
  'section-nav',
  'selectable-item',
  'reorder-list',
  'preview',
  'media-preview',
  'theme-color-picker',
  'weekly-schedule',
];

/** Every component (26), in the order of the list the wizard shows. */
export const ALL_COMPONENT_IDS: readonly string[] = [
  ...ESSENTIAL_COMPONENT_IDS,
  ...EXTRA_COMPONENT_IDS,
];

export interface ComponentsChoice {
  components: 'none' | 'recommended' | 'all' | 'custom';
  /** Only with `custom`. */
  componentList?: string[];
}

const sameSet = (a: readonly string[], b: readonly string[]): boolean =>
  a.length === b.length && a.every((id) => b.includes(id));

/**
 * How the ids ticked in a list are recorded: nothing is none, exactly the 16 essential ones (in any
 * order) the essential collection, all 26 all of them, and anything else a custom selection.
 */
export function normalizeComponents(ids: readonly string[]): ComponentsChoice {
  const unique = [...new Set(ids)];
  if (unique.length === 0) return { components: 'none' };
  if (sameSet(unique, ESSENTIAL_COMPONENT_IDS)) return { components: 'recommended' };
  if (sameSet(unique, ALL_COMPONENT_IDS)) return { components: 'all' };
  return { components: 'custom', componentList: unique };
}

/** The ids a recorded choice stands for. */
export function componentIdsOf(choice: {
  components: string;
  componentList?: readonly string[] | undefined;
}): readonly string[] {
  switch (choice.components) {
    case 'recommended':
      return ESSENTIAL_COMPONENT_IDS;
    case 'all':
      return ALL_COMPONENT_IDS;
    case 'custom':
      return choice.componentList ?? [];
    default:
      return [];
  }
}

/** What the components profile takes: a collection, or the ids of a custom selection. */
export function componentSetOf(choice: {
  components: string;
  componentList?: readonly string[] | undefined;
}): 'recommended' | 'all' | readonly string[] {
  if (choice.components === 'all') return 'all';
  if (choice.components === 'custom') return choice.componentList ?? [];
  return 'recommended';
}
