import { ComponentFixture, TestBed } from '@angular/core/testing';
import { provideRouter } from '@angular/router';
import { Empty } from './empty';

describe('Empty', () => {
  let fixture: ComponentFixture<Empty>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [Empty],
      providers: [provideRouter([])],
    }).compileComponents();

    fixture = TestBed.createComponent(Empty);
    fixture.detectChanges();
  });

  it('renders a router outlet for pages without the layout', () => {
    expect(fixture.nativeElement.querySelector('router-outlet')).not.toBeNull();
  });
});
