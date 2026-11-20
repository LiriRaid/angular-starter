import { TestBed } from '@angular/core/testing';
import { HomeDetails } from './home-details';

describe('HomeDetails', () => {
  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [HomeDetails],
    }).compileComponents();
  });

  it('counts the clicks', async () => {
    const fixture = TestBed.createComponent(HomeDetails);
    await fixture.whenStable();
    const element = fixture.nativeElement as HTMLElement;
    const button = element.querySelector('button') as HTMLButtonElement;
    expect(button.textContent).toContain('Clicked 0 times');

    button.click();
    await fixture.whenStable();
    expect(button.textContent).toContain('Clicked 1 times');
  });
});
