import { Injectable, inject } from '@angular/core';
import { Meta, Title } from '@angular/platform-browser';
import { RouterStateSnapshot, TitleStrategy } from '@angular/router';
import { NAV_APP_NAME_TOKEN, NAV_TREE_TOKEN } from './navigation.tokens';
import { findNavigationMatch } from './navigation.utils';

/**
 * Sets the page title to `<title> | <app name>` and the meta description. The title of the item in
 * the navigation tree wins over the `title` of the route; without either, only the app name is used.
 */
@Injectable()
export class NavigationTitleStrategy extends TitleStrategy {
  private readonly title = inject(Title);
  private readonly meta = inject(Meta);
  private readonly tree = inject(NAV_TREE_TOKEN);
  private readonly appName = inject(NAV_APP_NAME_TOKEN);

  override updateTitle(snapshot: RouterStateSnapshot): void {
    const item = findNavigationMatch(this.tree, snapshot.url)?.path.at(-1);
    const pageTitle = item?.title || this.buildTitle(snapshot);

    this.title.setTitle(pageTitle ? `${pageTitle} | ${this.appName}` : this.appName);
    this.meta.updateTag({
      name: 'description',
      content: item?.description ?? (pageTitle ? `${this.appName} - ${pageTitle}` : this.appName),
    });
  }
}
