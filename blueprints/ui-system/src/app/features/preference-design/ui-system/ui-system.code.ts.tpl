/**
 * El código de cada variante del UI System sale de las mismas propiedades con las que se pinta su
 * vista previa: lo que se ve y lo que se copia no pueden diferir.
 */

/** Un valor que se pasa por nombre (`[options]="plans"`) en el código, pero que el componente recibe ya resuelto. */
export interface UiRef {
  readonly ref: string;
  readonly value: unknown;
}

/** Texto (atributo), número o booleano (enlace) o una referencia; las claves que empiezan por `[` o `(` son enlaces tal cual. */
export type UiPropValue = string | number | boolean | UiRef;
export type UiProps = Readonly<Record<string, UiPropValue>>;

const MAX_LINE = 80;

export function asRef(ref: string, value: unknown): UiRef {
  return { ref, value };
}

function isRef(value: UiPropValue): value is UiRef {
  return typeof value === 'object';
}

function isBinding(name: string): boolean {
  return name.startsWith('[') || name.startsWith('(');
}

/** Las entradas que recibe el componente: sin los enlaces escritos a mano y con las referencias ya resueltas. */
export function inputsOf(props: UiProps): Record<string, unknown> {
  const inputs: Record<string, unknown> = {};
  for (const [name, value] of Object.entries(props)) {
    if (isBinding(name)) continue;
    inputs[name] = isRef(value) ? value.value : value;
  }
  return inputs;
}

function attribute(name: string, value: UiPropValue): string {
  if (isBinding(name)) return `${name}="${String(value)}"`;
  if (isRef(value)) return `[${name}]="${value.ref}"`;
  if (typeof value === 'string') return `${name}="${value}"`;
  if (value === true) return name;
  return `[${name}]="${String(value)}"`;
}

/** La etiqueta de un componente con sus propiedades; los atributos van uno por línea si no caben en una, y el contenido de varias líneas, sangrado entre las etiquetas. */
export function snippet(selector: string, props: UiProps, content = ''): string {
  const attributes = Object.entries(props).map(([name, value]) => attribute(name, value));
  const single = [selector, ...attributes].join(' ');
  const multiline = content.includes('\n');

  if (!multiline && single.length + content.length + selector.length + 5 <= MAX_LINE) {
    return content ? `<${single}>${content}</${selector}>` : `<${single} />`;
  }

  const closeOpening = content ? '>' : '/>';
  const opening = `<${single}`.length + closeOpening.length <= MAX_LINE ? `<${single}${content ? '>' : ' />'}` : [`<${selector}`, ...attributes.map((item) => `  ${item}`), closeOpening].join('\n');
  if (!content) return opening;
  if (!multiline) return `${opening}${content}</${selector}>`;

  const body = content.split('\n').map((line) => `  ${line}`);
  return [opening, ...body, `</${selector}>`].join('\n');
}
