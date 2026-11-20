import { Component } from '@angular/core';
import { ComponentFixture, TestBed } from '@angular/core/testing';
import { By } from '@angular/platform-browser';
import { beforeEach, describe, expect, it } from 'vitest';

import { AsTooltip } from './as-tooltip.directive';

@Component({
  template: '<button asTooltip="Detalle">Ver detalle</button>',
  imports: [AsTooltip],
})
class TooltipHost {}

describe('AsTooltip', () => {
  let fixture: ComponentFixture<TooltipHost>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({ imports: [TooltipHost] }).compileComponents();
    fixture = TestBed.createComponent(TooltipHost);
    fixture.detectChanges();
  });

  it('habilita la directiva con una única importación', () => {
    const directive = fixture.debugElement.query(By.directive(AsTooltip)).injector.get(AsTooltip);

    expect(directive.content()).toBe('Detalle');
  });

  it('renderiza el panel desde su template HTML', async () => {
    const button = fixture.nativeElement.querySelector('button') as HTMLButtonElement;
    button.dispatchEvent(new Event('mouseenter'));
    await new Promise((resolve) => setTimeout(resolve));

    expect(document.querySelector<HTMLElement>('[role="tooltip"]')?.textContent).toContain('Detalle');

    button.dispatchEvent(new Event('mouseleave'));
    expect(document.querySelector('[role="tooltip"]')).toBeNull();
  });
});
