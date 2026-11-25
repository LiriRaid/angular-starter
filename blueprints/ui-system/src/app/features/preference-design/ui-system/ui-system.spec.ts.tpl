import { TestBed } from '@angular/core/testing';
import { reflectComponentType, type Type } from '@angular/core';
import {
  SaAvatar, // uis(avatar)
  SaButton,
  SaCheckbox, // uis(checkbox)
  SaDivider, // uis(divider)
  SaDrawer, // uis(drawer)
  SaIcon, // uis(icon)
  SaInput, // uis(input)
  SaModal, // uis(modal)
  SaPopover, // uis(popover)
  SaSelect, // uis(select)
  SaSkeleton, // uis(skeleton)
  SaTabs, // uis(tabs)
  SaTextarea, // uis(textarea)
  SaToggle,
} from '@shared/components';
import { AlertService } from '@shared/services'; // uis(toast)
import { UI_COMPONENTS, type UiComponentEntry } from './ui-system.catalog';
import { UiSystem } from './ui-system';

const entryOf = (id: string): UiComponentEntry => {
  const entry = UI_COMPONENTS.find((candidate) => candidate.id === id);
  if (!entry) throw new Error(`The catalog has no "${id}".`);
  return entry;
};
const idsOf = (id: string): string[] => entryOf(id).variants.map((variant) => variant.id);

