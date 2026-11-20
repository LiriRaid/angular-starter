import { TestBed } from '@angular/core/testing';
import { provideAsIcons } from '@core/icons/icons.provider';
import { AsMediaPreview } from './as-media-preview';

describe('AsMediaPreview', () => {
  function render(inputs: Record<string, unknown>) {
    TestBed.configureTestingModule({ imports: [AsMediaPreview], providers: [provideAsIcons()] });
    const fixture = TestBed.createComponent(AsMediaPreview);
    for (const [key, value] of Object.entries(inputs)) fixture.componentRef.setInput(key, value);
    fixture.detectChanges();
    return fixture.nativeElement as HTMLElement;
  }

  it('shows an image with the file name as its text', () => {
    const element = render({ kind: 'image', url: '/photos/ada.png', fileName: 'Ada' });
    const image = element.querySelector('img');
    expect(image?.getAttribute('src')).toBe('/photos/ada.png');
    expect(image?.getAttribute('alt')).toBe('Ada');
  });

  it('shows a video and an audio player with controls', () => {
    expect(render({ kind: 'video', url: '/v.mp4' }).querySelector('video')?.hasAttribute('controls')).toBe(true);
    TestBed.resetTestingModule();
    expect(render({ kind: 'audio', url: '/a.mp3' }).querySelector('audio')?.hasAttribute('controls')).toBe(true);
  });

  it('shows a download card for any other document', () => {
    const element = render({ kind: 'document', url: '/files/report.pdf' });
    const link = element.querySelector('a');
    expect(link?.getAttribute('href')).toBe('/files/report.pdf');
    expect(link?.getAttribute('download')).toBe('report.pdf');
    expect(element.textContent).toContain('report.pdf');
  });
});
