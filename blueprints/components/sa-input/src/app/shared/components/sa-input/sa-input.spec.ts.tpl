import { ComponentFixture, TestBed } from '@angular/core/testing';
import { AsInput } from './as-input';

describe('AsInput', () => {
  let fixture: ComponentFixture<AsInput>;
  let component: AsInput;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [AsInput],
    }).compileComponents();

    fixture = TestBed.createComponent(AsInput);
    component = fixture.componentInstance;
  });

  it('writes and emits plain input values through the ControlValueAccessor contract', () => {
    const onChange = vi.fn();
    const valueChangeSpy = vi.spyOn(component.valueChange, 'emit');
    component.registerOnChange(onChange);

    component.writeValue('hello');
    fixture.detectChanges();

    expect(component.displayValue()).toBe('hello');

    component.onInput({ target: { value: 'updated' } } as unknown as Event);

    expect(component.displayValue()).toBe('updated');
    expect(onChange).toHaveBeenCalledWith('updated');
    expect(valueChangeSpy).toHaveBeenCalledWith('updated');
  });

  it('formats price values for display while preserving the raw control value while typing', () => {
    fixture.componentRef.setInput('type', 'price');
    component.writeValue('12345.67');
    fixture.detectChanges();

    expect(component.displayValue()).toBe('12,345.67');

    component.onFocusInput();

    expect(component.displayValue()).toBe('12345.67');
  });

  describe('type="number"', () => {
    const typed = (value: string): Event => ({ target: { value } }) as unknown as Event;

    beforeEach(() => {
      fixture.componentRef.setInput('type', 'number');
      fixture.componentRef.setInput('showStepper', true);
      fixture.componentRef.setInput('step', 0.5);
      fixture.componentRef.setInput('min', 0);
      fixture.componentRef.setInput('max', 3);
      fixture.detectChanges();
    });

    it('se dibuja como texto y conserva "1." mientras se escribe, sin que el navegador borre el valor', () => {
      const onChange = vi.fn();
      component.registerOnChange(onChange);

      component.onInput(typed('1.'));

      expect(component.inputType()).toBe('text');
      expect(component.displayValue()).toBe('1.');
      expect(onChange).toHaveBeenCalledWith('1.');
    });

    it('descarta lo que no es número al escribir', () => {
      component.onInput(typed('-1a2;5'));

      expect(component.displayValue()).toBe('-125');
    });

    it('stepValue suma el paso directo (1.5 → 2.0) y respeta max y min', () => {
      const onChange = vi.fn();
      component.registerOnChange(onChange);
      component.writeValue('1.5');

      component.stepValue(1);
      expect(onChange).toHaveBeenLastCalledWith('2');

      component.stepValue(1);
      component.stepValue(1);
      expect(onChange).toHaveBeenLastCalledWith('3');

      component.writeValue('0');
      component.stepValue(-1);
      expect(onChange).toHaveBeenLastCalledWith('0');
    });

    it('stepValue no hace nada si el campo está deshabilitado', () => {
      const onChange = vi.fn();
      component.registerOnChange(onChange);
      component.setDisabledState(true);

      component.stepValue(1);

      expect(onChange).not.toHaveBeenCalled();
    });

    it('↑/↓ pasan por stepValue y no por el stepUp() nativo', () => {
      component.writeValue('1');
      const up = new KeyboardEvent('keydown', { key: 'ArrowUp', cancelable: true });
      const down = new KeyboardEvent('keydown', { key: 'ArrowDown', cancelable: true });

      component.onNumberKeydown(up);
      expect(up.defaultPrevented).toBe(true);
      expect(component.displayValue()).toBe('1.5');

      component.onNumberKeydown(down);
      expect(down.defaultPrevented).toBe(true);
      expect(component.displayValue()).toBe('1');
    });

    it('otras teclas no se interceptan', () => {
      const enter = new KeyboardEvent('keydown', { key: 'Enter', cancelable: true });

      component.onNumberKeydown(enter);

      expect(enter.defaultPrevented).toBe(false);
    });

    it('la rueda solo mueve el valor con el campo enfocado: sin foco deja pasar el scroll de la página', () => {
      component.writeValue('1');
      const wheelUp = new WheelEvent('wheel', { deltaY: -10, cancelable: true });

      component.onNumberWheel(wheelUp);
      expect(wheelUp.defaultPrevented).toBe(false);
      expect(component.displayValue()).toBe('1');

      component.onFocusInput();
      component.onNumberWheel(wheelUp);
      expect(wheelUp.defaultPrevented).toBe(true);
      expect(component.displayValue()).toBe('1.5');
    });

    it('sin showStepper las flechas y la rueda siguen funcionando (como el input nativo) pero no se dibujan los botones', () => {
      fixture.componentRef.setInput('showStepper', false);
      fixture.detectChanges();
      component.writeValue('1');
      component.onFocusInput();
      const up = new KeyboardEvent('keydown', { key: 'ArrowUp', cancelable: true });

      component.onNumberKeydown(up);
      expect(up.defaultPrevented).toBe(true);
      expect(component.displayValue()).toBe('1.5');

      component.onNumberWheel(new WheelEvent('wheel', { deltaY: 10, cancelable: true }));
      expect(component.displayValue()).toBe('1');
      expect(fixture.nativeElement.querySelector('.as-input-stepper-btn')).toBeNull();
    });

    it('en un input que no es numérico ni ↑/↓ ni la rueda se interceptan', () => {
      fixture.componentRef.setInput('type', 'text');
      fixture.detectChanges();
      component.writeValue('1');
      component.onFocusInput();
      const up = new KeyboardEvent('keydown', { key: 'ArrowUp', cancelable: true });
      const wheel = new WheelEvent('wheel', { deltaY: -10, cancelable: true });

      component.onNumberKeydown(up);
      component.onNumberWheel(wheel);

      expect(up.defaultPrevented).toBe(false);
      expect(wheel.defaultPrevented).toBe(false);
      expect(component.displayValue()).toBe('1');
    });

    it('la coma decimal se toma como punto al escribir', () => {
      component.onInput(typed('2,5'));

      expect(component.displayValue()).toBe('2.5');
    });

    it('con showStepper se renderizan los botones Aumentar y Disminuir', () => {
      const labels = Array.from(fixture.nativeElement.querySelectorAll('.as-input-stepper-btn')).map((button) => (button as HTMLElement).getAttribute('aria-label'));

      expect(labels).toEqual(['Aumentar', 'Disminuir']);
    });
  });

  it('adds unique tags and emits the updated tag list', () => {
    fixture.componentRef.setInput('isTagInput', true);
    const onChange = vi.fn();
    const tagsChangeSpy = vi.spyOn(component.tagsChange, 'emit');
    component.registerOnChange(onChange);

    component.onInput({ target: { value: ' ventas ' } } as unknown as Event);
    component.addTag();
    component.onInput({ target: { value: 'ventas' } } as unknown as Event);
    component.addTag();

    expect(component.tags()).toEqual(['ventas']);
    expect(onChange).toHaveBeenCalledWith(['ventas']);
    expect(tagsChangeSpy).toHaveBeenCalledWith(['ventas']);
  });

  it('removes tags and emits the remaining tag list', () => {
    fixture.componentRef.setInput('isTagInput', true);
    const tagsChangeSpy = vi.spyOn(component.tagsChange, 'emit');

    component.writeValue(['ventas', 'soporte']);
    component.removeTag(0);

    expect(component.tags()).toEqual(['soporte']);
    expect(tagsChangeSpy).toHaveBeenCalledWith(['soporte']);
  });

  it('only emits icon clicks when the icon is clickable and enabled', () => {
    const iconClickSpy = vi.spyOn(component.iconClick, 'emit');
    const clickEvent = new MouseEvent('click');

    component.onIconClick(clickEvent);
    expect(iconClickSpy).not.toHaveBeenCalled();

    fixture.componentRef.setInput('iconClickable', true);
    fixture.detectChanges();

    component.onIconClick(clickEvent);
    expect(iconClickSpy).toHaveBeenCalledWith(clickEvent);

    component.setDisabledState(true);
    component.onIconClick(clickEvent);

    expect(iconClickSpy).toHaveBeenCalledTimes(1);
  });

  describe('isTagInput con label', () => {
    const label = (): HTMLLabelElement => fixture.nativeElement.querySelector('label');

    beforeEach(() => {
      fixture.componentRef.setInput('isTagInput', true);
      fixture.componentRef.setInput('label', 'Etiquetas');
    });

    it('en `over` el label vive arriba del campo, no dentro, y no pinta una caja oscura propia', () => {
      fixture.componentRef.setInput('variant', 'over');
      fixture.detectChanges();

      expect(label().classList.contains('-top-4.5')).toBe(true);
      expect(label().classList.contains('top-1/2')).toBe(false);
      expect(label().classList.contains('bg-(--app-panel-bg)')).toBe(false);
      expect(label().style.backgroundColor).toBe('transparent');
    });

    it('en `in` el label queda dentro, arriba, y el campo le deja sitio como el input', () => {
      fixture.componentRef.setInput('variant', 'in');
      fixture.detectChanges();
      const box: HTMLElement = fixture.nativeElement.querySelector('.as-input-tags');

      expect(label().classList.contains('bg-(--app-panel-bg)')).toBe(false);
      expect(box.style.paddingTop).toBe('1.3125rem');
    });

    it('el fondo del label se redondea arriba y abajo en todos los campos de texto', () => {
      fixture.componentRef.setInput('variant', 'over');
      fixture.detectChanges();
      expect(label().classList.contains('rounded-md')).toBe(true);
      expect(label().classList.contains('rounded-bl-none')).toBe(false);
    });
  });
});
