@if (src(); as url) {
  <span
    class="as-icon__svg"
    [class.as-animate-spin]="spin()"
    [style.--as-icon-url]="'url(' + url + ')'"
  ></span>
} @else if (name()) {
  <svg [lucideIcon]="name()" [size]="pixels()" [class.as-animate-spin]="spin()"></svg>
}
