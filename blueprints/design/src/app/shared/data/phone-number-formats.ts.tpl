/** Patrón de agrupación del número nacional (sin código de país) por iso2 — cuántos dígitos
 *  van en cada bloque, ej. Honduras "4-4" → [4, 4], EE.UU./Canadá "3-3-4" → [3, 3, 4].
 *  Solo se listan los países donde el uso real difiere del agrupamiento genérico de 4 en 4
 *  (ver fallback en `groupNationalDigits`) — cubre Centroamérica/LatAm y NANP, que es el
 *  alcance real del negocio; el resto de países cae al fallback. */
export const PHONE_NUMBER_GROUPING: Readonly<Record<string, readonly number[]>> = {
  // NANP (código de país "1"): area code + exchange + subscriber.
  us: [3, 3, 4],
  ca: [3, 3, 4],
  pr: [3, 3, 4],
  do: [3, 3, 4],
  // Centroamérica: 8 dígitos en dos bloques de 4.
  hn: [4, 4],
  gt: [4, 4],
  sv: [4, 4],
  ni: [4, 4],
  cr: [4, 4],
  pa: [4, 4],
  // Otros países LatAm comunes.
  mx: [3, 3, 4],
  co: [3, 3, 4],
};

/** País preferido cuando varios comparten el mismo dialCode (ej. "1" = NANP: EE.UU., Canadá,
 *  Puerto Rico, American Samoa...) — usado por `matchDialCode` para resolver la ambigüedad al
 *  reconocer un número ya guardado, tanto al crear (se escribe/pega manual) como al editar (se
 *  carga desde la BD): no hay forma de saber el país exacto solo con el dialCode sin mirar el
 *  area code, así que se prefiere el país real más usado en vez del primero alfabético. */
export const PREFERRED_COUNTRY_BY_DIAL_CODE: Readonly<Record<string, string>> = {
  '1': 'us',
};
