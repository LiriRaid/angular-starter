import { ComponentFixture, TestBed } from '@angular/core/testing';

import { SaSelect } from './sa-select';

const OPTIONS = [
  { label: 'Apple', value: 'a' },
  { label: 'Banana', value: 'b' },
  { label: 'Cherry', value: 'c' },
];

describe('SaSelect', () => {
  let fixture: ComponentFixture<SaSelect>;
  let component: SaSelect;

  beforeEach(async () => {
    TestBed.overrideComponent(SaSelect, { set: { imports: [], template: '' } });

    await TestBed.configureTestingModule({ imports: [SaSelect] }).compileComponents();

    fixture = TestBed.createComponent(SaSelect);
    component = fixture.componentInstance;
    fixture.componentRef.setInput('options', OPTIONS);
    fixture.componentRef.setInput('optionLabel', 'label');
    fixture.componentRef.setInput('optionValue', 'value');
    fixture.detectChanges();
  });

  it('creates the component', () => {
    expect(component).toBeTruthy();
  });

  it('optionPresenceOf lee el estado de presencia del campo indicado y es undefined sin él', () => {
    const agent = { label: 'Ana', value: 'a', presence: 'busy' };

    expect(component.optionPresenceOf(agent)).toBeUndefined();

    fixture.componentRef.setInput('optionPresence', 'presence');
    fixture.detectChanges();

    expect(component.optionPresenceOf(agent)).toBe('busy');
    expect(component.optionPresenceOf({ label: 'Luis', value: 'l' })).toBeUndefined();
  });

  it('reflects the written value', () => {
    component.writeValue('b');
    expect(component.value()).toBe('b');
    expect(component.hasValue()).toBe(true);

    component.writeValue(null);
    expect(component.hasValue()).toBe(false);
  });

  it('shows all options when not searchable', () => {
    expect(component.displayOptions()).toEqual(OPTIONS);
  });

  it('filters options by the typed text when searchable', () => {
    fixture.componentRef.setInput('searchable', true);

    // Texto que no coincide con ningún value => se trata como término de búsqueda.
    component.onSelectChange('ban');

    expect(component.displayOptions()).toEqual([{ label: 'Banana', value: 'b' }]);
  });

  it('commits the value when selecting a real option', () => {
    fixture.componentRef.setInput('searchable', true);
    const emitSpy = vi.spyOn(component.valueChange, 'emit');

    component.onSelectChange('a');

    expect(component.value()).toBe('a');
    expect(emitSpy).toHaveBeenCalledWith('a');
  });

  it('exposes the label color by state', () => {
    expect(component.labelColor()).toBe('var(--app-text-subtle)');

    component.writeValue('a');
    expect(component.labelColor()).toBe('var(--app-text-muted)');

    component.isFocused.set(true);
    expect(component.labelColor()).toBe('var(--app-text-primary)');
  });

  it('floats the label when it has a value', () => {
    expect(component.shouldFloat()).toBe(false);

    component.writeValue('a');

    expect(component.shouldFloat()).toBe(true);
  });
});

describe('SaSelect · opciones con ícono (template)', () => {
  const ICON_OPTIONS = [
    { label: 'Casa', value: 'home', icon: 'Home', color: '#3b82f6' },
    { label: 'Trabajo', value: 'work', icon: 'User', color: '#10b981' },
  ];
  let fixture: ComponentFixture<SaSelect>;

  const setup = (inputs: Record<string, unknown> = {}) => {
    fixture = TestBed.createComponent(SaSelect);
    const defaults = { options: ICON_OPTIONS, optionLabel: 'label', optionValue: 'value', optionIcon: 'icon', optionColor: 'color', searchable: false, ...inputs };
    for (const [name, value] of Object.entries(defaults)) fixture.componentRef.setInput(name, value);
    fixture.detectChanges();
  };
  const el = () => fixture.nativeElement as HTMLElement;

  beforeEach(async () => {
    await TestBed.configureTestingModule({ imports: [SaSelect] }).compileComponents();
  });

  it('el ícono plano de cada opción mide 14 por defecto y respeta optionIconSize', () => {
    setup();
    expect(el().querySelector('.sa-select-option svg')?.getAttribute('width')).toBe('14');

    fixture.componentRef.setInput('optionIconSize', 20);
    fixture.detectChanges();
    expect(el().querySelector('.sa-select-option svg')?.getAttribute('width')).toBe('20');
  });

  it('hideOptionLabel quita el texto de las filas y del campo cerrado, no el ícono', () => {
    setup();
    expect(el().querySelector('.sa-select-option .truncate')?.textContent).toContain('Casa');

    fixture.componentRef.setInput('hideOptionLabel', true);
    fixture.componentInstance.writeValue('work');
    fixture.detectChanges();

    expect(el().querySelector('.sa-select-option .truncate')).toBeNull();
    expect(el().querySelector('.sa-select-field-label .truncate')).toBeNull();
    expect(el().querySelector('.sa-select-field-label svg')).toBeTruthy();
  });

  it('accentColor tiñe el fondo del campo y sin él no pone estilo propio', () => {
    setup();
    const fieldset = () => el().querySelector('fieldset') as HTMLElement;
    expect(fieldset().style.background).toBe('');

    fixture.componentRef.setInput('accentColor', '#ff0000');
    fixture.detectChanges();
    expect(fieldset().style.background).toContain('color-mix');
    expect(fieldset().style.background).toContain('#ff0000');
  });

  it('panelStyleClass se suma a la clase del panel desplegable', () => {
    setup({ panelStyleClass: 'mi-panel otra' });
    const panel = el().querySelector('.sa-select-panel') as HTMLElement;
    expect(panel.classList.contains('mi-panel')).toBe(true);
    expect(panel.classList.contains('otra')).toBe(true);
    expect(panel.classList.contains('sa-select-panel')).toBe(true);
  });
});

