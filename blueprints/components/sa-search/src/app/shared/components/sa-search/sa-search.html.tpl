@if (renderCollapsed()) {
  <sa-button icon="Search" iconSize="18" size="medium" variant="outlined" ariaLabel="Buscar" styleClass="sa-search-btn" (onClick)="onCollapsedClick()" />
} @else if (mode() === 'chat') {
  <div class="sa-search-chat-input w-full" [class]="inputClass()">
    <sa-button icon="ArrowLeft" iconSize="18" size="xsmall" text ariaLabel="Cerrar búsqueda" styleClass="sa-search-back-btn !rounded-full !border-0 hover:!bg-transparent [color:var(--app-text-subtle)] dark:[color:var(--app-text-color)] hover:[color:var(--app-text-primary)]" (onClick)="backClick.emit()" />
    <input class="sa-search-chat-field" [placeholder]="placeholder()" [formControl]="control()" (keyup)="onKeyup($event)" />
  </div>
} @else {
  <sa-input lucideIcon="Search" [iconSize]="18" iconPosition="left" [placeholder]="placeholder()" [formControl]="control()" class="w-full" [inputClass]="inputClass()" (keyup)="onKeyup($event)" />
}
