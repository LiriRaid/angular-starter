import { SecurityContext } from '@angular/core';
import { ComponentFixture, TestBed } from '@angular/core/testing';
import { DomSanitizer } from '@angular/platform-browser';

import { SaMediaPreview } from './sa-media-preview';

function srcFor(fixture: ComponentFixture<SaMediaPreview>, url: string): string | null {
  fixture.componentRef.setInput('url', url);
  return TestBed.inject(DomSanitizer).sanitize(SecurityContext.RESOURCE_URL, fixture.componentInstance.safeUrl());
}

describe('SaMediaPreview', () => {
  let fixture: ComponentFixture<SaMediaPreview>;
  let component: SaMediaPreview;

  beforeEach(async () => {
    await TestBed.configureTestingModule({ imports: [SaMediaPreview] }).compileComponents();
    fixture = TestBed.createComponent(SaMediaPreview);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('una URL https o http llega tal cual al visor', () => {
    expect(srcFor(fixture, 'https://bucket.example.com/archivo.pdf')).toBe('https://bucket.example.com/archivo.pdf');
    expect(srcFor(fixture, 'http://localhost:9000/archivo.pdf')).toBe('http://localhost:9000/archivo.pdf');
  });

  it.each(['javascript:alert(1)', 'data:text/html,<script>alert(1)</script>', 'ftp://host/archivo.pdf', ''])('«%s» no llega al iframe: queda en blanco', (url) => {
    expect(srcFor(fixture, url)).toBe('about:blank');
  });

  it('close() pone visible en false', () => {
    component.visible.set(true);
    component.close();
    expect(component.visible()).toBe(false);
  });

  it('download() trae el archivo como blob (para forzar la descarga real en otro origen) y limpia el object URL', async () => {
    const blob = new Blob(['fake'], { type: 'image/png' });
    vi.stubGlobal('fetch', vi.fn().mockResolvedValue({ blob: () => Promise.resolve(blob) } as Response));
    vi.useFakeTimers();
    const createObjectUrlSpy = vi.fn((_: Blob) => 'blob:preview');
    const revokeObjectUrlSpy = vi.fn();
    Object.defineProperty(URL, 'createObjectURL', { configurable: true, writable: true, value: createObjectUrlSpy });
    Object.defineProperty(URL, 'revokeObjectURL', { configurable: true, writable: true, value: revokeObjectUrlSpy });
    const clickSpy = vi.spyOn(HTMLAnchorElement.prototype, 'click').mockImplementation(() => {});

    fixture.componentRef.setInput('url', 'https://cdn.example/img.png');
    fixture.componentRef.setInput('fileName', 'foto.png');
    await component.download();

    expect(createObjectUrlSpy).toHaveBeenCalledTimes(1);
    expect(createObjectUrlSpy.mock.calls[0][0].type).toBe('image/png');
    expect(clickSpy).toHaveBeenCalled();
    expect(revokeObjectUrlSpy).not.toHaveBeenCalled();
    vi.runAllTimers();
    expect(revokeObjectUrlSpy).toHaveBeenCalledWith('blob:preview');
    vi.useRealTimers();
  });

  it.each(['javascript:alert(1)', 'data:text/html,<script>alert(1)</script>', ''])('download() no abre «%s» en una ventana aunque el fetch falle', async (url) => {
    vi.stubGlobal('fetch', vi.fn().mockRejectedValue(new Error('unsupported scheme')));
    const openSpy = vi.fn();
    vi.stubGlobal('open', openSpy);
    fixture.componentRef.setInput('url', url);

    await component.download();

    expect(openSpy).not.toHaveBeenCalled();
  });

  it('download() cae a window.open si el fetch falla', async () => {
    vi.stubGlobal('fetch', vi.fn().mockRejectedValue(new Error('network')));
    const openSpy = vi.fn();
    vi.stubGlobal('open', openSpy);
    fixture.componentRef.setInput('url', 'https://cdn.example/img.png');

    await component.download();

    expect(openSpy).toHaveBeenCalledWith('https://cdn.example/img.png', '_blank');
  });
});
