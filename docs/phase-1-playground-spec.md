# Phase 1 Playground Spec

## Goal

Validate whether opening boxes and packs is compelling enough to repeat.

The playground succeeds when the player naturally wants to buy and open the next box after seeing the result of the current one.

## Core Loop

```text
start with money
buy box
choose pack
reveal 5 cards
review rarity and value
sell or keep cards
return to buy box
```

## Non-Goals

Do not include these in the first playground:

- PvP
- trading or marketplace systems
- guilds
- complex economy simulation
- grading
- roguelike runs
- deckbuilding
- account systems
- backend persistence

## Player Resources

Track only the resources needed for the loop:

- `money`: currency used to buy boxes
- `inventory`: kept cards
- `box_count_opened`: total boxes opened this session
- `pack_count_opened`: total packs opened this session
- `cards_seen`: total cards revealed this session

Session-only state is acceptable. Durable save data is optional for the first implementation.

## Box

A box is the purchasable unit.

Minimum fields:

```text
id
name
price
pack_count
set_id
```

Initial target:

```text
Starter Box
price: 100
pack_count: 3
set_id: genesis
```

## Pack

A pack is the reveal unit selected from an opened box.

Minimum fields:

```text
id
name
card_count
set_id
rarity_table
```

Initial target:

```text
Genesis Pack
card_count: 5
```

## Card

A card is the result unit.

Minimum fields:

```text
id
name
set_id
rarity
base_value
```

Rarity should be immediately visible during reveal.

Initial rarity tiers:

```text
common
uncommon
rare
epic
legendary
```

Initial value bands:

```text
common: 5-12
uncommon: 12-25
rare: 30-80
epic: 100-250
legendary: 500-1500
```

## Reveal Flow

The reveal flow is the most important part of Phase 1.

Required states:

```text
closed_pack
opening_pack
card_back
card_reveal
result_summary
sell_or_keep
```

Required feel checks:

- The next input should always be obvious.
- Reveals should have a short anticipation beat before showing the card.
- Higher rarity cards should feel different through color, timing, sound, or motion.
- Result summary should make the value outcome clear without slowing down the next opening.

## Sell Or Keep

After each pack or box result, let the player decide:

```text
sell all
keep all
choose per card
```

For the first implementation, `sell all` and `keep all` are enough. Per-card decisions can wait until the loop feels good.

## Screen States

Minimum screens:

```text
box_shop
box_opening
pack_select
pack_reveal
result_summary
inventory
```

`inventory` can be minimal and does not need collection goals yet.

## Implementation Path

Implement the first playable playground in Usagi and export it to web for shareable checks.

On the current Linux `aarch64` host, local Usagi export may be blocked by the lack of a published v1.0.0 Linux aarch64 CLI. If source build is not practical, use GitHub Actions on an x86_64 runner to run `usagi export --target web` and publish the web export to GitHub Pages.

Recommended Usagi project shape:

```text
playground/usagi/
  main.lua
  data/
    cards.json
    boxes.json
```

Keep the exported preview static and GitHub Pages friendly:

- no backend
- no build step unless it becomes necessary
- no account system
- session-only state by default
- keyboard and gamepad-friendly input
- data files that are easy to tune

Keep logic small and readable:

- Use one `State` table for cross-frame state.
- Keep data in `data/` when it is easier to tune than hard-coded Lua.
- Prefer simple keyboard and mouse input.
- Use local `usagi dev` on supported hosts.
- Use `usagi export playground/usagi --target web` for deployable previews.

## Acceptance Criteria

The first playable playground is complete when:

- player starts with enough money to buy at least one box
- player can buy a box
- box grants packs
- player can select and open a pack
- each pack reveals 5 cards
- each card has rarity and value
- player can sell all revealed cards for money
- player can keep all revealed cards in inventory
- player can return to buy or open another box

## Validation Questions

Ask these after each playable iteration:

- Did the player want to open the next pack?
- Was the reveal pace too slow, too fast, or right?
- Did rarity differences feel meaningful?
- Did the result summary create a clear win/loss feeling?
- Did selling or keeping make the next box feel closer?
- What step created friction before the next opening?
