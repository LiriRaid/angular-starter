import { ChangeDetectionStrategy, Component, ElementRef, inject, viewChild } from '@angular/core';
import { RouterOutlet } from '@angular/router';
import { SidebarStatus } from '../enums/sidebar-status.enum';
import { Sidebar } from '../sidebar/sidebar';
import { LayoutService } from '../../services/layout.service';
import { Header } from '../header/header';
import { AsToast } from '@shared/components';
import { AlertService } from '@shared/services';

@Component({
  selector: '__PREFIX__-main',
  imports: [RouterOutlet, Sidebar, Header, AsToast],
  templateUrl: './main.html',
  styleUrl: './main.css',
  changeDetection: ChangeDetectionStrategy.OnPush,
  host: {
    '(window:resize)': 'onResize()',
  },
})
export class Main {
  readonly SidebarStatus = SidebarStatus;
  readonly layoutService = inject(LayoutService);
  protected readonly alertService = inject(AlertService);

  private readonly routeContainer = viewChild<ElementRef<HTMLElement>>('routeContainer');
  private skipFirstActivation = true;

  onResize(): void {
    this.layoutService.setMobile(window.innerWidth < 1024);
  }

  onRouteActivate(): void {
    if (this.skipFirstActivation) {
      this.skipFirstActivation = false;
      return;
    }

    const el = this.routeContainer()?.nativeElement;
    if (!el) return;

    el.classList.remove('route-entering');
    void el.offsetWidth;
    el.classList.add('route-entering');
  }
}
