# CzechDream Forever

Vue 3 + TypeScript guild website and the CzechDream Lite quality-of-life addon for WoW Forever.

## WoW addon installation

Download the current version from the website or copy `addon/CzechDreamForever` into the WoW client's `Interface/AddOns/` directory. The folder must contain `CzechDreamForever.toc` directly.

In game:

- `/cd`, `/czechdream` or `/forever` opens the settings panel.
- `/cd debug` prints addon diagnostics.
- Hold Shift while talking to a quest NPC to temporarily disable quest automation.

The addon stores its settings in `CzechDreamLiteDB`. It does not need the website, a backend or an internet connection.

The public versioned release archive is stored in `public/downloads/` and is served directly by Netlify.

## Local development

```bash
npm install
npm run dev
```

The web backend endpoint is `POST /api/sync`. Database credentials and the final persistence adapter are intentionally separate from the addon V0.1 flow.
