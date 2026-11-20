/** One file of a component and what the `@shared/components` barrel exports from it. */
export interface ComponentExport {
  /** Path below `shared/components`, without extension (`as-button/as-button`). */
  from: string;
  /** Names to export; `type X` exports a type. */
  names: readonly string[];
}

export interface ComponentDefinition {
  /** The id without the `as-` prefix; its blueprint is `blueprints/components/as-<id>`. */
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
    /** The file that exports `exports`, when it is not `as-<id>.ts`. */
    main?: string;
  } = {},
): ComponentDefinition => ({
  id,
  uses,
  exports: [
    { from: `as-${id}/${options.main ?? `as-${id}`}`, names: exports },
    ...(options.extra ?? []),
  ],
  styles: options.styles ?? [],
});

/** The generic components of the reference application, renamed from `omniinbox-*` to `as-*`. */
export const COMPONENTS: readonly ComponentDefinition[] = [
  component('icon', [], ['AsIcon']),
  component('button', ['icon'], ['AsButton', 'type ButtonSeverity'], {
    extra: [{ from: 'as-button/as-ripple', names: ['AsRipple'] }],
    styles: ['button-styles'],
  }),
  component('input', ['button', 'icon', 'select'], ['AsInput'], { styles: ['input-styles'] }),
  component('textarea', ['icon', 'input'], ['AsTextarea']),
  component('checkbox', ['icon'], ['AsCheckbox']),
  component('toggle', [], ['AsToggle']),
  component('select', ['avatar', 'icon', 'input'], ['AsSelect'], { styles: ['select-styles'] }),
  component('avatar', ['icon'], ['AsAvatar'], { styles: ['presence-indicator-styles'] }),
  component(
    'divider',
    [],
    ['AsDivider', 'type AsDividerLayout', 'type AsDividerType', 'type AsDividerAlign'],
  ),
  component('skeleton', [], ['AsSkeleton']),
  component('tooltip', [], ['AsTooltip', 'type AsTooltipPosition'], {
    main: 'as-tooltip.directive',
    styles: ['tooltip-styles'],
  }),
  component('modal', ['button', 'icon'], ['AsModal']),
  component('drawer', ['icon'], ['AsDrawer', 'type AsDrawerPosition']),
  component('toast', ['button'], ['AsToast'], { styles: ['toast-styles'] }),
  component(
    'tabs',
    ['avatar', 'button', 'icon', 'tooltip'],
    ['AsTabs', 'type AsTab', 'type AsTabAvatar'],
  ),
  component(
    'popover',
    ['button', 'tooltip'],
    ['AsPopover', 'type AsPopoverActionItem', 'type SubPanelAnchor'],
    { styles: ['popover-styles'] },
  ),
  // What the "all" collection adds to the recommended one.
  component(
    'table',
    ['checkbox', 'icon', 'select', 'skeleton'],
    ['AsTable', 'type AsTableColumn', 'type AsTableAlign', 'type AsTablePageEvent'],
    { styles: ['table-styles'] },
  ),
  component('search', ['button', 'input'], ['AsSearch']),
  component('datepicker', ['button', 'icon', 'input', 'popover', 'select'], ['AsDatepicker']),
  component('section-nav', ['icon'], ['AsSectionNav', 'type AsSectionNavItem']),
  component('selectable-item', ['icon'], ['AsSelectableItem']),
  component('reorder-list', [], ['AsReorderList']),
  component('preview', ['button', 'icon', 'modal'], ['AsPreview']),
  component('media-preview', ['button', 'modal'], ['AsMediaPreview', 'type MediaPreviewKind']),
  component('theme-color-picker', ['popover', 'tooltip'], ['AsThemeColorPicker']),
  component(
    'weekly-schedule',
    ['button', 'toggle'],
    [
      'AsWeeklySchedule',
      'computeWeeklyHours',
      'parseSchedule',
      'type AsScheduleDay',
      'type AsWeeklySchedulePreset',
    ],
  ),
];

/** The `recommended` collection, in the order the documentation lists it. */
export const RECOMMENDED_COMPONENTS: readonly string[] = [
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

/** What `all` adds to the recommended collection. */
export const EXTRA_COMPONENTS: readonly string[] = [
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

export type ComponentSet = 'recommended' | 'all';

/** The components of a collection plus what they import, each once, imported ones first. */
export function componentsOf(set: ComponentSet): ComponentDefinition[] {
  const ids =
    set === 'all' ? [...RECOMMENDED_COMPONENTS, ...EXTRA_COMPONENTS] : RECOMMENDED_COMPONENTS;
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
