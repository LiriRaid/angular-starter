# shared/animations

`animations.css` is the one stylesheet of the animations the application shares. It is imported from
`src/styles.css`, after the rest of the styles, so every class below is available anywhere.

| Class                                                      | What it animates                                                                           |
| ---------------------------------------------------------- | ------------------------------------------------------------------------------------------ |
| `fade-in-out-enter`, `fade-in-out-leave`                   | opacity, 350 ms in and 200 ms out                                                          |
| `soft-fade-in-out-enter`, `soft-fade-in-out-leave`         | a shorter, subtler fade                                                                    |
| `route-transition`, `route-entering`                       | the fade and the 4 px rise of a routed page when it appears                                |
| `slide-in-out-enter`, `slide-in-out-leave`                 | a block of unknown height that opens and closes (an accordion) when it is added or removed |
| `slide-in-from-bottom-enter`, `slide-in-from-bottom-leave` | a panel that comes up from the bottom edge                                                 |
| `as-collapse-grid`, `is-collapsed`                         | a block that is always in the page and collapses to zero height on a transition            |

Use the `-enter` and `-leave` classes with Angular's `animate.enter` and `animate.leave` on content
that appears and disappears with `@if`:

<!-- prettier-ignore -->
```html
@if (open()) {
  <div animate.enter="fade-in-out-enter" animate.leave="fade-in-out-leave">...</div>
}
```

For content that is always there, toggle `is-collapsed` on an `as-collapse-grid` wrapper instead:
Angular runs `animate.enter` every time the element is mounted, including the first load of the page.

The route fade, the collapse grid and the slide from the bottom switch themselves off for users who
ask for reduced motion (`prefers-reduced-motion: reduce`); do the same with the ones you add. Add
yours to this file, as a pair of `-enter` and `-leave` classes with their `@keyframes`, so the whole
application keeps one vocabulary of motion.
