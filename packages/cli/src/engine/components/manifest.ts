import { ESSENTIAL_COMPONENT_IDS, EXTRA_COMPONENT_IDS } from '../../config/components.js';

/** One file of a component and what the `@shared/components` barrel exports from it. */
export interface ComponentExport {
  /** Path below `shared/components`, without extension (`sa-button/sa-button`). */
  from: string;
  /** Names to export; `type X` exports a type. */
  names: readonly string[];
}

export interface ComponentDefinition {
  /** The id without the `sa-` prefix; its blueprint is `blueprints/components/sa-<id>`. */
  id: string;
  /** Components it imports, by id. They are always generated with it. */
  uses: readonly string[];
  exports: readonly ComponentExport[];
  /**
   * Global stylesheets of the component below `src/styles/components`, without extension. Each one
   * is imported from `styles.css` only when the component is generated, so a project does not
   * bundle the styles of components it does not have.
   */
  styles: readonly string[];
}

const component = (
  id: string,
  uses: readonly string[],
  exports: readonly string[],
  options: {
    extra?: readonly ComponentExport[];
    styles?: readonly string[];
    /** The file that exports `exports`, when it is not `sa-<id>.ts`. */
    main?: string;
  } = {},
): ComponentDefinition => ({
  id,
  uses,
  exports: [
    { from: `sa-${id}/${options.main ?? `sa-${id}`}`, names: exports },
    ...(options.extra ?? []),
  ],
  styles: options.styles ?? [],
});

/** The generic components of the reference application, renamed from `omniinbox-*` to `sa-*`. */
export const COMPONENTS: readonly ComponentDefinition[] = [
  component('icon', [], ['SaIcon']),
  component('button', ['icon'], ['SaButton', 'type ButtonSeverity'], {
    extra: [{ from: 'sa-button/sa-ripple', names: ['SaRipple'] }],
    styles: ['button-styles'],
  }),
  component('input', ['button', 'icon', 'select'], ['SaInput'], { styles: ['input-styles'] }),
  component('textarea', ['icon', 'input'], ['SaTextarea']),
  component('checkbox', ['icon'], ['SaCheckbox']),
  component('toggle', [], ['SaToggle']),
  component('select', ['avatar', 'icon', 'input'], ['SaSelect'], { styles: ['select-styles'] }),
  component('avatar', ['icon'], ['SaAvatar'], { styles: ['presence-indicator-styles'] }),
  component(
    'divider',
    [],
    ['SaDivider', 'type SaDividerLayout', 'type SaDividerType', 'type SaDividerAlign'],
  ),
  component('skeleton', [], ['SaSkeleton']),
  component('tooltip', [], ['SaTooltip', 'type SaTooltipPosition'], {
    main: 'sa-tooltip.directive',
    styles: ['tooltip-styles'],
  }),
  component('modal', ['button', 'icon'], ['SaModal']),
  component('drawer', ['icon'], ['SaDrawer', 'type SaDrawerPosition']),
  component('toast', ['button'], ['SaToast'], { styles: ['toast-styles'] }),
  component(
    'tabs',
    ['avatar', 'button', 'icon', 'tooltip'],
    ['SaTabs', 'type SaTab', 'type SaTabAvatar'],
  ),
  component(
    'popover',
    ['button', 'tooltip'],
    ['SaPopover', 'type SaPopoverActionItem', 'type SubPanelAnchor'],
    { styles: ['popover-styles'] },
  ),
  // What the "all" collection adds to the recommended one.
  component(
    'table',
    ['checkbox', 'icon', 'select', 'skeleton'],
    ['SaTable', 'type SaTableColumn', 'type SaTableAlign', 'type SaTablePageEvent'],
    { styles: ['table-styles'] },
  ),
  component('search', ['button', 'input'], ['SaSearch']),
  component('datepicker', ['button', 'icon', 'input', 'popover', 'select'], ['SaDatepicker']),
  component('section-nav', ['icon'], ['SaSectionNav', 'type SaSectionNavItem']),
  component('selectable-item', ['icon'], ['SaSelectableItem']),
  component('reorder-list', [], ['SaReorderList']),
  component('preview', ['button', 'icon', 'modal'], ['SaPreview']),
  component('media-preview', ['button', 'modal'], ['SaMediaPreview', 'type MediaPreviewKind']),
  component('theme-color-picker', ['popover', 'tooltip'], ['SaThemeColorPicker']),
  component(
    'weekly-schedule',
    ['button', 'toggle'],
    [
      'SaWeeklySchedule',
      'computeWeeklyHours',
      'parseSchedule',
      'type SaScheduleDay',
      'type SaWeeklySchedulePreset',
    ],
  ),
];

/** The `recommended` collection, in the order the documentation lists it. */
export const RECOMMENDED_COMPONENTS: readonly string[] = ESSENTIAL_COMPONENT_IDS;

/** What "all the components" adds to the essential collection. */
export const EXTRA_COMPONENTS: readonly string[] = EXTRA_COMPONENT_IDS;

export type ComponentSet = 'recommended' | 'all';

/** The components of a collection plus what they import, each once, imported ones first. */
export function componentsOf(set: ComponentSet): ComponentDefinition[] {
  return componentsOfIds(
    set === 'all' ? [...RECOMMENDED_COMPONENTS, ...EXTRA_COMPONENTS] : RECOMMENDED_COMPONENTS,
  );
}

/** The components with these ids plus what they import, each once, imported ones first. */
export function componentsOfIds(ids: readonly string[]): ComponentDefinition[] {
  const byId = new Map(COMPONENTS.map((definition) => [definition.id, definition]));
  const ordered: ComponentDefinition[] = [];
  // Components can import each other in both directions (input and select), so a component is
  // marked before its imports are visited.
  const visited = new Set<string>();
  const visit = (id: string): void => {
    if (visited.has(id)) return;
    visited.add(id);
    const definition = byId.get(id);
    if (!definition) throw new Error(`The component "${id}" is not in the manifest.`);
    definition.uses.forEach(visit);
    ordered.push(definition);
  };
  ids.forEach(visit);
  return ordered;
}

/** The global stylesheets (without extension) of these components, each once. */
export function stylesOf(definitions: readonly ComponentDefinition[]): string[] {
  return [...new Set(definitions.flatMap((definition) => definition.styles))];
}

/** The `export { ... } from '...';` lines of the barrel for these components. */
export function barrelLines(definitions: readonly ComponentDefinition[]): string[] {
  return definitions.flatMap((definition) =>
    definition.exports.map(({ from, names }) => `export { ${names.join(', ')} } from './${from}';`),
  );
}
