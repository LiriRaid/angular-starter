import { TestBed } from '@angular/core/testing';
import { __CLASS__ } from './__NAME__';

describe('__CLASS__', () => {
  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [__CLASS__],
    }).compileComponents();
  });

  it('should create', () => {
    const fixture = TestBed.createComponent(__CLASS__);
    expect(fixture.componentInstance).toBeTruthy();
  });
});
