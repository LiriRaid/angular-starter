<aside class="rail" aria-label="Navegación principal">
  <div class="rail-logo" aria-hidden="true">{{ brandInitial }}</div>

  <nav class="rail-nav">
    @for (item of items(); track item.id) {
      <button type="button" class="rail-item" [class.rail-item--active]="isActive(item)" [attr.aria-current]="isActive(item) ? (isFolder(item) ? 'true' : 'page') : null" [attr.aria-expanded]="isFolder(item) ? openItemId() === item.id : null" (click)="select(item, $event)">
        @if (item.icon) {
          <sa-icon [name]="item.icon" size="22" />
        }
        <span class="rail-label">{{ item.title }}</span>
      </button>
    }
  </nav>

  @if (openItem(); as folder) {
    <div class="rail-subnav" role="group" [attr.aria-label]="folder.title" [style.top.px]="subnavTop()" [style.left.px]="subnavLeft()">
      <strong class="rail-subnav-title">{{ folder.title }}</strong>
      @for (entry of subnavEntries(); track entry.id) {
        @if (entry.link) {
          <button type="button" class="rail-subnav-item" [style.padding-left.rem]="0.75 + entry.depth * 0.75" [class.rail-subnav-item--active]="isActive({ id: entry.id, title: entry.title, link: entry.link })" (click)="goTo(entry.link)">{{ entry.title }}</button>
        } @else {
          <span class="rail-subnav-group" [style.padding-left.rem]="0.75 + entry.depth * 0.75">{{ entry.title }}</span>
        }
      }
    </div>
  }
</aside>
