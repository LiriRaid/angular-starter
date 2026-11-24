import { ChangeDetectionStrategy, Component, signal } from '@angular/core';
import { RouterLink } from '@angular/router';
import { SaIcon } from '@shared/components';
import { SOCIAL_LINKS, STARTER_LINKS, WELCOME_CARDS } from './home.data';

/** The welcome page of a new project, like the one of a new Angular application. Edit it or replace it. */
@Component({
  selector: '__PREFIX__-home',
  imports: [SaIcon, RouterLink],
  templateUrl: './home.html',
  styleUrl: './home.css',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class Home {
  protected readonly projectName = signal('__PROJECT_NAME__');
  protected readonly cards = WELCOME_CARDS;
  protected readonly starterLinks = STARTER_LINKS;
  protected readonly socialLinks = SOCIAL_LINKS;
}
