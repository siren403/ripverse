# Interaction Pattern Database

This document stores reusable interaction and motion knowledge for Ripverse harness decisions.

Use it when changing pack opening, card reveal, drag gestures, snap motion, or tactile feedback in the Phase 1 playground.

## RPV-INT-001: Resistance Snap Reveal

### Status

Adopted for Phase 1 card reveal prototyping.

### Purpose

Make card reveal feel tactile instead of like a static result transition.

The player should feel:

```text
drag -> resistance -> threshold -> visible snap -> reveal advance
```

### Pattern Stack

```text
direct manipulation
elastic / rubber-band drag
threshold commit
visible snap animation
progressive reveal
```

### Preferred Project Name

Use `ResistanceSnapReveal` in docs and code comments when a compact name is needed.

Descriptive phrase:

```text
elastic drag + threshold commit + outCirc snap + progressive reveal
```

### Interaction Contract

- Dragged cards must respond to pointer movement before the threshold.
- Resistance may reduce card movement relative to pointer movement.
- The threshold must commit the reveal gesture.
- The committed snap must be visible over multiple frames.
- Releasing input must not skip the snap animation.
- The reveal should advance only after the snap animation completes.
- High-rarity cards should delay readable rarity clues longer than low-rarity cards.

### Failure Modes To Prevent

#### Teleport Snap

Problem:

```text
threshold crossed -> card position immediately becomes final position
```

Why it fails:

The player sees a coordinate jump, not a tactile snap.

Required fix:

Use a time-based snap state that persists independently from pointer movement.

#### Input-Held-Only Snap

Problem:

```text
snap easing is calculated only while mouse/touch is held
release -> reveal advances immediately
```

Why it fails:

The code has easing, but the player never sees it because the state transition consumes the frame.

Required fix:

Store snap state outside the active drag object. Continue drawing the dragged card until snap completion.

#### Linear Tail

Problem:

```text
threshold crossed -> card follows remaining pointer movement linearly
```

Why it fails:

The gesture feels like normal dragging instead of a decisive commit.

Required fix:

After threshold, stop following pointer movement and animate toward the final position.

### Usagi Implementation Notes

Recommended state shape:

```lua
State.card_snap = {
  axis = "horizontal" or "vertical",
  from = current_distance,
  to = open_distance,
  duration = snap_duration,
  started_at = usagi.elapsed,
}
```

Update loop:

```text
if State.card_snap exists:
  update snap animation
  return before normal drag handling
```

Draw loop:

```text
if State.card_snap exists:
  draw next card with reveal progress
  draw dragged card at animated snap position
```

Transition rule:

```text
advance_pack_reveal() only after snap animation reaches t >= 1
```

### Easing

Use `outCirc` for the committed snap unless a feel test says otherwise.

Formula:

```lua
local shifted = t - 1
return math.sqrt(1 - shifted * shifted)
```

Feel:

```text
fast initial pull -> soft final settle
```

### Reveal Direction Semantics

Horizontal drag:

```text
fast reveal / quick check
```

Vertical drag:

```text
suspense reveal / slow roll
```

Vertical reveal should support delayed information exposure:

```text
frame / border -> rarity symbol -> name -> value
```

High-rarity cards should not expose rarity-defining clues immediately.

### Acceptance Checks

Before reporting this interaction fixed:

- Verify threshold crossing does not immediately call `advance_pack_reveal()`.
- Verify a persistent snap state exists outside `State.drag`.
- Verify the dragged card is still drawn while snapping.
- Verify the next reveal state starts only after snap completion.
- Verify `rg` does not find obsolete linear snap fields such as `snap_rate` or `snap_window` if they were intentionally removed.
- Verify local Usagi export succeeds when the CLI is available, or verify the Pages export succeeds when local export is unavailable.

## Reference Vocabulary

Use these terms when researching or explaining this pattern:

- direct manipulation
- drag-to-reveal interaction
- elastic drag interaction
- rubber-band interaction
- threshold gesture
- commit threshold
- snap interaction
- progressive reveal
- progressive disclosure
- easeOutCirc / outCirc

## Source References

- Material Design, Gestures: https://m2.material.io/design/interaction/gestures.html
- Apple Human Interface Guidelines, Scroll Views: https://developer.apple.com/design/human-interface-guidelines/scroll-views
- Microsoft, Cross-slide guidelines: https://learn.microsoft.com/en-us/windows/apps/design/input/guidelines-for-cross-slide
- Interaction Design Foundation, Progressive Disclosure: https://www.interaction-design.org/literature/topics/progressive-disclosure
- Robert Penner easing references: https://robertpenner.com/easing/
