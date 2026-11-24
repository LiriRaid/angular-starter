<div class="sidebar-wrapper" [class.collapsed]="layoutService.state() === SidebarStatus.COLLAPSED" [class.mobile]="layoutService.isMobile()" [class.expanded]="layoutService.state() === SidebarStatus.EXPANDED && !layoutService.isMobile()">
  @if (layoutService.shouldRender()) {
    @if (layoutService.isMobile() && layoutService.isOpen()) {
      <div class="fixed inset-0 z-1000 bg-(--app-sidebar-backdrop-bg)" (click)="layoutService.setOpen(false)"></div>
    }

    <aside class="sidebar" [class.open]="layoutService.isOpen()" (transitionend)="onTransitionEnd($event)">
      <div class="flex shrink-0 items-center px-2.5 h-15">
        <div class="flex w-full min-h-7 items-center gap-3">
          <!-- Marca: reemplaza la inicial por el logo del proyecto. -->
          <div class="flex size-9.5 shrink-0 items-center justify-center rounded-xl bg-(--sa-primary-color) text-body-2-bold text-white" aria-hidden="true">{{ brandInitial }}</div>

          <span class="sidebar-brand-separator text-(--app-text-subtle)">|</span>

          <div class="brand-text min-w-0 flex-1">
            <span class="brand-name text-body-2-bold text-(--app-text-muted)" [class.sidebar-text-hidden]="!isSidebarVisible()">{{ brandTitle }}</span>
          </div>
        </div>
      </div>

      <div class="px-2.5">
        <sa-search [placeholder]="'Buscar módulos'" [control]="searchInput" [mode]="layoutService.state() === SidebarStatus.COLLAPSED && !layoutService.isMobile() ? 'collapsed' : 'input'" (collapsedSearchClick)="onCollapsedSearchClick()"></sa-search>
      </div>

      <nav class="sidebar-content flex flex-col flex-1 overflow-y-auto overflow-x-hidden my-3">
        @for (group of navigationGroups(); track group.items) {
          <div class="sidebar-group flex flex-col" [class.gap-2.5]="isSidebarVisible()">
            <div class="sidebar-group-label text-caption-2-bold" [class.sidebar-text-hidden]="!isSidebarVisible()">{{ group.label }}</div>

            <nav class="px-2.5">
              <ul class="flex flex-col gap-2">
                @for (item of group.items; track item.id) {
                  @if (!isHidden(item)) {
                    <li class="sidebar-item-stack" [class.sidebar-item-stack--collapsed]="!(isSidebarVisible() && (item.unfolded || isSearching()))">
                      <button type="button" saRipple (click)="unfolItem(item)" [saTooltip]="isSidebarVisible() ? undefined : item.title" tooltipPosition="right" [showDelay]="300" [class]="'sa-btn sidebar-menu-item sidebar-menu-item--parent' + (item.unfolded || isActive(item) ? ' sidebar-link--active' : '') + (isSidebarVisible() ? '' : ' sidebar-menu-item--collapsed')">
                        @if (item.icon) {
                          <sa-icon [name]="item.icon" size="18"></sa-icon>
                        }

                        <span class="sidebar-btn-label text-caption-1-bold" [class.sidebar-text-hidden]="!isSidebarVisible()">{{ item.title }}</span>

                        @if (isSidebarVisible() && item.children) {
                          <div class="chevron" [class.sidebar-text-hidden]="!isSidebarVisible()" [class.pointer-events-none]="!isSidebarVisible()">
                            @if (item.unfolded) {
                              <sa-icon name="ChevronCircleUp" size="16"></sa-icon>
                            } @else {
                              <sa-icon name="ChevronCircleDown" size="16"></sa-icon>
                            }
                          </div>
                        }
                      </button>

                      <!-- CHILDREN NIVEL 1 -->
                      <div class="sidebar-collapse" [class.sidebar-collapse--expanded]="isSidebarVisible() && (item.unfolded || isSearching())">
                        <ul class="sidebar-tree-line list-none m-0 px-0 pt-0 pb-0.5 gap-2 grid" [class.sidebar-tree-line--active]="hasActiveDescendant(item.children)">
                          @for (children of item.children; track $index) {
                            @if (!isHidden(children)) {
                              @if (children.children) {
                                <li class="sidebar-item-stack" [class.sidebar-item-stack--collapsed]="!(isSidebarVisible() && (children.unfolded || isSearching()))">
                                  <button type="button" saRipple (click)="unfolItem(children)" [class]="'sa-btn sidebar-menu-item sidebar-menu-item--child level-1 w-full sidebar-hover-with-before' + (children.unfolded || isActive(children) ? ' selected-children sidebar-link--active sidebar-selected-with-before' : '') + (isSidebarVisible() ? '' : ' sidebar-menu-item--collapsed')">
                                    <div class="flex items-center justify-center">
                                      @if (children.icon) {
                                        <sa-icon [name]="children.icon" size="18"></sa-icon>
                                      }
                                    </div>

                                    <span class="sidebar-btn-label text-caption-2-bold" [class.sidebar-text-hidden]="!isSidebarVisible()">{{ children.title }}</span>

                                    @if (isSidebarVisible()) {
                                      <div class="chevron" [class.sidebar-text-hidden]="!isSidebarVisible()" [class.pointer-events-none]="!isSidebarVisible()">
                                        @if (children.unfolded) {
                                          <sa-icon name="ChevronCircleUp" size="16"></sa-icon>
                                        } @else {
                                          <sa-icon name="ChevronCircleDown" size="16"></sa-icon>
                                        }
                                      </div>
                                    }
                                  </button>

                                  <!-- NIVEL 2 -->
                                  <div class="sidebar-collapse" [class.sidebar-collapse--expanded]="isSidebarVisible() && (children.unfolded || isSearching())">
                                    <ul class="sidebar-tree-line sidebar-tree-line--level-2 list-none m-0 px-0 pt-0 pb-0.5 gap-2 grid" [class.sidebar-tree-line--active]="hasActiveDescendant(children.children)">
                                      @for (children2 of children.children; track $index) {
                                        @if (!isHidden(children2)) {
                                          <li class="grid">
                                            <button type="button" saRipple (click)="navigate(children2.link ?? '')" [class]="'sa-btn sidebar-menu-item sidebar-menu-item--child level-2 sidebar-hover-with-before' + (isActive(children2) ? ' selected-children2 sidebar-link--active sidebar-selected-with-before' : '')">
                                              <div class="flex items-center justify-center">
                                                @if (children2.icon) {
                                                  <sa-icon [name]="children2.icon" size="18"></sa-icon>
                                                }
                                              </div>

                                              <div class="grid">
                                                <span class="sidebar-btn-label text-left text-caption-2-bold" [class.sidebar-text-hidden]="!isSidebarVisible()"> {{ children2.title }} </span>
                                              </div>
                                            </button>
                                          </li>
                                        }
                                      }
                                    </ul>
                                  </div>
                                </li>
                              } @else {
                                <li>
                                  <button type="button" saRipple (click)="navigate(children.link ?? '')" [class]="'sa-btn sidebar-menu-item sidebar-menu-item--child level-1 w-full sidebar-hover-with-before' + (isActive(children) ? ' selected-children sidebar-link--active sidebar-selected-with-before' : '')">
                                    @if (children.icon) {
                                      <sa-icon class="flex items-center" [name]="children.icon" size="18"></sa-icon>
                                    }
                                    <span class="sidebar-btn-label text-left text-caption-2-bold" [class.sidebar-text-hidden]="!isSidebarVisible()">{{ children.title }}</span>
                                  </button>
                                </li>
                              }
                            }
                          }
                        </ul>
                      </div>
                    </li>
                  }
                }
              </ul>
            </nav>
          </div>
        }
      </nav>

      <footer class="sidebar-footer">
        <__PREFIX__-user-menu [expanded]="isSidebarVisible()" />
      </footer>
    </aside>
  }
</div>
