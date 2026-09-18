# CzechDream Forever

Vue 3 + TypeScript web dashboard, Netlify Functions API, database schema and a playable WoW addon V0.1.

## WoW addon installation

Copy the folder `addon/CzechDreamForever` into your WoW client's `Interface/AddOns/` directory. The folder must contain `CzechDreamForever.toc` directly.

In game:

- `/forever` opens the CzechDream Forever panel.
- `/forever hello` discovers other installed CzechDream Forever players in the guild.
- `/forever crew The Boys` changes the crew name.
- `/forever moment Palo zase spadol z útesu` adds a custom moment.

The addon stores data in `WTF/Account/.../SavedVariables/CzechDreamForever.lua` and synchronizes events through the guild addon channel. No backend or internet connection is required for V0.1.

## Local development

```bash
npm install
npm run dev
```

The web backend endpoint is `POST /api/sync`. Database credentials and the final persistence adapter are intentionally separate from the addon V0.1 flow.
