local boxes = usagi.read_json("boxes.json")
local cards = usagi.read_json("cards.json")
local rarities = usagi.read_json("rarities.json")
local pack_models = usagi.read_json("pack_models.json")

local COLOR = {
  BG = gfx.COLOR_BLACK,
  PANEL = gfx.COLOR_DARK_BLUE,
  PANEL_DARK = gfx.COLOR_DARK_PURPLE,
  TEXT = gfx.COLOR_WHITE,
  MUTED = gfx.COLOR_LIGHT_GRAY,
  MONEY = gfx.COLOR_YELLOW,
  GOOD = gfx.COLOR_GREEN,
  BAD = gfx.COLOR_RED,
  COMMON = gfx.COLOR_LIGHT_GRAY,
  UNCOMMON = gfx.COLOR_GREEN,
  RARE = gfx.COLOR_BLUE,
  EPIC = gfx.COLOR_PINK,
  LEGENDARY = gfx.COLOR_ORANGE,
}

local RARITY_COLORS = {
  common = COLOR.COMMON,
  uncommon = COLOR.UNCOMMON,
  rare = COLOR.RARE,
  epic = COLOR.EPIC,
  legendary = COLOR.LEGENDARY,
}

local SCREEN_W = 320
local STATUS_H = 24
local FOOTER_Y = 168
local FOOTER_LEFT_X = 8
local FOOTER_RIGHT_X = 312
local PANEL_MAIN = { x = 18, y = 38, w = 284, h = 86 }
local PANEL_FOCUS = { x = 70, y = 44, w = 180, h = 94 }
local PANEL_INVENTORY = { x = 12, y = 34, w = 296, h = 124 }
local CARD_W = 50
local CARD_H = 68
local CARD_GAP = 8
local CARD_Y = 62
local STACK_CARD_X = 118
local STACK_CARD_Y = 70
local DRAG_COMMIT_DISTANCE = 58
local TEAR_GESTURE_DISTANCE = 44
local BACK_TEAR_GESTURE_DISTANCE = 62
local PACK_X = 126
local PACK_Y = 58
local PACK_W = 68
local PACK_H = 88
local PACK_TEAR_W = PACK_W
local PACK_SEAM_H = 80
local PACK_QUEUE_X = 24
local PACK_QUEUE_Y = 66
local PACK_QUEUE_STEP_X = 7
local PACK_QUEUE_STEP_Y = 5
local PACK_TURN_DISTANCE = 72
local CARD_PAD_X = 5
local CARD_TEXT_W = CARD_W - CARD_PAD_X * 2
local SPR = {
  pack_front = { sx = 0, sy = 0, sw = 80, sh = 104 },
  pack_back = { sx = 80, sy = 0, sw = 80, sh = 104 },
  card_base = { sx = 0, sy = 112, sw = 64, sh = 88 },
  card_rare = { sx = 64, sy = 112, sw = 64, sh = 88 },
  card_epic = { sx = 128, sy = 112, sw = 64, sh = 88 },
  card_legendary = { sx = 192, sy = 112, sw = 64, sh = 88 },
  tear = { sx = 0, sy = 220, sw = 256, sh = 24 },
}
local SHOP_ITEM_W = 72
local SHOP_ITEM_H = 78
local SHOP_CENTER_X = 124
local SHOP_Y = 58
local SHOP_GAP = 22
local SHOP_DRAG_THRESHOLD = 16
local SHOP_ITEM_ROT_STEP = 0.11
local BUTTON_W = 126
local BUTTON_H = 16
local BUTTON_GAP = 16
local BUTTON_ROW_Y = 138
local RESULT_VALUE_Y = 132
local RESULT_BUTTON_Y = 150
local HIT_H = 20
local TWO_BUTTONS_X = math.floor((SCREEN_W - BUTTON_W * 2 - BUTTON_GAP) / 2)
local ONE_BUTTON_X = math.floor((SCREEN_W - BUTTON_W) / 2)

local HITBOX = {
  active_pack = { x = PACK_X, y = PACK_Y, w = PACK_W, h = PACK_H },
  result_sell = { x = TWO_BUTTONS_X, y = RESULT_BUTTON_Y, w = BUTTON_W, h = HIT_H },
  result_keep = { x = TWO_BUTTONS_X + BUTTON_W + BUTTON_GAP, y = RESULT_BUTTON_Y, w = BUTTON_W, h = HIT_H },
  inventory_back = { x = ONE_BUTTON_X, y = RESULT_BUTTON_Y, w = BUTTON_W, h = HIT_H },
}

local advance_primary
local advance_secondary
local handle_mouse_click
local update_shop_drag
local update_pack_select_drag
local update_pack_drag
local buy_box
local selected_box
local sync_packs_remaining
local start_pack
local advance_pack_reveal
local begin_face_up_reveal
local update_reveal
local generate_pack
local generate_slot_pack
local generate_flat_pack
local pack_model_by_id
local roll_pack_event
local slot_rarity_table
local build_reveal_order
local strongest_card_index
local hit_card_index
local roll_rarity
local cards_by_rarity
local roll_value
local total_value
local rarity_score
local rarity_info
local rarity_color
local rarity_label
local pack_event_label
local sell_all
local keep_all
local after_pack_decision
local toggle_inventory
local next_screen_after_inventory
local draw_header
local draw_box_shop
local draw_box_carousel
local draw_box_card
local draw_rotated_pack_card
local draw_rotated_rect_fill
local draw_rotated_rect
local rotated_rect_points
local rotate_point
local draw_box_opening
local draw_pack_select
local draw_pack_queue
local draw_active_pack
local draw_pack_face
local draw_pack_reveal
local draw_pack_status
local draw_pack_wrapper
local draw_pack_stack
local draw_flip_stack
local draw_current_reveal_card
local draw_reveal_cards
local draw_sprite_part
local draw_sprite_scaled
local card_sprite_for
local draw_card
local draw_card_sprite_frame
local draw_card_fields
local draw_card_suspense
local draw_card_back
local draw_card_peek
local draw_tension_line
local draw_result_summary
local draw_inventory
local draw_footer
local footer_hint
local draw_panel
local draw_button
local draw_button_group
local draw_right_text
local draw_fit_text
local drag_progress
local rubber_band_drag
local drag_profile
local reveal_clue_progress
local point_in_rect
local fit_text

function _config()
  return {
    name = "Ripverse Playground",
    game_id = "ripverse.playground.usagi",
    pixel_perfect = true,
  }
end

function _init()
  State = {
    screen = "box_shop",
    money = 300,
    inventory = {},
    selected_box_index = 1,
    shop_offset = 0,
    shop_drag = nil,
    pack_queue = {},
    pack_turn = 0,
    pack_side = "front",
    packs_remaining = 0,
    current_box = nil,
    pack_cards = {},
    current_pack_event = nil,
    reveal_order = {},
    opening_style = "raw",
    revealed_cards = {},
    reveal_index = 0,
    reveal_timer = 0,
    reveal_phase = "idle",
    drag = nil,
    drag_card = nil,
    tear_dir = 1,
    tear_progress = 0,
    trick_progress = 0,
    card_drag_x = 0,
    card_drag_y = 0,
    card_drag_progress = 0,
    card_pointer_x = 0,
    card_tension_gap = 0,
    card_snap_ready = false,
    box_count_opened = 0,
    pack_count_opened = 0,
    cards_seen = 0,
    last_pack_value = 0,
    transition_timer = 0,
    message = "Drag packs. Tap to buy.",
  }
