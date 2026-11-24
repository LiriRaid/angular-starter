@if (renderCollapsed()) {
  <as-button icon="Search" iconSize="18" size="medium" variant="outlined" ariaLabel="Buscar" styleClass="as-search-btn" (onClick)="collapsedSearchClick.emit()" />
} @else if (mode() === 'chat') {
  <div class="as-search-chat-input w-full" [class]="inputClass()">
    <as-button icon="ArrowLeft" iconSize="18" size="xsmall" text ariaLabel="Cerrar búsqueda" styleClass="as-search-back-btn !rounded-full !border-0 hover:!bg-transparent [color:var(--app-text-subtle)] dark:[color:var(--app-text-color)] hover:[color:var(--app-text-primary)]" (onClick)="backClick.emit()" />
    <input class="as-search-chat-field" [placeholder]="placeholder()" [formControl]="control()" (keyup)="onKeyup($event)" />
  </div>
} @else {
  <as-input lucideIcon="Search" [iconSize]="18" iconPosition="left" [placeholder]="placeholder()" [formControl]="control()" class="w-full" [inputClass]="inputClass()" (keyup)="onKeyup($event)" />
}
