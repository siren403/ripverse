# Pack Opening System

## Purpose

Ripverse pack opening should feel like a physical card pack ritual, not a static result list.

The system should increase suspense around the same generated cards. Opening techniques may change reveal order, pacing, and presentation, but must not change pull rates or card values.

For the Phase 1 playground, motion is the first validation target. Wrapper tearing, card dragging, sliding, flipping, partial peeks, and pacing should be prototyped before deeper pack-system completeness. Static buttons are acceptable as accessibility fallbacks, but should not be the primary pack-opening interaction.

## Real TCG Reference

Modern Pokemon TCG booster packs are structured around known suspense slots. Pokemon Support describes current booster packs as 10 game cards: 4 commons, 3 uncommons, and 3 foils, with at least one foil rare or higher. Packs also include an Energy card and a code card.

Scarlet & Violet changed the pack structure toward more foil slots. TCGplayer notes that the three foil slots can each carry different rarities, creating larger variation between weak and strong packs.

Common physical opening behaviors:

- Choose a pack before opening.
- Tear or peel the wrapper.
- Remove or ignore the code card.
- Hold the stack back-facing.
- Move cards from the back to the front to make the hit appear later.
- Flip the stack face-up.
- Reveal cards one by one.
- Slow down near reverse, foil, rare, or hit slots.
- Pause longer on rare or better pulls.
- Sort the pack into bulk, keep, sell, sleeve, or next pack.

## Card Trick

The card trick is an opening technique, not a luck modifier.

Observed Pokemon-style patterns:

```text
older / XY-like packs: move 3 from back to front
Sun & Moon / Sword & Shield-like packs: move 4 from back to front
Scarlet & Violet-like packs: move or remove 1 Energy, with less need for the old trick
```

The intent is to reorder the viewing sequence so the rare, holo, or best hit is checked last.

Ripverse should preserve that intent:

```text
generated pack: fixed before opening technique
opening technique: changes reveal order and pacing only
hit slot: revealed last when using trick-based modes
```

## Phase 1 Pack Model

Use a compact five-card pack for the playground.

```text
slot 1: base card
slot 2: base card
slot 3: base card
slot 4: sparkle slot
slot 5: hit slot
```

Slot meanings:

- `base card`: low suspense, fast reveal.
- `sparkle slot`: possible mid-pack surprise.
- `hit slot`: highest suspense, usually last.

The current economy can keep the existing rarity roll for each card, but reveal presentation should treat the strongest or configured hit card as the pack climax.

## Pack Selection

The shop should feel like choosing a physical pack or box, not pressing a form button.

Phase 1 can use a horizontal carousel:

```text
drag left/right -> change focused box
tap focused box -> buy it
keyboard enter -> buy focused box fallback
```

Multiple sample boxes are acceptable for feel validation even before the economy is final.

## Opening Techniques

### Raw Rip

Fast direct opening.

```text
wrapper -> stack -> reveal slot 1 -> slot 2 -> slot 3 -> slot 4 -> slot 5 -> result
```

Use when the player wants speed. Minimal suspense staging.

### Card Trick

Back-facing reorder before reveal.

```text
wrapper -> stack back -> move cards -> flip -> reveal low cards -> sparkle -> hit -> result
```

For the five-card Ripverse pack, the implementation can keep the hit slot last and move one low-value card earlier as the visible "trick" action.

Example:

```text
generated slots: 1 2 3 4 5
reveal order:    2 3 1 4 5
```

The exact order may change later, but `5` should remain last when it is the configured hit slot.

### Slow Roll

Suspense-first reveal, especially near the final card.

```text
wrapper -> stack -> quick commons -> partial border peek -> rarity peek -> full hit reveal -> result
```

For Phase 1 this can be a pacing variant of Card Trick, not a separate economy mode.

## Reveal Pacing

Use variable timing.

```text
base card: short hold
sparkle slot: medium hold
rare or better: long hold
legendary/chase: longest hold plus stronger border or pulse
```

Avoid making every card use the same reveal tempo.

Drag motion should use weighted progress rather than linear position:

```text
low rarity: light, quick slide
rare: slight resistance before border and rarity become readable
epic/legendary: stronger resistance, border peek first, rarity/value/name revealed in stages
```

The goal is for the player to feel a hit before the full card is readable. Border color, pulse, and staged text reveal are valid Phase 1 signals.

## Wrapper Motions

Represent more than one physical opening pattern:

```text
front top tear: horizontal tear line, top strip separates
back seam tear: vertical center seam opens from the back
```

These can share input mechanics in the prototype while using distinct visuals.

## Player Controls

The opening interaction should keep one clear next action.

```text
OPEN STYLE -> RAW / TRICK
DRAG -> tear wrapper
DRAG -> slide next card right or flip stack
SELL / KEEP -> after all cards are revealed
```

Do not show `SELL / KEEP` before the pack reveal is complete.

## Implementation Rules

- Generate the full pack before applying an opening technique.
- Store original generated slot order.
- Store reveal order separately.
- Never let opening technique alter rarity odds, values, or inventory outcome.
- Use the hit slot as a presentation concept first, not a new economy system.
- Keep Phase 1 focused on pack opening feel before adding grading, trading, decks, or collection metas.

## Sources

- Pokemon Support, "What can I expect in a Pokemon Trading Card Game booster pack?"
- TCGplayer, "How Pokemon Booster Packs Are Changing in Scarlet & Violet"
