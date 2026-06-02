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

local CARD_W = 50
local CARD_H = 68
local CARD_GAP = 8
local CARD_Y = 62
local BUTTON_W = 126
local BUTTON_H = 14
local HIT_H = 20

local HITBOX = {
  box_buy = { x = 32, y = 136, w = BUTTON_W, h = HIT_H },
  box_inventory = { x = 178, y = 136, w = BUTTON_W, h = HIT_H },
  pack_open = { x = 32, y = 136, w = BUTTON_W, h = HIT_H },
  pack_inventory = { x = 190, y = 136, w = BUTTON_W, h = HIT_H },
  result_sell = { x = 24, y = 158, w = BUTTON_W, h = HIT_H },
  result_keep = { x = 172, y = 158, w = BUTTON_W, h = HIT_H },
  inventory_back = { x = 92, y = 164, w = BUTTON_W, h = HIT_H },
}

local advance_primary
local advance_secondary
local handle_mouse_click
local buy_box
local open_pack
local update_reveal
local reveal_hold
local generate_pack
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
local draw_big_pack
local draw_reveal_cards
local draw_card
local draw_card_back
local draw_result_summary
local draw_inventory
local draw_footer
local draw_panel
local draw_button
local point_in_rect
local short_name

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
    revealed_cards = {},
    reveal_index = 0,
    reveal_timer = 0,
    reveal_phase = "idle",
    box_count_opened = 0,
    pack_count_opened = 0,
    cards_seen = 0,
    last_pack_value = 0,
    transition_timer = 0,
    message = "Buy a box to start ripping.",
  }
end

function _update(dt)
  if input.pressed(input.BTN1) or input.key_pressed(input.KEY_ENTER) then
    advance_primary()
  end

  if input.pressed(input.BTN2) or input.key_pressed(input.KEY_SPACE) then
    advance_secondary()
  end

  if input.key_pressed(input.KEY_I) then
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
    open_pack()
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
  elseif State.screen == "pack_select" then
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
    if point_in_rect(mx, my, HITBOX.pack_open) then
      open_pack()
    elseif point_in_rect(mx, my, HITBOX.pack_inventory) then
      toggle_inventory()
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

function open_pack()
  if State.packs_remaining <= 0 then
    State.screen = "box_shop"
    State.message = "No packs left. Buy the next box."
    return
  end

  State.packs_remaining = State.packs_remaining - 1
  State.pack_count_opened = State.pack_count_opened + 1
  State.revealed_cards = generate_pack(State.current_box)
  State.reveal_index = 0
  State.reveal_timer = 0
  State.reveal_phase = "closed_pack"
  State.last_pack_value = total_value(State.revealed_cards)
  State.message = "Ripping pack..."
  State.screen = "pack_reveal"
end

function update_reveal(dt)
  State.reveal_timer = State.reveal_timer + dt

  if State.reveal_phase == "closed_pack" and State.reveal_timer >= 0.35 then
    State.reveal_phase = "opening_pack"
    State.reveal_timer = 0
  elseif State.reveal_phase == "opening_pack" and State.reveal_timer >= 0.35 then
    State.reveal_phase = "card_back"
    State.reveal_timer = 0
  elseif State.reveal_phase == "card_back" and State.reveal_timer >= 0.24 then
    State.reveal_index = State.reveal_index + 1
    State.cards_seen = State.cards_seen + 1
    State.reveal_phase = "card_reveal"
    State.reveal_timer = 0
  elseif State.reveal_phase == "card_reveal" and State.reveal_timer >= reveal_hold() then
    if State.reveal_index >= #State.revealed_cards then
      State.screen = "result_summary"
      State.reveal_phase = "idle"
      State.message = "Sell for money or keep for collection."
    else
      State.reveal_phase = "card_back"
      State.reveal_timer = 0
    end
  end
end

function reveal_hold()
  local card = State.revealed_cards[State.reveal_index]
  if card == nil then
    return 0.35
  end

  if card.rarity == "legendary" then
    return 1.05
  elseif card.rarity == "epic" then
    return 0.85
  elseif card.rarity == "rare" then
    return 0.65
  end

  return 0.45
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
  State.revealed_cards = {}
  after_pack_decision("Sold pack for $" .. State.last_pack_value .. ".")
end

