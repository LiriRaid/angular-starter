import { ComponentFixture, TestBed } from '@angular/core/testing';
import { describe, expect, it, beforeEach } from 'vitest';
import { AsAvatar } from './as-avatar';
import { ComponentRef } from '@angular/core';

type AsAvatarInternals = {
  radius: () => string;
  initialsClass: () => string;
  resolvedDotSize: () => string;
  resolvedDotIconSize: () => number;
  dotIcon: () => string | null;
};

describe('AsAvatar', () => {
  let fixture: ComponentFixture<AsAvatar>;
  let component: AsAvatar;
  let internals: AsAvatarInternals;
  let ref: ComponentRef<AsAvatar>;

  beforeEach(async () => {
    TestBed.overrideComponent(AsAvatar, { set: { imports: [], template: '' } });

    await TestBed.configureTestingModule({
      imports: [AsAvatar],
    }).compileComponents();

    fixture = TestBed.createComponent(AsAvatar);
    component = fixture.componentInstance;
    internals = component as unknown as AsAvatarInternals;
    ref = fixture.componentRef;
    fixture.detectChanges();
  });

  it('radius is 9999px for circle shape', () => {
    ref.setInput('shape', 'circle');
    fixture.detectChanges();
    expect(internals.radius()).toBe('9999px');
  });

  it('radius is proportional to size for rounded shape', () => {
    ref.setInput('shape', 'rounded');
    ref.setInput('size', 40);
    fixture.detectChanges();
    expect(internals.radius()).toBe(`${Math.round(40 * 0.28)}px`);
  });

  it('initialsClass includes the textClass input', () => {
    ref.setInput('textClass', 'text-caption-1-bold');
    fixture.detectChanges();
    expect(internals.initialsClass()).toContain('text-caption-1-bold');
  });

  it('resolvedDotSize/resolvedDotIconSize use the small bucket for size <= 40', () => {
    ref.setInput('size', 40);
    fixture.detectChanges();
    expect(internals.resolvedDotSize()).toBe('0.875rem');
    expect(internals.resolvedDotIconSize()).toBe(10);
  });

  it('resolvedDotSize/resolvedDotIconSize use the large bucket for size > 40', () => {
    ref.setInput('size', 42);
    fixture.detectChanges();
    expect(internals.resolvedDotSize()).toBe('1rem');
    expect(internals.resolvedDotIconSize()).toBe(12);
  });

  it('dotSize/dotIconSize inputs override the computed bucket', () => {
    ref.setInput('size', 40);
    ref.setInput('dotSize', '1.75rem');
    ref.setInput('dotIconSize', 20);
    fixture.detectChanges();
    expect(internals.resolvedDotSize()).toBe('1.75rem');
    expect(internals.resolvedDotIconSize()).toBe(20);
  });

  it('dotIcon resolves the status icon, null for online', () => {
    ref.setInput('presenceStatus', 'busy');
    fixture.detectChanges();
    expect(internals.dotIcon()).toBe('CircleMinus');

    ref.setInput('presenceStatus', 'online');
    fixture.detectChanges();
    expect(internals.dotIcon()).toBeNull();
  });
});
