<div class="breadcrumb-shell relative min-w-0">
  <div class="breadcrumb block w-full min-w-0 text-base" [class.breadcrumb--compact]="hasHiddenBreadcrumbs()">
    <div class="breadcrumb-track">
      @for (crumb of visibleBreadcrumbs(); track crumb.label; let last = $last) {
        <span class="breadcrumb-item inline-flex items-center" [class.breadcrumb-current]="!hasHiddenBreadcrumbs() && last" [class.breadcrumb-item--compressible]="last" [class.clickable]="isCrumbClickable(crumb)" [class.non-clickable]="!isCrumbClickable(crumb)" (click)="onCrumbClick(crumb)">
          <span class="breadcrumb-item-content inline-flex items-center" [class.breadcrumb-item-content--compressible]="last">
            @if (crumb.icon && !hasHiddenBreadcrumbs() && last) {
              <as-icon [name]="crumb.icon" [size]="iconSize()" class="breadcrumb-icon inline-flex items-center"></as-icon>
            }

            <span class="breadcrumb-label block">{{ crumb.label }}</span>
          </span>
        </span>

        @if (!last) {
          <span class="breadcrumb-separator inline-flex items-center" aria-hidden="true">
            <as-icon name="ChevronRight" size="18" extraClass="breadcrumb-separator-icon"></as-icon>
          </span>
        }
      }

      @if (hasHiddenBreadcrumbs()) {
        <div class="breadcrumb-actions inline-flex items-center relative shrink-0" [class.breadcrumb-actions--push-end]="shouldPushToggleToEnd()" [class.ml-auto]="shouldPushToggleToEnd()">
          <button class="breadcrumb-collapse inline-flex items-center" type="button" [attr.aria-label]="dropdownOpen() ? 'Hide hidden breadcrumb items' : 'Show hidden breadcrumb items'" (click)="toggleDropdown($event)">
            <as-icon [name]="dropdownOpen() ? 'ChevronUp' : 'ChevronDown'" size="14"></as-icon>
          </button>

          @if (dropdownOpen()) {
            <div class="breadcrumb-dropdown" animate.enter="soft-fade-in-out-enter" animate.leave="soft-fade-in-out-leave">
              @for (crumb of hiddenActionBreadcrumbs(); track crumb.label; let first = $first) {
                <div class="breadcrumb-dropdown-item-wrapper" [class.breadcrumb-dropdown-item-wrapper--with-context]="first && hasHiddenContext()">
                  @if (first && hasHiddenContext()) {
                    <span class="breadcrumb-dropdown-floating-label">
                      {{ hiddenContextLabel() }}
                    </span>
                  }

                  <button class="breadcrumb-dropdown-item" [class.breadcrumb-dropdown-item--with-context]="first && hasHiddenContext()" type="button" [class.is-current]="crumb.isLast" [disabled]="!isCrumbClickable(crumb)" (click)="onCrumbClick(crumb)">
                    @if (crumb.icon && crumb.isLast) {
                      <as-icon [name]="crumb.icon" size="16" class="breadcrumb-dropdown-icon shrink-0"></as-icon>
                    }

                    <span class="breadcrumb-dropdown-label">{{ crumb.label }}</span>
                  </button>
                </div>
              }
            </div>
          }
        </div>
      }
    </div>
  </div>

  <div class="breadcrumb-measure" aria-hidden="true">
    <div class="breadcrumb-measure-track">
      @for (crumb of breadcrumbs(); track crumb.label; let last = $last) {
        <span class="breadcrumb-item breadcrumb-item--measure inline-flex items-center">
          <span class="breadcrumb-item-content inline-flex items-center">
            @if (crumb.icon && last) {
              <as-icon [name]="crumb.icon" [size]="iconSize()" class="breadcrumb-icon inline-flex items-center"></as-icon>
            }

            <span class="breadcrumb-label block">{{ crumb.label }}</span>
          </span>
        </span>

        @if (!last) {
          <span class="breadcrumb-separator breadcrumb-separator--measure inline-flex items-center" aria-hidden="true">
            <as-icon name="ChevronRight" size="18" extraClass="breadcrumb-separator-icon"></as-icon>
          </span>
        }
      }
    </div>

    <button class="breadcrumb-collapse breadcrumb-collapse--measure inline-flex items-center" type="button" tabindex="-1" aria-hidden="true">
      <as-icon name="ChevronDown" size="14"></as-icon>
    </button>
  </div>
</div>
