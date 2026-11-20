import { TestBed } from '@angular/core/testing';
import { DOCUMENT } from '@angular/common';
import { describe, expect, it, vi, beforeEach, afterEach } from 'vitest';
import { ThemeService } from './theme.service';

describe('ThemeService', () => {
  let service: ThemeService;
  let document: Document;

  beforeEach(() => {
    vi.spyOn(window, 'requestAnimationFrame').mockImplementation((cb) => {
      cb(0);
      return 0;
    });
    localStorage.clear();

    TestBed.configureTestingModule({});
    service = TestBed.inject(ThemeService);
    document = TestBed.inject(DOCUMENT);
  });

  afterEach(() => {
    vi.restoreAllMocks();
    localStorage.clear();
    document.documentElement.classList.remove('dark');
  });

  it('creates the service', () => {
    expect(service).toBeTruthy();
  });

  it('initializes with dark as default mode signal', () => {
    expect(service.mode()).toBe('dark');
  });

  it('toggleMode switches from dark to light', () => {
    service.mode['set']('dark');
    service.toggleMode();
    expect(service.mode()).toBe('light');
  });

  it('toggleMode switches from light to dark', () => {
    service.setMode('light');
    service.toggleMode();
    expect(service.mode()).toBe('dark');
  });

  it('setMode updates the mode signal and persists to localStorage', () => {
    service.setMode('light');
    expect(service.mode()).toBe('light');
    expect(localStorage.getItem('__PROJECT_NAME__:theme-mode')).toBe('light');
  });

  it('setMode dark adds the dark class to documentElement', () => {
    service.setMode('dark');
    expect(document.documentElement.classList.contains('dark')).toBe(true);
  });

  it('setMode light removes the dark class from documentElement', () => {
    document.documentElement.classList.add('dark');
    service.setMode('light');
    expect(document.documentElement.classList.contains('dark')).toBe(false);
  });

  it('initialize reads stored mode from localStorage', () => {
    localStorage.setItem('__PROJECT_NAME__:theme-mode', 'light');
    service.initialize();
    expect(service.mode()).toBe('light');
  });
});
