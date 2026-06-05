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

## RPV-INT-002: UI Motion Preset System

### Status

Adopted as a Phase 1 implementation direction. Do not build a broad engine before the feel is validated, but avoid adding one-off motion code when a reusable preset would cover the case.

### Purpose

Keep UI animation consistent, tunable, and reusable.

Ripverse should not accumulate separate hand-coded tweens for every button, label, counter, card, and panel. Repeated UI motion should be named and parameterized.

### Pattern Stack

```text
motion token
named preset
state transition
tween registry
stagger / cascade
acceptance check
```

### Preferred Project Name

Use `MotionPreset` for individual motions and `MotionRegistry` for the runtime system if implemented.

### Preset Vocabulary

Use compact names that describe the physical role:

```text
hover_pop
press_squash
value_bump
rarity_pulse
stagger_in
layout_reflow
snap_return
card_lift
card_settle
pack_rip_jolt
```

### Interaction Contract

- No repeated UI motion should be implemented as an unnamed one-off if it is likely to recur.
- Motion parameters should be centralized enough to tune duration/easing without hunting through unrelated UI code.
- A preset should state its purpose, trigger, animated fields, duration, easing, and expected feel.
- Layout changes should use `layout_reflow` or an equivalent slot/position tween instead of instant target changes.
- Value changes should use a `value_bump` or delayed counter tween so money/value changes feel earned.
- Container children should use staggered delay when appearing as a group.

### Preset Examples

```text
hover_pop:
  trigger: pointer enters selectable UI
  fields: scale, optional z/roll
  easing: outBack or outCirc
  duration: 0.08-0.14s

press_squash:
  trigger: button/card press down
  fields: scale_x, scale_y, y offset
  easing: outQuad then outBack
  duration: 0.05-0.10s

value_bump:
  trigger: money/value/counter changes
  fields: displayed number, scale, color flash
  easing: outCubic for number, outBack for scale
  duration: 0.16-0.35s

stagger_in:
  trigger: multiple cards/results enter
  fields: alpha, y, scale
  easing: outBack
  delay step: 0.025-0.065s

layout_reflow:
  trigger: item removed/inserted/reordered
  fields: display_slot, x/y, depth, scale
  easing: outCubic or critically damped spring
  duration: 0.12-0.22s
```

### Failure Modes To Prevent

#### Ad Hoc Motion Drift

Problem:

```text
each feature invents its own duration/easing/scale behavior
```

Why it fails:

The UI feels inconsistent and every feel adjustment becomes a hunt through scattered code.

Required fix:

Name the motion and route it through a reusable preset or a documented helper.

#### Synchronized Mechanical Entry

Problem:

```text
all result cards / panels / buttons enter on the same frame
```

Why it fails:

It reads as a screen replacement, not a physical sequence.

Required fix:

Use staggered child entry with small offset delays.

#### Linear UI Motion

Problem:

```text
position/scale/value changes interpolate linearly
```

Why it fails:

Linear movement feels robotic unless used intentionally for metronomic or mechanical UI.

Required fix:

Use easing by default. Use linear only when the design explicitly wants constant-speed motion.

### Usagi Implementation Notes

Usagi has low-level drawing and frame update hooks, not a built-in Tween node. A small local tween registry is appropriate once repeated motion code appears.

Minimal shape:

```lua
State.tweens = {}

motion_start(id, preset, target, params)
motion_update(dt)
motion_value(id, field, fallback)
```

For layout motion, prefer animating semantic fields such as `display_slot`, `depth`, and `reveal_progress` instead of directly hard-coding final x/y at multiple call sites.

### Acceptance Checks

- Can the same motion be reused by at least two UI elements?
- Can the duration/easing be tuned in one place?
- Does the motion preserve the core rip loop pace?
- Is there a no-motion or reduced-motion fallback path if the effect becomes distracting?
- Does the motion clarify state change instead of decorating unrelated content?

### Source References

- Lexispell / Godot UI animation summary: https://80.lv/articles/game-developer-explains-how-to-animate-ui-in-godot
- Godot Tween UI value animation: https://docs.godotengine.org/en/3.0/getting_started/step_by_step/ui_code_a_life_bar.html
- Toptal motion design principles: https://www.toptal.com/designers/ux/motion-design-principles
- Roblox easing reference: https://create.roblox.com/docs/building-and-visuals/ui/ui-animations
- Tweening and easing overview: https://gamejuice.co.uk/articles/tweening-easing-animations

