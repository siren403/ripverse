# Ripverse Harness Context

## North Star

Every Ripverse system should make the player want to open the next pack.

## MVP Boundary

Phase 1 validates the core rip loop:

```text
resource gain
box purchase
pack opening
card reveal
sell or keep
next box
```

Do not prioritize PvP, trading, guilds, complex economies, or meta competition during the initial playground.

## Playground Direction

Use the playground to validate the feeling of opening boxes and packs before committing to larger architecture. The primary target is Usagi Engine exported to web. On the current Linux `aarch64` host, local Usagi export may require source build because the official v1.0.0 installer does not publish a Linux aarch64 CLI. If local export is blocked, use GitHub Actions on an x86_64 runner to export the Usagi project and publish it through GitHub Pages.

## Harness Policy

When a repeated clarification, agent mistake, or project convention appears, use `harness-stabilizer` to decide whether it belongs in:

- `AGENTS.md` for project-wide behavior rules
- `docs/` for domain knowledge and design decisions
- `.codex/skills/` or global skills for repeatable workflows
- scripts for deterministic build/export/validation tasks
- agents for recurring specialist roles

## Turn Closure Policy

End-of-turn direction should preserve the current objective instead of expanding the option space. Prefer one clear next objective or desirable immediate objective over broad recommendations. For Ripverse, default orientation stays on the Phase 1 rip-loop playground unless the user redirects.
