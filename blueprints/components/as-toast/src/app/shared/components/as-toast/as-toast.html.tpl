<div #wrapperRef popover="manual" class="as-toast-wrapper" [attr.data-position]="position()">
  <div class="as-toast-track" [style.height.px]="trackHeight() || null" (mouseenter)="hovered.set(true)" (mouseleave)="hovered.set(false)">
    @for (msg of messages(); track msg.id; let i = $index) {
      <div #toastItem class="as-toast-item" [class.as-toast-item--success]="msg.type === AsToastType.Success" [class.as-toast-item--error]="msg.type === AsToastType.Error" [class.as-toast-item--warn]="msg.type === AsToastType.Warning" [class.as-toast-item--info]="msg.type === AsToastType.Info" [class.as-toast-item--secondary]="msg.type === AsToastType.Secondary || msg.type === AsToastType.Loading" [class.as-toast-item--contrast]="msg.type === AsToastType.Contrast" [class.is-new]="msg.id === newestId()" [ngStyle]="itemStyle(i, msg.id)" role="alert" aria-live="polite">
        <div class="as-toast-shell">
          <div class="as-toast-main">
            @if (hasIcon()) {
              <div class="as-toast-icon-wrap">
                <as-icon [name]="toastIcon(msg)" size="24" [spin]="msg.type === AsToastType.Loading" />
              </div>
            }

            <div class="as-toast-body">
              <h4 class="as-toast-title text-body-2-bold">{{ msg.title }}</h4>
              <p class="as-toast-message text-caption-2-medium" [innerHTML]="formattedMessage(msg.message)"></p>
            </div>

            @if (!(msg.persistent && msg.action)) {
              <as-button icon="CloseCircle" iconSize="20" variant="text" ariaLabel="Cerrar alerta" styleClass="as-toast-close-button" (onClick)="close(msg.id)" />
            }
          </div>

          @if (msg.action; as action) {
            <div class="as-toast-actions">
              <as-button [label]="action.label" [severity]="actionSeverity(action)" styleClass="!min-h-8 !rounded-lg text-caption-1-medium" (onClick)="executeAction(action, msg.id)" />
              @if (action.secondary; as secondary) {
                <as-button [label]="secondary.label" severity="secondary" variant="outlined" styleClass="!min-h-8 !rounded-lg text-caption-1-medium" (onClick)="executeAction(secondary, msg.id)" />
              }
            </div>
          }

          @if (showProgressBar(msg)) {
            <div class="as-toast-progress" [style.--toast-duration]="toastDuration(msg)"></div>
          }
        </div>
      </div>
    }
  </div>
</div>
