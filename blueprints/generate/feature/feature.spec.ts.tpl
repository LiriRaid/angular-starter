import { TestBed } from '@angular/core/testing';
import { __CLASS__ } from './__NAME__';

describe('__CLASS__', () => {
  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [__CLASS__],
    }).compileComponents();
  });

  it('should render its title', async () => {
    const fixture = TestBed.createComponent(__CLASS__);
    await fixture.whenStable();
    const compiled = fixture.nativeElement as HTMLElement;
    expect(compiled.querySelector('h1')?.textContent).toContain('__TITLE__');
  });
});
