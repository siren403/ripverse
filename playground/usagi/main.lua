local boxes = usagi.read_json("boxes.json")
local cards = usagi.read_json("cards.json")

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
local CURRENT_CARD_X = math.floor((SCREEN_W - CARD_W) / 2)
local CURRENT_CARD_Y = 70
local CARD_PAD_X = 5
local CARD_TEXT_W = CARD_W - CARD_PAD_X * 2
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
  box_buy = { x = TWO_BUTTONS_X, y = BUTTON_ROW_Y, w = BUTTON_W, h = HIT_H },
  box_inventory = { x = TWO_BUTTONS_X + BUTTON_W + BUTTON_GAP, y = BUTTON_ROW_Y, w = BUTTON_W, h = HIT_H },
  pack_raw = { x = TWO_BUTTONS_X, y = BUTTON_ROW_Y, w = BUTTON_W, h = HIT_H },
  pack_trick = { x = TWO_BUTTONS_X + BUTTON_W + BUTTON_GAP, y = BUTTON_ROW_Y, w = BUTTON_W, h = HIT_H },
  pack_next = { x = ONE_BUTTON_X, y = RESULT_BUTTON_Y, w = BUTTON_W, h = HIT_H },
  result_sell = { x = TWO_BUTTONS_X, y = RESULT_BUTTON_Y, w = BUTTON_W, h = HIT_H },
  result_keep = { x = TWO_BUTTONS_X + BUTTON_W + BUTTON_GAP, y = RESULT_BUTTON_Y, w = BUTTON_W, h = HIT_H },
  inventory_back = { x = ONE_BUTTON_X, y = RESULT_BUTTON_Y, w = BUTTON_W, h = HIT_H },
}

local advance_primary
local advance_secondary
local handle_mouse_click
local buy_box
local start_pack
local advance_pack_reveal
local update_reveal
local generate_pack
local build_reveal_order
local strongest_card_index
local roll_rarity
local cards_by_rarity
local roll_value
local total_value
local sell_all
local keep_all
local after_pack_decision
local toggle_inventory
local next_screen_after_inventory
local draw_header
local draw_box_shop
local draw_box_opening
local draw_pack_select
local draw_pack_reveal
local draw_pack_status
local draw_pack_wrapper
local draw_pack_stack
local draw_current_reveal_card
local draw_reveal_cards
local draw_card
local draw_card_back
local draw_result_summary
local draw_inventory
local draw_footer
local footer_hint
local draw_panel
local draw_button
local draw_button_group
local draw_right_text
local draw_fit_text
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
    packs_remaining = 0,
    current_box = nil,
    pack_cards = {},
    reveal_order = {},
    opening_style = "raw",
    revealed_cards = {},
    reveal_index = 0,
    reveal_timer = 0,
    reveal_phase = "idle",
    box_count_opened = 0,
    pack_count_opened = 0,
    cards_seen = 0,
    last_pack_value = 0,
    transition_timer = 0,
    message = "Buy a box.",
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
    buy_box(boxes[1])
  elseif State.screen == "pack_select" then
    start_pack("raw")
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
  elseif State.screen == "pack_select" then
    start_pack("trick")
  elseif State.screen == "box_shop" then
    toggle_inventory()
  end
end

function handle_mouse_click()
  local mx, my = input.mouse()

  if State.screen == "box_shop" then
    if point_in_rect(mx, my, HITBOX.box_buy) then
      buy_box(boxes[1])
    elseif point_in_rect(mx, my, HITBOX.box_inventory) then
      toggle_inventory()
    end
  elseif State.screen == "pack_select" then
    if point_in_rect(mx, my, HITBOX.pack_raw) then
      start_pack("raw")
    elseif point_in_rect(mx, my, HITBOX.pack_trick) then
      start_pack("trick")
    end
  elseif State.screen == "pack_reveal" then
    if point_in_rect(mx, my, HITBOX.pack_next) then
      advance_pack_reveal()
    end
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

function buy_box(box)
  if State.money < box.price then
    State.message = "Not enough money. Sell cards or reset."
    return
  end

  State.money = State.money - box.price
  State.current_box = box
  State.packs_remaining = box.pack_count
  State.box_count_opened = State.box_count_opened + 1
  State.transition_timer = 0
  State.message = "Opening box..."
  State.screen = "box_opening"
end

