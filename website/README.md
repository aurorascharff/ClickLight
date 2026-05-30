# ClickLight Website

Minimal homepage for [ClickLight](https://github.com/aurorascharff/ClickLight), built with the Next.js 16 App Router.

The page is meant to feel like a live product demo rather than a marketing site: the background acts as the ClickLight test surface, the floating menu mirrors the macOS menu bar app, and the install command is available directly from the hero.

## Local Development

```bash
npm install
npm run dev
```

Open `http://localhost:3000`, or run a specific port when testing inside Codex:

```bash
npm run dev -- --port 3333 --hostname 127.0.0.1
```

## Scripts

- `npm run dev` starts the local development server.
- `npm run build` creates the production build.
- `npm run start` serves the production build locally.

## Notes

- The ClickLight mark lives in `public/clicklight-icon.png` and is used for the hero logo and favicon.
- Set `NEXT_PUBLIC_SITE_URL` in production if the deployed domain is not provided by Vercel.
- Vercel Analytics is wired in `app/layout.tsx`.
- The demo behavior and controls live in `app/page.tsx`; visual styling lives in `app/globals.css`.
