# Ripverse Agent Guidance

## Product North Star

Every Ripverse system should make the player want to open the next pack.

Before proposing or implementing a feature, check whether it strengthens the core rip loop:

```text
resource gain
box purchase
pack opening
card reveal
sell or keep
next box
```

## Phase 1 Scope

Focus Phase 1 on validating whether card opening itself can remain fun for repeated play.

Prioritize:

- boxes
- packs
- opening flow
- card reveal
- sell or keep decisions
- repeatable next-box motivation

Deprioritize for the initial MVP:

- PvP
- trading or marketplace systems
- guilds
- complex economies
- meta competition

## Design System

Use `DESIGN.md` when adding or changing gameplay UI. Keep the Phase 1 playground compact, pixel-oriented, and anchored to the next pack action. Button labels must fit inside their borders; put input hints and guidance in the footer instead of inside buttons.

## Playground Policy

Treat the playground as a fast feel-validation space, not as a final architecture commitment.

For card-pack opening work, prioritize motion and tactile feel before deeper system completeness. A prototype should first validate wrapper tearing, dragging, sliding, flipping, pacing, and reveal feel; then use systems such as reveal order, hit slots, and opening styles to support that feel. Avoid replacing tactile validation with static button-driven flows unless the user explicitly asks for a non-motion fallback.

The primary Phase 1 playground target is Usagi Engine exported to web. On the current Linux `aarch64` host, the official Usagi v1.0.0 installer does not provide a Linux aarch64 CLI, so local Usagi export may require source build. If local export is blocked, use GitHub Actions on an x86_64 runner to run `usagi export --target web` and publish the exported static files to GitHub Pages.

When starting a local static preview server, use the project server script. Prefer foreground mode so the process stays tied to the active Codex exec session and cannot become a dangling server after session end. If background mode is used, stop it with `scripts/stop-web.sh` before ending the turn.

On a headless cloud host, use Tailscale Serve or GitHub Pages for browser access from external devices. For Usagi, serve the actual `usagi export --target web` output, not a browser-native substitute, unless the user explicitly asks for a fallback.

## Harness Policy

When a repeated clarification, agent mistake, or fragile convention appears, use `harness-stabilizer` to decide whether it should become durable guidance in `AGENTS.md`, `docs/`, a skill, a script, or an agent.

## Turn Closure

When ending a work turn, state the next concrete objective or the desirable immediate objective when it is useful for orientation. Keep it as a milestone that preserves direction, not as a broad recommendation list.

Avoid speculative follow-up ideas that could pull the project away from the current objective. For Ripverse, the next objective should remain anchored to the Phase 1 rip-loop playground unless the user redirects the project.
