import { PHONE_COUNTRIES, type PhoneCountry } from '@shared/data/phone-countries';
import { PHONE_NUMBER_GROUPING, PREFERRED_COUNTRY_BY_DIAL_CODE } from '@shared/data/phone-number-formats';

// Ordenado una sola vez a nivel de módulo (no en cada llamada) — probado los códigos más largos
// primero para no confundir, ej. "+52" con el inicio de un código de 1 dígito.
const COUNTRIES_BY_DIAL_CODE_LENGTH = [...PHONE_COUNTRIES].sort((a, b) => b.dialCode.length - a.dialCode.length);

/** Encuentra el país cuyo `dialCode` matchea el inicio de un número en dígitos puros (sin "+").
 *  Usado tanto para formatear números crudos como para parsear lo que se escribe/carga en el
 *  modo `phoneCountryPicker` de `as-input` (crear y editar comparten esta misma función,
 *  sin lógica duplicada). Si el dialCode es ambiguo (varios países), resuelve al preferido
 *  (`PREFERRED_COUNTRY_BY_DIAL_CODE`) en vez de al primero alfabético. */
export function matchDialCode(digits: string): PhoneCountry | null {
  const match = COUNTRIES_BY_DIAL_CODE_LENGTH.find((c) => digits.startsWith(c.dialCode));
  if (!match) return null;

  const preferredIso2 = PREFERRED_COUNTRY_BY_DIAL_CODE[match.dialCode];
  if (!preferredIso2 || match.iso2 === preferredIso2) return match;

  return PHONE_COUNTRIES.find((c) => c.dialCode === match.dialCode && c.iso2 === preferredIso2) ?? match;
}

/** Agrupa un número nacional según el patrón real de su país (ej. Honduras "4-4", EE.UU.
 *  "3-3-4" — ver `PHONE_NUMBER_GROUPING`). Sin `iso2` conocido, o si el país no tiene patrón
 *  listado, cae al agrupamiento genérico de bloques de 4 (ej. "96991587" -> "9699 1587"). */
export function groupNationalDigits(digits: string, iso2?: string): string {
  const pattern = iso2 ? PHONE_NUMBER_GROUPING[iso2.toLowerCase()] : undefined;
  if (!pattern) return digits.replace(/(\d{4})(?=\d)/g, '$1 ');

  const groups: string[] = [];
  let rest = digits;
  for (const size of pattern) {
    if (!rest) break;
    groups.push(rest.slice(0, size));
    rest = rest.slice(size);
  }
  if (rest) groups.push(rest);

  return groups.join(' ');
}

/** Formatea un telefono crudo/E.164 (ej. "+50496991587", "50496991587" o ya con espacios)
 *  agrupando el numero nacional segun el patron real de su pais (ej. "+504 9699 1587") — mismo
 *  criterio que el modo `phoneCountryPicker` de `as-input`. Si no matchea ningun
 *  codigo de pais conocido, solo antepone el "+" sin agrupar. */
export function formatPhoneNumber(phone: string | null | undefined): string {
  const digits = (phone ?? '').replace(/\D/g, '');
  if (!digits) return phone ?? '';

  const match = matchDialCode(digits);
  if (!match) return `+${digits}`;

  const national = groupNationalDigits(digits.slice(match.dialCode.length), match.iso2);
  return `+${match.dialCode} ${national}`.trim();
}
