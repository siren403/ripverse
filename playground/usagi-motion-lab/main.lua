local SHADERS = { "crt", "gameboy", nil }
local LABELS = { "CRT", "GAMEBOY", "OFF" }
local COLORS = {
  gfx.COLOR_RED,
  gfx.COLOR_ORANGE,
  gfx.COLOR_YELLOW,
  gfx.COLOR_GREEN,
  gfx.COLOR_BLUE,
  gfx.COLOR_INDIGO,
  gfx.COLOR_PINK,
  gfx.COLOR_PEACH,
}

local CUBE_VERTS = {
  { -1, -1, -1 }, { 1, -1, -1 }, { 1, 1, -1 }, { -1, 1, -1 },
  { -1, -1, 1 }, { 1, -1, 1 }, { 1, 1, 1 }, { -1, 1, 1 },
}

local CUBE_EDGES = {
  { 1, 2 }, { 2, 3 }, { 3, 4 }, { 4, 1 },
  { 5, 6 }, { 6, 7 }, { 7, 8 }, { 8, 5 },
  { 1, 5 }, { 2, 6 }, { 3, 7 }, { 4, 8 },
}

local DRAG_CARD_W = 34
local DRAG_CARD_H = 54

function _config()
  return {
    name = "Ripverse Motion Lab",
    pixel_perfect = false,
  }
end

function _init()
  State = {
    t = 0,
    shader_idx = 1,
    scanline = 0.55,
    cards = {},
    layout_t = 0,
    drag = nil,
    returning = nil,
  }

  for i = 1, 7 do
    table.insert(State.cards, {
      slot = i,
      display_slot = i,
      tier = i,
    })
  end

  gfx.shader_set(SHADERS[State.shader_idx])
end

