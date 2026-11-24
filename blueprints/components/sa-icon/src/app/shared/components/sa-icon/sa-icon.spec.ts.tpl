import { ComponentFixture, TestBed } from '@angular/core/testing';
import { SaIconsSVG } from '@core/common/icons/sa-icons';
import { SaIcon } from './sa-icon';

describe('SaIcon', () => {
  let fixture: ComponentFixture<SaIcon>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [SaIcon],
    }).compileComponents();
  });

  it('renders a Lucide svg when the icon name maps to the registry', () => {
    fixture = TestBed.createComponent(SaIcon);
    fixture.componentRef.setInput('name', 'Home');
    fixture.detectChanges();

    const iconElement = fixture.nativeElement.querySelector('svg');

    expect(iconElement).not.toBeNull();
    expect(iconElement.getAttribute('width')).toBe('20');
  });

  it('renders a single SVG image reference when the icon name maps to a colored local asset', () => {
    SaIconsSVG.push({ name: 'Demo', url: 'assets/svg/demo.svg', colored: true });
    fixture = TestBed.createComponent(SaIcon);
    fixture.componentRef.setInput('name', 'Demo');
    fixture.detectChanges();

    const imageElement = fixture.nativeElement.querySelector('image');
    const htmlImageElement = fixture.nativeElement.querySelector('img');

    expect(imageElement).not.toBeNull();
    expect(imageElement.getAttribute('href')).toContain('assets/svg/demo.svg');
    expect(htmlImageElement).toBeNull();
    SaIconsSVG.pop();
  });
});
