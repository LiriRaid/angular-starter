import { ComponentFixture, TestBed } from '@angular/core/testing';
import { describe, expect, it, beforeEach } from 'vitest';
import { SaAvatar } from './sa-avatar';
import { ComponentRef } from '@angular/core';

type SaAvatarInternals = {
  radius: () => string;
  initialsClass: () => string;
  initialsFontSize: () => string | null;
  resolvedDotSize: () => string;
  resolvedDotIconSize: () => number;
  dotIcon: () => string | null;
};

describe('SaAvatar', () => {
  let fixture: ComponentFixture<SaAvatar>;
  let component: SaAvatar;
  let internals: SaAvatarInternals;
  let ref: ComponentRef<SaAvatar>;

  beforeEach(async () => {
    TestBed.overrideComponent(SaAvatar, { set: { imports: [], template: '' } });

    await TestBed.configureTestingModule({
      imports: [SaAvatar],
    }).compileComponents();

    fixture = TestBed.createComponent(SaAvatar);
    component = fixture.componentInstance;
    internals = component as unknown as SaAvatarInternals;
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

  describe('the size of the initials', () => {
    const classAt = (size: number): string => {
      ref.setInput('size', size);
      fixture.detectChanges();
      return internals.initialsClass();
    };
    /** The font size, in px, that the Tailwind class of the initials stands for. */
    const pixelsOf = (classes: string): number => {
      const sizes: Record<string, number> = { 'text-xs': 12, 'text-sm': 14, 'text-base': 16, 'text-lg': 18, 'text-xl': 20, 'text-2xl': 24, 'text-3xl': 30, 'text-4xl': 36, 'text-5xl': 48 };
      const arbitrary = /text-\[(\d+)px\]/.exec(classes);
      if (arbitrary) return Number(arbitrary[1]);
      const named = classes.split(' ').find((token) => token in sizes);
      if (!named) throw new Error(`no size class in "${classes}"`);
      return sizes[named];
    };

    it('grows with the avatar: the larger the circle, the larger the letters', () => {
      const sizes = [20, 24, 28, 32, 40, 48, 56, 64, 80, 96, 128];
      const pixels = sizes.map((size) => pixelsOf(classAt(size)));
      for (let index = 1; index < pixels.length; index += 1) {
        expect(pixels[index], `${sizes[index]}px`).toBeGreaterThanOrEqual(pixels[index - 1]);
      }
      expect(pixels[0]).toBeLessThan(pixels[pixels.length - 1]);
    });

    it('keeps the letters about a third of the avatar, from the smallest to the largest', () => {
      for (const size of [24, 32, 40, 56, 80, 96]) {
        const ratio = pixelsOf(classAt(size)) / size;
        expect(ratio, `${size}px`).toBeGreaterThan(0.3);
        expect(ratio, `${size}px`).toBeLessThan(0.45);
      }
    });

    it('uses an arbitrary size when the avatar is too small for any named Tailwind size', () => {
      expect(classAt(24)).toContain('text-[9px]');
      expect(classAt(20)).toContain('text-[8px]');
    });

    it('uses the named Tailwind sizes for the usual avatars', () => {
      expect(classAt(32)).toContain('text-xs');
      expect(classAt(40)).toContain('text-sm');
      expect(classAt(56)).toContain('text-xl');
    });

    it('does not carry a fixed caption size any more', () => {
      expect(classAt(24)).not.toContain('text-caption');
      expect(classAt(56)).not.toContain('text-caption');
    });

    it('leaves a size of text the consumer gives, and keeps the rest of its classes', () => {
      ref.setInput('size', 56);
      ref.setInput('textClass', 'text-caption-2-bold tracking-wide');
      fixture.detectChanges();
      expect(internals.initialsClass()).toContain('text-caption-2-bold');
      expect(internals.initialsClass()).toContain('tracking-wide');
      expect(internals.initialsClass()).not.toContain('text-xl');
    });

    it('keeps the proportional size when the consumer only adds a weight or a spacing', () => {
      ref.setInput('size', 40);
      ref.setInput('textClass', 'tracking-wide');
      fixture.detectChanges();
      expect(internals.initialsClass()).toContain('tracking-wide');
      expect(internals.initialsClass()).toContain('text-sm');
    });

    it('scales a size given in CSS from that same size', () => {
      ref.setInput('cssSize', '3.5rem');
      fixture.detectChanges();
      expect(internals.initialsFontSize()).toBe('calc(3.5rem * 0.38)');
      expect(internals.initialsClass()).not.toMatch(/text-(xs|sm|base|lg|\d?xl|\[)/);
    });

    it('takes no inline size when the avatar is sized in pixels, so the class is the one that decides', () => {
      ref.setInput('size', 40);
      fixture.detectChanges();
      expect(internals.initialsFontSize()).toBeNull();
    });
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
