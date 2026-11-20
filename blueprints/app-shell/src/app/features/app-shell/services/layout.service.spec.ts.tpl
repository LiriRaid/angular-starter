import { TestBed } from '@angular/core/testing';
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';

import { LayoutService, NAVIGATION_GROUPS_TOKEN, SIDEBAR_INITIAL_STATE } from './layout.service';
import { SidebarStatus } from '../layout/enums/sidebar-status.enum';
import type { NavigationGroup } from '@core/navigation/navigation.types';

function makeGroups(): readonly NavigationGroup[] {
  return [
    {
      label: 'Group',
      items: [
        {
          id: 'parent',
          title: 'Parent',
          unfolded: false,
          children: [{ id: 'child', title: 'Child', link: '/settings/general' }],
        },
        { id: 'leaf', title: 'Leaf', link: '/dashboard' },
      ],
    },
  ];
}

function setup(initialState = SidebarStatus.EXPANDED, innerWidth = 1280) {
  Object.defineProperty(window, 'innerWidth', { value: innerWidth, configurable: true, writable: true });

  TestBed.configureTestingModule({
    providers: [LayoutService, { provide: NAVIGATION_GROUPS_TOKEN, useValue: makeGroups() }, { provide: SIDEBAR_INITIAL_STATE, useValue: initialState }],
  });

  return TestBed.inject(LayoutService);
}