function start_pack(opening_style)
  if State.packs_remaining <= 0 then
    State.screen = "box_shop"
    State.message = "No packs left. Buy the next box."
    return
  end

  State.packs_remaining = State.packs_remaining - 1
  State.pack_count_opened = State.pack_count_opened + 1
  State.opening_style = opening_style
  State.pack_cards = generate_pack(State.current_box)
  State.reveal_order = build_reveal_order(State.pack_cards, opening_style)
  State.revealed_cards = {}
  for _, card_index in ipairs(State.reveal_order) do
    table.insert(State.revealed_cards, State.pack_cards[card_index])
  end
  State.reveal_index = 0
  State.reveal_timer = 0
  State.reveal_phase = "wrapper"
  State.last_pack_value = total_value(State.pack_cards)
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
      State.message = "Move cards. Hit last."
    else
      State.reveal_phase = "card_back"
      State.message = "Pull the first card."
    end
  elseif State.reveal_phase == "trick_stack" then
    State.reveal_phase = "card_back"
    State.message = "Flip the stack."
  elseif State.reveal_phase == "card_back" then
    State.reveal_index = State.reveal_index + 1
    State.cards_seen = State.cards_seen + 1
    State.reveal_phase = "card_reveal"

    if State.reveal_index >= #State.revealed_cards then
      State.message = "Final card."
    else
      State.message = "Card " .. State.reveal_index .. " of " .. #State.revealed_cards .. "."
    end
  elseif State.reveal_phase == "card_reveal" then
    if State.reveal_index >= #State.revealed_cards then
      State.screen = "result_summary"
      State.reveal_phase = "idle"
      State.message = "Sell or keep."
    else
      State.reveal_phase = "card_back"
      State.message = "Next card."
    end
  end
end

function update_reveal(dt)
  State.reveal_timer = State.reveal_timer + dt
end

function generate_pack(box)
  local result = {}
  local pack = box.pack

  for _ = 1, pack.card_count do
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
    })
  end

  return result
end

function build_reveal_order(card_list, opening_style)
  local result = {}

  if opening_style ~= "trick" then
    for i = 1, #card_list do
      table.insert(result, i)
    end

    return result
  end

  local hit_index = strongest_card_index(card_list)
  local trick_order = { 2, 3, 1, 4, 5 }

  for _, index in ipairs(trick_order) do
    if index <= #card_list and index ~= hit_index then
      table.insert(result, index)
    end
  end

  table.insert(result, hit_index)
  return result
end

function strongest_card_index(card_list)
  local best_index = #card_list
  local best_score = -1

  for i, card in ipairs(card_list) do
    local rarity_score = 1
    if card.rarity == "uncommon" then
      rarity_score = 2
    elseif card.rarity == "rare" then
      rarity_score = 3
    elseif card.rarity == "epic" then
      rarity_score = 4
    elseif card.rarity == "legendary" then
      rarity_score = 5
    end

    local score = rarity_score * 10000 + card.base_value
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

function sell_all()
  State.money = State.money + State.last_pack_value
  State.pack_cards = {}
  State.reveal_order = {}
  State.revealed_cards = {}
  after_pack_decision("Sold $" .. State.last_pack_value .. ". Next?")
end

