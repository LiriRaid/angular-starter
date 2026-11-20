import { type Signal } from '@angular/core';
import { takeUntilDestroyed, toObservable } from '@angular/core/rxjs-interop';
import { type AbstractControl } from '@angular/forms';

/**
 * Deshabilita los controles cuando el modo es "view" y los habilita cuando no.
 * Debe llamarse en contexto de inyección (constructor).
 */
export function disableControlsInView(isView: Signal<boolean>, controls: readonly AbstractControl[]): void {
  toObservable(isView)
    .pipe(takeUntilDestroyed())
    .subscribe((view) => controls.forEach((control) => (view ? control.disable() : control.enable())));
}
