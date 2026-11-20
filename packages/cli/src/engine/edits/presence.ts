import { addNamedImports, parseSource } from './typescript.js';

/**
 * Edits that presence makes to the user menu of the application shell (ADR-0009): the presence dot of
 * its avatars, the status row, the sub-panels and the `UserStatusMenu` its class holds. They only
 * add; every anchor is named in the error that stops the stage when the developer reshaped the file.
 */

const STATUS_ROW_MARKER = 'um-status-trigger';

/** The button of the user menu that opens the design preferences page (ADR-0010). */
const PREFERENCES_BUTTON = 'label="Preferencias de Diseño"';

const eolOf = (text: string): string => (text.includes('\r\n') ? '\r\n' : '\n');

/** The sidebar card and the popover panel paint different surfaces behind the dot. */
const DOT_BACKGROUND = {
  card: 'var(--app-sidebar-bg)',
  panel: 'var(--app-overlay-bg)',
} as const;

const STATUS_ROW = `<div class="um-status-trigger flex items-center justify-between gap-2 py-1.5 px-2 rounded-lg cursor-pointer" (mouseenter)="statusMenu.onStatusTriggerEnter()" (mouseleave)="statusMenu.onStatusTriggerLeave()">
  <div class="flex items-center gap-2">
    <span class="um-status-badge shrink-0 w-3.5 h-3.5 rounded-full relative flex items-center justify-center" [attr.data-status]="statusMenu.status()" aria-hidden="true">
      @if (statusMenu.statusIcon(statusMenu.status()); as icon) {
        <as-icon [name]="icon" size="14" />
      }
    </span>
    <span class="text-caption-1-medium text-(--app-text-color)">Estado</span>
  </div>
  <div class="flex items-center gap-1">
    <span class="text-caption-2-regular text-(--app-text-subtle) truncate max-w-22">{{ statusMenu.statusLabel() }}</span>
    <as-icon name="ChevronRight" size="13" class="text-(--app-text-subtle) shrink-0" />
  </div>
</div>`;

const DIVIDER = '<hr class="h-px border-0 bg-(--app-border-color) m-0" aria-hidden="true" />';

const SUB_PANELS = `<!-- Sub-panels of the status: outside the popover, whose panel is in the top layer, so that position: fixed is relative to the viewport. -->
@if (statusMenu.statusSubPanelPos(); as pos) {
  <div class="um-sub-panel fixed z-9999 min-w-48 p-1" data-popover-sub-panel [style.top.px]="pos.top ?? null" [style.bottom.px]="pos.bottom ?? null" [style.left.px]="pos.left ?? null" [style.right.px]="pos.right ?? null" (mouseenter)="statusMenu.onStatusPanelEnter()" (mouseleave)="statusMenu.onStatusPanelLeave()" (click)="$event.stopPropagation()">
    <div class="um-sub-panel-header pt-1.5 px-2.5 pb-1 text-[0.65rem] font-bold tracking-[0.06em] uppercase text-(--app-text-subtle)">Estado</div>
    <div class="um-sub-panel-options flex flex-col gap-0.5">
      @for (option of statusMenu.statusOptions; track option.id) {
        <button type="button" class="um-sub-option flex items-center gap-2 w-full py-1.75 px-2.5 rounded-[0.4375rem] text-[0.8125rem] font-medium text-(--app-text-color) bg-transparent border-0 cursor-pointer text-left whitespace-nowrap" [class.um-sub-option--active]="statusMenu.hoveredStatus() === option.id" (mouseenter)="statusMenu.onStatusOptionHover(option.id)" (click)="statusMenu.selectStatusDirect(option.id)">
          <span class="um-status-icon shrink-0 w-3.5 h-3.5 rounded-full relative flex items-center justify-center" [attr.data-status]="option.id">
            @if (statusMenu.statusIcon(option.id); as icon) {
              <as-icon [name]="icon" size="14" />
            }
          </span>
          <span class="flex-1 text-left">{{ option.label }}</span>
          @if (option.hasDuration) {
            <as-icon name="ChevronRight" size="12" class="text-(--app-text-subtle) shrink-0" />
          }
        </button>
      }
    </div>
  </div>
}

@if (statusMenu.durationSubPanelPos(); as pos) {
  <div class="um-sub-panel um-sub-panel--duration fixed z-9999 min-w-40 p-1" data-popover-sub-panel [style.top.px]="pos.top ?? null" [style.bottom.px]="pos.bottom ?? null" [style.left.px]="pos.left ?? null" [style.right.px]="pos.right ?? null" (mouseenter)="statusMenu.onDurationPanelEnter()" (mouseleave)="statusMenu.onDurationPanelLeave()" (click)="$event.stopPropagation()">
    <div class="um-sub-panel-header pt-1.5 px-2.5 pb-1 text-[0.65rem] font-bold tracking-[0.06em] uppercase text-(--app-text-subtle)">Volver en</div>
    @for (duration of statusMenu.durationOptions; track duration.label) {
      <button type="button" class="um-sub-option flex items-center gap-2 w-full py-1.75 px-2.5 rounded-[0.4375rem] text-[0.8125rem] font-medium text-(--app-text-color) bg-transparent border-0 cursor-pointer text-left whitespace-nowrap" (click)="statusMenu.selectWithDuration(duration.minutes)">
        <span class="flex-1 text-left">{{ duration.label }}</span>
      </button>
    }
  </div>
}`;

