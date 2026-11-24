<div #wrapperRef popover="manual" class="sa-toast-wrapper" [attr.data-position]="position()">
  <div class="sa-toast-track" [style.height.px]="trackHeight() || null" (mouseenter)="hovered.set(true)" (mouseleave)="hovered.set(false)">
    @for (msg of messages(); track msg.id; let i = $index) {
      <div #toastItem class="sa-toast-item" [class.sa-toast-item--success]="msg.type === SaToastType.Success" [class.sa-toast-item--error]="msg.type === SaToastType.Error" [class.sa-toast-item--warn]="msg.type === SaToastType.Warning" [class.sa-toast-item--info]="msg.type === SaToastType.Info" [class.sa-toast-item--secondary]="msg.type === SaToastType.Secondary || msg.type === SaToastType.Loading" [class.sa-toast-item--contrast]="msg.type === SaToastType.Contrast" [class.is-new]="msg.id === newestId()" [ngStyle]="itemStyle(i, msg.id)" role="alert" aria-live="polite">
        <div class="sa-toast-shell">
          <div class="sa-toast-main">
            @if (hasIcon()) {
              <div class="sa-toast-icon-wrap">
                <sa-icon [name]="toastIcon(msg)" size="24" [spin]="msg.type === SaToastType.Loading" />
              </div>
            }

            <div class="sa-toast-body">
              <h4 class="sa-toast-title text-body-2-bold">{{ msg.title }}</h4>
              <p class="sa-toast-message text-caption-2-medium" [innerHTML]="formattedMessage(msg.message)"></p>
            </div>

            @if (!(msg.persistent && msg.action)) {
              <sa-button icon="CloseCircle" iconSize="20" variant="text" ariaLabel="Cerrar alerta" styleClass="sa-toast-close-button" (onClick)="close(msg.id)" />
            }
          </div>

          @if (msg.action; as action) {
            <div class="sa-toast-actions">
              <sa-button [label]="action.label" [severity]="actionSeverity(action)" styleClass="!min-h-8 !rounded-lg text-caption-1-medium" (onClick)="executeAction(action, msg.id)" />
              @if (action.secondary; as secondary) {
                <sa-button [label]="secondary.label" severity="secondary" variant="outlined" styleClass="!min-h-8 !rounded-lg text-caption-1-medium" (onClick)="executeAction(secondary, msg.id)" />
              }
            </div>
          }

          @if (showProgressBar(msg)) {
            <div class="sa-toast-progress" [style.--toast-duration]="toastDuration(msg)"></div>
          }
        </div>
      </div>
    }
  </div>
</div>
