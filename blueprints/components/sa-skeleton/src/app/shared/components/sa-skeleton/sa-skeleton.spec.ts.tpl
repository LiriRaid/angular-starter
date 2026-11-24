import { ComponentFixture, TestBed } from '@angular/core/testing';
import { describe, expect, it, beforeEach } from 'vitest';
import { ComponentRef } from '@angular/core';
import { SaSkeleton } from './sa-skeleton';

type SaSkeletonInternals = {
  resolvedRadius: () => string;
  lineClass: () => string;
  fillWidth: () => string;
  fillHeight: () => string;
};

describe('SaSkeleton', () => {
  let fixture: ComponentFixture<SaSkeleton>;
  let component: SaSkeleton;
  let internals: SaSkeletonInternals;
  let ref: ComponentRef<SaSkeleton>;

  beforeEach(async () => {
    TestBed.overrideComponent(SaSkeleton, { set: { imports: [], template: '' } });

    await TestBed.configureTestingModule({
      imports: [SaSkeleton],
    }).compileComponents();

    fixture = TestBed.createComponent(SaSkeleton);
    component = fixture.componentInstance;
    internals = component as unknown as SaSkeletonInternals;
    ref = fixture.componentRef;
    fixture.detectChanges();
  });

  it('creates the component', () => {
    expect(component).toBeTruthy();
  });

  it('resolvedRadius returns the radius input for rectangles', () => {
    ref.setInput('radius', '1rem');
    fixture.detectChanges();
    expect(internals.resolvedRadius()).toBe('1rem');
  });

  it('resolvedRadius returns 50% when shape is circle', () => {
    ref.setInput('shape', 'circle');
    fixture.detectChanges();
    expect(internals.resolvedRadius()).toBe('50%');
  });

  it('lineClass combines base class with textClass input', () => {
    ref.setInput('textClass', 'text-body-2');
    fixture.detectChanges();
    expect(internals.lineClass()).toContain('text-body-2');
    expect(internals.lineClass()).toContain('sa-skeleton-line');
  });

  it('fillWidth returns 100% when fill is true', () => {
    ref.setInput('fill', true);
    fixture.detectChanges();
    expect(internals.fillWidth()).toBe('100%');
  });

  it('fillWidth returns the width input when fill is false', () => {
    ref.setInput('fill', false);
    ref.setInput('width', '200px');
    fixture.detectChanges();
    expect(internals.fillWidth()).toBe('200px');
  });

  it('fillHeight returns 100% when fill is true', () => {
    ref.setInput('fill', true);
    fixture.detectChanges();
    expect(internals.fillHeight()).toBe('100%');
  });
});
