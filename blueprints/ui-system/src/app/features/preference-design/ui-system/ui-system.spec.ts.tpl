import { TestBed } from '@angular/core/testing';
import { AlertService } from '@shared/services';
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
    expect(root.textContent).toContain('as-button');
    expect(Array.from(cards).every((card) => card.querySelector('.border-dashed') !== null)).toBe(true);
  });

  it('says which tokens change a component', async () => {
    const { card } = await render();
    expect(card('button').textContent).toContain('Tamaño de botones');
    expect(card('toast').textContent).toContain('Tamaño de fuente');
    expect(card('avatar').textContent).toContain('ningún token');
  });

  it('filters the catalog by what is typed', async () => {
    const { fixture, component, root } = await render();
    component.query.set('modal');
    await fixture.whenStable();
    const cards = root.querySelectorAll('article[data-component]');
    expect(Array.from(cards).map((card) => card.getAttribute('data-component'))).toEqual(['modal']);
  });

  it('hides and shows the preview of a component', async () => {
    const { fixture, component, card } = await render();
    component.setShown('button', false);
    await fixture.whenStable();
    expect(card('button').querySelector('.border-dashed')).toBeNull();
    component.setShown('button', true);
    await fixture.whenStable();
    expect(card('button').querySelector('.border-dashed')).not.toBeNull();
  });

  describe('variants', () => {
    it('gives every component more than one variant to look at', () => {
      for (const entry of UI_COMPONENTS) {
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
        expect(card('button').querySelector(`[data-variant="${id}"] as-button`), id).not.toBeNull();
      }
    });

    it('shows the modes and the types of the text field', async () => {
      const { card } = await render();
      expect(idsOf('input')).toEqual(expect.arrayContaining(['mode-in', 'mode-on', 'mode-over', 'type-text', 'type-number', 'type-tel', 'type-price', 'type-tags']));
      expect(card('input').querySelectorAll('as-input').length).toBe(entryOf('input').variants.length);
    });

    it('covers the options of the rest of the components', () => {
      expect(idsOf('select')).toEqual(expect.arrayContaining(['mode-in', 'mode-on', 'mode-over', 'multiple', 'clearable', 'icon-only']));
      expect(idsOf('textarea')).toEqual(expect.arrayContaining(['mode-in', 'mode-on', 'mode-over']));
      expect(idsOf('tabs')).toEqual(expect.arrayContaining(['default', 'pills', 'compact']));
      expect(idsOf('avatar')).toEqual(expect.arrayContaining(['shape-circle', 'shape-rounded']));
      expect(idsOf('divider')).toEqual(expect.arrayContaining(['horizontal-solid', 'horizontal-dashed', 'horizontal-dotted', 'vertical-solid']));
      expect(idsOf('skeleton')).toEqual(expect.arrayContaining(['layout-line', 'layout-stat', 'layout-row', 'layout-circles']));
      expect(idsOf('tooltip')).toEqual(['top', 'bottom', 'left', 'right']);
      expect(idsOf('popover')).toEqual(expect.arrayContaining(['top', 'bottom', 'left', 'right', 'actions']));
      expect(idsOf('toggle')).toEqual(expect.arrayContaining(['off', 'on', 'disabled-off', 'disabled-on']));
      expect(idsOf('checkbox')).toEqual(expect.arrayContaining(['unchecked', 'checked', 'indeterminate', 'disabled']));
      expect(idsOf('toast')).toEqual(expect.arrayContaining(['success', 'info', 'warning', 'error', 'secondary', 'contrast', 'loading']));
    });

    it('renders a preview for every variant of every component', async () => {
      const { card } = await render();
      for (const entry of UI_COMPONENTS) {
        for (const variant of entry.variants) {
          expect(card(entry.id).querySelector(`[data-variant="${variant.id}"]`), `${entry.id}/${variant.id}`).not.toBeNull();
        }
      }
    });
  });

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

    it('is chosen by clicking the chip of a variant', async () => {
      const { fixture, card } = await render();
      (card('avatar').querySelector('[data-variant="shape-rounded"] [data-chip]') as HTMLButtonElement).click();
      await fixture.whenStable();
      expect(card('avatar').querySelector('[data-selected-code]')?.textContent).toContain('shape="rounded"');
      expect(card('avatar').querySelector('[data-variant="shape-rounded"] [data-chip]')?.getAttribute('aria-pressed')).toBe('true');
    });

    it('lists the code of every variant of a component', async () => {
      const { component } = await render();
      const all = component.allCodeOf(entryOf('tooltip'));
      for (const position of ['top', 'bottom', 'left', 'right']) {
        expect(all).toContain(`tooltipPosition="${position}"`);
      }
    });

    it('shows the toast with the method of the chosen type', async () => {
      const { component } = await render();
      const toast = entryOf('toast');
      component.choose(toast, toast.variants.find((variant) => variant.id === 'error')!);
      expect(component.codeOf(toast)).toContain('showError(');
    });
  });

  describe('overlays', () => {
    it('opens the drawer over the whole page, in each position', async () => {
      const { fixture, component } = await render();
      const drawer = entryOf('drawer');
      expect(idsOf('drawer')).toEqual(expect.arrayContaining(['left', 'right', 'top', 'bottom', 'full']));

      for (const position of ['left', 'right', 'top', 'bottom', 'full']) {
        component.openOverlay(drawer, drawer.variants.find((variant) => variant.id === position)!);
        await fixture.whenStable();
        const panel = overlay().querySelector('dialog.as-drawer') as HTMLElement | null;
        expect(panel, position).not.toBeNull();
        expect(panel?.classList.contains(`as-drawer-${position}`), position).toBe(true);
        expect((fixture.nativeElement as HTMLElement).contains(panel), position).toBe(false);
        component.drawerOpen.set(false);
        await fixture.whenStable();
      }
    });

    it('shows the drawer with its header, its content and its footer', async () => {
      const { fixture, component } = await render();
      const drawer = entryOf('drawer');
      component.setOption(drawer, drawer.options!.find((option) => option.id === 'footer')!, true);
      component.openOverlay(drawer, drawer.variants[0]);
      await fixture.whenStable();

      const panel = overlay().querySelector('dialog.as-drawer') as HTMLElement;
      expect(Array.from(panel.children).map((child) => child.className)).toEqual(['as-drawer-header', 'as-drawer-content', 'as-drawer-footer']);
      expect(panel.querySelector('.as-drawer-header [drawer-header]')).not.toBeNull();
      expect(panel.querySelector('.as-drawer-footer [drawer-footer]')).not.toBeNull();
      expect(panel.querySelector('.as-drawer-close-button')).not.toBeNull();
    });

    it('applies the options to the drawer and to its code', async () => {
      const { fixture, component } = await render();
      const drawer = entryOf('drawer');
      const closable = drawer.options!.find((option) => option.id === 'closable')!;
      component.openOverlay(drawer, drawer.variants[0]);
      await fixture.whenStable();
      expect(overlay().querySelector('.as-drawer-close-button')).not.toBeNull();

      component.setOption(drawer, closable, false);
      await fixture.whenStable();
      expect(overlay().querySelector('.as-drawer-close-button')).toBeNull();
      expect(component.codeOf(drawer)).toContain('[closable]="false"');
    });

    it('opens the modal over the page with its title, its footer and its options', async () => {
      const { fixture, component } = await render();
      const modal = entryOf('modal');
      component.setOption(modal, modal.options!.find((option) => option.id === 'footer')!, true);
      component.openOverlay(modal, modal.variants[0]);
      await fixture.whenStable();

      const panel = overlay().querySelector('.as-modal') as HTMLElement;
      expect(panel).not.toBeNull();
      expect((fixture.nativeElement as HTMLElement).contains(panel)).toBe(false);
      expect(panel.querySelector('.as-modal-header-title')?.textContent).toContain('Título');
      expect(panel.querySelector('.as-modal-footer')).not.toBeNull();
      expect(component.codeOf(modal)).toContain('showFooter');
    });
  });

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
  });
});
