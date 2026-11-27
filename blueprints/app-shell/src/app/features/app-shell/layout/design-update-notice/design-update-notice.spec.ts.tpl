import { TestBed } from '@angular/core/testing';
import { DESIGN_CHANGE_NOTIFIER, type DesignChange, type DesignChangeNotifier } from '@core/design-preferences/design-change-notifier';
import { DesignPreferencesService } from '@core/design-preferences/design-preferences.service';
import { DesignUpdateNotice } from './design-update-notice';

class FakeNotifier implements DesignChangeNotifier {
  listener: ((change: DesignChange) => void) | null = null;
  connect(listener: (change: DesignChange) => void): void {
    this.listener = listener;
  }
  disconnect(): void {
    this.listener = null;
  }
}

describe('DesignUpdateNotice', () => {
  let service: DesignPreferencesService;
  let notifier: FakeNotifier;

  const render = async () => {
    const fixture = TestBed.createComponent(DesignUpdateNotice);
    await fixture.whenStable();
    return fixture;
  };

  const announceChange = async (): Promise<void> => {
    notifier.listener?.({ version: 'another-version' });
    await Promise.resolve();
  };

  beforeEach(async () => {
    notifier = new FakeNotifier();
    await TestBed.configureTestingModule({
      imports: [DesignUpdateNotice],
      providers: [{ provide: DESIGN_CHANGE_NOTIFIER, useValue: notifier }],
    }).compileComponents();
    service = TestBed.inject(DesignPreferencesService);
    await service.initialize();
  });

  it('shows nothing while the design is the one the platform has', async () => {
    const fixture = await render();
    expect((fixture.nativeElement as HTMLElement).querySelector('[role="status"]')).toBeNull();
  });

  it('tells the user that the design changed and offers to reload the page', async () => {
    const fixture = await render();
    await announceChange();
    await fixture.whenStable();
    const notice = (fixture.nativeElement as HTMLElement).querySelector('[role="status"]');
    expect(notice?.textContent).toContain('El diseño de la plataforma cambió');
    expect(notice?.textContent).toContain('Recargar');
  });

  it('reloads the page only when the user asks for it', async () => {
    const reload = vi.spyOn(service, 'reload').mockImplementation(() => undefined);
    const fixture = await render();
    await announceChange();
    await fixture.whenStable();
    expect(reload).not.toHaveBeenCalled();
    const button = Array.from((fixture.nativeElement as HTMLElement).querySelectorAll('button')).find((element) => element.textContent?.includes('Recargar'));
    button?.click();
    expect(reload).toHaveBeenCalledTimes(1);
  });

  it('can be dismissed, and comes back with the next change', async () => {
    const fixture = await render();
    await announceChange();
    await fixture.whenStable();
    (fixture.nativeElement as HTMLElement).querySelector<HTMLButtonElement>('button[aria-label="Cerrar aviso"]')?.click();
    await fixture.whenStable();
    expect((fixture.nativeElement as HTMLElement).querySelector('[role="status"]')).toBeNull();
    notifier.listener?.({ version: 'a-third-version' });
    await Promise.resolve();
    await fixture.whenStable();
    expect((fixture.nativeElement as HTMLElement).querySelector('[role="status"]')).not.toBeNull();
  });
});
