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

      <div class="as-collapse-grid" data-preview [class.is-collapsed]="!isShown(entry.id)" [attr.inert]="isShown(entry.id) ? null : ''">
        <div class="flex flex-col gap-3">
          <div class="flex flex-col gap-4 rounded-lg border border-dashed border-(--app-border-color) bg-(--app-panel-muted-bg) p-4">
            @for (group of groupsOf(entry); track group.name) {
              <section class="flex flex-col gap-2" [attr.aria-label]="group.name">
                <h5 class="text-caption-2-semibold text-(--app-text-subtle)">{{ group.name }}</h5>
                <div class="flex flex-wrap items-end gap-x-5 gap-y-4">
                  @for (item of group.variants; track item.id) {
                    <figure class="m-0 flex flex-col items-start gap-1.5" [attr.data-variant]="item.id">
                      <div [class]="item.boxClass ?? entry.previewClass ?? ''">
                        @switch (entry.id) {
                          @case ('input') {
                            @if (item.inputs['type'] === 'password') {
                              <as-input [label]="$any(item.inputs['label'])" [variant]="$any(item.inputs['variant'] ?? 'on')" [type]="isPasswordShown(item) ? 'text' : 'password'" [lucideIcon]="isPasswordShown(item) ? 'EyeOff' : 'Eye'" iconPosition="right" [iconClickable]="true" (iconClick)="togglePassword(item)" />
                            } @else {
                              <ng-container *ngComponentOutlet="outlets[entry.id]; inputs: item.inputs" />
                            }
                          }
                          @case ('checkbox') {
                            <as-checkbox [formControl]="checkboxes[item.id]" [ariaLabel]="$any(item.inputs['ariaLabel'])" [indeterminate]="item.inputs['indeterminate'] === true" />
                          }
                          @case ('tooltip') {
                            @if (item.text) {
                              <as-button variant="outlined"><span asTooltip="Texto de ayuda" [tooltipPosition]="$any(item.inputs['tooltipPosition'])">{{ item.text }}</span></as-button>
                            } @else {
                              <as-button [label]="$any(item.inputs['label'])" variant="outlined" asTooltip="Texto de ayuda" [tooltipPosition]="$any(item.inputs['tooltipPosition'])" [showDelay]="$any(item.inputs['showDelay'] ?? 0)" />
                            }
                          }
                          @case ('tabs') {
                            <as-tabs [tabs]="tabsOf(item)" [active]="activeOf(entry, item)" (activeChange)="setActive(entry, item, $event)" [variant]="$any(item.inputs['variant'] ?? 'default')" [size]="$any(item.inputs['size'] ?? 'default')" ariaLabel="Pestañas de ejemplo" />
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
                            <ng-container *ngComponentOutlet="outlets[entry.id]; inputs: item.inputs; content: contentOf(entry, item)" />
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
                <as-modal [visible]="modalOpen()" (visibleChange)="modalOpen.set($event)" title="Título" [flush]="modalInputs().flush ?? false" [titleIcon]="modalInputs().titleIcon ?? null" [titleDotColor]="modalInputs().titleDotColor ?? null" [width]="modalInputs().width ?? '34rem'" [variant]="modalInputs().variant ?? 'default'" [showFooter]="modalInputs().showFooter ?? false" [closable]="modalInputs().closable ?? true" [dismissableMask]="modalInputs().dismissableMask ?? true">
                  <div class="flex flex-col gap-2 p-5 text-caption-1-regular text-(--app-text-color)">
                    <p>El contenido del diálogo.</p>
                    @if (modalLong()) {
                      @for (line of longText; track $index) {
                        <p>{{ line }}</p>
                      }
                    }
                  </div>
                  @if (modalInputs().showFooter) {
                    <div modal-footer class="flex justify-end gap-2 p-3">
                      <as-button label="Cancelar" variant="outlined" size="small" (onClick)="modalOpen.set(false)" />
                      <as-button label="Guardar" size="small" (onClick)="modalOpen.set(false)" />
                    </div>
                  }
                </as-modal>
              }
              @case ('drawer') {
                <as-drawer [visible]="drawerOpen()" (visibleChange)="drawerOpen.set($event)" ariaLabel="Panel de ejemplo" [position]="drawerInputs().position ?? 'left'" [width]="drawerInputs().width ?? null" [closable]="drawerInputs().closable ?? true" [dismissible]="drawerInputs().dismissible ?? true" [closeOnEscape]="drawerInputs().closeOnEscape ?? true" [density]="drawerInputs().density ?? 'comfortable'" [flush]="drawerInputs().flush ?? false" [closeIcon]="drawerInputs().closeIcon ?? 'X'" [closeLabel]="drawerInputs().closeLabel ?? 'Cerrar'">
                  <h3 drawer-header class="text-body-2-bold text-(--app-text-color)">Título del panel</h3>
                  <div class="flex flex-col gap-2 p-5 text-caption-1-regular text-(--app-text-color)">
                    <p>El contenido del panel.</p>
                    @if (drawerLong()) {
                      @for (line of longText; track $index) {
                        <p>{{ line }}</p>
                      }
                    }
                  </div>
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
            <button type="button" data-all-code-toggle class="flex w-fit items-center gap-1.5 text-caption-2-semibold text-(--app-text-color)" [attr.aria-expanded]="isCodeOpen(entry.id)" (click)="toggleCode(entry.id)">
              <span aria-hidden="true" class="inline-block transition-transform duration-200" [class.rotate-90]="isCodeOpen(entry.id)">▸</span>
              Código de todas las variantes
            </button>
            <div class="as-collapse-grid" data-all-code [class.is-collapsed]="!isCodeOpen(entry.id)" [attr.inert]="isCodeOpen(entry.id) ? null : ''">
              <div>
                <pre class="overflow-x-auto rounded-lg bg-(--app-panel-muted-bg) p-3 text-caption-2-regular text-(--app-text-color)"><code>{{ entry.code }}

{{ allCode()[entry.id] }}</code></pre>
              </div>
            </div>
          </div>
        </div>
      </div>
    </article>
  } @empty {
    <p class="text-caption-1-regular text-(--app-text-subtle)">Ningún componente coincide con la búsqueda.</p>
  }
</section>
