# Usagi Playground

Investigation date: 2026-06-02
Updated: 2026-06-05 for Usagi v1.1.0 Linux `aarch64` release

## Role

Use Usagi Engine as a Phase 1 playground tool for validating the feel of Ripverse's box, pack, and card reveal loop. Do not treat Usagi as the confirmed final engine for the full game.

## Fit

Usagi is useful for early Ripverse work because it supports rapid 2D pixel-art prototyping, Lua-based iteration, local live reload, simple project structure, and web export.

Use it to answer questions like:

- Does opening a pack feel good?
- Does the card reveal tempo create anticipation?
- Does selling or keeping cards naturally lead into another box?
- Does the UI make the next action obvious?

## Operating Decisions

- Use `usagi dev` for local development and live reload.
- Do not rely on external mobile or PC access to `usagi dev` live reload.
- Use web export for shareable previews.
- Prefer GitHub Pages for visual and milestone checks from external mobile or PC devices.
- Reconsider Tailscale only for private internal previews, server API testing, or non-public tools.

## Current Host Support

The current development host is Linux `aarch64`. Usagi v1.1.0 publishes an official Linux `aarch64` CLI, so local runtime/export validation is available on this host.

Do not replace the Usagi playground with a browser-native substitute unless the user explicitly asks for a fallback. The primary deployable artifact should be the Usagi web export.

Expected local validation command:

```sh
usagi dev playground/usagi
```

Expected local export command:

```sh
usagi export playground/usagi --target web
```

Use GitHub Actions to publish the exported static files to GitHub Pages and as a fallback if the local CLI is unavailable.

## Known Constraints

Usagi is not currently chosen for:

- mobile targets
- medium-to-large polished games
- complex web app integration
- account, backend, or marketplace systems

If Ripverse moves beyond Phase 1 playground validation, re-evaluate the engine before locking architecture around Usagi.

## Initial Playground Target

The first playable loop should stay small:

```text
starting money
box purchase
pack selection
five-card reveal
rarity and value display
sell all or keep
next box
```
