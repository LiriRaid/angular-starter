import { TestBed } from '@angular/core/testing';
import { Reports } from './reports';

describe('Reports', () => {
  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [Reports],
    }).compileComponents();
  });

  it('shows one card per report', async () => {
    const fixture = TestBed.createComponent(Reports);
    await fixture.whenStable();
    const compiled = fixture.nativeElement as HTMLElement;
    expect(compiled.querySelector('h1')?.textContent).toContain('Reports');
    expect(compiled.querySelectorAll('article')).toHaveLength(fixture.componentInstance.reports.length);
  });
});