function keep_all()
  for _, card in ipairs(State.revealed_cards) do
    table.insert(State.inventory, card)
  end

  State.revealed_cards = {}
  after_pack_decision("Kept cards. Collection +" .. #State.inventory .. " total.")
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
  gfx.rect_fill(0, 0, 320, 24, COLOR.PANEL_DARK)
  gfx.text("RIPVERSE", 8, 6, COLOR.TEXT)
  gfx.text("$" .. State.money, 84, 6, COLOR.MONEY)
  gfx.text("BOX " .. State.box_count_opened, 142, 6, COLOR.MUTED)
  gfx.text("PACK " .. State.pack_count_opened, 196, 6, COLOR.MUTED)
  gfx.text("INV " .. #State.inventory, 270, 6, COLOR.MUTED)
end

function draw_box_shop()
  local box = boxes[1]

  draw_panel(18, 38, 284, 86)
  gfx.text("BOX SHOP", 32, 48, COLOR.TEXT)
  gfx.text(box.name, 32, 68, COLOR.MONEY)
  gfx.text("Price $" .. box.price .. " / " .. box.pack_count .. " packs", 32, 84, COLOR.MUTED)
  gfx.text("Genesis set / 5 cards per pack", 32, 100, COLOR.MUTED)

  draw_button(32, 136, "CLICK / BTN1  BUY", COLOR.GOOD)
  draw_button(178, 136, "CLICK / BTN2  INV", COLOR.MUTED)
end

function draw_box_opening()
  local pulse = math.floor(State.transition_timer * 12) % 2
  local color = COLOR.MONEY

  if pulse == 1 then
    color = COLOR.LEGENDARY
  end

  draw_panel(70, 44, 180, 94)
  gfx.text("STARTER BOX", 104, 58, COLOR.TEXT)
  gfx.rect_ex(120, 76, 80, 46, 3, color)
  gfx.text("3 PACKS", 138, 94, color)
  gfx.text("OPENING...", 116, 126, COLOR.MUTED)
end

function draw_pack_select()
  draw_panel(18, 38, 284, 86)
  gfx.text("OPENED BOX", 32, 48, COLOR.TEXT)
  gfx.text("Packs remaining: " .. State.packs_remaining, 32, 68, COLOR.MONEY)
  gfx.text("Each pack reveals 5 cards.", 32, 84, COLOR.MUTED)
  gfx.text("Open the next pack and chase the spike.", 32, 100, COLOR.MUTED)

  draw_button(32, 136, "CLICK / BTN1  OPEN", COLOR.GOOD)
  draw_button(190, 136, "CLICK / BTN2  INV", COLOR.MUTED)
end

function draw_pack_reveal()
  draw_pack_status()

  if State.reveal_phase == "closed_pack" or State.reveal_phase == "opening_pack" then
    draw_big_pack()
  else
    draw_reveal_cards()
  end
end

function draw_pack_status()
  gfx.text("PACK REVEAL", 16, 34, COLOR.TEXT)
  gfx.text("Value $" .. State.last_pack_value, 222, 34, COLOR.MONEY)
end

function draw_big_pack()
  local pulse = math.floor(State.reveal_timer * 10) % 2
  local color = COLOR.RARE

  if State.reveal_phase == "opening_pack" and pulse == 1 then
    color = COLOR.LEGENDARY
  end

  gfx.rect_fill(126, 58, 68, 88, COLOR.PANEL)
  gfx.rect_ex(126, 58, 68, 88, 3, color)
  gfx.text("GENESIS", 142, 82, COLOR.TEXT)
  gfx.text("PACK", 150, 100, color)
  gfx.text("RIPPING...", 132, 128, COLOR.MUTED)
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
  gfx.text(short_name(card.name), x + 5, y + 9, COLOR.TEXT)
  gfx.text(card.rarity, x + 5, y + 31, color)
  gfx.text("$" .. card.base_value, x + 5, y + 52, COLOR.MONEY)
end

function draw_card_back(x, y)
  gfx.rect_fill(x, y, CARD_W, CARD_H, COLOR.PANEL_DARK)
  gfx.rect(x, y, CARD_W, CARD_H, COLOR.MUTED)
  gfx.text("CARD", x + 12, y + 26, COLOR.MUTED)
end

function draw_result_summary()
  gfx.text("PACK RESULT", 16, 34, COLOR.TEXT)
  draw_reveal_cards()

  gfx.text("Total value $" .. State.last_pack_value, 24, 144, COLOR.MONEY)
  draw_button(24, 158, "CLICK / BTN1  SELL", COLOR.GOOD)
  draw_button(172, 158, "CLICK / BTN2  KEEP", COLOR.RARE)
end

function draw_inventory()
  draw_panel(12, 34, 296, 124)
  gfx.text("INVENTORY", 24, 44, COLOR.TEXT)

  if #State.inventory == 0 then
    gfx.text("No kept cards yet.", 24, 66, COLOR.MUTED)
  else
    local max_rows = math.min(#State.inventory, 8)
    for i = 1, max_rows do
      local card = State.inventory[#State.inventory - i + 1]
      local y = 62 + (i - 1) * 12
      local color = RARITY_COLORS[card.rarity] or COLOR.MUTED
      gfx.text(card.name, 24, y, COLOR.TEXT)
      gfx.text(card.rarity, 148, y, color)
      gfx.text("$" .. card.base_value, 242, y, COLOR.MONEY)
    end
  end

  draw_button(92, 164, "CLICK / BTN1  BACK", COLOR.GOOD)
end

function draw_footer()
  gfx.text(State.message, 8, 170, COLOR.MUTED)
end

function draw_panel(x, y, w, h)
  gfx.rect_fill(x, y, w, h, COLOR.PANEL)
  gfx.rect(x, y, w, h, COLOR.MUTED)
end

function draw_button(x, y, label, color)
  gfx.rect(x, y, BUTTON_W, BUTTON_H, color)
  gfx.text(label, x + 4, y + 4, color)
end

function point_in_rect(px, py, rect)
  return px >= rect.x
    and px <= rect.x + rect.w
    and py >= rect.y
    and py <= rect.y + rect.h
end

function short_name(name)
  if #name <= 12 then
    return name
  end

  return string.sub(name, 1, 12)
end