## RPV-INT-003: Kinetic Card Drag

### Status

Adopted for card-hand, orbit-card, and pack-result drag prototypes.

### Purpose

Make a dragged card feel like a light physical object held by the player, not a rectangle pinned to the pointer.

### Pattern Stack

```text
card pickup
full-scale lift
lag follow
velocity roll
pointer-offset tilt
layout reflow
spring / back return
```

### Interaction Contract

- On pickup, the card should first read as a front-facing full card.
- The grabbed card should be removed from its layout group visually.
- The remaining layout should reflow immediately and smoothly.
- In a one-direction ordered row, cards before the removed slot should hold position and cards after the removed slot should move forward into the gap.
- Drag position should lag behind pointer movement slightly.
- Roll should respond to horizontal velocity and acceleration.
- Fake 3D X/Y tilt should respond to pointer offset from the card center and drag velocity, but should be subtle at pickup.
- Release should begin card return and layout reflow at the same time.
- Return should restore the original index/slot order smoothly, not snap at the final frame.

### Balatro-Inspired Interpretation

Research and observation suggest the target feel is a stack of small motion layers, not a single transform:

```text
position = smoothed pointer follow
scale = lift toward full card scale
z roll = x velocity + acceleration
y tilt = horizontal pointer offset + x velocity
x tilt = vertical pointer offset + y velocity
shadow = lift/depth signal
return = outBack or spring settle
```

Do not claim exact Balatro internals unless source-confirmed. Treat this as a project motion model inspired by observed card feel.

### Failure Modes To Prevent

#### Pointer Pinning

Problem:

```text
card position equals pointer position every frame
```

Why it fails:

The card feels like a cursor skin, not an object with weight.

Required fix:

Use lag follow or spring follow.

#### Tilt On Pickup

Problem:

```text
card becomes trapezoid / perspective-skewed immediately when picked up
```

Why it fails:

The player expects the card to present itself clearly when grabbed.

Required fix:

Start tilt near zero and introduce tilt from movement, pointer offset, or velocity.

#### Layout Snap On Release

Problem:

```text
return animation finishes -> layout suddenly switches to full group
```

Why it fails:

The final snap breaks the illusion of a physical hand of cards.

Required fix:

Start restoring the full layout target on release, while the returning card is still animating.

#### Wrong Gap Direction

Problem:

```text
when card N is removed, cards before N move backward due to recentering
```

Why it fails:

The hand feels like it is re-sorting arbitrarily.

Required fix:

For ordered rows, keep cards before the removed slot in place and move only cards after the removed slot forward.

### Usagi Implementation Notes

Recommended per-card fields:

```lua
card.slot
card.display_slot
```

Recommended drag state:

```lua
State.drag = {
  index = card_index,
  x = start_x,
  y = start_y,
  target_x = pointer_target_x,
  target_y = pointer_target_y,
  vx = 0,
  vy = 0,
  ax = 0,
  ay = 0,
  angle = 0,
  tilt_x = 0,
  tilt_y = 0,
}
```

For fake perspective, draw the held card as a quad rather than a simple rotated rectangle:

```text
tilted_points(x, y, w, h, roll, tilt_x, tilt_y)
```

Use `display_slot` interpolation for layout reflow:

```lua
card.display_slot = lerp(card.display_slot, target_slot, amount)
```

Gap rule for an ordered row:

```text
if card.slot < removed_slot: target_slot = card.slot
if card.slot > removed_slot: target_slot = card.slot - 1
```

On release:

```text
State.drag -> State.returning
layout target immediately becomes full group
returning card animates to original slot
```

### Acceptance Checks

- Pickup frame shows a readable front-facing card.
- Dragged card has visible lag, not pointer pinning.
- Fast left/right drag creates stronger roll than slow drag.
- Pointer offset creates subtle X/Y perspective tilt only after movement starts.
- Removed card leaves no static hole in the layout.
- Cards before the removed slot do not move backward to fill the gap.
- Release starts both return animation and layout restoration immediately.
- Final frame does not produce a visible layout tick.