/** The text with every line break written as `eol`, whatever it was before. */
const withEol = (text: string, eol: string): string =>
  text.replaceAll('\r\n', '\n').replaceAll('\n', eol);

/**
 * Gives both avatars the presence dot, puts the status row before the preferences button and the
 * sub-panels after the popover. A template that already has the status row is left as it is.
 */
export function addPresenceToUserMenuTemplate(html: string): string {
  if (html.includes(STATUS_ROW_MARKER)) return html;
  const eol = eolOf(html);

  const popoverEnd = html.indexOf('</as-popover>');
  if (popoverEnd < 0) {
    throw new Error(
      'Could not find the popover of the user menu (</as-popover>) to put the status sub-panels after.',
    );
  }
  const avatars = [...html.matchAll(/<as-avatar\b[^>]*>/g)].filter(
    ([tag]) => !tag.includes('mode='),
  );
  if (avatars.length === 0) {
    throw new Error('Could not find the <as-avatar> of the user menu to give the presence dot.');
  }
  const preferences = html.indexOf(PREFERENCES_BUTTON);
  const button = preferences < 0 ? -1 : html.lastIndexOf('<as-button', preferences);
  if (button < 0) {
    throw new Error(
      `Could not find the preferences button (${PREFERENCES_BUTTON}) to put the status row before.`,
    );
  }

  // Edit from the end of the file to its start so that the positions found above stay valid.
  const indentation = /[ \t]*$/.exec(html.slice(0, button))?.[0] ?? '';
  const indent = (block: string): string =>
    withEol(block, eol)
      .split(eol)
      .map((line, index) => (index === 0 || line === '' ? line : `${indentation}${line}`))
      .join(eol);
  const end = popoverEnd + '</as-popover>'.length;
  let edited = `${html.slice(0, end)}${eol}${eol}${withEol(SUB_PANELS, eol)}${html.slice(end)}`;
  edited = `${edited.slice(0, button)}${indent(STATUS_ROW)}${eol}${eol}${indentation}${DIVIDER}${eol}${eol}${indentation}${edited.slice(button)}`;

  for (const avatar of [...avatars].reverse()) {
    const start = avatar.index;
    const background = avatar[0].includes('um-card-avatar')
      ? DOT_BACKGROUND.card
      : DOT_BACKGROUND.panel;
    const attributes = ` mode="presence" [presenceStatus]="statusMenu.status()" dotBackground="${background}"`;
    const tag = avatar[0].replace(/\s*(\/?)>$/, (_closing, slash: string) =>
      slash ? `${attributes} />` : `${attributes}>`,
    );
    edited = `${edited.slice(0, start)}${tag}${edited.slice(start + avatar[0].length)}`;
  }
  return edited;
}

/**
 * Gives the class `UserMenu` its `UserStatusMenu`: the logic of the status row and its sub-panels,
 * which reads the popover and whether it is open. A class that already has it is left as it is.
 */
export function addPresenceToUserMenuClass(source: string): string {
  const file = parseSource(source);
  const declaration = file.getClass('UserMenu');
  if (!declaration) throw new Error('Could not find the class "UserMenu".');
  if (declaration.getProperty('statusMenu')) return source;
  if (!declaration.getProperty('popoverRef')) {
    throw new Error(
      'The class "UserMenu" has no popoverRef (viewChild(AsPopover)), which the status menu reads.',
    );
  }
  addNamedImports(file, { module: './user-status', names: ['UserStatusMenu'] });
  declaration.addProperty({
    name: 'statusMenu',
    isReadonly: true,
    initializer: 'new UserStatusMenu(() => this.popoverRef(), () => this.popoverOpen())',
  });
  return file.getFullText();
}
