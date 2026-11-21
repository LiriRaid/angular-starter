<section class="flex flex-col gap-4 border-t border-(--app-border-color) pt-4" aria-label="UI System">
  <header class="flex flex-wrap items-end justify-between gap-3">
    <div>
      <h3 class="text-body-2-bold text-(--app-text-color)">UI System</h3>
      <p class="text-caption-2-regular text-(--app-text-subtle)">Los componentes instalados con todas sus variantes, su código y los tokens que los cambian. Pulsa el nombre de una variante para ver su código; mueve los tokens arriba y mira cómo responden.</p>
    </div>
    <input type="search" class="w-56 rounded-lg border border-(--app-border-color) bg-(--app-panel-bg) px-3 py-1.5 text-caption-1-medium text-(--app-text-color)" placeholder="Buscar componente" aria-label="Buscar componente" [value]="query()" (input)="query.set($any($event.target).value)" />
  </header>

  @for (entry of filtered(); track entry.id) {
    <article class="flex flex-col gap-3 rounded-xl border border-(--app-border-color) p-4" [attr.data-component]="entry.id">
      <header class="flex items-start justify-between gap-3">
        <div class="min-w-0">
          <h4 class="text-caption-1-bold text-(--app-text-color)">{{ entry.label }}</h4>
          <code class="text-caption-2-regular text-(--app-text-subtle)">{{ entry.selector }}</code>
        </div>
        <as-toggle [checked]="isShown(entry.id)" (changed)="setShown(entry.id, $event)" [ariaLabel]="'Mostrar la vista previa de ' + entry.label" />
      </header>

      <p class="text-caption-2-regular text-(--app-text-subtle)">{{ entry.description }}</p>

      <p class="flex flex-wrap items-center gap-1.5 text-caption-2-regular text-(--app-text-subtle)">
        <span>Cambia con:</span>
        @for (token of entry.affects; track token) {
          <span class="rounded-full bg-(--app-badge-soft-bg) px-2 py-0.5 text-caption-2-semibold text-(--app-badge-soft-text)">{{ token }}</span>
        } @empty {
          <span>ningún token</span>
        }
      </p>

      @if (isShown(entry.id)) {
        <div class="flex flex-col gap-4 rounded-lg border border-dashed border-(--app-border-color) bg-(--app-panel-muted-bg) p-4">
          @for (group of groupsOf(entry); track group.name) {
            <section class="flex flex-col gap-2" [attr.aria-label]="group.name">
              <h5 class="text-caption-2-semibold text-(--app-text-subtle)">{{ group.name }}</h5>
              <div class="flex flex-wrap items-end gap-x-5 gap-y-4">
                @for (item of group.variants; track item.id) {
                  <figure class="m-0 flex flex-col items-start gap-1.5" [attr.data-variant]="item.id">
                    <div [class]="item.boxClass ?? entry.previewClass ?? ''">
                      @switch (entry.id) {
                        @case ('divider') {
                          <as-divider [layout]="$any(item.inputs['layout'])" [type]="$any(item.inputs['type'])" [align]="$any(item.inputs['align'])">{{ item.text }}</as-divider>
                        }
                        @case ('checkbox') {
                          <as-checkbox [formControl]="checkboxes[item.id]" [ariaLabel]="$any(item.inputs['ariaLabel'])" [indeterminate]="item.inputs['indeterminate'] === true" />
                        }
                        @case ('tooltip') {
                          <as-button [label]="$any(item.inputs['label'])" variant="outlined" [asTooltip]="$any(item.inputs['asTooltip'])" [tooltipPosition]="$any(item.inputs['tooltipPosition'])" />
                        }
                        @case ('popover') {
                          <as-popover [position]="$any(item.inputs['position'] ?? 'top')" [triggerIcon]="$any(item.inputs['triggerIcon'])" [triggerVariant]="$any(item.inputs['triggerVariant'] ?? 'outlined')" [actions]="item.inputs['actions'] === true" [items]="actionItems" triggerAriaLabel="Abrir popover de ejemplo">
                            @if (item.text) {
                              <p class="w-48 p-3 text-caption-1-regular text-(--app-text-color)">{{ item.text }}</p>
                            }
                          </as-popover>
                        }
                        @case ('tabs') {
                          <as-tabs [tabs]="tabsOf(item)" [active]="activeTab()" (activeChange)="activeTab.set($event)" [variant]="$any(item.inputs['variant'] ?? 'default')" [size]="$any(item.inputs['size'] ?? 'default')" ariaLabel="Pestañas de ejemplo" />
                        }
                        @case ('modal') {
                          <as-button label="Abrir" variant="outlined" size="small" (onClick)="openOverlay(entry, item)" />
                        }
                        @case ('drawer') {
                          <as-button label="Abrir" variant="outlined" size="small" (onClick)="openOverlay(entry, item)" />
                        }
                        @case ('toast') {
                          <as-button label="Mostrar" variant="outlined" size="small" (onClick)="showToast(item)" />
                        }
                        @default {
                          <ng-container *ngComponentOutlet="outlets[entry.id]; inputs: item.inputs" />
                        }
                      }
                    </div>
                    <button type="button" data-chip class="rounded-full border px-2 py-0.5 text-caption-2-semibold transition-colors" [class]="isSelected(entry, item) ? 'border-transparent bg-(--app-badge-soft-bg) text-(--app-badge-soft-text)' : 'border-(--app-border-color) text-(--app-text-subtle) hover:text-(--app-text-color)'" [attr.aria-pressed]="isSelected(entry, item)" (click)="choose(entry, item)">{{ item.label }}</button>
                  </figure>
                }
              </div>
            </section>
          }

          @if (entry.options; as options) {
            <div class="flex flex-wrap gap-x-5 gap-y-2 border-t border-(--app-border-color) pt-3" role="group" aria-label="Opciones">
              @for (option of options; track option.id) {
                <label class="flex items-center gap-2 text-caption-2-regular text-(--app-text-color)">
                  <as-toggle [checked]="isOptionOn(entry, option)" (changed)="setOption(entry, option, $event)" [ariaLabel]="option.label" />
                  {{ option.label }}
                </label>
              }
            </div>
          }

          @switch (entry.id) {
            @case ('modal') {
              <as-modal [visible]="modalOpen()" (visibleChange)="modalOpen.set($event)" title="Título" [titleIcon]="modalInputs().titleIcon ?? null" [titleDotColor]="modalInputs().titleDotColor ?? null" [width]="modalInputs().width ?? '34rem'" [variant]="modalInputs().variant ?? 'default'" [showFooter]="modalInputs().showFooter ?? false" [closable]="modalInputs().closable ?? true" [dismissableMask]="modalInputs().dismissableMask ?? true">
                <p class="p-4 text-caption-1-regular text-(--app-text-color)">El contenido del diálogo.</p>
                @if (modalInputs().showFooter) {
                  <div modal-footer class="flex justify-end gap-2 p-3">
                    <as-button label="Cancelar" variant="outlined" size="small" (onClick)="modalOpen.set(false)" />
                    <as-button label="Guardar" size="small" (onClick)="modalOpen.set(false)" />
                  </div>
                }
              </as-modal>
            }
            @case ('drawer') {
              <as-drawer [visible]="drawerOpen()" (visibleChange)="drawerOpen.set($event)" ariaLabel="Panel de ejemplo" [position]="drawerInputs().position ?? 'left'" [width]="drawerInputs().width ?? null" [closable]="drawerInputs().closable ?? true" [dismissible]="drawerInputs().dismissible ?? true" [closeOnEscape]="drawerInputs().closeOnEscape ?? true" [density]="drawerInputs().density ?? 'comfortable'" [flush]="drawerInputs().flush ?? false">
                <h3 drawer-header class="text-body-2-bold text-(--app-text-color)">Título del panel</h3>
                <p class="text-caption-1-regular text-(--app-text-color)">El contenido del panel.</p>
                @if (drawerFooter()) {
                  <div drawer-footer class="flex items-center gap-2.5">
                    <as-button label="Cancelar" variant="outlined" size="small" (onClick)="drawerOpen.set(false)" />
                    <as-button label="Guardar" size="small" (onClick)="drawerOpen.set(false)" />
                  </div>
                }
              </as-drawer>
            }
          }
        </div>

        <div class="flex flex-col gap-2">
          <h5 class="text-caption-2-semibold text-(--app-text-subtle)">
            Código de <code class="text-(--app-text-color)">{{ selectedOf(entry).label }}</code>
          </h5>
          <pre class="overflow-x-auto rounded-lg bg-(--app-panel-muted-bg) p-3 text-caption-2-regular text-(--app-text-color)"><code data-selected-code>{{ codeOf(entry) }}</code></pre>
          <details>
            <summary class="cursor-pointer text-caption-2-semibold text-(--app-text-color)">Código de todas las variantes</summary>
            <pre class="mt-2 overflow-x-auto rounded-lg bg-(--app-panel-muted-bg) p-3 text-caption-2-regular text-(--app-text-color)"><code>{{ entry.code }}

{{ allCode()[entry.id] }}</code></pre>
          </details>
        </div>
      }
    </article>
  } @empty {
    <p class="text-caption-1-regular text-(--app-text-subtle)">Ningún componente coincide con la búsqueda.</p>
  }
</section>
