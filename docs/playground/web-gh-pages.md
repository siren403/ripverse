# Browser-Native Fallback Preview

## Decision

The primary Phase 1 browser preview should be Usagi's web export. Use the browser-native web playground only as an explicitly labeled fallback when Usagi export is blocked and the user accepts a temporary substitute.

## Reason

The Phase 1 goal is to validate the feel of the rip loop, but engine feel still matters. A browser-native fallback can help inspect copy, data, and rough loop structure, but it does not validate Usagi's pixel-art runtime, input handling, web shell, or export pipeline.

## Fallback Scope

If used, the browser-native fallback should implement only the Phase 1 loop:

```text
starting money
box purchase
pack selection
five-card reveal
rarity and value display
sell all or keep
next box
```

Do not add backend persistence, accounts, trading, grading, deckbuilding, or roguelike systems.

## Project Shape

Use a static structure that GitHub Pages can serve directly:

```text
playground/web/
  index.html
  src/
    main.js
    styles.css
  data/
    boxes.json
    cards.json
```

## Preview Policy

Local fallback preview should use the project server script so the process is tracked and does not multiply across Codex sessions.

```sh
scripts/serve-web.sh
```

Default mode runs in the foreground so the server remains tied to the active Codex exec session and is not left dangling after the session ends. It records state under `.server/` and refuses to start a second tracked server.

Use background mode only when explicitly needed:

```sh
scripts/serve-web.sh --background
scripts/stop-web.sh
```

Before ending a turn after using background mode, stop the server with `scripts/stop-web.sh`.

On a headless cloud host, prefer serving the fallback static directory directly through Tailscale Serve when browser access is needed from another device in the tailnet. This avoids keeping a separate Python server alive.

```sh
sudo tailscale serve --bg --http=8082 playground/web
tailscale serve status
```

Disable the Tailscale HTTP preview when it should no longer be exposed:

```sh
sudo tailscale serve --http=8082 off
```

Do not publish this fallback as the canonical preview when a Usagi web export is available.

## Validation

Every preview should answer:

- Does the player want to open the next pack?
- Is the reveal pacing clear?
- Are rarity spikes readable?
- Does sell or keep push the player toward the next box?