describe('SaSelect · seguimiento del scroll', () => {
  let fixture: ComponentFixture<SaSelect>;
  let component: SaSelect;
  let scroller: HTMLElement;
  let trigger: HTMLElement;
  let panel: HTMLElement;
  const setRect = (el: HTMLElement, top: number, height: number): void => {
    vi.spyOn(el, 'getBoundingClientRect').mockReturnValue({ top, bottom: top + height, left: 400, right: 640, width: 240, height, x: 400, y: top, toJSON: () => ({}) } as DOMRect);
  };
  const reposition = (): void => (component as unknown as { positionPanel: () => void }).positionPanel();

  beforeEach(async () => {
    TestBed.overrideComponent(SaSelect, { set: { imports: [], template: '' } });
    await TestBed.configureTestingModule({ imports: [SaSelect] }).compileComponents();
    fixture = TestBed.createComponent(SaSelect);
    component = fixture.componentInstance;
    fixture.componentRef.setInput('options', OPTIONS);
    fixture.detectChanges();

    vi.spyOn(document.documentElement, 'clientWidth', 'get').mockReturnValue(1000);
    vi.spyOn(document.documentElement, 'clientHeight', 'get').mockReturnValue(800);
    scroller = document.createElement('div');
    scroller.style.overflowY = 'auto';
    setRect(scroller, 80, 600);
    trigger = document.createElement('div');
    scroller.appendChild(trigger);
    panel = document.createElement('div');
    document.body.append(scroller, panel);

    const target = component as unknown as { triggerRef: () => unknown; panelRef: () => unknown };
    vi.spyOn(target, 'triggerRef').mockReturnValue({ nativeElement: trigger });
    vi.spyOn(target, 'panelRef').mockReturnValue({ nativeElement: panel });
    vi.spyOn(panel, 'getBoundingClientRect').mockReturnValue({ top: 0, bottom: 200, left: 0, right: 240, width: 240, height: 200, x: 0, y: 0, toJSON: () => ({}) } as DOMRect);
  });

  afterEach(() => {
    scroller.remove();
    panel.remove();
    vi.restoreAllMocks();
    vi.useRealTimers();
  });

  it('con el campo visible coloca el panel pegado a él', () => {
    setRect(trigger, 300, 40);
    const hideSpy = vi.spyOn(component, 'hidePanel');

    reposition();

    expect(panel.style.top).toBe('342px');
    expect(panel.style.left).toBe('400px');
    expect(hideSpy).not.toHaveBeenCalled();
  });

  it('cuando el scroll saca el campo del contenedor, el panel se cierra en vez de quedar pegado a la ventana', () => {
    setRect(trigger, 20, 40);
    const hideSpy = vi.spyOn(component, 'hidePanel').mockImplementation(() => undefined);

    reposition();

    expect(hideSpy).toHaveBeenCalled();
  });

  it('con el panel abierto un scroll lo reposiciona y al cerrarlo deja de escuchar', () => {
    setRect(trigger, 300, 40);
    Object.assign(panel, { showPopover: vi.fn(), hidePopover: vi.fn(), matches: () => false });
    vi.useFakeTimers();

    component.showPanel();
    vi.runAllTimers();
    setRect(trigger, 340, 40);
    scroller.dispatchEvent(new Event('scroll'));
    vi.runAllTimers();
    expect(panel.style.top).toBe('382px');

    component.onPanelToggle({ newState: 'closed' } as ToggleEvent);
    setRect(trigger, 400, 40);
    scroller.dispatchEvent(new Event('scroll'));
    vi.runAllTimers();
    expect(panel.style.top).toBe('382px');
  });
});