describe('UiSystem', () => {
  beforeEach(() => {
    // jsdom no implementa `<dialog>.show()` ni `.close()`: el panel los llama al abrirse y al cerrarse.
    HTMLDialogElement.prototype.show ??= function (this: HTMLDialogElement) {
      this.setAttribute('open', '');
    };
    HTMLDialogElement.prototype.close ??= function (this: HTMLDialogElement) {
      this.removeAttribute('open');
    };
    // jsdom tampoco implementa `Element.scrollTo`, que las pestañas usan para traer la elegida a la vista.
    HTMLElement.prototype.scrollTo ??= function () {};
  });

  const render = async () => {
    await TestBed.configureTestingModule({ imports: [UiSystem] }).compileComponents();
    const fixture = TestBed.createComponent(UiSystem);
    await fixture.whenStable();
    const root = fixture.nativeElement as HTMLElement;
    const card = (id: string) => root.querySelector(`[data-component="${id}"]`) as HTMLElement;
    return { fixture, component: fixture.componentInstance, root, card };
  };
  const overlay = () => document.querySelector('.cdk-overlay-container') as HTMLElement;

  it('lists every component with its selector and a preview', async () => {
    const { root } = await render();
    const cards = root.querySelectorAll('article[data-component]');
    expect(cards).toHaveLength(UI_COMPONENTS.length);
    expect(root.textContent).toContain('sa-button');
    expect(Array.from(cards).every((card) => card.querySelector('.border-dashed') !== null)).toBe(true);
  });

  it('says which tokens change a component', async () => {
    const { card } = await render();
    expect(card('button').textContent).toContain('Tamaño de botones');
    expect(card('toast').textContent).toContain('Tamaño de fuente'); // uis(toast)
    expect(card('avatar').textContent).toContain('ningún token'); // uis(avatar)
  });

  it('filters the catalog by what is typed', async () => {
    const { fixture, component, root } = await render();
    component.query.set('sa-button');
    await fixture.whenStable();
    const cards = Array.from(root.querySelectorAll('article[data-component]'));
    expect(cards.map((card) => card.getAttribute('data-component'))).toContain('button');
    expect(cards.length).toBeLessThan(UI_COMPONENTS.length);

    component.query.set('zzz-no-component');
    await fixture.whenStable();
    expect(root.querySelectorAll('article[data-component]')).toHaveLength(0);
    expect(root.textContent).toContain('Ningún componente coincide');
  });

  it('collapses the preview of a component with the accordion animation and expands it again', async () => {
    const { fixture, component, card } = await render();
    const collapse = () => card('button').querySelector('[data-preview]') as HTMLElement;
    expect(collapse().classList.contains('sa-collapse-grid')).toBe(true);
    expect(collapse().classList.contains('is-collapsed')).toBe(false);

    component.setShown('button', false);
    await fixture.whenStable();
    expect(collapse().classList.contains('is-collapsed')).toBe(true);
    expect(collapse().hasAttribute('inert')).toBe(true);

    component.setShown('button', true);
    await fixture.whenStable();
    expect(collapse().classList.contains('is-collapsed')).toBe(false);
  });

  it('expands and collapses the code of all the variants with the same animation', async () => {
    const { fixture, card } = await render();
    const toggle = card('button').querySelector('[data-all-code-toggle]') as HTMLButtonElement;
    const collapse = () => card('button').querySelector('[data-all-code]') as HTMLElement;
    expect(collapse().classList.contains('is-collapsed')).toBe(true);
    expect(toggle.getAttribute('aria-expanded')).toBe('false');

    toggle.click();
    await fixture.whenStable();
    expect(collapse().classList.contains('is-collapsed')).toBe(false);
    expect(toggle.getAttribute('aria-expanded')).toBe('true');

    toggle.click();
    await fixture.whenStable();
    expect(collapse().classList.contains('is-collapsed')).toBe(true);
  });

  describe('variants', () => {
    it('gives every component more than one variant to look at', () => {
      for (const entry of UI_COMPONENTS.filter((candidate) => !candidate.noPreview)) {
        expect(entry.variants.length, entry.id).toBeGreaterThan(1);
        expect(new Set(entry.variants.map((variant) => variant.id)).size, entry.id).toBe(entry.variants.length);
      }
    });

    it('shows every button size and every severity at once', async () => {
      const { card } = await render();
      expect(idsOf('button')).toEqual(
        expect.arrayContaining([
          'size-xsmall',
          'size-small',
          'size-medium',
          'size-high',
          'size-large',
          'severity-primary',
          'severity-danger',
          'outlined',
          'text',
          'dashed',
          'raised',
          'icon-only',
          'loading',
          'disabled',
        ]),
      );
      for (const id of idsOf('button')) {
        expect(card('button').querySelector(`[data-variant="${id}"] sa-button`), id).not.toBeNull();
      }
    });

    // uis:begin(input)
    it('shows the modes and the types of the text field', async () => {
      const { card } = await render();
      expect(idsOf('input')).toEqual(expect.arrayContaining(['mode-in', 'mode-on', 'mode-over', 'type-text', 'type-number', 'type-tel', 'type-price', 'type-tags']));
      expect(card('input').querySelectorAll('sa-input').length).toBe(entryOf('input').variants.length);
    });
    // uis:end

    it('covers the options of the rest of the components', () => {
      expect(idsOf('select')).toEqual(expect.arrayContaining(['mode-in', 'mode-on', 'mode-over', 'multiple-on', 'clearable-on', 'icon-only'])); // uis(select)
      expect(idsOf('textarea')).toEqual(expect.arrayContaining(['mode-in', 'mode-on', 'mode-over'])); // uis(textarea)
      expect(idsOf('tabs')).toEqual(expect.arrayContaining(['default', 'pills', 'compact', 'default-icons', 'pills-icons', 'compact-icons', 'fit-icons', 'fit-counts', 'overflow-icons', 'overflow-counts'])); // uis(tabs)
      expect(idsOf('avatar')).toEqual(expect.arrayContaining(['shape-circle', 'shape-rounded'])); // uis(avatar)
      expect(idsOf('divider')).toEqual(expect.arrayContaining(['horizontal-solid', 'horizontal-dashed', 'horizontal-dotted', 'vertical-solid'])); // uis(divider)
      expect(idsOf('skeleton')).toEqual(expect.arrayContaining(['layout-line', 'layout-stat', 'layout-row', 'layout-circles'])); // uis(skeleton)
      expect(idsOf('tooltip')).toEqual(['host-top', 'host-bottom', 'host-left', 'host-right', 'text-top', 'text-bottom', 'text-left', 'text-right', 'host-delay']); // uis(tooltip)
      expect(idsOf('popover')).toEqual(expect.arrayContaining(['top', 'bottom', 'left', 'right', 'actions'])); // uis(popover)
      expect(idsOf('toggle')).toEqual(expect.arrayContaining(['off', 'on', 'disabled-off', 'disabled-on'])); // uis(toggle)
      expect(idsOf('checkbox')).toEqual(expect.arrayContaining(['unchecked', 'checked', 'indeterminate', 'disabled'])); // uis(checkbox)
      expect(idsOf('toast')).toEqual(expect.arrayContaining(['success', 'info', 'warning', 'error', 'secondary', 'contrast', 'loading', 'position-top-center'])); // uis(toast)
    });

    it('renders a preview for every variant of every component that has one', async () => {
      const { card } = await render();
      for (const entry of UI_COMPONENTS.filter((candidate) => !candidate.noPreview)) {
        for (const variant of entry.variants) {
          expect(card(entry.id).querySelector(`[data-variant="${variant.id}"]`), `${entry.id}/${variant.id}`).not.toBeNull();
        }
      }
    });
  });

  describe('the components with no preview yet', () => {
    it('show their selector and how they are used, and no preview', async () => {
      const { card } = await render();
      for (const entry of UI_COMPONENTS.filter((candidate) => candidate.noPreview)) {
        expect(card(entry.id).textContent, entry.id).toContain(entry.selector);
        expect(card(entry.id).textContent, entry.id).toContain('todavía no tiene vista previa');
        expect(card(entry.id).querySelector('[data-variant]'), entry.id).toBeNull();
        expect(card(entry.id).querySelector('[data-selected-code]')?.textContent, entry.id).toContain(entry.selector);
      }
    });
  });

  describe('the properties of the components', () => {
    const CLASSES: Record<string, Type<unknown>> = {
      icon: SaIcon, // uis(icon)
      button: SaButton,
      input: SaInput, // uis(input)
      textarea: SaTextarea, // uis(textarea)
      checkbox: SaCheckbox, // uis(checkbox)
      toggle: SaToggle,
      select: SaSelect, // uis(select)
      avatar: SaAvatar, // uis(avatar)
      divider: SaDivider, // uis(divider)
      skeleton: SaSkeleton, // uis(skeleton)
      modal: SaModal, // uis(modal)
      drawer: SaDrawer, // uis(drawer)
      tabs: SaTabs, // uis(tabs)
      popover: SaPopover, // uis(popover)
    };

    it('shows every input of every component, or says why it does not', () => {
      for (const [id, type] of Object.entries(CLASSES)) {
        const entry = entryOf(id);
        const shown = new Set<string>();
        const note = (props: Record<string, unknown>) => Object.keys(props).forEach((name) => shown.add(name.replace(/^[[(]+|[\])]+$/g, '')));
        for (const variant of entry.variants) note(variant.props);
        note(entry.baseProps ?? {});
        for (const option of entry.options ?? []) if (option.prop) shown.add(option.prop);
        const missing = (reflectComponentType(type)?.inputs ?? []).map((input) => input.propName).filter((name) => !shown.has(name) && !(entry.notShown ?? []).includes(name));
        expect(missing, id).toEqual([]);
      }
    });
  });

  describe('the modes of the field', () => {
    // uis:begin(input)
    it('shows required in each mode, with its own name', async () => {
      const { card } = await render();
      for (const mode of ['on', 'in', 'over']) {
        const figure = card('input').querySelector(`[data-variant="required-${mode}"]`) as HTMLElement;
        expect(figure, mode).not.toBeNull();
        expect(figure.querySelector('[data-chip]')?.textContent).toContain(`required variant="${mode}"`);
      }
    });
    // uis:end

    // uis:begin(input)
    it('lets the password be shown and hidden with the eye', async () => {
      const { fixture, card } = await render();
      const figure = () => card('input').querySelector('[data-variant="type-password"]') as HTMLElement;
      expect(figure().querySelector('input')?.getAttribute('type')).toBe('password');
      expect(figure().querySelector('svg.lucide-eye')).not.toBeNull();

      (figure().querySelector('svg.lucide-eye')?.closest('sa-icon') as HTMLElement).click();
      await fixture.whenStable();
      expect(figure().querySelector('input')?.getAttribute('type')).toBe('text');
      expect(figure().querySelector('svg.lucide-eye-off')).not.toBeNull();
    });
    // uis:end

    it('gives every mode the options that apply to it', () => {
      for (const mode of ['on', 'in', 'over']) {
        expect(idsOf('input')).toEqual(expect.arrayContaining([`required-${mode}`, `readonly-${mode}`, `icon-left-${mode}`, `icon-right-${mode}`])); // uis(input)
        expect(idsOf('textarea')).toEqual(expect.arrayContaining([`required-${mode}`, `readonly-${mode}`, `icon-${mode}`])); // uis(textarea)
        expect(idsOf('select')).toEqual(expect.arrayContaining([`required-${mode}`, `clearable-${mode}`, `multiple-${mode}`])); // uis(select)
      }
    });
  });

  // uis:begin(tabs)
  describe('tabs', () => {
    it('keep each example independent: choosing a tab in one does not change the others', async () => {
      const { fixture, card } = await render();
      const active = (id: string) => card('tabs').querySelector(`[data-variant="${id}"] .sa-tab--active`)?.textContent?.trim();
      const second = (id: string) => card('tabs').querySelectorAll(`[data-variant="${id}"] .sa-tab`)[1] as HTMLElement;

      second('pills').click();
      await fixture.whenStable();
      expect(active('pills')).toContain('Dos');
      for (const id of ['default', 'default-icons', 'compact', 'pills-compact', 'compact-icons', 'overflow-icons', 'fit-icons']) {
        expect(active(id), id).not.toContain('Dos');
      }

      second('compact').click();
      await fixture.whenStable();
      expect(active('compact')).toContain('Dos');
      expect(active('default')).not.toContain('Dos');
      expect(active('pills')).toContain('Dos');
    });

    it('has no state shared between variants', () => {
      expect('sharedGroups' in entryOf('tabs')).toBe(false);
    });
  });
  // uis:end

  // uis:begin(tooltip)
  describe('the tooltip', () => {
    it('is shown on the whole button and on its text, in each position', async () => {
      const { card } = await render();
      for (const position of ['top', 'bottom', 'left', 'right']) {
        const host = card('tooltip').querySelector(`[data-variant="host-${position}"]`) as HTMLElement;
        const text = card('tooltip').querySelector(`[data-variant="text-${position}"]`) as HTMLElement;
        expect(host.querySelector('sa-button')?.hasAttribute('satooltip'), position).toBe(true);
        expect(text.querySelector('sa-button span[satooltip]'), position).not.toBeNull();
        expect(host.querySelector('[data-chip]')?.textContent).toContain('host');
        expect(text.querySelector('[data-chip]')?.textContent).toContain('texto');
      }
    });
  });
  // uis:end

  describe('the chips', () => {
    it('paint the variant names and the tokens with the dark surface of the fields, in both themes', async () => {
      const { root } = await render();
      const chips = Array.from(root.querySelectorAll('[data-chip], [data-token]'));
      expect(chips.length).toBeGreaterThan(100);
      for (const chip of chips) {
        expect(chip.className).toContain('bg-(--app-control-surface-bg)');
        expect(chip.className).not.toContain('badge-soft-bg');
      }
    });

    it('mark the chosen variant with the primary colour, not with a lighter background', async () => {
      const { card } = await render();
      const chosen = card('button').querySelector('[data-chip][aria-pressed="true"]') as HTMLElement;
      expect(chosen.className).toContain('text-(--app-badge-soft-text)');
      expect(chosen.className).toContain('border-(--app-badge-soft-text)');
    });
  });

  // uis:begin(select)
  describe('the readonly select', () => {
    it('shows a chosen value in each mode, so the readonly look can be judged', async () => {
      const { card } = await render();
      for (const mode of ['on', 'in', 'over']) {
        const field = card('select').querySelector(`[data-variant="readonly-${mode}"] input`) as HTMLInputElement;
        expect(field.value, mode).toBe('Pro');
      }
    });
  });
  // uis:end

  // uis:begin(skeleton)
  describe('the skeleton', () => {
    it('gives every variant a box of its own, so one does not overlap the next', () => {
      for (const variant of entryOf('skeleton').variants) {
        expect(variant.boxClass, variant.id).toBeTruthy();
      }
    });
  });
  // uis:end

  describe('code', () => {
    it('follows the variant that is chosen', async () => {
      const { fixture, component, card } = await render();
      const button = entryOf('button');
      const code = () => (card('button').querySelector('[data-selected-code]') as HTMLElement).textContent ?? '';

      expect(component.selectedOf(button).id).toBe(button.variants[0].id);

      component.choose(button, button.variants.find((variant) => variant.id === 'size-xsmall')!);
      await fixture.whenStable();
      expect(code()).toContain('size="xsmall"');

      component.choose(button, button.variants.find((variant) => variant.id === 'size-large')!);
      await fixture.whenStable();
      expect(code()).toContain('size="large"');
      expect(code()).not.toContain('xsmall');
    });

    // uis:begin(avatar)
    it('is chosen by clicking the chip of a variant', async () => {
      const { fixture, card } = await render();
      (card('avatar').querySelector('[data-variant="shape-rounded"] [data-chip]') as HTMLButtonElement).click();
      await fixture.whenStable();
      expect(card('avatar').querySelector('[data-selected-code]')?.textContent).toContain('shape="rounded"');
      expect(card('avatar').querySelector('[data-variant="shape-rounded"] [data-chip]')?.getAttribute('aria-pressed')).toBe('true');
    });
    // uis:end

    // uis:begin(tooltip)
    it('lists the code of every variant of a component', async () => {
      const { component } = await render();
      const all = component.allCodeOf(entryOf('tooltip'));
      for (const position of ['top', 'bottom', 'left', 'right']) {
        expect(all).toContain(`tooltipPosition="${position}"`);
      }
    });
    // uis:end

    // uis:begin(toast)
    it('shows the toast with the method of the chosen type', async () => {
      const { component } = await render();
      const toast = entryOf('toast');
      component.choose(toast, toast.variants.find((variant) => variant.id === 'error')!);
      expect(component.codeOf(toast)).toContain('showError(');
    });
    // uis:end
  });

  // uis:begin(drawer|modal)
  describe('overlays', () => {
    // uis:begin(drawer)
    it('opens the drawer over the whole page, in each position', async () => {
      const { fixture, component } = await render();
      const drawer = entryOf('drawer');
      expect(idsOf('drawer')).toEqual(expect.arrayContaining(['left', 'right', 'top', 'bottom', 'full']));

      for (const position of ['left', 'right', 'top', 'bottom', 'full']) {
        component.openOverlay(drawer, drawer.variants.find((variant) => variant.id === position)!);
        await fixture.whenStable();
        const panel = overlay().querySelector('dialog.sa-drawer') as HTMLElement | null;
        expect(panel, position).not.toBeNull();
        expect(panel?.classList.contains(`sa-drawer-${position}`), position).toBe(true);
        expect((fixture.nativeElement as HTMLElement).contains(panel), position).toBe(false);
        component.drawerOpen.set(false);
        await fixture.whenStable();
      }
    });
    // uis:end

    // uis:begin(drawer)
    it('shows the drawer with its header, its content and its footer', async () => {
      const { fixture, component } = await render();
      const drawer = entryOf('drawer');
      component.setOption(drawer, drawer.options!.find((option) => option.id === 'footer')!, true);
      component.openOverlay(drawer, drawer.variants[0]);
      await fixture.whenStable();

      const panel = overlay().querySelector('dialog.sa-drawer') as HTMLElement;
      expect(Array.from(panel.children).map((child) => child.className)).toEqual(['sa-drawer-header', 'sa-drawer-content', 'sa-drawer-footer']);
      expect(panel.querySelector('.sa-drawer-header [drawer-header]')).not.toBeNull();
      expect(panel.querySelector('.sa-drawer-footer [drawer-footer]')).not.toBeNull();
      expect(panel.querySelector('.sa-drawer-close-button')).not.toBeNull();
      expect(panel.classList.contains('sa-drawer--flush')).toBe(true);
      expect(component.codeOf(drawer)).toContain('flush');
      expect(component.codeOf(drawer)).toContain('class="p-5"');
    });
    // uis:end

    // uis:begin(drawer)
    it('applies the options to the drawer and to its code', async () => {
      const { fixture, component } = await render();
      const drawer = entryOf('drawer');
      const closable = drawer.options!.find((option) => option.id === 'closable')!;
      component.openOverlay(drawer, drawer.variants[0]);
      await fixture.whenStable();
      expect(overlay().querySelector('.sa-drawer-close-button')).not.toBeNull();

      component.setOption(drawer, closable, false);
      await fixture.whenStable();
      expect(overlay().querySelector('.sa-drawer-close-button')).toBeNull();
      expect(component.codeOf(drawer)).toContain('[closable]="false"');
    });
    // uis:end

    // uis:begin(modal)
    it('opens the modal over the page with its title, its footer and its options', async () => {
      const { fixture, component } = await render();
      const modal = entryOf('modal');
      component.setOption(modal, modal.options!.find((option) => option.id === 'footer')!, true);
      component.openOverlay(modal, modal.variants[0]);
      await fixture.whenStable();

      const panel = overlay().querySelector('.sa-modal') as HTMLElement;
      expect(panel).not.toBeNull();
      expect((fixture.nativeElement as HTMLElement).contains(panel)).toBe(false);
      expect(panel.querySelector('.sa-modal-header-title')?.textContent).toContain('Título');
      expect(panel.querySelector('.sa-modal-footer')).not.toBeNull();
      expect(component.codeOf(modal)).toContain('showFooter');
      expect(panel.classList.contains('sa-modal--flush')).toBe(true);
      expect(component.codeOf(modal)).toContain('flush');
      expect(component.codeOf(modal)).toContain('class="p-5"');
    });
    // uis:end
    // uis:begin(modal)
    it('lets the modal be fixed with the draggable switch, and writes it in the code', async () => {
      const { fixture, component } = await render();
      const modal = entryOf('modal');
      const press = (header: HTMLElement) => header.dispatchEvent(new MouseEvent('mousedown', { bubbles: true, clientX: 10, clientY: 10 }));

      component.openOverlay(modal, modal.variants[0]);
      await fixture.whenStable();
      expect(component.codeOf(modal)).not.toContain('draggable');
      press(overlay().querySelector('.sa-modal-header') as HTMLElement);
      expect((overlay().querySelector('.sa-modal') as HTMLElement).style.position).toBe('fixed');
      document.dispatchEvent(new MouseEvent('mouseup'));

      component.modalOpen.set(false);
      await new Promise((resolve) => setTimeout(resolve, 400));
      component.setOption(modal, modal.options!.find((option) => option.id === 'draggable')!, false);
      component.openOverlay(modal, modal.variants[0]);
      await fixture.whenStable();

      expect(component.codeOf(modal)).toContain('[draggable]="false"');
      press(overlay().querySelector('.sa-modal-header') as HTMLElement);
      expect((overlay().querySelector('.sa-modal') as HTMLElement).style.position).toBe('');
    });
    // uis:end
  });
  // uis:end

  // uis:begin(drawer|modal)
  describe('overlay sizes', () => {
    // uis:begin(modal)
    it('gives the modal the width and the shape of the chosen variant', async () => {
      const { fixture, component } = await render();
      const modal = entryOf('modal');
      component.openOverlay(modal, modal.variants.find((variant) => variant.id === 'width-48')!);
      await fixture.whenStable();
      expect((overlay().querySelector('.sa-modal') as HTMLElement).style.width).toBe('48rem');

      component.openOverlay(modal, modal.variants.find((variant) => variant.id === 'preview')!);
      await fixture.whenStable();
      expect(overlay().querySelector('.sa-modal')?.classList.contains('sa-modal--preview')).toBe(true);
    });
    // uis:end

    // uis:begin(drawer)
    it('gives the drawer the width of the chosen variant', async () => {
      const { fixture, component } = await render();
      const drawer = entryOf('drawer');
      component.openOverlay(drawer, drawer.variants.find((variant) => variant.id === 'width-45')!);
      await fixture.whenStable();
      expect((overlay().querySelector('dialog.sa-drawer') as HTMLElement).style.getPropertyValue('--sa-drawer-width')).toBe('45rem');
    });
    // uis:end
  });
  // uis:end

  // uis:begin(toast)
  describe('toast', () => {
    it('shows a toast of the chosen type through the alert service', async () => {
      const { component } = await render();
      const alerts = TestBed.inject(AlertService);
      const toast = entryOf('toast');
      const success = vi.spyOn(alerts, 'showSuccess');
      const warning = vi.spyOn(alerts, 'showWarning');
      const error = vi.spyOn(alerts, 'showError');
      component.showToast(toast.variants.find((variant) => variant.id === 'success')!);
      component.showToast(toast.variants.find((variant) => variant.id === 'warning')!);
      component.showToast(toast.variants.find((variant) => variant.id === 'error')!);
      expect(success).toHaveBeenCalledOnce();
      expect(warning).toHaveBeenCalledOnce();
      expect(error).toHaveBeenCalledOnce();
    });

    it('passes the position of the variant to the alert service for every type', async () => {
      const { component } = await render();
      const alerts = TestBed.inject(AlertService);
      const warning = vi.spyOn(alerts, 'showWarning');
      const error = vi.spyOn(alerts, 'showError');
      const toast = entryOf('toast');
      const withPosition = (method: string) => ({ ...toast.variants[0], props: { method, title: 'T', message: 'M', position: 'bottom-right' } });
      component.showToast(withPosition('showWarning'));
      component.showToast(withPosition('showError'));
      expect(warning).toHaveBeenCalledWith('T', 'M', undefined, undefined, false, 'bottom-right');
      expect(error).toHaveBeenCalledWith('T', 'M', undefined, undefined, 'bottom-right');
    });
  });
  // uis:end
});
