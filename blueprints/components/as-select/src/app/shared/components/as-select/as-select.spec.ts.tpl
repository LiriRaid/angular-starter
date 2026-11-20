import { ComponentFixture, TestBed } from '@angular/core/testing';

import { AsSelect } from './as-select';

const OPTIONS = [
  { label: 'Apple', value: 'a' },
  { label: 'Banana', value: 'b' },
  { label: 'Cherry', value: 'c' },
];

describe('AsSelect', () => {
  let fixture: ComponentFixture<AsSelect>;
  let component: AsSelect;

  beforeEach(async () => {
    TestBed.overrideComponent(AsSelect, { set: { imports: [], template: '' } });

    await TestBed.configureTestingModule({ imports: [AsSelect] }).compileComponents();

    fixture = TestBed.createComponent(AsSelect);
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
