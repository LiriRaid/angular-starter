@for (row of rows(); track row) {
  <span
    class="as-skeleton__block"
    [class.as-skeleton__block--short]="
      shape() === 'text' && rows().length > 1 && row === rows().length - 1
    "
  ></span>
}