function keep_all()
  for _, card in ipairs(State.revealed_cards) do
    table.insert(State.inventory, card)
  end

  State.pack_cards = {}
  State.reveal_order = {}
  State.revealed_cards = {}
  after_pack_decision("Kept " .. #State.inventory .. " cards.")
end

function after_pack_decision(message)
  State.message = message

  if State.packs_remaining > 0 then
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
  local box = boxes[1]

  draw_panel(PANEL_MAIN.x, PANEL_MAIN.y, PANEL_MAIN.w, PANEL_MAIN.h)
  gfx.text("BOX SHOP", 32, 48, COLOR.TEXT)
  gfx.text(box.name, 32, 68, COLOR.MONEY)
  gfx.text("$" .. box.price .. " / " .. box.pack_count .. " packs", 32, 84, COLOR.MUTED)
  gfx.text("Genesis / 5 cards each", 32, 100, COLOR.MUTED)

  draw_button_group(BUTTON_ROW_Y, "BUY", COLOR.GOOD, "CARDS", COLOR.RARE)
end

function draw_box_opening()
  local pulse = math.floor(State.transition_timer * 12) % 2
  local color = COLOR.MONEY

  if pulse == 1 then
    color = COLOR.LEGENDARY
  end

  draw_panel(PANEL_FOCUS.x, PANEL_FOCUS.y, PANEL_FOCUS.w, PANEL_FOCUS.h)
  gfx.text("STARTER BOX", 104, 58, COLOR.TEXT)
  gfx.rect_ex(120, 76, 80, 46, 3, color)
  gfx.text("3 PACKS", 138, 94, color)
  gfx.text("OPENING...", 116, 126, COLOR.MUTED)
end

function draw_pack_select()
  draw_panel(PANEL_MAIN.x, PANEL_MAIN.y, PANEL_MAIN.w, PANEL_MAIN.h)
  gfx.text("OPEN STYLE", 32, 48, COLOR.TEXT)
  gfx.text("Packs left: " .. State.packs_remaining, 32, 68, COLOR.MONEY)
  gfx.text("RAW is fast.", 32, 84, COLOR.MUTED)
  gfx.text("TRICK saves hit for last.", 32, 100, COLOR.MUTED)

  draw_button_group(BUTTON_ROW_Y, "RAW", COLOR.GOOD, "TRICK", COLOR.RARE)
end

function draw_pack_reveal()
  draw_pack_status()

  if State.reveal_phase == "wrapper" then
    draw_pack_wrapper()
  elseif State.reveal_phase == "trick_stack" or State.reveal_phase == "card_back" then
    draw_pack_stack()
  else
    draw_current_reveal_card()
  end

  draw_button(ONE_BUTTON_X, RESULT_BUTTON_Y, "NEXT", COLOR.GOOD)
end

function draw_pack_status()
  local style = "RAW"
  if State.opening_style == "trick" then
    style = "TRICK"
  end

  gfx.text("PACK " .. style, 16, 34, COLOR.TEXT)
  draw_right_text("CARD " .. State.reveal_index .. "/" .. #State.revealed_cards, 304, 34, COLOR.MUTED)
end

function draw_pack_wrapper()
  local pulse = math.floor(State.reveal_timer * 10) % 2
  local color = COLOR.RARE

  if pulse == 1 then
    color = COLOR.LEGENDARY
  end

  gfx.rect_fill(126, 58, 68, 88, COLOR.PANEL)
  gfx.rect_ex(126, 58, 68, 88, 3, color)
  gfx.text("GENESIS", 142, 82, COLOR.TEXT)
  gfx.text("PACK", 150, 100, color)
  gfx.text("SEALED", 138, 128, COLOR.MUTED)
end

function draw_pack_stack()
  local x = CURRENT_CARD_X
  local y = CURRENT_CARD_Y

  if State.reveal_phase == "trick_stack" then
    gfx.text("BACK FACING", 112, 52, COLOR.MUTED)
    gfx.rect_fill(x + 8, y - 8, CARD_W, CARD_H, COLOR.PANEL_DARK)
    gfx.rect(x + 8, y - 8, CARD_W, CARD_H, COLOR.RARE)
  else
    gfx.text("READY", 142, 52, COLOR.MUTED)
  end

  draw_card_back(x, y)
end

function draw_current_reveal_card()
  local card = State.revealed_cards[State.reveal_index]
  if card == nil then
    draw_card_back(CURRENT_CARD_X, CURRENT_CARD_Y)
    return
  end

  draw_card(card, CURRENT_CARD_X, CURRENT_CARD_Y, true)
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

function draw_card(card, x, y, is_current)
  local color = RARITY_COLORS[card.rarity] or COLOR.MUTED

  gfx.rect_fill(x, y, CARD_W, CARD_H, COLOR.PANEL)
  gfx.rect_ex(x, y, CARD_W, CARD_H, is_current and 3 or 1, color)
  draw_fit_text(card.name, x + CARD_PAD_X, y + 9, CARD_TEXT_W, COLOR.TEXT)
  draw_fit_text(card.rarity, x + CARD_PAD_X, y + 31, CARD_TEXT_W, color)
  draw_fit_text("$" .. card.base_value, x + CARD_PAD_X, y + 52, CARD_TEXT_W, COLOR.MONEY)
end

function draw_card_back(x, y)
  gfx.rect_fill(x, y, CARD_W, CARD_H, COLOR.PANEL_DARK)
  gfx.rect(x, y, CARD_W, CARD_H, COLOR.MUTED)
  gfx.text("CARD", x + 12, y + 26, COLOR.MUTED)
end

function draw_result_summary()
  gfx.text("PACK RESULT", 16, 34, COLOR.TEXT)
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
      local color = RARITY_COLORS[card.rarity] or COLOR.MUTED
      draw_fit_text(card.name, 24, y, 112, COLOR.TEXT)
      gfx.text(card.rarity, 148, y, color)
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
    return "enter buy | space cards"
  elseif State.screen == "pack_select" then
    return "enter raw | space trick"
  elseif State.screen == "pack_reveal" then
    return "enter next"
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
