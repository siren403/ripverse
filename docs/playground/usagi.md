# Usagi Playground

Investigation date: 2026-06-02

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

## Current Host Limitation

The current development host is Linux `aarch64`. On 2026-06-02, the official Usagi install script reported that only `x86_64` Linux binaries are published. The playground can be authored here, but runtime validation should happen on a supported Usagi host until an `aarch64` build path is confirmed.

Because of this limitation, do not replace the Usagi playground with a browser-native substitute unless the user explicitly asks for a fallback. The primary deployable artifact should be the Usagi web export.

Expected validation command on a supported host:

```sh
usagi dev playground/usagi
```

Expected export command on a supported host:

```sh
usagi export playground/usagi --target web
```

If local source build is not practical on the current host, use GitHub Actions on an x86_64 runner to run the export and publish the exported static files to GitHub Pages.

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