function _update(dt)
  State.t = State.t + dt

  if input.pressed(input.BTN1) then
    State.shader_idx = (State.shader_idx % #SHADERS) + 1
    gfx.shader_set(SHADERS[State.shader_idx])
  end

  update_card_drag(dt)
  update_orbit_layout(dt)
end

function _draw(_dt)
  gfx.clear(gfx.COLOR_BLACK)
  gfx.shader_uniform("u_time", State.t)
  gfx.shader_uniform("u_scanline", State.scanline)
  gfx.shader_uniform("u_resolution", { usagi.GAME_W, usagi.GAME_H })

  draw_neon_grid()
  draw_particle_ring()
  draw_cube(248, 70, 34)
  draw_card_orbit()
  draw_hud()
end

function draw_neon_grid()
  local horizon = 102
  gfx.rect_fill(0, 0, usagi.GAME_W, usagi.GAME_H, gfx.COLOR_DARK_BLUE)
  gfx.rect_fill(0, horizon, usagi.GAME_W, usagi.GAME_H - horizon, gfx.COLOR_DARK_PURPLE)

  for i = 0, 16 do
    local x = i * 22 - 24
    gfx.line(160, horizon, x, 180, gfx.COLOR_INDIGO)
  end

  for i = 0, 9 do
    local y = horizon + i * i * 1.15
    gfx.line(0, y, usagi.GAME_W, y, gfx.COLOR_BLUE)
  end

  for i = 0, 34 do
    local x = (i * 13 + math.floor(State.t * 18)) % usagi.GAME_W
    local y = (i * 29 + math.floor(State.t * 23)) % 90
    gfx.px(x, y, COLORS[(i % #COLORS) + 1])
  end
end

function draw_particle_ring()
  local cx = 86
  local cy = 76
  for i = 1, 28 do
    local a = State.t * 1.9 + i * 0.45
    local r = 22 + math.sin(State.t * 3 + i) * 8
    local x = cx + math.cos(a) * r
    local y = cy + math.sin(a) * r * 0.58
    local color = COLORS[(i % #COLORS) + 1]
    gfx.circ_fill(x, y, 2 + (i % 3), color)
  end
  gfx.circ(cx, cy, 30 + math.sin(State.t * 4) * 3, gfx.COLOR_YELLOW)
  gfx.circ(cx, cy, 43 + math.cos(State.t * 3) * 3, gfx.COLOR_PINK)
end

function draw_card_orbit()
  local draw_list = build_card_draw_list()
  local active = nil

  if State.drag ~= nil then
    active = {
      index = State.drag.index,
      x = State.drag.x,
      y = State.drag.y,
      w = State.drag.w,
      h = State.drag.h,
      angle = State.drag.angle,
      tilt_x = State.drag.tilt_x,
      tilt_y = State.drag.tilt_y,
      color = State.drag.color,
      depth = 1.15,
    }
  elseif State.returning ~= nil then
    active = return_card_item()
  end

  table.sort(draw_list, function(a, b)
    return a.depth < b.depth
  end)

  for _, item in ipairs(draw_list) do
    if active == nil or item.index ~= active.index then
      draw_rot_card(item.x, item.y, item.w, item.h, item.angle, item.color, item.depth)
    end
  end

  if active ~= nil then
    draw_card_shadow(active.x, active.y, active.w, active.h, active.angle, active.tilt_x or 0, active.tilt_y or 0)
    draw_tilted_card(active.x, active.y, active.w, active.h, active.angle, active.tilt_x or 0, active.tilt_y or 0, active.color, active.depth)
    gfx.text("DRAG", active.x + 2, active.y + active.h + 4, active.color)
  end
end

function build_card_draw_list()
  local draw_list = {}
  local active_index = nil
  if State.drag ~= nil then
    active_index = State.drag.index
  end

  local visible_slots = {}
  local visible_count = 0
  for i, card in ipairs(State.cards) do
    if i ~= active_index then
      visible_count = visible_count + 1
    end
  end

  for i, card in ipairs(State.cards) do
    if i == active_index then
      goto continue
    end

    local x, y, depth, angle = orbit_pose(card.display_slot, visible_count)
    local w = math.max(9, 28 * depth)
    local h = 44 * depth
    local color = COLORS[((card.tier + math.floor(State.t * 3)) % #COLORS) + 1]
    table.insert(draw_list, {
      index = i,
      depth = depth,
      cx = x,
      cy = y,
      x = x - w / 2,
      y = y - h / 2,
      w = w,
      h = h,
      angle = angle,
      color = color,
    })

    ::continue::
  end

  return draw_list
end

function update_orbit_layout(dt)
  local active_index = nil
  if State.drag ~= nil then
    active_index = State.drag.index
  end

  for i, card in ipairs(State.cards) do
    local target_slot = card.slot
    if i ~= active_index and active_index ~= nil and card.slot > active_index then
      target_slot = card.slot - 1
    end

    local amount = math.min(1, dt * 8)
    card.display_slot = lerp(card.display_slot, target_slot, amount)
  end
end

function orbit_pose(slot, count)
  local cx = 162
  local cy = 84
  local spacing = 0.66
  local center = (count + 1) / 2
  local a = State.t * 0.85 + (slot - center) * spacing
  local radius = 56
  local depth = 0.55 + 0.45 * math.sin(a)
  local x = cx + math.cos(a) * radius
  local y = cy + math.sin(a) * 18
  local angle = math.sin(a) * 0.22
  return x, y, depth, angle
end

function update_card_drag(dt)
  local mx, my = input.mouse()

  if State.returning ~= nil then
    local item = return_card_item()
    if item ~= nil then
      State.returning.last_item = item
    end
    if item == nil or State.returning.t >= 1 then
      State.returning = nil
    else
      State.returning.t = math.min(1, State.returning.t + 0.09)
    end
  end

  if State.drag == nil and input.mouse_pressed(input.MOUSE_LEFT) then
    local hit = hit_card(mx, my)
    if hit ~= nil then
      State.drag = {
        index = hit.index,
        dx = mx - (hit.cx - DRAG_CARD_W / 2),
        dy = my - (hit.cy - DRAG_CARD_H / 2),
        x = hit.x,
        y = hit.y,
        target_x = hit.cx - DRAG_CARD_W / 2,
        target_y = hit.cy - DRAG_CARD_H / 2,
        lift_x = hit.cx - DRAG_CARD_W / 2,
        lift_y = hit.cy - DRAG_CARD_H / 2,
        w = hit.w,
        h = hit.h,
        angle = hit.angle,
        tilt_x = 0,
        tilt_y = 0,
        vx = 0,
        vy = 0,
        ax = 0,
        ay = 0,
        prev_target_x = hit.cx - DRAG_CARD_W / 2,
        prev_target_y = hit.cy - DRAG_CARD_H / 2,
        color = hit.color,
      }
      State.returning = nil
    end
  end

  if State.drag ~= nil and input.mouse_held(input.MOUSE_LEFT) then
    local drag = State.drag
    local target_x = mx - drag.dx
    local target_y = my - drag.dy
    local frame_dt = math.max(0.001, dt)
    local raw_vx = (target_x - drag.prev_target_x) / frame_dt
    local raw_vy = (target_y - drag.prev_target_y) / frame_dt
    local raw_ax = raw_vx - drag.vx
    local raw_ay = raw_vy - drag.vy

    drag.vx = lerp(drag.vx, raw_vx, 0.24)
    drag.vy = lerp(drag.vy, raw_vy, 0.24)
    drag.ax = lerp(drag.ax, raw_ax, 0.18)
    drag.ay = lerp(drag.ay, raw_ay, 0.18)
    drag.prev_target_x = target_x
    drag.prev_target_y = target_y
    drag.target_x = target_x
    drag.target_y = target_y

    drag.lift_x = lerp(drag.lift_x, target_x, 0.34)
    drag.lift_y = lerp(drag.lift_y, target_y, 0.34)
    drag.w = lerp(drag.w, DRAG_CARD_W, 0.25)
    drag.h = lerp(drag.h, DRAG_CARD_H, 0.25)
    drag.x = drag.lift_x
    drag.y = drag.lift_y

    local velocity_tilt = clamp(drag.vx * 0.004, -0.35, 0.35)
    local acceleration_tilt = clamp(drag.ax * 0.0009, -0.18, 0.18)
    local hover_wobble = math.sin(State.t * 9) * 0.025
    drag.angle = lerp(drag.angle, velocity_tilt + acceleration_tilt + hover_wobble, 0.28)
    local moved = math.abs(drag.vx) + math.abs(drag.vy)
    local tilt_target_y = 0
    local tilt_target_x = 0
    if moved > 12 then
      tilt_target_y = clamp((mx - (drag.x + drag.w / 2)) * 0.025 + drag.vx * 0.0016, -0.30, 0.30)
      tilt_target_x = clamp((my - (drag.y + drag.h / 2)) * -0.018 + drag.vy * -0.0011, -0.22, 0.22)
    end
    drag.tilt_y = lerp(drag.tilt_y, tilt_target_y, 0.24)
    drag.tilt_x = lerp(drag.tilt_x, tilt_target_x, 0.24)
  elseif State.drag ~= nil then
    State.returning = {
      index = State.drag.index,
      from_x = State.drag.x,
      from_y = State.drag.y,
      from_w = State.drag.w,
      from_h = State.drag.h,
      from_angle = State.drag.angle,
      from_tilt_x = State.drag.tilt_x,
      from_tilt_y = State.drag.tilt_y,
      color = State.drag.color,
      t = 0,
    }
    State.drag = nil
  end
end

function hit_card(mx, my)
  local cards = build_card_draw_list()
  table.sort(cards, function(a, b)
    return a.depth > b.depth
  end)

  for _, item in ipairs(cards) do
    if mx >= item.x and mx <= item.x + item.w and my >= item.y and my <= item.y + item.h then
      return item
    end
  end

  return nil
end

function return_card_item()
  local returning = State.returning
  if returning == nil then
    return nil
  end

  local t = ease_out_back(returning.t)
  local target_cx, target_cy, target_depth, target_angle = orbit_pose(returning.index, #State.cards)
  local target_w = math.max(9, 28 * target_depth)
  local target_h = 44 * target_depth
  return {
    index = returning.index,
    x = lerp(returning.from_x, target_cx - target_w / 2, t),
    y = lerp(returning.from_y, target_cy - target_h / 2, t),
    w = lerp(returning.from_w, target_w, t),
    h = lerp(returning.from_h, target_h, t),
    angle = lerp(returning.from_angle, target_angle, t),
    tilt_x = lerp(returning.from_tilt_x, 0, t),
    tilt_y = lerp(returning.from_tilt_y, 0, t),
    color = returning.color,
    depth = 1.12,
  }
end

function lerp(a, b, t)
  return a + (b - a) * t
end

function clamp(value, min_value, max_value)
  return math.max(min_value, math.min(max_value, value))
end

function ease_out_back(t)
  local c1 = 1.70158
  local c3 = c1 + 1
  local p = t - 1
  return 1 + c3 * p * p * p + c1 * p * p
end

function draw_rot_card(x, y, w, h, angle, color, depth)
  local x1, y1, x2, y2, x3, y3, x4, y4 = rot_points(x, y, w, h, angle)
  local fill = depth > 0.72 and gfx.COLOR_DARK_BLUE or gfx.COLOR_DARK_PURPLE
  gfx.tri_fill(x1, y1, x2, y2, x3, y3, fill)
  gfx.tri_fill(x1, y1, x3, y3, x4, y4, fill)
  gfx.line_ex(x1, y1, x2, y2, depth > 0.8 and 3 or 1, color)
  gfx.line_ex(x2, y2, x3, y3, depth > 0.8 and 3 or 1, color)
  gfx.line_ex(x3, y3, x4, y4, depth > 0.8 and 3 or 1, color)
  gfx.line_ex(x4, y4, x1, y1, depth > 0.8 and 3 or 1, color)
  gfx.line(x1 + 4, y1 + 9, x2 - 4, y2 + 9, gfx.COLOR_LIGHT_GRAY)
  gfx.line(x4 + 4, y4 - 10, x3 - 4, y3 - 10, color)
end

function draw_tilted_card(x, y, w, h, angle, tilt_x, tilt_y, color, depth)
  local x1, y1, x2, y2, x3, y3, x4, y4 = tilted_points(x, y, w, h, angle, tilt_x, tilt_y)
  local fill = gfx.COLOR_DARK_BLUE
  gfx.tri_fill(x1, y1, x2, y2, x3, y3, fill)
  gfx.tri_fill(x1, y1, x3, y3, x4, y4, fill)
  gfx.line_ex(x1, y1, x2, y2, 3, color)
  gfx.line_ex(x2, y2, x3, y3, 3, color)
  gfx.line_ex(x3, y3, x4, y4, 3, color)
  gfx.line_ex(x4, y4, x1, y1, 3, color)
  gfx.line(x1 + 5, y1 + 10, x2 - 5, y2 + 7, gfx.COLOR_LIGHT_GRAY)
  gfx.line(x4 + 5, y4 - 9, x3 - 5, y3 - 12, color)
  gfx.line(x1 + 7, y1 + h * 0.45, x2 - 7, y2 + h * 0.42, gfx.COLOR_BLUE)
end

function draw_card_shadow(x, y, w, h, angle, tilt_x, tilt_y)
  local x1, y1, x2, y2, x3, y3, x4, y4 = tilted_points(x + 5, y + 7, w, h, angle, tilt_x, tilt_y)
  gfx.tri_fill(x1, y1, x2, y2, x3, y3, gfx.COLOR_BLACK)
  gfx.tri_fill(x1, y1, x3, y3, x4, y4, gfx.COLOR_BLACK)
end

function tilted_points(x, y, w, h, angle, tilt_x, tilt_y)
  local left_inset = math.max(0, tilt_y) * 9
  local right_inset = math.max(0, -tilt_y) * 9
  local top_shift = tilt_x * 8
  local bottom_shift = -tilt_x * 8
  local x1, y1 = x + left_inset, y + top_shift
  local x2, y2 = x + w - right_inset, y - top_shift
  local x3, y3 = x + w + right_inset, y + h + bottom_shift
  local x4, y4 = x - left_inset, y + h - bottom_shift
  local cx = x + w / 2
  local cy = y + h / 2
  x1, y1 = rot_point(x1, y1, cx, cy, angle)
  x2, y2 = rot_point(x2, y2, cx, cy, angle)
  x3, y3 = rot_point(x3, y3, cx, cy, angle)
  x4, y4 = rot_point(x4, y4, cx, cy, angle)
  return x1, y1, x2, y2, x3, y3, x4, y4
end

function draw_cube(cx, cy, scale)
  local projected = {}
  local ax = State.t * 0.9
  local ay = State.t * 1.3
  local az = State.t * 0.6

  for i, v in ipairs(CUBE_VERTS) do
    local x, y, z = rotate3(v[1], v[2], v[3], ax, ay, az)
    local d = 3.4
    local p = scale / (z + d)
    projected[i] = { cx + x * p, cy + y * p }
  end

  for i, edge in ipairs(CUBE_EDGES) do
    local a = projected[edge[1]]
    local b = projected[edge[2]]
    gfx.line_ex(a[1], a[2], b[1], b[2], i % 3 == 0 and 2 or 1, COLORS[(i % #COLORS) + 1])
  end
end

function rotate3(x, y, z, ax, ay, az)
  local sx, cx = math.sin(ax), math.cos(ax)
  local sy, cy = math.sin(ay), math.cos(ay)
  local sz, cz = math.sin(az), math.cos(az)

  local y1 = y * cx - z * sx
  local z1 = y * sx + z * cx
  local x2 = x * cy + z1 * sy
  local z2 = -x * sy + z1 * cy
  local x3 = x2 * cz - y1 * sz
  local y3 = x2 * sz + y1 * cz
  return x3, y3, z2
end

function rot_points(x, y, w, h, angle)
  local cx = x + w / 2
  local cy = y + h / 2
  local x1, y1 = rot_point(x, y, cx, cy, angle)
  local x2, y2 = rot_point(x + w, y, cx, cy, angle)
  local x3, y3 = rot_point(x + w, y + h, cx, cy, angle)
  local x4, y4 = rot_point(x, y + h, cx, cy, angle)
  return x1, y1, x2, y2, x3, y3, x4, y4
end

function rot_point(x, y, cx, cy, angle)
  local s = math.sin(angle)
  local c = math.cos(angle)
  local dx = x - cx
  local dy = y - cy
  return cx + dx * c - dy * s, cy + dx * s + dy * c
end

function draw_hud()
  gfx.rect_fill(0, 0, usagi.GAME_W, 22, gfx.COLOR_BLACK)
  gfx.text("MOTION LAB", 8, 7, gfx.COLOR_YELLOW)
  gfx.text("shader " .. LABELS[State.shader_idx], 212, 7, gfx.COLOR_GREEN)
  gfx.text("drag cards | BTN1 shader", 8, 166, gfx.COLOR_LIGHT_GRAY)
end
