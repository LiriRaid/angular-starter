import { ChangeDetectionStrategy, Component, DestroyRef, ElementRef, afterNextRender, computed, inject, input, signal } from '@angular/core';
import { takeUntilDestroyed, toObservable } from '@angular/core/rxjs-interop';
import { Router } from '@angular/router';
import { BreadcrumbItem } from '@core/navigation/breadcrumb.types';
import { DropdownCoordinatorService } from '../../services/dropdown-coordinator.service';
import { LayoutService } from '../../services/layout.service';
import { SidebarStatus } from '../../layout/enums/sidebar-status.enum';
import { AsIcon } from '@shared/components';

@Component({
  selector: '__PREFIX__-breadcrumb',
  standalone: true,
  imports: [AsIcon],
  templateUrl: './breadcrumb.html',
  styleUrls: ['./breadcrumb.css'],
  changeDetection: ChangeDetectionStrategy.OnPush,
  host: {
    '(window:resize)': 'onResize()',
    '(document:click)': 'onDocumentClick($event)',
  },
})
export class BreadcrumbComponent {
  readonly breadcrumbs = input<BreadcrumbItem[]>([]);

  readonly iconSize = signal('20');
  readonly viewportWidth = signal(0);
  readonly hiddenStartIndex = signal<number | null>(null);

  private readonly FIRST_LEVEL_ONLY_BREAKPOINT = 399;
  private readonly DESKTOP_EXPANDED_HIDE_CURRENT_BREAKPOINT = 1024;
  private readonly MIN_CRUMBS_FOR_HIDE_CURRENT_RULE = 4;
  private readonly DROPDOWN_ID = 'breadcrumb-menu';

  private readonly elementRef = inject(ElementRef<HTMLElement>);
  private readonly destroyRef = inject(DestroyRef);
  private readonly router = inject(Router);
  private readonly dropdownCoordinator = inject(DropdownCoordinatorService);
  private readonly layoutService = inject(LayoutService);

  readonly dropdownOpen = computed(() => this.dropdownCoordinator.isOpen(this.DROPDOWN_ID));

  readonly visibleBreadcrumbs = computed(() => {
    const start = this.hiddenStartIndex();
    return start === null ? this.breadcrumbs() : this.breadcrumbs().slice(0, start);
  });

  readonly hiddenBreadcrumbs = computed(() => {
    const start = this.hiddenStartIndex();
    return start === null ? [] : this.breadcrumbs().slice(start);
  });

  readonly hasHiddenBreadcrumbs = computed(() => this.hiddenBreadcrumbs().length > 0);

  readonly hiddenContextBreadcrumbs = computed(() => this.hiddenBreadcrumbs().filter(this.isContextCrumb));

  readonly hiddenActionBreadcrumbs = computed(() => this.hiddenBreadcrumbs().filter(this.isActionCrumb));

  readonly hiddenContextLabel = computed(() =>
    this.hiddenContextBreadcrumbs()
      .map(({ label }) => label)
      .join(' / '),
  );

  readonly hasHiddenContext = computed(() => this.hiddenContextBreadcrumbs().length > 0);

  readonly shouldPushToggleToEnd = computed(() => this.hasHiddenBreadcrumbs() && this.visibleBreadcrumbs().length === 1);

  readonly isDesktopExpandedSidebar = computed(() => {
    return !this.layoutService.isMobile() && this.layoutService.state() !== SidebarStatus.COLLAPSED;
  });

  readonly shouldHideOnlyCurrentCrumb = computed(() => {
    return this.isDesktopExpandedSidebar() && this.viewportWidth() <= this.DESKTOP_EXPANDED_HIDE_CURRENT_BREAKPOINT && this.breadcrumbs().length >= this.MIN_CRUMBS_FOR_HIDE_CURRENT_RULE;
  });

  constructor() {
    afterNextRender(() => {
      this.viewportWidth.set(window.innerWidth);
      this.updateIconSize();

      const shell = this.getElement<HTMLElement>('.breadcrumb-shell');

      if (shell) {
        const resizeObserver = new ResizeObserver(() => this.recalculateLayout());
        resizeObserver.observe(shell);
        this.destroyRef.onDestroy(() => resizeObserver.disconnect());
      }

      this.recalculateLayout();
    });

    toObservable(
      computed(() => ({
        crumbs: this.breadcrumbs(),
        viewport: this.viewportWidth(),
        state: this.layoutService.state(),
        mobile: this.layoutService.isMobile(),
      })),
    )
      .pipe(takeUntilDestroyed())
      .subscribe(() => queueMicrotask(() => this.recalculateLayout()));
  }

  onResize(): void {
    this.viewportWidth.set(window.innerWidth);
    this.updateIconSize();

    if (!this.hasHiddenBreadcrumbs()) {
      this.closeDropdown();
    }
  }

  toggleDropdown(event: MouseEvent): void {
    event.stopPropagation();
    this.dropdownCoordinator.toggle(this.DROPDOWN_ID);
  }

