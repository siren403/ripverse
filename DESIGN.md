# Ripverse Design System

## Product Feeling

Ripverse should feel like a focused pack-ripping machine: compact, readable, tense before the reveal, and fast after the result.

The UI should always answer:

- What can I do next?
- What did I just get?
- Did this result move me closer to the next box?

## Constraints

The Phase 1 playground targets Usagi's default pixel-art frame.

```text
canvas: 320x180
style: pixel UI
layout: fixed, no scrolling
input: keyboard/gamepad primary, mouse click supported
```

Avoid text-heavy panels. Use short labels and put input help in the footer.

## Screen Anatomy

```text
0-23      top status bar
24-135    active stage
136-163   actions / result value
164-179   footer hint / feedback
```

Keep these regions stable across screens so opening, selling, and returning to the next box never feels like a navigation puzzle.

## Layout Tokens

Treat coordinates as named layout tokens before placing UI.

```text
screen: w=320 h=180
status: x=0 y=0 w=320 h=24
main panel: x=18 y=38 w=284 h=86
focused panel: x=70 y=44 w=180 h=94
inventory panel: x=12 y=34 w=296 h=124
button: w=126 h=16
two-button group: gap=16 centered in 320px frame
default button row: y=138
result value row: y=132
result button row: y=150
footer: y=168 left x=8 right x=312
```

Do not hand-place paired buttons. Use the centered two-button group token so `OPEN/CARDS`, `BUY/CARDS`, and `SELL/KEEP` share the same horizontal rhythm.

Keep text in measured containers. If text can vary by data, draw it through a fit/truncate helper instead of assuming character count.

## Palette Roles

Use colors by role, not decoration.

```text
background: black
surface: dark blue
surface-strong: dark purple
text: white
muted: light gray
money: yellow
positive action: green
secondary action: blue
danger/blocking: red
legendary/chase: orange
```

Rarity colors:

```text
common: light gray
uncommon: green
rare: blue
epic: pink
legendary: orange
```

## Components

### Status Bar

Always show:

```text
money
boxes opened
packs opened
cards seen
kept cards
```

Status values should be compact but recognizable. Prefer `BOX 1`, `PACK 1`, `SEEN 5`, `KEPT 5` over single-letter counters like `B1`, `P1`, `C5`, `K5`.

### Panels

Use panels for the current task only. A panel should contain one decision or one result.

Preferred panel sizes:

```text
main panel: x=18 y=38 w=284 h=86
focused panel: x=70 y=44 w=180 h=94
inventory panel: x=12 y=34 w=296 h=124
```

### Buttons

Buttons must use short action labels that fit inside the border.

Good:

```text
BUY
OPEN
SELL
KEEP
CARDS
BACK
```

Avoid:

```text
CLICK / BTN1 OPEN PACK
BTN2 / SPACE INVENTORY
```

Input hints belong in the footer.

### Cards

Cards should make rarity and value readable at a glance.

Minimum card fields shown:

```text
name
rarity
value
```

Card text must stay inside the card border. Fit dynamic fields to the card text width instead of clipping or allowing overflow.

Higher rarity should differ by border color and reveal hold timing. Legendary cards may add a stronger border or pulse, but avoid effects that slow down the next pack.

### Footer

Use the footer for:

```text
current feedback
available input hint
next action orientation
```

Keep footer text short enough for 320px width.

Use a split footer: feedback on the left, input hint right-aligned on the right. Both sides must be measured or truncated so they do not collide.

## Copy Rules

Use direct action language.

Good:

```text
Buy a box.
Choose a pack.
Sell or keep.
Next box?
```

Avoid tutorial prose inside the game frame.

## Phase 1 UX Rules

- The primary action should be visually leftmost.
- The secondary action should be right of the primary action.
- A result screen must make total value obvious.
- The player should never wonder how to return to the next pack or box.
- Do not introduce collection goals, grading, trading, or deckbuilding UI in Phase 1.
