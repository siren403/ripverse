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

## Current Host Constraint

The current host is Linux `aarch64`. The official Usagi v1.0.0 release publishes Linux `x86_64`, macOS `aarch64`, Windows `x86_64`, and wasm runtime assets, but no Linux `aarch64` CLI asset.

Local export options:

- Build Usagi CLI from source on this host after installing Rust and Linux build dependencies.
- Build the v1.0.0 CLI from source and use the v1.0.0 wasm template.
- Use a supported host to run the official installer and export.

## Preferred Fallback

If local export is blocked, use GitHub Actions on an x86_64 runner:

```text
checkout repo
install Usagi with official install script
run usagi export playground/usagi --target web
unzip export/*-web.zip
upload the unzipped files as GitHub Pages artifact
deploy Pages
```

This keeps the preview as a real Usagi web export while avoiding the local Linux `aarch64` CLI limitation.

## Do Not Substitute Silently

Do not publish a browser-native implementation as if it were the Usagi playground. If a browser-native fallback is used, label it explicitly as a fallback and keep the next objective anchored to producing the Usagi web export.
