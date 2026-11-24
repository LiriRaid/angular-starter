import { ComponentFixture, TestBed } from '@angular/core/testing';
import { describe, expect, it, vi, beforeEach } from 'vitest';
import { SaButton } from './sa-button';

describe('SaButton', () => {
  let fixture: ComponentFixture<SaButton>;
  let component: SaButton;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [SaButton],
    }).compileComponents();

    fixture = TestBed.createComponent(SaButton);
    component = fixture.componentInstance;
  });

  it('keeps width classes on the host and text classes on the label', () => {
    fixture.componentRef.setInput('styleClass', 'w-full text-caption-1-bold rounded-lg');
    fixture.detectChanges();

    expect(component.hostClass()).toBe('block w-full');
    expect(component.buttonClass()).toContain('rounded-lg');
    expect(component.buttonClass()).not.toContain('text-caption-1-bold');
    expect(component.computedLabelClass()).toContain('text-caption-1-bold');
  });

  it('emits the click event through the custom output', () => {
    const clickEvent = new MouseEvent('click');
    const emitSpy = vi.spyOn(component.onClick, 'emit');

    component.handleClick(clickEvent);

    expect(emitSpy).toHaveBeenCalledWith(clickEvent);
  });

  it('no emite aria-pressed por defecto y lo anuncia solo cuando el botón es de alternar', () => {
    fixture.detectChanges();
    const button = (): HTMLButtonElement => fixture.nativeElement.querySelector('button');
    expect(button().hasAttribute('aria-pressed')).toBe(false);

    fixture.componentRef.setInput('ariaPressed', true);
    fixture.detectChanges();
    expect(button().getAttribute('aria-pressed')).toBe('true');

    fixture.componentRef.setInput('ariaPressed', false);
    fixture.detectChanges();
    expect(button().getAttribute('aria-pressed')).toBe('false');
  });

  // ── isDisabled ──────────────────────────────────────────────────────────────

  it('isDisabled returns true when disabled input is true', () => {
    fixture.componentRef.setInput('disabled', true);
    fixture.detectChanges();

    expect(component.isDisabled()).toBe(true);
  });

  it('isDisabled returns true when loading input is true', () => {
    fixture.componentRef.setInput('loading', true);
    fixture.detectChanges();

    expect(component.isDisabled()).toBe(true);
  });

  it('isDisabled returns false when both disabled and loading are false', () => {
    fixture.componentRef.setInput('disabled', false);
    fixture.componentRef.setInput('loading', false);
    fixture.detectChanges();

    expect(component.isDisabled()).toBe(false);
  });

  // ── handleClick when disabled ───────────────────────────────────────────────

  it('handleClick does NOT emit when isDisabled is true (disabled input)', () => {
    fixture.componentRef.setInput('disabled', true);
    fixture.detectChanges();

    const emitSpy = vi.spyOn(component.onClick, 'emit');
    const clickEvent = new MouseEvent('click');
    component.handleClick(clickEvent);

    expect(emitSpy).not.toHaveBeenCalled();
  });

  it('handleClick does NOT emit when isDisabled is true (loading input)', () => {
    fixture.componentRef.setInput('loading', true);
    fixture.detectChanges();

    const emitSpy = vi.spyOn(component.onClick, 'emit');
    const clickEvent = new MouseEvent('click');
    component.handleClick(clickEvent);

    expect(emitSpy).not.toHaveBeenCalled();
  });

  // ── isIconOnly ──────────────────────────────────────────────────────────────

  it('isIconOnly is true when there is an icon and no label or badge', () => {
    fixture.componentRef.setInput('icon', 'Search');
    fixture.componentRef.setInput('label', '');
    fixture.componentRef.setInput('badge', null);
    fixture.detectChanges();

    expect(component.isIconOnly()).toBe(true);
  });

  it('isIconOnly is false when there is an icon and a label', () => {
    fixture.componentRef.setInput('icon', 'Search');
    fixture.componentRef.setInput('label', 'Buscar');
    fixture.detectChanges();

    expect(component.isIconOnly()).toBe(false);
  });

  it('isIconOnly is false when there is an icon and a badge', () => {
    fixture.componentRef.setInput('icon', 'Bell');
    fixture.componentRef.setInput('label', '');
    fixture.componentRef.setInput('badge', '3');
    fixture.detectChanges();

    expect(component.isIconOnly()).toBe(false);
  });

  // ── isOutlined ──────────────────────────────────────────────────────────────

  it('isOutlined is true when outlined input is true', () => {
    fixture.componentRef.setInput('outlined', true);
    fixture.detectChanges();

    expect(component.isOutlined()).toBe(true);
  });

  it('isOutlined is true when variant is "outlined"', () => {
    fixture.componentRef.setInput('variant', 'outlined');
    fixture.detectChanges();

    expect(component.isOutlined()).toBe(true);
  });

  it('isOutlined is false when neither outlined nor variant is set', () => {
    fixture.detectChanges();

    expect(component.isOutlined()).toBe(false);
  });

  it('rounded añade la clase de radio y sin él no cambia el borde por defecto', () => {
    fixture.detectChanges();
    expect(component.buttonClass()).not.toContain('sa-btn-r-');

    fixture.componentRef.setInput('rounded', 'lg');
    fixture.detectChanges();
    expect(component.buttonClass()).toContain('sa-btn-r-lg');

    fixture.componentRef.setInput('rounded', 'full');
    fixture.detectChanges();
    expect(component.buttonClass()).toContain('sa-btn-r-full');
    expect(component.buttonClass()).not.toContain('sa-btn-r-lg');
  });
});
