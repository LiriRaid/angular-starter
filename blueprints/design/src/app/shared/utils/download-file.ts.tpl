/** Lo que se espera antes de liberar la URL: la descarga empieza de forma asíncrona y liberarla antes puede dejar el archivo vacío. */
const REVOKE_DELAY_MS = 1000;

/** Descarga `content` como un archivo con ese nombre. El enlace va al documento mientras se pulsa y la URL se libera después, no en el mismo instante: algunos navegadores cancelan la descarga si se libera antes de que empiece. */
export function downloadFile(content: BlobPart, mime: string, filename: string): void {
  const url = URL.createObjectURL(new Blob([content], { type: mime }));
  const link = document.createElement('a');
  link.href = url;
  link.download = filename;
  document.body.appendChild(link);
  link.click();
  link.remove();
  setTimeout(() => URL.revokeObjectURL(url), REVOKE_DELAY_MS);
}
