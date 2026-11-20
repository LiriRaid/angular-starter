/** The browser starts the download asynchronously: releasing the URL earlier can leave an empty file. */
const REVOKE_DELAY_MS = 1000;

/** Saves `content` as a file with that name, as if the user had clicked a download link. */
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