### Source References

- Balatro card tilt user observation: https://www.reddit.com/r/balatro/comments/1efcmqc
- Card tilt pattern overview: https://www.hashbuilds.com/patterns/what-is-card-tilt
- 3D card tilt implementation discussion: https://frontendmasters.com/blog/the-deep-card-conundrum/
- Velocity-influenced drag motion reference: https://nathan-mrx.com/en/articles/1

## RPV-INT-004: Game Feel Motion Audit

### Status

Adopted as a review checklist before declaring a motion-heavy interaction “fixed.”

### Purpose

Prevent motion work from becoming a sequence of local patches without a feel model.

Game feel is not just “more animation.” It is the player perceiving control, weight, consequence, clarity, and reward through moment-to-moment response.

### Research Summary

Useful recurring concepts from game feel literature:

```text
real-time control
simulated physicality
polish / juice
clear feedback
anticipation
follow-through
offset and delay
squash and stretch
hit stop / hold beat
screen shake
particles
sound layering
persistent consequence
```

For Ripverse Phase 1, prioritize tactile UI/card motion over broad combat-style effects.

### Motion Audit Questions

Ask these before calling a feel change done:

- What player action triggered the motion?
- What should the motion communicate: selection, weight, reward, danger, rarity, value, or completion?
- Is the first response immediate enough to preserve control?
- Is there a visible follow-through after the initial response?
- Does the effect scale with importance?
- Does the timing match the player’s expectation, or does it fire late?
- Is the motion clarifying state, or only decorating the screen?
- Does it preserve the pace of opening the next pack?
- Could repeated use cause fatigue, noise, or motion sickness?
- Is there a reduced/subtle variant available for effects like shake or heavy post-processing?

### Ripverse Application

Use these mappings:

```text
pack purchase: press_squash + box lift
pack selected: card_lift / pack_lift
wrapper tear: resistance + strip separation + small jolt
common reveal: quick slide, low hold
rare reveal: stronger resistance, staged clue reveal
hit reveal: hold beat + border pulse + snap completion
sell value: value_bump + money trail/counter tween
keep cards: stagger_in inventory tuck
next pack return: layout_reflow, no hard screen reset feel
```

### Failure Modes To Prevent

#### Juice Without Meaning

Problem:

```text
particles, shake, pulse, and tween are added everywhere
```

Why it fails:

The player stops reading motion as information.

Required fix:

Tie each motion to a player action or state change.

#### Delayed Feedback

Problem:

```text
input happens -> feedback starts after a perceptible delay
```

Why it fails:

Control feels mushy even if the animation is pretty.

Required fix:

Provide immediate first-frame response, then use follow-through for polish.

#### Equal Weight For Unequal Events

Problem:

```text
common card and chase hit use the same motion profile
```

Why it fails:

The game loses rarity tension.

Required fix:

Tier motion intensity and timing by event importance.

#### Over-Strong Shake Or Post FX

Problem:

```text
strong shake/post-processing on frequent actions
```

Why it fails:

It causes fatigue and can obscure the card result.

Required fix:

Use shake/post FX sparingly and reserve high intensity for rare events.

### Acceptance Checks

- Every motion-heavy change names the player action and state meaning.
- Important events have stronger or longer feedback than routine events.
- No frequent action uses heavy shake/post-processing by default.
- Layout changes use interpolation, not instant coordinate replacement.
- Easing is intentional; linear motion is justified when used.
- The result still points the player toward opening the next pack.

### Source References

- Steve Swink game feel taxonomy summary: https://gamejuice.co.uk/articles/swink-6-components-game-feel
- Steve Swink, Principles of Virtual Sensation: https://www.gamedeveloper.com/design/principles-of-virtual-sensation
- Designing Game Feel survey: https://arxiv.org/abs/2011.09201
- The Art of Screenshake summary: https://www.gamedesign.gg/knowledge-base/game-design/game-feel-feedback/the-art-of-screenshake-jan-willem-nijman-vlambeer/
- Juice It or Lose It talk notes: https://lilys.ai/notes/784065
- Juice audit checklist: https://gamejuice.co.uk/articles/juice-audit-evaluating-game-feel
