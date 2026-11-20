import { TestBed } from '@angular/core/testing';
import { Dashboard } from './dashboard';

describe('Dashboard', () => {
  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [Dashboard],
    }).compileComponents();
  });

  it('shows one card per metric and the latest activity', async () => {
    const fixture = TestBed.createComponent(Dashboard);
    await fixture.whenStable();
    const compiled = fixture.nativeElement as HTMLElement;
    expect(compiled.querySelector('h1')?.textContent).toContain('Dashboard');
    expect(compiled.querySelectorAll('article')).toHaveLength(fixture.componentInstance.metrics.length);
    expect(compiled.querySelectorAll('li')).toHaveLength(fixture.componentInstance.activity.length);
  });
});