describe('LayoutService', () => {
  beforeEach(() => {
    vi.useFakeTimers();
    TestBed.resetTestingModule();
  });

  afterEach(() => {
    vi.useRealTimers();
  });

  // =========================
  // Initialization
  // =========================

  describe('initialization', () => {
    it('initializes as desktop expanded when innerWidth >= 1024 and initialState is EXPANDED', () => {
      const service = setup(SidebarStatus.EXPANDED, 1280);

      expect(service.isMobile()).toBe(false);
      expect(service.isOpen()).toBe(true);
      expect(service.shouldRender()).toBe(true);
      expect(service.state()).toBe(SidebarStatus.EXPANDED);
    });

    it('initializes as desktop collapsed when initialState is COLLAPSED', () => {
      const service = setup(SidebarStatus.COLLAPSED, 1280);

      expect(service.isMobile()).toBe(false);
      expect(service.isOpen()).toBe(false);
      expect(service.shouldRender()).toBe(true);
      expect(service.state()).toBe(SidebarStatus.COLLAPSED);
    });

    it('initializes as mobile when innerWidth < 1024', () => {
      const service = setup(SidebarStatus.EXPANDED, 768);

      expect(service.isMobile()).toBe(true);
      expect(service.isOpen()).toBe(false);
      expect(service.shouldRender()).toBe(false);
    });
  });

  // =========================
  // state computed
  // =========================

  describe('state', () => {
    it('returns EXPANDED when isOpen is true', () => {
      const service = setup();
      service.setOpen(true);
      expect(service.state()).toBe(SidebarStatus.EXPANDED);
    });

    it('returns COLLAPSED when isOpen is false', () => {
      const service = setup();
      service.setOpen(false);
      expect(service.state()).toBe(SidebarStatus.COLLAPSED);
    });
  });

  // =========================
  // setOpen — desktop
  // =========================

  describe('setOpen (desktop)', () => {
    it('opens and closes on desktop directly', () => {
      const service = setup(SidebarStatus.COLLAPSED);

      service.setOpen(true);
      expect(service.isOpen()).toBe(true);

      service.setOpen(false);
      expect(service.isOpen()).toBe(false);
    });

    it('updates lastUrl when currentUrl is provided', () => {
      const service = setup();
      service.setOpen(true, '/settings/general');
      expect(service['_lastUrl']).toBe('/settings/general');
    });
  });

  // =========================
  // setOpen — mobile
  // =========================

  describe('setOpen (mobile)', () => {
    it('closes immediately on mobile without rAF', () => {
      const service = setup(SidebarStatus.EXPANDED, 768);

      service.setOpen(false);

      expect(service.isOpen()).toBe(false);
    });

    it('sets shouldRender then opens via double rAF on mobile', () => {
      const service = setup(SidebarStatus.EXPANDED, 768);

      service.setOpen(true);

      expect(service.shouldRender()).toBe(true);
      expect(service.isOpen()).toBe(false);

      vi.runAllTimers();

      expect(service.isOpen()).toBe(true);
    });
  });

  // =========================
  // toggle
  // =========================

  describe('toggle', () => {
    it('toggles from open to closed', () => {
      const service = setup(SidebarStatus.EXPANDED);
      expect(service.isOpen()).toBe(true);

      service.toggle();

      expect(service.isOpen()).toBe(false);
    });

    it('toggles from closed to open', () => {
      const service = setup(SidebarStatus.COLLAPSED);
      expect(service.isOpen()).toBe(false);

      service.toggle();

      expect(service.isOpen()).toBe(true);
    });
  });

  // =========================
  // onTransitionClosed
  // =========================

  describe('onTransitionClosed', () => {
    it('hides the sidebar after CSS transition ends on mobile', () => {
      const service = setup(SidebarStatus.EXPANDED, 768);

      service.setOpen(false);
      service.onTransitionClosed();

      expect(service.shouldRender()).toBe(false);
    });

    it('does not affect shouldRender on desktop', () => {
      const service = setup(SidebarStatus.EXPANDED);

      service.setOpen(false);
      service.onTransitionClosed();

      expect(service.shouldRender()).toBe(true);
    });
  });

  // =========================
  // setMobile — desktop→mobile
  // =========================

  describe('setMobile (desktop → mobile)', () => {
    it('enters transition state and collapses without becoming mobile yet', () => {
      const service = setup(SidebarStatus.EXPANDED, 1280);

      service.setMobile(true);

      expect(service['_isDesktopToMobileTransition']()).toBe(true);
      expect(service.isMobile()).toBe(false);
      expect(service.isOpen()).toBe(false);
    });

    it('completes the transition after the CSS timeout', () => {
      const service = setup(SidebarStatus.EXPANDED, 1280);

      service.setMobile(true);
      vi.advanceTimersByTime(400);

      expect(service.isMobile()).toBe(true);
      expect(service['_isDesktopToMobileTransition']()).toBe(false);
      expect(service.shouldRender()).toBe(false);
    });

    it('ignores repeated setMobile(true) calls while already transitioning', () => {
      const service = setup(SidebarStatus.EXPANDED, 1280);

      service.setMobile(true);
      const firstState = service['_isDesktopToMobileTransition']();

      service.setMobile(true);

      expect(service['_isDesktopToMobileTransition']()).toBe(firstState);
    });

    it('blocks setOpen(false) during desktop→mobile transition', () => {
      const service = setup(SidebarStatus.EXPANDED, 1280);

      service.setMobile(true);
      const openBefore = service.isOpen();

      service.setOpen(false);

      expect(service.isOpen()).toBe(openBefore);
    });
  });

  // =========================
  // setMobile — mobile→desktop
  // =========================

  describe('setMobile (mobile → desktop)', () => {
    it('restores desktop expanded state via double rAF', () => {
      const service = setup(SidebarStatus.EXPANDED, 768);

      service.setMobile(false);
      vi.runAllTimers();

      expect(service.isMobile()).toBe(false);
      expect(service.isOpen()).toBe(true);
      expect(service.shouldRender()).toBe(true);
    });

    it('restores desktop collapsed state when it was collapsed before', () => {
      const service = setup(SidebarStatus.COLLAPSED, 768);

      service.setMobile(false);
      vi.runAllTimers();

      expect(service.isOpen()).toBe(false);
    });
  });

  // =========================
  // setMobile — cancel transition
  // =========================

  describe('setMobile (cancel desktop→mobile transition)', () => {
    it('cancels the transition and restores desktop state when viewport grows back', () => {
      const service = setup(SidebarStatus.EXPANDED, 1280);

      service.setMobile(true);
      service.setMobile(false);

      expect(service['_isDesktopToMobileTransition']()).toBe(false);
      expect(service.isMobile()).toBe(false);
      expect(service.shouldRender()).toBe(true);
    });
  });

  // =========================
  // finishDesktopToMobileTransition
  // =========================

  describe('finishDesktopToMobileTransition', () => {
    it('is a no-op when no transition is in progress', () => {
      const service = setup(SidebarStatus.EXPANDED);

      service.finishDesktopToMobileTransition();

      expect(service.isMobile()).toBe(false);
    });

    it('finalizes mobile state when called while transition is active', () => {
      const service = setup(SidebarStatus.EXPANDED, 1280);

      service.setMobile(true);
      service.finishDesktopToMobileTransition();

      expect(service.isMobile()).toBe(true);
      expect(service['_isDesktopToMobileTransition']()).toBe(false);
      expect(service.shouldRender()).toBe(false);
    });
  });

  // =========================
  // updateCurrentUrl
  // =========================

  describe('updateCurrentUrl', () => {
    it('stores the url internally', () => {
      const service = setup();

      service.updateCurrentUrl('/settings/notifications');

      expect(service['_lastUrl']).toBe('/settings/notifications');
    });

    it('ignores empty strings', () => {
      const service = setup();
      service.updateCurrentUrl('/settings/notifications');

      service.updateCurrentUrl('');

      expect(service['_lastUrl']).toBe('/settings/notifications');
    });
  });

  // =========================
  // getNavigationGroups / setNavigationGroups
  // =========================

  describe('getNavigationGroups / setNavigationGroups', () => {
    it('returns the groups provided at initialization', () => {
      const service = setup();
      const groups = service.getNavigationGroups();

      expect(groups).toHaveLength(1);
      expect(groups[0].label).toBe('Group');
    });

    it('replaces groups after setNavigationGroups', () => {
      const service = setup();

      const newGroups: readonly NavigationGroup[] = [{ label: 'New', items: [] }];
      service.setNavigationGroups(newGroups);

      expect(service.getNavigationGroups()[0].label).toBe('New');
    });
  });

  // =========================
  // collapseAll
  // =========================

  describe('collapseAll', () => {
    it('sets all items to unfolded = false', () => {
      const service = setup();
      service.getNavigationGroups()[0].items[0].unfolded = true;

      service.collapseAll();

      expect(service.getNavigationGroups()[0].items[0].unfolded).toBe(false);
    });
  });

  // =========================
  // expandParentsOfActiveItem
  // =========================

  describe('expandParentsOfActiveItem', () => {
    it('expands parent items that contain the active route', () => {
      const service = setup();
      expect(service.getNavigationGroups()[0].items[0].unfolded).toBe(false);

      service.expandParentsOfActiveItem('/settings/general');

      expect(service.getNavigationGroups()[0].items[0].unfolded).toBe(true);
    });
  });

  // =========================
  // expandParentsIfNoManualExpansion
  // =========================

  describe('expandParentsIfNoManualExpansion', () => {
    it('expands parents when there is no manual expansion', () => {
      const service = setup();

      service.expandParentsIfNoManualExpansion('/settings/general');

      expect(service.getNavigationGroups()[0].items[0].unfolded).toBe(true);
    });

    it('skips expansion when items are manually unfolded beyond the active route', () => {
      const service = setup();
      service.getNavigationGroups()[0].items[0].unfolded = true;
      service.updateCurrentUrl('/dashboard');

      service.expandParentsIfNoManualExpansion('/dashboard');

      expect(service.getNavigationGroups()[0].items[0].unfolded).toBe(true);
    });
  });

  // =========================
  // handleNavigationChange
  // =========================

  describe('handleNavigationChange', () => {
    it('updates the last url', () => {
      const service = setup();

      service.handleNavigationChange('/settings/notifications');

      expect(service['_lastUrl']).toBe('/settings/notifications');
    });

    it('collapses and re-expands items on mobile when sidebar is open', () => {
      const service = setup(SidebarStatus.EXPANDED, 768);
      service.getNavigationGroups()[0].items[0].unfolded = true;

      vi.runAllTimers();
      service.setOpen(true);
      vi.runAllTimers();

      service.handleNavigationChange('/settings/general');

      expect(service.getNavigationGroups()[0].items[0].unfolded).toBe(true);
    });

    it('does not touch expansion on desktop', () => {
      const service = setup();
      service.getNavigationGroups()[0].items[0].unfolded = true;

      service.handleNavigationChange('/dashboard');

      expect(service.getNavigationGroups()[0].items[0].unfolded).toBe(true);
    });
  });
});
