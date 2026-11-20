import { TestBed } from '@angular/core/testing';
import { Users } from './users';

describe('Users', () => {
  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [Users],
    }).compileComponents();
  });

  it('lists one row per user', async () => {
    const fixture = TestBed.createComponent(Users);
    await fixture.whenStable();
    const compiled = fixture.nativeElement as HTMLElement;
    expect(compiled.querySelector('h1')?.textContent).toContain('Users');
    expect(compiled.querySelectorAll('tbody tr')).toHaveLength(fixture.componentInstance.users.length);
  });

  it('builds the initials of a name', () => {
    const fixture = TestBed.createComponent(Users);
    expect(fixture.componentInstance.initials('maria lopez')).toBe('ML');
    expect(fixture.componentInstance.initials('Ana')).toBe('A');
  });
});
