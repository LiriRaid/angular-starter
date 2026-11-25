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

  describe('fill', () => {
    const render = (inputs: Record<string, unknown>): SVGElement => {
      fixture = TestBed.createComponent(SaIcon);
      fixture.componentRef.setInput('name', 'Star');
      for (const [name, value] of Object.entries(inputs)) fixture.componentRef.setInput(name, value);
      fixture.detectChanges();
      return fixture.nativeElement.querySelector('svg');
    };

    it('leaves the inside of the icon empty by default, so it is only a stroke', () => {
      expect(render({}).style.fill).toBe('');
    });

    it('fills the icon with the colour of its stroke when it is filled', () => {
      expect(render({ filled: true }).style.fill.toLowerCase()).toBe('currentcolor');
    });

    it('fills it with a colour of its own, apart from the stroke, when it has fillColor', () => {
      const svg = render({ color: 'red', fillColor: 'gold' });
      expect(svg.style.fill).toBe('gold');
      expect(fixture.nativeElement.style.color).toBe('red');
    });

    it('lets fillColor win over filled', () => {
      expect(render({ filled: true, fillColor: 'gold' }).style.fill).toBe('gold');
    });
  });
});