end

function _update(dt)
  if input.pressed(input.BTN1) or input.key_pressed(input.KEY_ENTER) then
    advance_primary()
  end

  if input.pressed(input.BTN2) or input.key_pressed(input.KEY_SPACE) then
    advance_secondary()
  end

  if input.key_pressed(input.KEY_I) and State.screen ~= "pack_reveal" then
    toggle_inventory()
  end

  if State.screen == "box_shop" then
    update_shop_drag()
  elseif State.screen == "pack_select" then
    update_pack_select_drag()
  end

  if State.screen == "pack_reveal" then
    update_pack_drag()
  end

  if input.mouse_pressed(input.MOUSE_LEFT) then
    handle_mouse_click()
  end

  if State.screen == "pack_reveal" then
    update_reveal(dt)
  elseif State.screen == "box_opening" then
    State.transition_timer = State.transition_timer + dt
    if State.transition_timer >= 0.55 then
      State.screen = "pack_select"
      State.message = "Box opened. Choose a pack."
    end
  end
end

function _draw(_dt)
  gfx.clear(COLOR.BG)
  draw_header()

  if State.screen == "box_shop" then
    draw_box_shop()
  elseif State.screen == "box_opening" then
    draw_box_opening()
  elseif State.screen == "pack_select" then
    draw_pack_select()
  elseif State.screen == "pack_reveal" then
    draw_pack_reveal()
  elseif State.screen == "result_summary" then
    draw_result_summary()
  elseif State.screen == "inventory" then
    draw_inventory()
  end

  draw_footer()
end

function advance_primary()
  if State.screen == "box_shop" then
    buy_box(selected_box())
  elseif State.screen == "pack_select" then
    start_pack()
  elseif State.screen == "pack_reveal" then
    advance_pack_reveal()
  elseif State.screen == "result_summary" then
    sell_all()
  elseif State.screen == "inventory" then
    State.screen = next_screen_after_inventory()
  end
end

function advance_secondary()
  if State.screen == "result_summary" then
    keep_all()
  elseif State.screen == "box_shop" then
    toggle_inventory()
  end
end

function handle_mouse_click()
  local mx, my = input.mouse()

  if State.screen == "pack_reveal" then
    return
  end

  if State.screen == "box_shop" then
    return
  elseif State.screen == "pack_select" then
    return
  elseif State.screen == "result_summary" then
    if point_in_rect(mx, my, HITBOX.result_sell) then
      sell_all()
    elseif point_in_rect(mx, my, HITBOX.result_keep) then
      keep_all()
    end
  elseif State.screen == "inventory" then
    if point_in_rect(mx, my, HITBOX.inventory_back) then
      State.screen = next_screen_after_inventory()
    end
  end
end

