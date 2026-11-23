# docs

The documentation of AS Starter inside the application, in the style of the Angular guides: a side menu
and one page per topic (`/docs/getting-started`, `/docs/design-base`, `/docs/components`,
`/docs/app-shell` and `/docs/tutorials`). The welcome page links to it.

- `docs.data.ts` holds the pages as data: a title, a summary and blocks (text, heading, list, code,
  note, steps). Add or edit a page there; the routes and the side menu read the list.
- `docs.routes.ts` declares one route per page, loaded lazily from `app.routes.ts` under `docs`.
- `docs.ts` / `docs.html` draw the side menu and the page the route names.

It is the documentation of the starter, not of your product: edit it, replace it with your own, or
delete the `docs` folder, its route in `app.routes.ts`, its item in the navigation tree and the two
cards of `features/home/home.data.ts` that link to it.
