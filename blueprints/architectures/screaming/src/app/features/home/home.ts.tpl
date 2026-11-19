import { Component, signal } from '@angular/core';

@Component({
  selector: '__PREFIX__-home',
  templateUrl: './home.html',
  styleUrl: './home.css',
})
export class Home {
  protected readonly projectName = signal('__PROJECT_NAME__');
}