function update_shop_drag()
  local mx, my = input.mouse()
  local in_bounds = mx >= 0 and mx < usagi.GAME_W and my >= 0 and my < usagi.GAME_H
  local carousel_rect = { x = 0, y = 48, w = SCREEN_W, h = 92 }

  if in_bounds and input.mouse_pressed(input.MOUSE_LEFT) and point_in_rect(mx, my, carousel_rect) then
    State.shop_drag = {
      start_x = mx,
      last_x = mx,
      start_offset = State.shop_offset,
      moved = false,
    }
  end

  if State.shop_drag and input.mouse_held(input.MOUSE_LEFT) then
    local dx = mx - State.shop_drag.start_x
    State.shop_drag.last_x = mx
    State.shop_offset = State.shop_drag.start_offset + dx
    if math.abs(dx) >= SHOP_DRAG_THRESHOLD then
      State.shop_drag.moved = true
    end
  elseif State.shop_drag and input.mouse_released(input.MOUSE_LEFT) then
    local dx = mx - State.shop_drag.start_x

    if math.abs(dx) >= SHOP_DRAG_THRESHOLD then
      if dx < 0 then
        State.selected_box_index = math.min(#boxes, State.selected_box_index + 1)
      else
        State.selected_box_index = math.max(1, State.selected_box_index - 1)
      end
      State.message = "Pick a box."
    elseif in_bounds and point_in_rect(mx, my, carousel_rect) then
      buy_box(selected_box())
    end

    State.shop_offset = 0
    State.shop_drag = nil
  elseif State.shop_drag and not input.mouse_held(input.MOUSE_LEFT) then
    State.shop_offset = 0
    State.shop_drag = nil
  end
end

function update_pack_select_drag()
  local mx, my = input.mouse()
  local in_bounds = mx >= 0 and mx < usagi.GAME_W and my >= 0 and my < usagi.GAME_H

  if not in_bounds then
    if not input.mouse_held(input.MOUSE_LEFT) then
      State.drag = nil
    end
    return
  end

  if input.mouse_pressed(input.MOUSE_LEFT) and point_in_rect(mx, my, HITBOX.active_pack) then
    State.drag = {
      kind = "pack_turn",
      start_x = mx,
      start_turn = State.pack_turn,
      moved = false,
    }
  end

  if State.drag and State.drag.kind == "pack_turn" and input.mouse_held(input.MOUSE_LEFT) then
    local dx = mx - State.drag.start_x
    State.pack_turn = math.max(0, math.min(1, State.drag.start_turn + dx / PACK_TURN_DISTANCE))
    State.pack_side = State.pack_turn >= 0.5 and "back" or "front"
    if math.abs(dx) >= SHOP_DRAG_THRESHOLD then
      State.drag.moved = true
    end
  elseif State.drag and State.drag.kind == "pack_turn" then
    State.pack_turn = State.pack_turn >= 0.5 and 1 or 0
    State.pack_side = State.pack_turn >= 0.5 and "back" or "front"
    if State.drag.moved then
      State.message = State.pack_side == "back" and "Back seam staged." or "Top tear staged."
    else
      start_pack()
    end
    State.drag = nil
  end
end

function update_pack_drag()
  local mx, my = input.mouse()
  local in_bounds = mx >= 0 and mx < usagi.GAME_W and my >= 0 and my < usagi.GAME_H

  if not in_bounds then
    if not input.mouse_held(input.MOUSE_LEFT) then
      State.drag = nil
    end
    return
  end

  if input.mouse_pressed(input.MOUSE_LEFT) then
    if State.reveal_phase == "wrapper" and point_in_rect(mx, my, HITBOX.active_pack) then
      State.tear_dir = mx >= PACK_X + PACK_W / 2 and -1 or 1
      State.drag = { kind = "tear", start_x = mx, start_y = my, tear_dir = State.tear_dir }
    elseif State.reveal_phase == "card_reveal"
      and State.reveal_index <= #State.revealed_cards
      and point_in_rect(mx, my, { x = STACK_CARD_X, y = STACK_CARD_Y, w = CARD_W, h = CARD_H }) then
      State.drag = { kind = "card", start_x = mx }
      State.drag.start_y = my
      State.drag.axis = nil
      State.drag_card = State.revealed_cards[State.reveal_index]
      State.card_drag_x = STACK_CARD_X
      State.card_drag_y = STACK_CARD_Y
      State.card_pointer_x = STACK_CARD_X
      State.card_tension_gap = 0
      State.card_snap_ready = false
    end
  end

  if State.drag and input.mouse_held(input.MOUSE_LEFT) then
    if State.drag.kind == "tear" then
      if State.opening_style == "trick" then
        State.tear_progress = drag_progress(my - State.drag.start_y, BACK_TEAR_GESTURE_DISTANCE)
      elseif State.drag.tear_dir < 0 then
        State.tear_progress = drag_progress(State.drag.start_x - mx, TEAR_GESTURE_DISTANCE)
      else
        State.tear_progress = drag_progress(mx - State.drag.start_x, TEAR_GESTURE_DISTANCE)
      end
    elseif State.drag.kind == "card" then
      local reveal_card = State.revealed_cards[State.reveal_index + 1] or State.drag_card
      local profile = drag_profile(reveal_card)
      local raw_dx = mx - State.drag.start_x
      local raw_dy = State.drag.start_y - my
      if State.drag.axis == nil and (math.abs(raw_dx) > 5 or math.abs(raw_dy) > 5) then
        State.drag.axis = math.abs(raw_dy) > math.abs(raw_dx) + 4 and "vertical" or "horizontal"
      end

      if State.drag.axis == "vertical" then
        local pointer_dy = math.max(0, raw_dy)
        local card_dy = rubber_band_drag(pointer_dy, profile)
        State.card_pointer_x = STACK_CARD_X
        State.card_drag_x = STACK_CARD_X
        State.card_drag_y = STACK_CARD_Y - math.floor(card_dy)
        State.card_drag_progress = math.max(0, math.min(1, card_dy / DRAG_COMMIT_DISTANCE))
        State.card_tension_gap = math.max(0, pointer_dy - card_dy)
        State.card_snap_ready = pointer_dy >= profile.breakpoint
      else
        local pointer_dx = math.max(0, raw_dx)
        local card_dx = rubber_band_drag(pointer_dx, profile)
        State.card_pointer_x = STACK_CARD_X + pointer_dx
        State.card_drag_x = STACK_CARD_X + math.floor(card_dx)
        State.card_drag_y = STACK_CARD_Y
        State.card_drag_progress = math.max(0, math.min(1, card_dx / DRAG_COMMIT_DISTANCE))
        State.card_tension_gap = math.max(0, pointer_dx - card_dx)
        State.card_snap_ready = pointer_dx >= profile.breakpoint
      end
    end
  elseif State.drag then
    if State.drag.kind == "tear" then
      if State.tear_progress >= 0.75 then
        advance_pack_reveal()
      else
        State.tear_progress = 0
      end
    elseif State.drag.kind == "card" then
      if State.card_snap_ready then
        advance_pack_reveal()
      end
    end

    State.drag = nil
    State.drag_card = nil
    State.card_drag_x = 0
    State.card_drag_y = 0
    State.card_drag_progress = 0
    State.card_pointer_x = 0
    State.card_tension_gap = 0
    State.card_snap_ready = false
  end
end

function buy_box(box)
  if State.money < box.price then
    State.message = "Not enough money. Sell cards or reset."
    return
  end

  State.money = State.money - box.price
  State.current_box = box
  State.pack_queue = {}
  for i = 1, box.pack_count do
    table.insert(State.pack_queue, { index = i, box_id = box.id })
  end
  sync_packs_remaining()
  State.pack_turn = 0
  State.pack_side = "front"
  State.box_count_opened = State.box_count_opened + 1
  State.transition_timer = 0
  State.message = "Opening box..."
  State.screen = "box_opening"
end

function selected_box()
  return boxes[State.selected_box_index] or boxes[1]
end

function sync_packs_remaining()
  State.packs_remaining = #State.pack_queue
end

function start_pack(opening_style)
  if #State.pack_queue <= 0 then
    State.screen = "box_shop"
    State.message = "No packs left. Buy the next box."
    return
  end

  table.remove(State.pack_queue, 1)
  sync_packs_remaining()
  State.pack_count_opened = State.pack_count_opened + 1
  opening_style = opening_style or (State.pack_side == "back" and "trick" or "raw")
  State.opening_style = opening_style
  State.pack_cards = generate_pack(State.current_box)
  if #State.pack_cards > 0 then
    State.current_pack_event = State.pack_cards[1].pack_event
  else
    State.current_pack_event = nil
  end
  State.reveal_order = build_reveal_order(State.pack_cards, opening_style)
  State.revealed_cards = {}
  for _, card_index in ipairs(State.reveal_order) do
    table.insert(State.revealed_cards, State.pack_cards[card_index])
  end
  State.reveal_index = 0
  State.reveal_timer = 0
  State.reveal_phase = "wrapper"
  State.drag = nil
  State.drag_card = nil
  State.tear_progress = 0
  State.tear_dir = 1
  State.trick_progress = 0
  State.card_drag_x = 0
  State.card_drag_y = 0
  State.card_drag_progress = 0
  State.last_pack_value = total_value(State.pack_cards)
  State.pack_turn = opening_style == "trick" and 1 or 0
  State.pack_side = opening_style == "trick" and "back" or "front"
  if opening_style == "trick" then
    State.message = "Back-facing trick."
  else
    State.message = "Raw rip."
  end
  State.screen = "pack_reveal"
end

function advance_pack_reveal()
  State.reveal_timer = 0

  if State.reveal_phase == "wrapper" then
    if State.opening_style == "trick" then
      State.reveal_phase = "trick_stack"
      State.trick_progress = 0
      State.message = "Card trick."
    else
      begin_face_up_reveal()
    end
  elseif State.reveal_phase == "trick_stack" then
    State.reveal_phase = "flip_stack"
    State.trick_progress = 0
    State.message = "Flip the stack."
  elseif State.reveal_phase == "flip_stack" then
    begin_face_up_reveal()
  elseif State.reveal_phase == "card_reveal" then
    if State.reveal_index >= #State.revealed_cards then
      State.screen = "result_summary"
      State.reveal_phase = "idle"
      State.message = "Sell or keep."
    else
      State.reveal_index = State.reveal_index + 1
      State.cards_seen = State.cards_seen + 1
      if State.reveal_index >= #State.revealed_cards then
        State.message = "Slide card to finish."
      else
        State.message = "Slide next card."
      end
    end
  end
end

function begin_face_up_reveal()
  State.reveal_index = 1
  State.cards_seen = State.cards_seen + 1
  State.reveal_phase = "card_reveal"

  if State.reveal_index >= #State.revealed_cards then
    State.message = "Final card."
  else
    State.message = "Slide top card."
  end
end

function update_reveal(dt)
  State.reveal_timer = State.reveal_timer + dt

  if State.screen == "pack_reveal" and State.reveal_phase == "trick_stack" then
    State.trick_progress = math.min(1, State.reveal_timer / 1.05)
    if State.trick_progress >= 1 then
      State.reveal_phase = "flip_stack"
      State.reveal_timer = 0
      State.trick_progress = 0
      State.message = "Flip the stack."
    end
  elseif State.screen == "pack_reveal" and State.reveal_phase == "flip_stack" then
    State.trick_progress = math.min(1, State.reveal_timer / 0.55)
    if State.trick_progress >= 1 then
      begin_face_up_reveal()
    end
  end

  if State.screen == "pack_reveal"
    and State.reveal_phase == "card_reveal"
    and State.reveal_index >= #State.revealed_cards
    and State.reveal_timer >= 0.75 then
    State.screen = "result_summary"
    State.reveal_phase = "idle"
    State.message = "Sell or keep."
  end
end

function generate_pack(box)
  local pack = box.pack
  local model = pack_model_by_id(pack.model_id)

  if model ~= nil then
    return generate_slot_pack(pack, model)
  end

  return generate_flat_pack(pack)
end

function generate_slot_pack(pack, model)
  local result = {}
  local event = roll_pack_event(pack, model)

  for i, slot in ipairs(model.slots) do
    local rarity = roll_rarity(slot_rarity_table(pack, slot, event))
    local pool = cards_by_rarity(rarity)
    local template = pool[math.random(1, #pool)]
    local value = roll_value(template.value_min, template.value_max)
    table.insert(result, {
      id = template.id,
      name = template.name,
      set_id = template.set_id,
      rarity = template.rarity,
      base_value = value,
      slot = slot.slot,
      slot_index = i,
      slot_label = slot.label,
      treatment = slot.treatment,
      pack_event = event,
    })
  end

  return result
end

function pack_model_by_id(model_id)
  for _, model in ipairs(pack_models) do
    if model.id == model_id then
      return model
    end
  end

  return pack_models[1]
end

function roll_pack_event(pack, model)
  local events = model.pack_events
  if events == nil then
    return { id = "normal", label = "Normal Pack" }
  end

  if pack.event_override ~= nil then
    for _, event in ipairs(events) do
      if event.id == pack.event_override then
        return event
      end
    end
  end

  local roll = math.random()
  local cursor = 0

  for _, event in ipairs(events) do
    cursor = cursor + event.weight
    if roll <= cursor then
      return event
    end
  end

  return events[#events]
end

function slot_rarity_table(pack, slot, event)
  if event ~= nil
    and event.slot_overrides ~= nil
    and event.slot_overrides[slot.slot] ~= nil then
    return event.slot_overrides[slot.slot]
  end

  if pack.slot_overrides ~= nil and pack.slot_overrides[slot.slot] ~= nil then
    return pack.slot_overrides[slot.slot]
  end

  return slot.rarity_table
end

function generate_flat_pack(pack)
  local result = {}

  for i = 1, pack.card_count do
    local rarity = roll_rarity(pack.rarity_table)
    local pool = cards_by_rarity(rarity)
    local template = pool[math.random(1, #pool)]
    local value = roll_value(template.value_min, template.value_max)
    table.insert(result, {
      id = template.id,
      name = template.name,
      set_id = template.set_id,
      rarity = template.rarity,
      base_value = value,
      slot = "wild_" .. i,
      slot_index = i,
      slot_label = "wild",
      treatment = "base",
    })
  end

  return result
end

function build_reveal_order(card_list, opening_style)
  local result = {}

  for i = 1, #card_list do
    table.insert(result, i)
  end

  if opening_style ~= "trick" then
    return result
  end

  local hit_index = hit_card_index(card_list)
  table.remove(result, hit_index)
  table.insert(result, hit_index)
  return result
end

function hit_card_index(card_list)
  for i, card in ipairs(card_list) do
    if card.slot == "hit" then
      return i
    end
  end

  return strongest_card_index(card_list)
end

function strongest_card_index(card_list)
  local best_index = #card_list
  local best_score = -1

  for i, card in ipairs(card_list) do
    local score = rarity_score(card) * 10000 + card.base_value
    if score >= best_score then
      best_score = score
      best_index = i
    end
  end

  return best_index
end

function roll_rarity(rarity_table)
  local roll = math.random()
  local cursor = 0

  for _, entry in ipairs(rarity_table) do
    cursor = cursor + entry.weight
    if roll <= cursor then
      return entry.rarity
    end
  end

  return rarity_table[#rarity_table].rarity
end

function cards_by_rarity(rarity)
  local result = {}

  for _, card in ipairs(cards) do
    if card.rarity == rarity then
      table.insert(result, card)
    end
  end

  return result
end

function roll_value(min_value, max_value)
  return math.random(min_value, max_value)
end

function total_value(card_list)
  local value = 0

  for _, card in ipairs(card_list) do
    value = value + card.base_value
  end

  return value
end

function rarity_score(card)
  if card == nil then
    return 1
  end

  return rarity_info(card.rarity).tier or 1
end

function rarity_info(rarity)
  for _, info in ipairs(rarities) do
    if info.id == rarity then
      return info
    end
  end

  return { id = rarity, label = rarity, symbol = "?", tier = 1, color_role = "common" }
end

function rarity_color(rarity)
  local role = rarity_info(rarity).color_role
  return RARITY_COLORS[role] or COLOR.MUTED
end

function rarity_label(rarity)
  local info = rarity_info(rarity)
  return info.symbol .. " " .. info.label
end

function pack_event_label(event)
  if event == nil or event.id == nil or event.id == "normal" then
    return nil
  end

  return event.label or event.id
end

function sell_all()
  State.money = State.money + State.last_pack_value
  State.pack_cards = {}
  State.reveal_order = {}
  State.revealed_cards = {}
  State.current_pack_event = nil
  after_pack_decision("Sold $" .. State.last_pack_value .. ". Next?")
end

function keep_all()
  for _, card in ipairs(State.revealed_cards) do
    table.insert(State.inventory, card)
  end

  State.pack_cards = {}
  State.reveal_order = {}
  State.revealed_cards = {}
  State.current_pack_event = nil
  after_pack_decision("Kept " .. #State.inventory .. " cards.")
end

function after_pack_decision(message)
  State.message = message

  sync_packs_remaining()
  State.pack_turn = 0
  State.pack_side = "front"

  if #State.pack_queue > 0 then
    State.screen = "pack_select"
  else
    State.screen = "box_shop"
  end
end

function toggle_inventory()
  if State.screen == "inventory" then
    State.screen = next_screen_after_inventory()
  else
    State.previous_screen = State.screen
    State.screen = "inventory"
  end
end

function next_screen_after_inventory()
  if State.previous_screen ~= nil then
    return State.previous_screen
  end

  if State.packs_remaining > 0 then
    return "pack_select"
  end

  return "box_shop"
end

function draw_header()
  gfx.rect_fill(0, 0, SCREEN_W, STATUS_H, COLOR.PANEL_DARK)
  gfx.text("RIP", 8, 6, COLOR.TEXT)
  gfx.text("$" .. State.money, 48, 6, COLOR.MONEY)
  gfx.text("BOX " .. State.box_count_opened, 100, 6, COLOR.MUTED)
  gfx.text("PACK " .. State.pack_count_opened, 154, 6, COLOR.MUTED)
  gfx.text("SEEN " .. State.cards_seen, 218, 6, COLOR.MUTED)
  draw_right_text("KEPT " .. #State.inventory, 314, 6, COLOR.MUTED)
end

function draw_box_shop()
  local box = selected_box()

  gfx.text("BOX SHOP", 16, 36, COLOR.TEXT)
  draw_right_text("$" .. box.price, 304, 36, COLOR.MONEY)
  draw_box_carousel()
  gfx.text(box.pack_count .. " packs / 5 cards", 96, 144, COLOR.MUTED)
end

function draw_box_carousel()
  for i, box in ipairs(boxes) do
    local offset = i - State.selected_box_index
    local drag_offset = State.shop_offset
    local x = SHOP_CENTER_X + offset * (SHOP_ITEM_W + SHOP_GAP) + drag_offset
    local y = SHOP_Y + math.abs(offset) * 5
    local selected = i == State.selected_box_index
    local drag_angle = (drag_offset / (SHOP_ITEM_W + SHOP_GAP)) * SHOP_ITEM_ROT_STEP
    local idle_angle = math.sin(usagi.elapsed * 1.4 + i * 0.8) * 0.015
    local angle = offset * SHOP_ITEM_ROT_STEP + drag_angle + idle_angle
    draw_box_card(box, x, y, selected, angle)
  end
end

function draw_box_card(box, x, y, selected, angle)
  local color = COLOR.RARE
  if box.id == "spark_box" then
    color = COLOR.EPIC
  elseif box.id == "chase_box" then
    color = COLOR.LEGENDARY
  end

  draw_rotated_pack_card(x, y, SHOP_ITEM_W, SHOP_ITEM_H, angle, selected, color)
  gfx.text("RIP", x + 26, y + 12, COLOR.TEXT)
  draw_fit_text(box.name, x + 7, y + 34, SHOP_ITEM_W - 14, color)
  gfx.text("$" .. box.price, x + 12, y + 56, COLOR.MONEY)

  if selected then
    gfx.text("TAP BUY", x + 13, y + 68, COLOR.MUTED)
  end
end

function draw_rotated_pack_card(x, y, w, h, angle, selected, color)
  draw_rotated_rect_fill(x, y, w, h, angle, COLOR.PANEL)
  draw_rotated_rect(x, y, w, h, angle, selected and 3 or 1, color)

  local band_y = y + 12
  draw_rotated_rect_fill(x + 6, band_y, w - 12, 9, angle, COLOR.PANEL_DARK)
  draw_rotated_rect(x + 6, band_y, w - 12, 9, angle, 1, color)
end

function draw_rotated_rect_fill(x, y, w, h, angle, color)
  local x1, y1, x2, y2, x3, y3, x4, y4 = rotated_rect_points(x, y, w, h, angle)
  gfx.tri_fill(x1, y1, x2, y2, x3, y3, color)
  gfx.tri_fill(x1, y1, x3, y3, x4, y4, color)
end

function draw_rotated_rect(x, y, w, h, angle, thickness, color)
  local x1, y1, x2, y2, x3, y3, x4, y4 = rotated_rect_points(x, y, w, h, angle)
  gfx.line_ex(x1, y1, x2, y2, thickness, color)
  gfx.line_ex(x2, y2, x3, y3, thickness, color)
  gfx.line_ex(x3, y3, x4, y4, thickness, color)
  gfx.line_ex(x4, y4, x1, y1, thickness, color)
end

function rotated_rect_points(x, y, w, h, angle)
  local cx = x + w / 2
  local cy = y + h / 2
  local x1, y1 = rotate_point(x, y, cx, cy, angle)
  local x2, y2 = rotate_point(x + w, y, cx, cy, angle)
  local x3, y3 = rotate_point(x + w, y + h, cx, cy, angle)
  local x4, y4 = rotate_point(x, y + h, cx, cy, angle)
  return x1, y1, x2, y2, x3, y3, x4, y4
end

function rotate_point(x, y, cx, cy, angle)
  local s = math.sin(angle)
  local c = math.cos(angle)
  local dx = x - cx
  local dy = y - cy
  return cx + dx * c - dy * s, cy + dx * s + dy * c
end

function draw_box_opening()
  local pulse = math.floor(State.transition_timer * 12) % 2
  local color = COLOR.MONEY
  local box = State.current_box or selected_box()

  if pulse == 1 then
    color = COLOR.LEGENDARY
  end

  draw_panel(PANEL_FOCUS.x, PANEL_FOCUS.y, PANEL_FOCUS.w, PANEL_FOCUS.h)
  draw_fit_text(box.name, 104, 58, 112, COLOR.TEXT)
  gfx.rect_ex(120, 76, 80, 46, 3, color)
  gfx.text(box.pack_count .. " PACKS", 138, 94, color)
  gfx.text("OPENING...", 116, 126, COLOR.MUTED)
end

function draw_pack_select()
  gfx.text("PACK QUEUE", 16, 36, COLOR.TEXT)
  draw_right_text("LEFT " .. State.packs_remaining, 304, 36, COLOR.MONEY)
  draw_pack_queue()
  draw_active_pack()
end

function draw_pack_queue()
  local count = math.min(#State.pack_queue, 6)

  for i = count, 1, -1 do
    local x = PACK_QUEUE_X + (i - 1) * PACK_QUEUE_STEP_X
    local y = PACK_QUEUE_Y + (i - 1) * PACK_QUEUE_STEP_Y
    local angle = -0.18 + i * 0.035
    draw_pack_face(x, y, 36, 48, angle, "front", false, COLOR.RARE)
  end

  if #State.pack_queue == 0 then
    gfx.text("EMPTY", PACK_QUEUE_X, PACK_QUEUE_Y + 18, COLOR.MUTED)
  end
end

function draw_active_pack()
  local turn = State.pack_turn
  local face = turn >= 0.5 and "back" or "front"
  local squash = math.abs(1 - turn * 2)
  local w = math.max(12, math.floor(PACK_W * (0.28 + squash * 0.72)))
  local x = PACK_X + math.floor((PACK_W - w) / 2)
  local angle = (turn - 0.5) * 0.18
  local color = face == "back" and COLOR.EPIC or COLOR.RARE

  draw_pack_face(x, PACK_Y, w, PACK_H, angle, face, true, color)
  gfx.text(face == "back" and "BACK" or "FRONT", 142, 150, color)
  gfx.text(face == "back" and "seam rip" or "top rip", 130, 136, COLOR.MUTED)
end

function draw_pack_face(x, y, w, h, angle, face, selected, color)
  local sprite = face == "back" and SPR.pack_back or SPR.pack_front
  draw_sprite_scaled(sprite, x, y, w, h, false, false, angle, gfx.COLOR_TRUE_WHITE, 1.0)
  draw_rotated_rect(x, y, w, h, angle, selected and 3 or 1, color)

  if w < 30 then
    return
  end

  if face == "back" then
    gfx.text("BACK", x + math.max(4, math.floor(w / 2) - 10), y + 24, COLOR.TEXT)
    gfx.text("SEAM", x + math.max(4, math.floor(w / 2) - 10), y + 43, color)
    draw_rotated_rect(x + math.floor(w / 2) - 2, y + 8, 4, h - 16, angle, 1, COLOR.MUTED)
  else
    gfx.text("RIP", x + math.max(4, math.floor(w / 2) - 6), y + 16, COLOR.TEXT)
    gfx.text("PACK", x + math.max(4, math.floor(w / 2) - 12), y + 43, color)
    draw_rotated_rect(x + 5, y + 12, w - 10, 3, angle, 1, COLOR.MUTED)
  end
end

function draw_pack_reveal()
  draw_pack_status()

  if State.reveal_phase == "wrapper" then
    draw_pack_wrapper()
  elseif State.reveal_phase == "trick_stack" then
    draw_pack_stack()
  elseif State.reveal_phase == "flip_stack" then
    draw_flip_stack()
  else
    draw_current_reveal_card()
  end
end

function draw_pack_status()
  local style = "TOP"
  if State.opening_style == "trick" then
    style = "SEAM"
  end

  gfx.text("PACK " .. style, 16, 34, COLOR.TEXT)
  draw_right_text("CARD " .. State.reveal_index .. "/" .. #State.revealed_cards, 304, 34, COLOR.MUTED)
end

function draw_pack_wrapper()
  local pulse = math.floor(State.reveal_timer * 10) % 2
  local color = COLOR.RARE
  local tear_w = math.floor(State.tear_progress * PACK_TEAR_W)

  if pulse == 1 then
    color = COLOR.LEGENDARY
  end

  if State.opening_style == "trick" then
    local seam_h = math.max(2, math.floor(State.tear_progress * PACK_SEAM_H))
    draw_sprite_scaled(SPR.pack_back, PACK_X, PACK_Y, PACK_W, PACK_H, false, false, 0, gfx.COLOR_TRUE_WHITE, 1.0)
    gfx.rect_ex(PACK_X, PACK_Y, PACK_W, PACK_H, 3, color)
    draw_sprite_part(SPR.tear, 0, 0, 18, 24, PACK_X + 26, PACK_Y + 6, 16, seam_h, false, false, 0, COLOR.RARE, 1.0)
    gfx.rect(PACK_X + 32, PACK_Y + 6, 4, PACK_SEAM_H, COLOR.MUTED)
    gfx.rect_fill(PACK_X + 31, PACK_Y + 6, 6, seam_h, COLOR.RARE)
    gfx.text("BACK", PACK_X + 20, PACK_Y + 24, COLOR.TEXT)
    gfx.text("SEAM", PACK_X + 18, PACK_Y + 44, color)
    gfx.text("PULL DOWN", PACK_X + 2, PACK_Y + 70, COLOR.MUTED)
  else
    local tear_x = PACK_X
    if State.tear_dir < 0 then
      tear_x = PACK_X + PACK_W - tear_w
    end

    draw_sprite_scaled(SPR.pack_front, PACK_X, PACK_Y, PACK_W, PACK_H, false, false, 0, gfx.COLOR_TRUE_WHITE, 1.0)
    gfx.rect_ex(PACK_X, PACK_Y, PACK_W, PACK_H, 3, color)
    if tear_w > 0 then
      draw_sprite_part(SPR.tear, 0, 0, math.max(1, math.floor(State.tear_progress * SPR.tear.sw)), 18, tear_x, PACK_Y, tear_w, 17, State.tear_dir < 0, false, 0, COLOR.LEGENDARY, 1.0)
    end
    gfx.rect(PACK_X, PACK_Y + 14, PACK_W, 2, COLOR.MUTED)
    gfx.text("GENESIS", PACK_X + 16, PACK_Y + 24, COLOR.TEXT)
    gfx.text("PACK", PACK_X + 24, PACK_Y + 42, color)
    gfx.text("TOP TEAR", PACK_X + 6, PACK_Y + 70, COLOR.MUTED)
  end
end

function draw_pack_stack()
  gfx.text("BACK FACING", 112, 52, COLOR.MUTED)
  local move_a = math.min(1, State.trick_progress * 2)
  local move_b = math.max(0, math.min(1, State.trick_progress * 2 - 1))

  gfx.rect_fill(STACK_CARD_X + 8, STACK_CARD_Y - 8, CARD_W, CARD_H, COLOR.PANEL_DARK)
  gfx.rect(STACK_CARD_X + 8, STACK_CARD_Y - 8, CARD_W, CARD_H, COLOR.RARE)
  draw_card_back(STACK_CARD_X, STACK_CARD_Y)

  draw_card_back(STACK_CARD_X + math.floor(move_a * 38), STACK_CARD_Y + 8)
  draw_card_back(STACK_CARD_X + 6 + math.floor(move_b * 38), STACK_CARD_Y + 14)
end

function draw_flip_stack()
  gfx.text("FLIP FACE UP", 106, 52, COLOR.MUTED)
  local lift = math.floor(State.trick_progress * 16)
  local width = math.max(10, CARD_W - math.floor(State.trick_progress * 36))

  draw_card_back(STACK_CARD_X + 38, STACK_CARD_Y + 8)
  draw_card_back(STACK_CARD_X + 44, STACK_CARD_Y + 14)
  gfx.rect_fill(STACK_CARD_X + math.floor((CARD_W - width) / 2), STACK_CARD_Y - lift, width, CARD_H, COLOR.PANEL_DARK)
  gfx.rect(STACK_CARD_X + math.floor((CARD_W - width) / 2), STACK_CARD_Y - lift, width, CARD_H, COLOR.MUTED)
end

function draw_current_reveal_card()
  local card = State.revealed_cards[State.reveal_index]
  local next_card = State.revealed_cards[State.reveal_index + 1]
  if card == nil then
    draw_card_back(STACK_CARD_X, STACK_CARD_Y)
    return
  end

  gfx.text("SLIDE CARD", 118, 52, COLOR.MUTED)
  if next_card ~= nil then
    if State.drag and State.drag.kind == "card" then
      draw_card(next_card, STACK_CARD_X, STACK_CARD_Y, false, reveal_clue_progress(next_card))
    else
      draw_card(next_card, STACK_CARD_X, STACK_CARD_Y, false, 0)
    end
    if State.drag and State.drag.kind == "card" then
      draw_card_peek(next_card, State.card_drag_progress)
      draw_tension_line(next_card)
    end
  end

  if State.drag and State.drag.kind == "card" and State.drag_card ~= nil then
    draw_card(State.drag_card, State.card_drag_x, State.card_drag_y, true)
  else
    draw_card(card, STACK_CARD_X, STACK_CARD_Y, true)
  end
end

function draw_reveal_cards()
  for i = 1, #State.revealed_cards do
    local x = 18 + (i - 1) * (CARD_W + CARD_GAP)

    if i <= State.reveal_index then
      draw_card(State.revealed_cards[i], x, CARD_Y, i == State.reveal_index)
    else
      draw_card_back(x, CARD_Y)
    end
  end
end

function draw_sprite_part(sprite, sx, sy, sw, sh, dx, dy, dw, dh, flip_x, flip_y, rotation, tint, alpha)
  gfx.sspr_ex(sprite.sx + sx, sprite.sy + sy, sw, sh, dx, dy, dw, dh, flip_x, flip_y, rotation, tint, alpha)
end

function draw_sprite_scaled(sprite, x, y, w, h, flip_x, flip_y, rotation, tint, alpha)
  gfx.sspr_ex(sprite.sx, sprite.sy, sprite.sw, sprite.sh, x, y, w, h, flip_x, flip_y, rotation, tint, alpha)
end

function card_sprite_for(card)
  local tier = rarity_score(card)
  if tier >= 7 then
    return SPR.card_legendary
  elseif tier >= 5 then
    return SPR.card_epic
  elseif tier >= 3 then
    return SPR.card_rare
  end

  return SPR.card_base
end

function draw_card(card, x, y, is_current, reveal_progress)
  local color = rarity_color(card.rarity)
  local treatment = card.treatment or "base"
  local label = rarity_label(card.rarity)

  if treatment == "reverse" then
    label = "rev " .. label
  elseif treatment == "holo" then
    label = "holo " .. label
  end

  draw_card_sprite_frame(card, x, y, is_current, reveal_progress)
  if treatment ~= "base" then
    gfx.rect(x + 3, y + 3, CARD_W - 6, CARD_H - 6, color)
  end
  draw_card_fields(card, x, y, label, color, reveal_progress or 1)
  if reveal_progress ~= nil and reveal_progress < 1 then
    draw_card_suspense(card, x, y, reveal_progress)
  end
end

function draw_card_sprite_frame(card, x, y, is_current, reveal_progress)
  local color = rarity_color(card.rarity)
  local sprite = card_sprite_for(card)
  if reveal_progress ~= nil and reveal_progress < 0.35 then
    color = COLOR.MUTED
    sprite = SPR.card_base
  end
  draw_sprite_scaled(sprite, x, y, CARD_W, CARD_H, false, false, 0, gfx.COLOR_TRUE_WHITE, 1.0)
  gfx.rect_ex(x, y, CARD_W, CARD_H, is_current and 3 or 1, color)
end

function draw_card_fields(card, x, y, label, color, reveal_progress)
  if reveal_progress >= 0.72 then
    draw_fit_text(card.name, x + CARD_PAD_X, y + 9, CARD_TEXT_W, COLOR.TEXT)
  end
  if reveal_progress >= 0.46 then
    draw_fit_text(label, x + CARD_PAD_X, y + 31, CARD_TEXT_W, color)
  end
  if reveal_progress >= 0.88 then
    draw_fit_text("$" .. card.base_value, x + CARD_PAD_X, y + 52, CARD_TEXT_W, COLOR.MONEY)
  end
end

function draw_card_suspense(card, x, y, reveal_progress)
  local color = rarity_color(card.rarity)
  local tier = rarity_score(card)
  local cover_h = math.max(0, math.floor((1 - reveal_progress) * (CARD_H - 8)))
  if cover_h > 0 then
    gfx.rect_fill(x + 4, y + 4, CARD_W - 8, cover_h, COLOR.PANEL_DARK)
  end
  if tier >= 5 and reveal_progress < 0.45 then
    gfx.rect_fill(x + 3, y + CARD_H - 18, CARD_W - 6, 10, COLOR.PANEL_DARK)
    gfx.rect(x + 3, y + CARD_H - 18, CARD_W - 6, 10, color)
  end
end

function draw_card_peek(card, progress)
  local profile = drag_profile(card)
  if profile.peek <= 0 then
    return
  end

  if State.card_tension_gap < profile.peek_gap then
    return
  end

  local color = rarity_color(card.rarity)
  local peek_progress = math.min(1, (State.card_tension_gap - profile.peek_gap) / profile.peek_span)
  local inset = math.max(1, 5 - math.floor(peek_progress * 4))
  local shine = math.floor((usagi.elapsed * 10) % 2)
  gfx.rect(STACK_CARD_X - inset, STACK_CARD_Y - inset, CARD_W + inset * 2, CARD_H + inset * 2, color)
  if profile.peek >= 2 and shine == 1 then
    gfx.rect(STACK_CARD_X + 3, STACK_CARD_Y + 3, CARD_W - 6, CARD_H - 6, color)
  end
end

function draw_tension_line(card)
  local profile = drag_profile(card)
  if State.card_tension_gap < profile.tension_gap then
    return
  end

  local color = rarity_color(card.rarity)
  if State.drag ~= nil and State.drag.axis == "vertical" then
    local x = STACK_CARD_X + CARD_W + 6
    local y1 = State.card_drag_y + CARD_H
    local stretch = math.min(22, math.floor(State.card_tension_gap / profile.sag_divisor))
    gfx.line(x, y1, x + stretch, y1 + 8, color)
    gfx.line(x + stretch, y1 + 8, x, STACK_CARD_Y + CARD_H, color)
    if State.card_snap_ready then
      gfx.rect(STACK_CARD_X - 4, STACK_CARD_Y - 4, CARD_W + 8, CARD_H + 8, color)
      draw_fit_text("SNAP", STACK_CARD_X + 13, STACK_CARD_Y - 12, 28, color)
    end
    return
  end

  local y = STACK_CARD_Y + CARD_H + 5
  local x1 = State.card_drag_x + CARD_W
  local x2 = math.min(State.card_pointer_x, STACK_CARD_X + 96)
  local mid = math.floor((x1 + x2) / 2)
  local sag = math.min(8, math.floor(State.card_tension_gap / profile.sag_divisor))

  gfx.line(x1, y, mid, y + sag, color)
  gfx.line(mid, y + sag, x2, y, color)
  if State.card_snap_ready then
    gfx.rect(STACK_CARD_X - 4, STACK_CARD_Y - 4, CARD_W + 8, CARD_H + 8, color)
    draw_fit_text("SNAP", STACK_CARD_X + 13, STACK_CARD_Y - 12, 28, color)
  end
end

function draw_card_back(x, y)
  draw_sprite_scaled(SPR.card_base, x, y, CARD_W, CARD_H, false, false, 0, gfx.COLOR_TRUE_WHITE, 0.7)
  gfx.rect_fill(x + 5, y + 5, CARD_W - 10, CARD_H - 10, COLOR.PANEL_DARK)
  gfx.rect(x, y, CARD_W, CARD_H, COLOR.MUTED)
  gfx.text("CARD", x + 12, y + 26, COLOR.MUTED)
end

function draw_result_summary()
  local event_label = pack_event_label(State.current_pack_event)

  gfx.text("PACK RESULT", 16, 34, COLOR.TEXT)
  if event_label ~= nil then
    draw_right_text(event_label, 304, 34, COLOR.LEGENDARY)
  end
  draw_reveal_cards()

  gfx.text("VALUE $" .. State.last_pack_value, TWO_BUTTONS_X, RESULT_VALUE_Y, COLOR.MONEY)
  draw_button_group(RESULT_BUTTON_Y, "SELL", COLOR.GOOD, "KEEP", COLOR.RARE)
end

function draw_inventory()
  draw_panel(PANEL_INVENTORY.x, PANEL_INVENTORY.y, PANEL_INVENTORY.w, PANEL_INVENTORY.h)
  gfx.text("INVENTORY", 24, 44, COLOR.TEXT)

  if #State.inventory == 0 then
    gfx.text("No kept cards yet.", 24, 66, COLOR.MUTED)
  else
    local max_rows = math.min(#State.inventory, 8)
    for i = 1, max_rows do
      local card = State.inventory[#State.inventory - i + 1]
      local y = 62 + (i - 1) * 12
      local color = rarity_color(card.rarity)
      draw_fit_text(card.name, 24, y, 112, COLOR.TEXT)
      draw_fit_text(rarity_info(card.rarity).symbol, 148, y, 32, color)
      gfx.text("$" .. card.base_value, 242, y, COLOR.MONEY)
    end
  end

  draw_button(ONE_BUTTON_X, RESULT_BUTTON_Y, "BACK", COLOR.GOOD)
end

function draw_footer()
  draw_fit_text(State.message, FOOTER_LEFT_X, FOOTER_Y, 150, COLOR.MUTED)
  draw_right_text(footer_hint(), FOOTER_RIGHT_X, FOOTER_Y, COLOR.MUTED)
end

function footer_hint()
  if State.screen == "box_shop" then
    return "drag packs | space cards"
  elseif State.screen == "pack_select" then
    return "drag turn | tap open"
  elseif State.screen == "pack_reveal" then
    return "drag | enter"
  elseif State.screen == "result_summary" then
    return "enter sell | space keep"
  elseif State.screen == "inventory" then
    return "enter back"
  end

  return ""
end

function draw_panel(x, y, w, h)
  gfx.rect_fill(x, y, w, h, COLOR.PANEL)
  gfx.rect(x, y, w, h, COLOR.MUTED)
end

function draw_button(x, y, label, color)
  local text_w, text_h = usagi.measure_text(label)
  local text_x = x + math.floor((BUTTON_W - text_w) / 2)
  local text_y = y + math.floor((BUTTON_H - text_h) / 2)

  gfx.rect(x, y, BUTTON_W, BUTTON_H, color)
  gfx.text(label, text_x, text_y, color)
end

function draw_button_group(y, left_label, left_color, right_label, right_color)
  draw_button(TWO_BUTTONS_X, y, left_label, left_color)
  draw_button(TWO_BUTTONS_X + BUTTON_W + BUTTON_GAP, y, right_label, right_color)
end

function draw_right_text(text, right_x, y, color)
  local text_w = usagi.measure_text(text)
  gfx.text(text, right_x - text_w, y, color)
end

function draw_fit_text(text, x, y, max_w, color)
  gfx.text(fit_text(text, max_w), x, y, color)
end

function drag_progress(distance, full_distance)
  local progress = distance / full_distance
  return math.max(0, math.min(1, progress))
end

function rubber_band_drag(pointer_dx, profile)
  if pointer_dx <= 0 then
    return 0
  end

  if profile.direct then
    return math.min(profile.open_dx, pointer_dx * profile.follow)
  end

  if pointer_dx >= profile.breakpoint then
    local over = pointer_dx - profile.breakpoint
    return math.min(profile.open_dx, profile.hold_dx + over * profile.snap_rate)
  end

  local normalized = pointer_dx / profile.breakpoint
  local eased = 1 - (1 / (1 + normalized * profile.resistance))
  return profile.hold_dx * eased
end

function drag_profile(card)
  local tier = rarity_score(card)

  if tier <= 2 then
    return { tier = tier, direct = true, follow = 1.05, resistance = 0.35, breakpoint = 48, hold_dx = 42, open_dx = 72, snap_rate = 1.8, lift = 0, peek = 0, peek_gap = 999, peek_span = 1, tension_gap = 999, sag_divisor = 8, clue_delay = 0.05, clue_span = 0.55 }
  elseif tier <= 3 then
    return { tier = tier, resistance = 1.05, breakpoint = 58, hold_dx = 31, open_dx = 72, snap_rate = 2.1, lift = 0, peek = 1, peek_gap = 18, peek_span = 30, tension_gap = 12, sag_divisor = 7, clue_delay = 0.18, clue_span = 0.58 }
  elseif tier <= 4 then
    return { tier = tier, resistance = 1.95, breakpoint = 72, hold_dx = 22, open_dx = 72, snap_rate = 2.3, lift = 0, peek = 1, peek_gap = 28, peek_span = 40, tension_gap = 12, sag_divisor = 6, clue_delay = 0.32, clue_span = 0.52 }
  elseif tier <= 6 then
    return { tier = tier, resistance = 3.10, breakpoint = 88, hold_dx = 14, open_dx = 72, snap_rate = 2.6, lift = 0, peek = 2, peek_gap = 42, peek_span = 56, tension_gap = 8, sag_divisor = 5, clue_delay = 0.50, clue_span = 0.42 }
  end

  return { tier = tier, resistance = 4.00, breakpoint = 104, hold_dx = 9, open_dx = 72, snap_rate = 2.8, lift = 0, peek = 2, peek_gap = 56, peek_span = 72, tension_gap = 5, sag_divisor = 4, clue_delay = 0.62, clue_span = 0.34 }
end

function reveal_clue_progress(card)
  local profile = drag_profile(card)
  local progress = (State.card_drag_progress - profile.clue_delay) / profile.clue_span
  return math.max(0, math.min(1, progress))
end

function point_in_rect(px, py, rect)
  return px >= rect.x
    and px <= rect.x + rect.w
    and py >= rect.y
    and py <= rect.y + rect.h
end

function fit_text(text, max_w)
  local text_w = usagi.measure_text(text)
  if text_w <= max_w then
    return text
  end

  local suffix = "."
  local suffix_w = usagi.measure_text(suffix)
  local result = ""

  for i = 1, #text do
    local candidate = string.sub(text, 1, i)
    local candidate_w = usagi.measure_text(candidate)
    if candidate_w + suffix_w > max_w then
      break
    end

    result = candidate
  end

  return result .. suffix
end
