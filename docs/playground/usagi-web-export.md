# Usagi Web Export

## Decision

The Phase 1 browser preview should come from Usagi's web export:

```sh
usagi export playground/usagi --target web
```

The expected exported web package contains:

```text
index.html
usagi.js
usagi.wasm
game.usagi
```

## Current Host Support

The current host is Linux `aarch64`. Usagi v1.1.0 publishes an official Linux `aarch64` CLI asset:

```text
usagi-1.1.0-linux-aarch64.tar.gz
```

Local export is now the preferred first validation path:

```sh
usagi export playground/usagi --target web
```

Local validation on 2026-06-05:

```text
usagi 1.1.0
usagi export playground/usagi --target web
wrote ripverse-playground-web.zip
```

## GitHub Pages Deployment

Use GitHub Actions for the public Pages deployment and as a fallback if local export is unavailable:

```text
checkout repo
install Usagi with official install script
run usagi export playground/usagi --target web
unzip export/*-web.zip
upload the unzipped files as GitHub Pages artifact
deploy Pages
```

This keeps the preview as a real Usagi web export and provides a stable external preview URL.

## Do Not Substitute Silently

Do not publish a browser-native implementation as if it were the Usagi playground. If a browser-native fallback is used, label it explicitly as a fallback and keep the next objective anchored to producing the Usagi web export.
