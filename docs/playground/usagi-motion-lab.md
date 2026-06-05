# Usagi Motion Lab

## Purpose

`playground/usagi-motion-lab` is the temporary primary surface for foundational feel work.

Use it to validate:

- shader treatment
- depth ordering
- drag inertia
- velocity tilt
- card snap and return
- layout reflow
- simple transform readability

Do not treat motion lab results as final card-pack UX. The lab exists because the main Ripverse gameplay surface is still too unstable in card design, UX, and motion fundamentals for every feel tweak to be meaningful.

## Export

```sh
usagi export playground/usagi-motion-lab --target web
```

Current local CLI path:

```sh
.tools/usagi-1.1.0/usagi export playground/usagi-motion-lab --target web
```

Expected output:

```text
ripverse-motion-lab-web.zip
```

## Preview

Use the existing tracked preview server script. Do not start extra untracked static servers.

```sh
python3 -m zipfile -e ripverse-motion-lab-web.zip .preview/usagi-motion-lab-web
HOST=0.0.0.0 PORT=8090 PREVIEW_DIR=/mnt/vol1/ripverse/.preview/usagi-motion-lab-web scripts/serve-usagi-preview.sh
```

Stop it with:

```sh
scripts/stop-usagi-preview.sh
```

If Tailscale Serve is already configured as `8091 -> localhost:8090`, the same external tailnet URL will show whichever Usagi export the local preview server is currently serving.

## Current Controls

```text
drag cards
BTN1 cycle shader
BTN2 / Space select tuning field
Arrow left/right adjust selected field
Arrow up/down coarse-adjust selected field
```

## Main Game Boundary

Avoid applying lab findings to `playground/usagi` until the user explicitly asks to move a motion pattern back into the main game.