  onDocumentClick(event: MouseEvent): void {
    if (!this.dropdownOpen()) return;

    const target = event.target as Node | null;
    if (target && !this.elementRef.nativeElement.contains(target)) {
      this.closeDropdown();
    }
  }

  onCrumbClick(crumb: BreadcrumbItem): void {
    if (!this.isCrumbClickable(crumb)) return;
    this.navigateTo(crumb.link!);
  }

  isCrumbClickable(crumb: BreadcrumbItem): boolean {
    return !!crumb.link && !crumb.isLast;
  }

  navigateTo(link: string): void {
    this.dropdownCoordinator.closeAll();
    this.router.navigate([link]);
  }

  private recalculateLayout(): void {
    const breadcrumbs = this.breadcrumbs();

    if (breadcrumbs.length <= 1) {
      this.hiddenStartIndex.set(null);
      this.closeDropdown();
      return;
    }

    if (this.viewportWidth() <= this.FIRST_LEVEL_ONLY_BREAKPOINT) {
      this.hiddenStartIndex.set(1);
      return;
    }

    if (this.shouldHideOnlyCurrentCrumb()) {
      this.hiddenStartIndex.set(breadcrumbs.length - 1);
      return;
    }

    const layout = this.getLayoutMetrics();
    if (!layout) return;

    const { availableWidth, trackGap, itemWidths, separatorWidths, toggleWidth } = layout;

    let bestVisibleCount = 1;

    for (let visibleCount = breadcrumbs.length; visibleCount >= 1; visibleCount--) {
      const hasHidden = visibleCount < breadcrumbs.length;
      const requiredWidth = this.calculateMinimumTrackWidth(itemWidths, separatorWidths, trackGap, visibleCount, this.getMinVisibleWidth(), hasHidden, toggleWidth);

      if (requiredWidth <= availableWidth) {
        bestVisibleCount = visibleCount;
        break;
      }
    }

    const nextHiddenStartIndex = bestVisibleCount === breadcrumbs.length ? null : bestVisibleCount;

    this.hiddenStartIndex.set(nextHiddenStartIndex);

    if (nextHiddenStartIndex === null) {
      this.closeDropdown();
    }
  }

  private getLayoutMetrics() {
    const breadcrumbs = this.breadcrumbs();
    const shell = this.getElement<HTMLElement>('.breadcrumb-shell');
    const track = this.getElement<HTMLElement>('.breadcrumb-track');
    const measureToggle = this.getElement<HTMLElement>('.breadcrumb-collapse--measure');
    const measureItems = this.getElements<HTMLElement>('.breadcrumb-item--measure');
    const measureSeparators = this.getElements<HTMLElement>('.breadcrumb-separator--measure');

    if (!shell || !track || !measureToggle || measureItems.length !== breadcrumbs.length) {
      return null;
    }

    return {
      availableWidth: shell.clientWidth,
      trackGap: this.readGap(track),
      itemWidths: measureItems.map((item) => item.getBoundingClientRect().width),
      separatorWidths: measureSeparators.map((separator) => separator.getBoundingClientRect().width),
      toggleWidth: measureToggle.getBoundingClientRect().width,
    };
  }

  private calculateMinimumTrackWidth(itemWidths: number[], separatorWidths: number[], gap: number, visibleCount: number, minLastWidth: number, hasHiddenBreadcrumbs: boolean, toggleWidth: number): number {
    const visibleItemsWidth = itemWidths.slice(0, Math.max(visibleCount - 1, 0)).reduce((sum, width) => sum + width, 0);

    const visibleSeparatorsWidth = separatorWidths.slice(0, Math.max(visibleCount - 1, 0)).reduce((sum, width) => sum + width, 0);

    const renderedElementCount = visibleCount + Math.max(visibleCount - 1, 0) + (hasHiddenBreadcrumbs ? 1 : 0);

    const totalGapWidth = Math.max(renderedElementCount - 1, 0) * gap;

    return visibleItemsWidth + visibleSeparatorsWidth + totalGapWidth + minLastWidth + (hasHiddenBreadcrumbs ? toggleWidth : 0);
  }

  private updateIconSize(): void {
    this.iconSize.set(window.innerWidth < 640 ? '18' : '20');
  }

  private readGap(element: HTMLElement): number {
    const styles = getComputedStyle(element);
    return parseFloat(styles.columnGap || styles.gap || '0') || 0;
  }

  private getMinVisibleWidth(): number {
    return 0;
  }

  private closeDropdown(): void {
    this.dropdownCoordinator.close(this.DROPDOWN_ID);
  }

  private getElement<T extends Element>(selector: string): T | null {
    return this.elementRef.nativeElement.querySelector(selector);
  }

  private getElements<T extends Element>(selector: string): T[] {
    return Array.from(this.elementRef.nativeElement.querySelectorAll(selector)) as T[];
  }

  private isContextCrumb = (crumb: BreadcrumbItem): boolean => !crumb.link && !crumb.isLast;

  private isActionCrumb = (crumb: BreadcrumbItem): boolean => !!crumb.link || !!crumb.isLast;
}
