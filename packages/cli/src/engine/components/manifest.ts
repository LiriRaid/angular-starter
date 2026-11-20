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
  /** Components it needs, by id. They are always generated with it. */
  uses: readonly string[];
  exports: readonly ComponentExport[];
}

const component = (
  id: string,
  uses: readonly string[],
  exports: readonly string[],
  extra: readonly ComponentExport[] = [],
): ComponentDefinition => ({
  id,
  uses,
  exports: [{ from: `as-${id}/as-${id}`, names: exports }, ...extra],
});

export const COMPONENTS: readonly ComponentDefinition[] = [
  component('icon', [], ['AsIcon']),
  component(
    'button',
    ['icon'],
    ['AsButton', 'type AsButtonSeverity', 'type AsButtonSize', 'type AsButtonVariant'],
  ),
  component('form-control', [], ['AsFormControl']),
  component('input', ['form-control', 'icon'], ['AsInput', 'type AsInputType']),
  component('textarea', ['form-control'], ['AsTextarea']),
  component('checkbox', ['form-control'], ['AsCheckbox']),
  component('toggle', ['form-control'], ['AsToggle']),
  component('select', ['form-control', 'icon'], ['AsSelect', 'type AsSelectOption']),
  component('avatar', [], ['AsAvatar', 'type AsAvatarSize', 'type AsAvatarStatus']),
  component('divider', [], ['AsDivider']),
  component('skeleton', [], ['AsSkeleton']),
  component('tooltip', [], ['AsTooltip', 'type AsTooltipPosition']),
  component('modal', ['icon'], ['AsModal']),
  component('drawer', ['icon'], ['AsDrawer']),
  component(
    'toast',
    ['icon'],
    ['AsToast'],
    [
      {
        from: 'as-toast/as-toast.service',
        names: [
          'AsToastService',
          'type AsToastItem',
          'type AsToastOptions',
          'type AsToastSeverity',
        ],
      },
    ],
  ),
  component('tabs', ['icon'], ['AsTabs', 'type AsTab']),
  component('popover', ['icon'], ['AsPopover', 'type AsPopoverItem', 'type AsPopoverPlacement']),
  // What the "all" collection adds to the recommended one.
  component(
    'table',
    ['icon'],
    ['AsTable', 'AsTableCell', 'type AsTableColumn', 'type AsTablePage', 'type AsTableSort'],
  ),
  component('search', ['icon'], ['AsSearch']),
  component('datepicker', ['form-control', 'icon'], ['AsDatepicker']),
  component('section-nav', ['icon'], ['AsSectionNav', 'type AsSectionNavItem']),
  component('selectable-item', [], ['AsSelectableItem']),
  component('reorder-list', ['icon'], ['AsReorderList']),
  component('preview', ['icon'], ['AsPreview']),
  component('media-preview', ['icon'], ['AsMediaPreview', 'type AsMediaKind']),
  component('theme-color-picker', ['popover', 'icon'], ['AsThemeColorPicker']),
  component(
    'weekly-schedule',
    ['form-control', 'toggle'],
    ['AsWeeklySchedule', 'computeWeeklyHours', 'defaultSchedule', 'type AsScheduleDay'],
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

/** The components of a collection plus what they need, each once, needed ones first. */
export function componentsOf(set: ComponentSet): ComponentDefinition[] {
  const ids =
    set === 'all' ? [...RECOMMENDED_COMPONENTS, ...EXTRA_COMPONENTS] : RECOMMENDED_COMPONENTS;
  const byId = new Map(COMPONENTS.map((definition) => [definition.id, definition]));
  const ordered: ComponentDefinition[] = [];
  const visit = (id: string): void => {
    const definition = byId.get(id);
    if (!definition) throw new Error(`The component "${id}" is not in the manifest.`);
    if (ordered.includes(definition)) return;
    definition.uses.forEach(visit);
    ordered.push(definition);
  };
  ids.forEach(visit);
  return ordered;
}

/** The `export { ... } from '...';` lines of the barrel for these components. */
export function barrelLines(definitions: readonly ComponentDefinition[]): string[] {
  return definitions.flatMap((definition) =>
    definition.exports.map(({ from, names }) => `export { ${names.join(', ')} } from './${from}';`),
  );
}
