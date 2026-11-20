import { ComponentFixture, TestBed } from '@angular/core/testing';
import { AsIconsSVG } from '@core/common/icons/as-icons';
import { AsIcon } from './as-icon';

describe('AsIcon', () => {
  let fixture: ComponentFixture<AsIcon>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [AsIcon],
    }).compileComponents();
  });

  it('renders a Lucide svg when the icon name maps to the registry', () => {
    fixture = TestBed.createComponent(AsIcon);
    fixture.componentRef.setInput('name', 'Home');
    fixture.detectChanges();

    const iconElement = fixture.nativeElement.querySelector('svg');

    expect(iconElement).not.toBeNull();
    expect(iconElement.getAttribute('width')).toBe('20');
  });

  it('renders a single SVG image reference when the icon name maps to a colored local asset', () => {
    AsIconsSVG.push({ name: 'Demo', url: 'assets/svg/demo.svg', colored: true });
    fixture = TestBed.createComponent(AsIcon);
    fixture.componentRef.setInput('name', 'Demo');
    fixture.detectChanges();

    const imageElement = fixture.nativeElement.querySelector('image');
    const htmlImageElement = fixture.nativeElement.querySelector('img');

    expect(imageElement).not.toBeNull();
    expect(imageElement.getAttribute('href')).toContain('assets/svg/demo.svg');
    expect(htmlImageElement).toBeNull();
    AsIconsSVG.pop();
  });
});
