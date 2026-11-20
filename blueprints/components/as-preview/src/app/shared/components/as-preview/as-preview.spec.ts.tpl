import { ComponentFixture, TestBed } from '@angular/core/testing';
import { describe, expect, it, vi } from 'vitest';

import { AsPreview } from './as-preview';

async function setup(): Promise<{ fixture: ComponentFixture<AsPreview>; component: AsPreview }> {
  await TestBed.configureTestingModule({
    imports: [AsPreview],
  }).compileComponents();

  const fixture = TestBed.createComponent(AsPreview);
  const component = fixture.componentInstance;
  fixture.detectChanges();

  return { fixture, component };
}

describe('AsPreview', () => {
  it('creates the component', async () => {
    const { component } = await setup();
    expect(component).toBeTruthy();
  });

  it('onBoxClick abre el file picker cuando no hay imagen', async () => {
    const { fixture, component } = await setup();
    const input: HTMLInputElement = fixture.nativeElement.querySelector('input[type="file"]');
    const clickSpy = vi.spyOn(input, 'click');
    component.onBoxClick();
    expect(clickSpy).toHaveBeenCalled();
  });

  it('onBoxClick abre la vista previa cuando ya hay imagen', async () => {
    const { fixture, component } = await setup();
    fixture.componentRef.setInput('imageUrl', 'data:image/png;base64,abc');
    fixture.detectChanges();
    expect(component.isPreviewOpen()).toBe(false);
    component.onBoxClick();
    expect(component.isPreviewOpen()).toBe(true);
  });

  it('onBoxClick abre la vista previa aunque esté deshabilitado, si ya hay imagen', async () => {
    const { fixture, component } = await setup();
    fixture.componentRef.setInput('imageUrl', 'data:image/png;base64,abc');
    fixture.componentRef.setInput('disabled', true);
    fixture.detectChanges();
    component.onBoxClick();
    expect(component.isPreviewOpen()).toBe(true);
  });

  it('onBoxClick no abre el file picker cuando está deshabilitado y no hay imagen', async () => {
    const { fixture, component } = await setup();
    fixture.componentRef.setInput('disabled', true);
    fixture.detectChanges();
    const input: HTMLInputElement = fixture.nativeElement.querySelector('input[type="file"]');
    const clickSpy = vi.spyOn(input, 'click');
    component.onBoxClick();
    expect(clickSpy).not.toHaveBeenCalled();
  });

  it('onFileInputChange emite fileSelected con el archivo elegido', async () => {
    const { component } = await setup();
    const spy = vi.spyOn(component.fileSelected, 'emit');
    const file = new File(['x'], 'logo.png', { type: 'image/png' });
    const event = { target: { files: [file], value: '' } } as unknown as Event;
    component.onFileInputChange(event);
    expect(spy).toHaveBeenCalledWith(file);
  });

  it('onRemoveClick emite removed y detiene la propagación', async () => {
    const { component } = await setup();
    const spy = vi.spyOn(component.removed, 'emit');
    const event = { stopPropagation: vi.fn() } as unknown as MouseEvent;
    component.onRemoveClick(event);
    expect(event.stopPropagation).toHaveBeenCalled();
    expect(spy).toHaveBeenCalled();
  });

  it('closePreview oculta la vista previa', async () => {
    const { component } = await setup();
    component.isPreviewOpen.set(true);
    component.closePreview();
    expect(component.isPreviewOpen()).toBe(false);
  });
});
