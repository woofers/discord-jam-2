pico-8 cartridge // http://www.pico-8.com
version 18
__lua__

step = 1 / 60
tile_size = 8
screen_size = 128
left = 0
right = 1
up = 2
down = 3
arrows = { right, left, up, down }
z_key = 4
x_key = 5
space_key = ' '

max_planets = 8

function make_object(object)
   object.__index = object
   setmetatable(object, {
      __call = function (cls, ...)
      local self = setmetatable({}, cls)
      self:init(...)
      return self
      end,
   })
end

function make_object(object, base)
   object.__index = object
   setmetatable(object, {
      __index = base,
      __call = function (cls, ...)
      local self = setmetatable({}, cls)
      self:init(...)
      return self
      end,
   })
end

function set_alpha_key()
   palt(0, false)
   palt(11, true)
   palt(14, true)
end

function reset_pallet()
   pal()
   set_alpha_key()
end

local queue = {}
make_object(queue)

function queue:init(fifo)
   self.queue = {}
   self.first = 1
   self.last = 0
   self.cursor = 0
end

function queue:is_empty()
   return self.first > self.last
end

function queue:next(func)
   if self:is_empty() then return end
   func = func or function(i, old) return self.queue[i] end
   local old = self.cursor
   self.cursor += 1
   if self.cursor > self.last then
      self.cursor = self.first
   end
   return func(self.cursor, old)
end

function queue:prev(func)
   if self:is_empty() then return end
   func = func or function(i) return self.queue[i] end
   local old = self.cursor
   self.cursor -= 1
   if self.cursor < self.first then
      self.cursor = self.last
   end
   return func(self.cursor, old)
end

function queue:remaining()
   return self.last - self.cursor
end

function queue:hit_planet(x, y, d)
   d = d or 1
   local fudge = 8
   local callback = function(i, old)
      if self.queue[i].x - fudge > x then
         self.cursor -= 1
         return self.queue[old]
      end
      return nil
   end

   local value = nil
   while value == nil do
      value = self:next(callback)
   end
   return value
end

function queue:push(item)
   self.last += 1
   self.queue[self.last] = item
end

function queue:pop()
   if not self:is_empty() then
      self.queue[self.first]:destroy()
      self.queue[self.first] = nil
      self.first += 1
   end
end

function queue:count()
   return self.last + 1
end

function queue:peek()
   if self:is_empty() then return end
   return self.queue[self.first]
end

function queue:update(dt)
   if self:is_empty() then return end
   for i=self.first, self.last do
      self.queue[i]:update(dt)
   end
end

function queue:render(dt)
   if (self:is_empty()) return
   for i=self.first, self.last do
      self.queue[i]:render(dt)
   end
end

local stack = {}
make_object(stack)

function stack:init()
   self.stack = {}
end

function stack:is_empty()
   return #self.stack <= 0
end

function stack:push(item)
   self.stack[#self.stack + 1] = item
end

function stack:pop()
   if not self:is_empty() then
      self.stack[#self.stack]:destroy()
      self.stack[#self.stack] = nil
      self:create()
   end
end

function stack:create()
   if (self:is_empty()) return
   self:peek():create()
end

function stack:peek()
   if (self:is_empty()) return
   return self.stack[#self.stack]
end

function stack:update(dt)
   if (self:is_empty()) return
   self:peek():update(dt)
end

function stack:render(dt)
   if (self:is_empty()) return
   cls()
   self:peek():render(dt)
end

local gameobject = {}
make_object(gameobject)

function gameobject:init()
end

function gameobject:create()
end

function gameobject:destroy()
end

function gameobject:update(dt)
end

function gameobject:reset()
end

function gameobject:render(dt)
end

local sprite = {}
make_object(sprite, gameobject)

function sprite:init(x, y)
   gameobject.init(self)
   x = x or 0
   y = y or 0
   self:set_location(x, y)
   self:set_scale(1, 1)
end

function sprite:set_location(x, y)
   self.x = x
   self.y = y
end

function sprite:set_scale(x, y)
   self.scale_x = x
   self.scale_y = y
end

function sprite:translate(x, y)
   self:set_location(self.x + x, self.y + y)
end

function sprite:facing_right()
   return self.scale_x > 0
end

function sprite:facing_left()
   return self.scale_x < 0
end

function sprite:is_colliding(flag)
   flag = flag or 1
   return self:is_colliding_top_left(flag)
       or self:is_colliding_bottom_left(flag)
       or self:is_colliding_top_right(flag)
       or self:is_colliding_bottom_right(flag)
end

function sprite:is_colliding_left(flag)
   return self:is_colliding_top_left(flag)
      and self:is_colliding_bottom_left(flag)
end

function sprite:is_colliding_right(flag)
   return self:is_colliding_top_right(flag)
      and self:is_colliding_bottom_right(flag)
end

function sprite:is_colliding_top(flag)
   return self:is_colliding_top_right(flag)
      and self:is_colliding_top_left(flag)
end

function sprite:is_colliding_bottom(flag)
   return self:is_colliding_bottom_right(flag)
      and self:is_colliding_bottom_left(flag)
end

function sprite:is_colliding_top_left(flag)
   return flag_get(self:left_x(), self:top_y(), flag)
end

function sprite:is_colliding_bottom_left(flag)
   return flag_get(self:left_x(), self:bottom_y(), flag)
end

function sprite:is_colliding_bottom_right(flag)
   return flag_get(self:right_x(), self:bottom_y(), flag)
end

function sprite:is_colliding_top_right(flag)
   return flag_get(self:right_x(), self:top_y(), flag)
end

function sprite:left_x()
   return flr(self:local_x() / tile_size)
end

function sprite:right_x()
   return flr((self:local_x() + tile_size - 1) / tile_size)
end

function sprite:top_y()
   return flr(self:local_y() / tile_size)
end

function sprite:bottom_y()
   return flr((self:local_y() + tile_size - 1) / tile_size)
end

function sprite:grid_x()
   return flr(self.x / tile_size)
end

function sprite:grid_y()
   return flr(self.y / tile_size)
end

function sprite:local_x()
   return mod(self.x, screen_size)
end

function sprite:local_y()
   return mod(self.y, screen_size)
end

function sprite:local_grid_x()
   return flr(self:local_x() / tile_size)
end

function sprite:local_grid_y()
   return flr(self:local_y() / tile_size)
end

local screen = {}
make_object(screen, sprite)

function screen:init(x, y)
   sprite.init(self)
   self:set_location(x, y)
end

function screen:set_location(x, y)
   sprite.x = x
   sprite.y = y
   camera(x, y)
end

function screen:min_x()
   return self.x
end

function screen:max_x()
   return self.x + screen_size - 1
end

function screen:min_y()
   return self.y
end

function screen:max_y()
   return self.y + screen_size - 1
end

function screen:is_visible(x, y, width, height)
   width = width or 0
   height = height or 0
   if (self:min_x() > x + width) return false
   if (self:max_x() < x) return false
   if (self:min_y() > y + height) return false
   if (self:max_y() < y) return false
   return true
end

function planet_size()
   local i = random(0, 3)
   if i == 0 then
      return 'large'
   elseif i == 1 then
      return 'normal'
   end
   return 'small'
end

local planet = {}
make_object(planet, sprite)

function planet:init(i)
   local next_planet = 37
   local planet_offset = 10
   self.x, self.y = self:spawn_location(i)
   self.color = (random(0, 2) == 1)
   self.alt = random(1, 3)
   self.size = planet_size()
end

function planet:score()
   if self.size == 'large' then
      return 20
   elseif self.size == 'normal' then
      return 40
   end
   return 80
end

function planet:origin()
   if self.size == 'large' then
      return -8, 5
   elseif self.size == 'normal' then
      return -8, 5
   end
   return -5, 6
end

function planet:radius()
   if self.size == 'large' then
      return 2
   elseif self.size == 'normal' then
      return 1.75
   end
   return 1.15
end

function planet:spawn_location(i)
   if self.size == 'large' then
      local y
      if not (mod(i, 2) == 0) then
         y = 20
      else
         y = 80
      end
      local x = 10 + 37 * (i - 1)
      return random(x - 8, x + 8), random(y - 8, y + 8)
   elseif self.size == 'normal' then
      local y
      if not (mod(i, 2) == 0) then
         y = 20
      else
         y = 80
      end
      local x = 20 + 37 * (i - 1)
      return random(x - 4, x + 4), random(y - 4, y + 4)
   end
   local y
   if not (mod(i, 2) == 0) then
      y = 30
   else
      y = 70
   end
   local x = 30 + 37 * (i - 1)
   return random(x - 2, x + 2), random(y - 2, y + 2)
end

function planet:offset()
   if self.size == 'large' then
      return 28, 10
   elseif self.size == 'normal' then
      return 22, 8
   end
   return 12, 2
end

function planet:update(dt)
end

function planet:render(dt)
   if self.color then
      red_pallet()
   end
   draw_planet(self.x, self.y, self.size, self.alt)
   reset_pallet()
end

function red_pallet()
   pal(1, 2)
   pal(7, 9)
   pal(12, 8)
end

local player = {}
make_object(player, sprite)

function player:init(x, y, planets, states)
   self.speed = 15
   self.x = x
   self.y = y
   self.r = 0
   self.ray_deadzone = 8
   self.ray_distance = 140
   self.ray_thickness = 14
   self.planets = planets
   self.planet_colors = {1, 2, 7, 8, 9, 12}
   self:reset()
   self:change_planet()
   self.states = states
   self.score = 0
   self.tmp_score = 0
   self.hit_x, self.hit_y = 0
   self.jump_time = 0.9
end

function player:reset(t)
   t = t or 0
   self.t = t
end

function player:update(dt)
   local scale = dt * self.speed
   if self.dying then
      local die_time = 1.65
      self.count += dt
      self.x += self:move_x(self.t, scale)
      self.y += self:move_y(self.t, scale)
      self.r = self:rotate_r(self.t, dt)
      self.r = mod(self.r, 360)
      if self.count > die_time then
         self:game_over()
      end
   elseif self.jump_time >= self.count then
      self.count += dt
      local x = self.translate_x * dt / self.jump_time
      local y = self.translate_y * dt / self.jump_time
      self.x += x
      self.y += y
      self.r += self.new_r * dt / self.jump_time
      self.was_hovering = true
   else
      if self.tmp_score then
         self.score += self.tmp_score
         self.tmp_score = 0
      end
      local rotation = dt * self.speed * 360
      local time = 360 / rotation
      self.t += dt
      self.t = mod(self.t, time)
      self.x += self:move_x(self.t, scale)
      self.y += self:move_y(self.t, scale)
      self.r = self:rotate_r(self.t, dt)
      self.r = mod(self.r, 360)
      if kbtn(space_key) and not self.was_hovering then
         sfx(0,0)
         sfx(4,1)
         self:change_planet(mod(self.t + time / (1.25), time))
      end
      self.was_hovering = false
   end
   camera(-50 + self.x, 0)
end


-- Hacky workaround which simulates player
-- movement loop to get correct location
function player:set_pos(t)
   local accum = 0
   local pos = { x=0, y=0 }
   if not t or t <= 0 then return pos end
   for i=0, t, step do
     accum += step
     local scale = step * self.speed
     pos.x += self:move_x(accum, scale)
     pos.y += self:move_y(accum, scale)
   end
   return pos
end

function player:die()
  self.dying = true
  self.count = 0
end

function player:game_over()
   self.states:pop()
end

function player:radius()
   return self.planet:radius()
end

function player:rotate_r(t, dt)
   return self:rotation_speed(dt) * t + 90
end

function player:rotation_speed(dt)
   return dt * self.speed * 360
end

function player:move_x(t, scale)
  return sin(t * scale) * scale * self:radius()
end

function player:move_y(t, scale)
  return cos(t * scale) * scale * self:radius()
end

function player:change_planet(t)
   t = t or 0
   if not self.planet then
      self.planet = self.planets:next()
   else
      local hit_x, hit_y = self:hit_location()
      if not hit_x then
         self:die()
         return
      end
      local direction = -1
      if (0 <= self.r and self.r <= 180) then
         direction = 1
      end
      local left = self.planets:remaining()
      self.planet = self.planets:hit_planet(hit_x, hit_y, direction)
      local skipped = left - self.planets:remaining() - 1
      if skipped >= 0 then
        self.tmp_score += self.planet:score()
        self.tmp_score += 10 * skipped
      end
   end
   local offset_x, offset_y = self.planet:offset()
   local spawn_new = function()
     if self.planets:remaining() <= 2 then
        self.planets:pop()
        self.planets:push(planet(self.planets:count()))
     end
   end
   spawn_new()
   spawn_new()
   spawn_new()
   self.speed += 1
   local new_pos = { x=self.planet.x + offset_x, y=self.planet.y + offset_y }
   local offset_pos = self:set_pos(t)
   self.origin_x = new_pos.x
   self.origin_y = new_pos.y
   new_pos.x += offset_pos.x
   new_pos.y += offset_pos.y
   self.new_r = mod(self:rotate_r(t, step) - self.r, 360)
   self.translate_x = new_pos.x - self.x
   self.translate_y = new_pos.y - self.y
   self.count = 0
   self:reset(t)
end

function player:render(dt)
   if (self.jump_time >= self.count) and not self.dying then
      draw_player(self.x, self.y, self.r, true)
   else
      draw_player(self.x, self.y, self.r)
   end
   if btn(z_key) and false then
      for i=self.ray_deadzone, self.ray_distance do
         for j=0, self.ray_thickness do
           local x, y = self:ray_location(i, j)
           pset(x, y, 14)
         end
      end
      for j=0, self.ray_thickness do
        local x, y = self:ray_location(0, j)
        pset(x, y, 13)
      end
     pset(self.hit_x, self.hit_y, 3)
     local px, py = self.planet:origin()
     pset(self.origin_x + px, self.origin_y + py, 13)
   end
end

function player:hit_location(dt)
   for i=self.ray_deadzone, self.ray_distance do
      for t=0, self.ray_thickness do
         local x, y = self:ray_location(i, t)
         local color = pget(x, y)
         for j=1, #self.planet_colors do
            if color == self.planet_colors[j] then
               self.hit_x, self.hit_y = x, y
               return x, y
            end
         end
      end
   end
   return false, false
end

function player:ray_location(r, t)
   t = t or 0
   local px, py = self.planet:origin()
   return rotate(self.origin_x + t + 8, self.origin_y + r + 15,
                 self.origin_x + px, self.origin_y + py,
                 -(mod(self.r - 90, 360) / 360)
   )
end

function draw_planet(x, y, size, alt)
   alt = alt or 1
   size = size or 'large'
   local case = {}
   case['large'] = function()
      spr(12, x, y, 4, 5)
   end
   case['normal'] = function()
      if alt == 1 then
         spr(1, x, y, 3, 4)
      else
         spr(4, x, y, 3, 4)
      end
   end
   case['small'] = function()
      if alt == 1 then
         spr(7, x, y, 2, 3)
      else
         spr(9, x, y, 2, 3)
      end
   end
   case[size](a)
end

function draw_redstar(x, y)
    spr(11, x, y)
end

function draw_bluestar(x, y)
    spr(27, x, y)
end

function draw_player(x, y, r, flame)
   local flame = flame or false
   r = r or 0
   if (flame) then
      spr_r(48, x, y, r, 2, 2)
   else
      spr_r(32, x, y, r, 2, 2)
   end
end

function blinking_text(dt)
    local blink_sequence = {0, 0, 0, 5, 6, 7, 7, 7, 7, 7, 6, 5, 0}
    blink_frame += 1
    if blink_frame > blink_speed * dt then
        blink_index += 1
        blink_frame = 0
    end
    if blink_index > #blink_sequence then
        blink_index = 1
    end
    blink_color = blink_sequence[blink_index]
end

function endscreen(dt)
    local endzoom_sequence = {128, 64, 32, 12, 4, 1}
    local endzoom_x = {0, 31, 48, 59, 62, 64}
    local endzoom_y = {10, 31, 48, 59, 62, 64}
    endzoom_frame += 1
    if endzoom_frame > endzoom_speed * dt then
        endzoom_index += 1
        endzoom_frame = 0
    end
    if endzoom_index > #endzoom_sequence then
        endzoom_index = 6
    end
    endzoom = endzoom_sequence[endzoom_index]
    endzoomx = endzoom_x[endzoom_index]
    endzoomy = endzoom_y[endzoom_index]
end

function pal_swap(color, comp)
  pal(0, comp or 6)
  pal(1, color)
  pal(7, color)
  pal(12, color)
end

function introscreen(dt)
    local intro_sequence = {1, 2, 3, 4, 5, 6, 8, 0}
    local intro_sec = {12, 8, 6, 9, 0, 5, 2, 7}
    local intro_wsequence = {"dangerous", "orbit", "genesis:" , "endgame",
        "beyond", "our", "intergalactic", "space"}

    intro_frame += 1
    if intro_frame > intro_speed * dt then
        intro_index += 1
        intro_frame = 0
    end
    introcolor = intro_sequence[intro_index]
    introcolorsec = intro_sec[intro_index]
    introword = intro_wsequence[intro_index]
    if intro_index > #intro_sequence then
        intropop = true
    end

end

local star = {}
make_object(star, sprite)

function star:init(x, y, width, height, color)
   self.x = x
   self.y = y
   self.width = width or random(1, 2)
   self.height = height or random(1, 2)
   self.color = color or 7
end

function star:update(dt)
   speed = 30
   self.y += speed * random(1, 3) * dt
   if self.y > screen_size - 1 then
      self.y = random(0, 40)
   end
end

function star:render(dt)
   draw_rectangle(self.x, self.y, self.width, self.height, self.color)
end

local play = {}
make_object(play, gameobject)

function play:init(states)
   self.game_states = states
   self.planets = queue()
   for i=1, max_planets do
      self.planets:push(planet(i))
   end
   self.player = player(50, 10, self.planets, states)
end

function play:create()
end

function play:destroy()

end

function play:update(dt)
   self.planets:update(dt)
   self.player:update(dt)
end

function play:render(dt)
   reset_pallet()
   self.planets:render(dt)
   self.player:render(dt)
   spr(154, self.player.x + 30, 0, 5, 1)
   print(self.player.score, self.player.x + 59, 12, 6)
end

function play:render_debug(dt)
   local cpu = stat(1)
   local mem = stat(0)
   local cpu_color = 6
   local mem_color = 6

   if not min_mem then
      min_mem = 9999
      max_mem = 0
   end

   if (mem < min_mem) min_mem = mem
   if (mem > max_mem) max_mem = mem

   if (cpu > 0.8) cpu_color = 12
   if (mem > 250) mem_color = 12

   print("cpu "..cpu, self.player.x - 80 + 0 * screen_size + 32, 0 * screen_size + 8, cpu_color)
   print("mem "..mem, self.player.x - 80 + 0 * screen_size + 32, 0 * screen_size + 16, mem_color)
   print("mem min "..min_mem, self.player.x - 80 + 0 * screen_size + 32, 0 * screen_size + 24, 6)
   print("mem max "..max_mem, self.player.x - 80 + 0 * screen_size + 32, 0 * screen_size + 32, 6)
end

local gameover = {}
make_object(gameover, gameobject)

function gameover:init(states)
    self.game_states = states
end

function gameover:create()
   blink_color = 0
   blink_index = 1
   blink_speed = 13 * 60
   blink_frame = 0
   endzoom_index = 1
   endzoom_speed = 100 * 60
   endzoom_frame = 0
   sfx(2,-1)
   self.over = false
end

function gameover:destroy()
end

function gameover:update(dt)
    camera(0,0)
    if (kbtn(space_key)) then
        self.game_states:push(play(self.game_states))
    end
    if endzoom_index > 3 and not self.over  then
        self.over = true
        sfx(3,0)
    end
end

function gameover:render(dt)
    bg(0)
    endscreen(dt)
    sspr(0, 32, 16, 16, endzoomx, endzoomy, endzoom, endzoom)
    if endzoom_index > 3 then
        blinking_text(dt)
        print("press space to try again", 18, 95, blink_color)
    end
end

function kbtn(key)
   if stat(30) == true then
      c=stat(31)
      if c>=" " and c<="z" then
         return c == key
      end
   end
   return false
end

function enable_keyboard()
   poke(24365,1)
end

function new_stars()
   local stars = {}
   for i=1, 20 do
      local color = random(1, 11)
      if (color ~= 1 and color ~= 2 and color ~= 10) then
        color = 7
      end
      stars[i] = star(
         random(1, 128), random(1, 128),
         random(0, 1), random(0,1), color
      )
   end
   return stars
end

local menu = {}
make_object(menu, gameobject)

function menu:init(states)
   self.game_states = states
   self.stars = new_stars()
   sfx(10,0,0,-1)
   blink_color = 0
   blink_index = 1
   blink_speed = 13 * 60
   blink_frame = 0
end

function menu:create()
end

function menu:destroy()
end

function menu:update(dt)
   camera(0, 0)
   if (kbtn(space_key) and not self.exit) then
      self.game_states:push(gameover(self.game_states))
      self.game_states:push(play(self.game_states))
   end
end

function draw_menu_planet()
   draw_planet(61, 34)
end

function menu:render(dt)
   bg(0)
   blinking_text(dt)
   -- draw white stars
   for i=1, #self.stars do
      self.stars[i]:render(dt)
   end
   print("doge: bois", 30, 100, 7)
   print("press space to start", 32, 113, blink_color)

   -- draw planet
   draw_menu_planet()
   -- draw color stars
   draw_redstar(12, 43)
   draw_redstar(103, 87)
   draw_bluestar(37, 29)
   draw_bluestar(76, 99)
end

local intro = {}
make_object(intro, gameobject)

function intro:init(states)
    self.game_states = states
end

function intro:create()
   intro_index = 1
   intro_speed = 35 * 60
   intro_frame = 0
   intropop = false
end

function intro:destroy()
end

function intro:update(dt)
    camera(0,0)
    if (intropop) then
        self.game_states:pop()
    end
end

function intro:render(dt)

    introscreen(dt)
    local color = 7
    if introcolor == 6 then
       color = 5
    end
    bg(introcolor)
    pal_swap(introcolor, introcolorsec)
    draw_menu_planet()
    reset_pallet()
    print(introword, 30, 100, color)


end

function _init()
   enable_keyboard()
   reset_pallet()

   game_states = stack()
   game_states:push(menu(game_states))
   game_states:push(intro(game_states))
   game_states:create()
end

function _update60()
   game_states:update(step)
end

function _draw()
   game_states:render(step)
end

function bg(color)
   draw_rectangle(0, 0, screen_size - 1, screen_size - 1, color)
end

function circle(x, y, width, height, r, color)
  circ(x + width / 2, y + height / 2, r, color)
end

function draw_sprite(id, x, y, tile_x, tile_y, flip_x, flip_y)
   adjust_x, adjust_y = 0, 0
   if (flip_x) adjust_x = tile_size * tile_x
   if (flip_y) adjust_y = tile_size * tile_y

   spr(id, x + adjust_x, y + adjust_y, tile_x, tile_y, flip_x, flip_y)
end

function draw_rectangle(x, y, width, height, color, border, border_color)
   border = border or 0
   border_color = border_color or 0

   rectfill(x, y, x + width, y + height, color)
   if border > 0 then
       draw_rectangle(x + border, y + border, width - 2 * border, height - 2 * border, border_color)
   end
end

function random(min, max)
   return min + flr(rnd(max - min))
end

function flag_get(x, y, flag)
   local tile = game_states:peek().level:ram_room():tile(x, y)
   if tile then
      value = tile:has_flag(flag)
      return value
   end
   return false
end

function round(num)
   return flr(num + 0.5)
end

function mod(a, b)
   return a - flr(a / b) * b
end

function to_html()
   path = 'discord-jam-2'
   export(path .. "/index.html")
   exit()
end

-- From https://www.lexaloffle.com/bbs/?pid=40230
function rotate(x,y,cx,cy,angle)
   local sina=sin(angle)
   local cosa=cos(angle)
   x-=cx
   y-=cy
   local rotx=cosa*x-sina*y
   local roty=sina*x+cosa*y
   rotx+=cx
   roty+=cy
   return rotx,roty
end

-- Sprite rotation
-- From https://www.lexaloffle.com/bbs/?pid=52525
function spr_r(s,x,y,a,w,h)
   sw=(w or 1)*8
   sh=(h or 1)*8
   sx=(s%8)*8
   sy=flr(s/8)*8
   x0=flr(0.5*sw)
   y0=flr(0.5*sh)
   a=a/360
   sa=sin(a)
   ca=cos(a)
   for ix=0,sw-1 do
      for iy=0,sh-1 do
         dx=ix-x0
         dy=iy-y0
         xx=flr(dx*ca-dy*sa+x0)
         yy=flr(dx*sa+dy*ca+y0)
         if (xx>=0 and xx<sw and yy>=0 and yy<=sh) then
            local color = sget(sx+xx,sy+yy)
            if not (color == 11 or color == 14) then
               pset(x+ix,y+iy,color)
            end
         end
      end
   end
end

to_html()

__gfx__
ee333eee000000000000ccc0000000000000000000c77cc000000000000000cc000000000000007c7000000000200000eeeeeeeeeee0000cccccc000eeeeeeee
ee333eee0000000000cccccc0000000000000000c717c110000000000000ccccc1000000000077cccc00000000800000eeeeeeeee00ccccccc0000110eeeeeee
ee333eee00000000cc1cc00000000000000000cc111111ccc0000000000cc17ccc000000001171cccc11000028782000eeeeeeee0cccc117c0000000100eeeee
ee333eee000000c771100c000000000000000c11111c1cccc0c0000000c111cc1c10000000c77ccccc11000000800000eeeeee00cccc1111110001000000eeee
ee333eee0000077710011117777000000000cccc11cccc11100000000cc117c1111000000c1cc1ccc100000000200000eeeee0cc1c1111111110001010000eee
ee333eee0000c7111111777777110000000cccccccccc111100000000ccc7c771110000007cc1cccc100000000000000eeee0c111111ccccc1111110010000ee
ee333eee000c77111c777cccccc11000000cccccccc01c1111100000c1c1cc711cc100007c1ccc10ccc0000000000000eee0cc1cc1cccc7cc11111000100100e
ee333eee000cc11ccc1cccccccc1110000cccccc1100000111100000c7ccc77ccc1110007ccccc0cccc0000000000000eee0c1111ccccccccccc00000000010e
eefffeee00cc11ccc111ccccccc1110000ccccc11111000001110000c71ccccccc1110007ccccccccc00000000100000ee0cc111177cc7cc0000000000000000
eefffeee00cc1ccc11111ccccc1111000cccc111ccc1111000110000cccccccc1c110000c1c17cc00c00100000c00000e0cc1111c7ccccc00000000000000000
eefffeee0cccccccc1cc10cccc1101000ccc7111ccccc11100110000cc7ccc111111000011c1ccc01cc000001c7c1000e0c7c117771cc1000000011000000000
eefffeee0c7111ccccc710ccccc100000ccc711ccccccc0100011000ccc71cccc1110100c1711cccc100000000c000000ccc7cc7c11111100111c11000000000
eefffeee0711c11cccc7100ccc0000000cc7711ccccccc010001100007cc11cc111001000c7101ccc0000000001000000c7cc7c7111c111111c7cc0000000000
eefffeee0711711cccc7110cc0000000ccc7111cccc1cc0110111000071cc1cc110000000cc71011c01000000000000007cc7777ccccc1cc77cccc1000000000
eefffeeec71c711cc10c71111ccc0000ccc71cccccc111c01011000000717cc1cc11000000177711000000000000000007cc7177cccccccc77cc00cc00000000
eefffeeec71c710cc1107c1111000000ccc7cccccccc11c11001000000cc1177cc11000000017c0000000000000000007ccc11cccccc7777cc00000cc0000000
ee333eeec7cc710cc100cc11100001000cc7cccccccc11c1100110000000c111c00000000000cc0001000000100000007cc1117ccc1771ccc0000ccccc011000
ee333eee07cc10cccccccc11000001100ccc1cccccccccc110001000000000c000000000000000ccc0000000000000007cc11c77ccc1111c11001ccc00001000
ee333eee0c711cccccccccc1000111000ccc1ccccccccc01100100000000000000000000000000000000000000000000ccc11cc7ccc111111111100000011100
ee333eee0ccccccccccccc00000011000ccc11ccccccc1110011000000000000000000000000000000000000000000007cc1cc177ccc1111111ccc0000010000
ee333eee0c777cc77c1cc0001000000000c1c11ccccc11110000000000000000000000000000000000000000000000000ccccc11ccccccccc1ccc7cc00000000
ee333eee00c71cc77111c1001000000000ccc1111cc111000100000000000000000000000000000000000000000000000ccccc11cccc77ccccc7777c11000000
ee333eee00c111771111000000000000000ccc11111110000100000000000000000000000000000000000000000000000c7c7111cccccccccc7777c111100000
ee333eee000c11111100000000000000000c7cccc00000001100000000000000000000000000000000000000000000000cc7c11111ccccc7777c111111000000
eefffeee000cc11cc7100000000000000000ccccccc1111110000000bbbbbbbbeeeeeeeebbbbbbbbeeeeeeee70000000e0c7cc1111000cccc111111110000000
eefffeee0000cccc771110011100000000000ccccc11111111000000bbbbbbbbeeeeeeeebbbbbbbbeeeeeeee00000000e0ccc7cc1110000001111c1111000000
eefffeee00000c111001000010000000000000cccc11111110000000bbbbbbbbeeeeeeeebbbbbbbbeeeeeeee00000000ee0cc7cccc11000000001cc000000000
eefffeee000000cc111000000000000000000000ccccc11100000000bbbbbbbbeeeeeeeebbbbbbbbeeeeeeee00000000eee0c7c7cc1111110001111000000010
eefffeee00000000c7177c0000000000000000000000111000000000bbbbbbbbeeeeeeeebbbbbbbbeeeeeeee00000000eee0cc7cc111111c1111111000100100
eefffeee0000000000c77c0000000000000000000000c00000000000bbbbbbbbeeeeeeeebbbbbbbbeeeeeeee00000000eeee0cc7cc11111111cccc000110000e
eefffeee000000000000000000000000000000000000000000000000bbbbbbbbeeeeeeeebbbbbbbbeeeeeeee00000000eeeee0ccc7cc1c1111ccc10011000eee
eefffeee000000000000000000000000000000000000000000000000bbbbbbbbeeeeeeeebbbbbbbbeeeeeeee00000000eeeeee00cccc11c1111c1111000eeeee
bbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbb10000000eeeeeeeeecccc11111111000eeeeeeee
bbbbbbb7eeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbb88bbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbb00000000eeeeeeeeeeec7c7ccc10000eeeeeeeee
bbbbbbb7eeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeee7bb88888beeeeeeeebbbbbbbbeeeeeeeebbbbbbbbee000070eeeeeeeeeeeeeeeccccc1eeeeeeeeeee
bbbbbb7177eeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeee7b889888beeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeee0070eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
bbbbb777777777ee00bbbbbbeeeeeeeebbbbbbbbeeeeee7788999988eeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
bbbbb775767776777505bbbbeeeeeeeebbbbbbbbeeee7777899a9998eeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
bbbbb775767776777500bbbbeeeeeeeebbbbbbbbeee7777e89aaa998eeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
bbbbb667777777ee00bbbbbbeeeeeeeebbbbbbbbeee777ee89aaaa98eeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeee8177bbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbb
eeeeeee87bbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbdee88eeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbb
eeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbb7de8888eeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbb
eeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbb7de898888ebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbb
eeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbb677d88999988bbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbb
eeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbb677dd899a9998bbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbb
eeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbb67ddb89aaa998bbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbb
eeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbdddbb89aaaa98bbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbb
bbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeee2222222822222228f777777528888882
bbb888b7eeeeeeeebbbbbbbbee99eeeebbbbbbbbeeeeeee5bbbb88bbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeee12282222922822227f77775582222221
bb8899b7eeeeeeeebbbbbbbbe999eeeebbbbbbbbeeeeee75bbb8888beeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeee222222222222222277ffff5582222221
bb89907177eeeeeebbbbbbbb7999eeeebbbbbbbbeeeeee75b888898beeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeee282222122822229277ffff5582222221
b8890777777777ee00bbbbbb7949eeeebbbbbbbbeeee677588999988eeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeee222282222222822277ffff5582222221
88890775767776777505bbbb6699eeeebbbbbbbbeee677558999a998eeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeee222222822222228277ffff5582222221
88990775767776777500bbbb6094eeeebbbbbbbbeee6755e899aaa98eeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeee2282222222822222775555f582222221
b8880667777777ee00bbbbbbeee9eeeebbbbbbbbeee555ee89aaaa98eeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeee22222122222229227555555f21111112
eee88e8177bbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbb
eeeeeee87bbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbb6eeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbb
eeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbb76ee88888ebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbb
eeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbb76e889988ebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbb
eeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbb677688999988bbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbb
eeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbb67766899a9998bbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbb
eeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbb6766b899aaa98bbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbb
eeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbb666bb89aaaa98bbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbb
0000000000000000000000000000000000000000000000000000000000000000bbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeee
0000000000000000000000000101010110101010000000000000000000000000bbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeee
0000000000000000000000101010101001010101010000000000000000000000bbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeee
0000000000000000000101010101010110101010101010000000000000000000bbbb1182eeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeee
000000000000000000101010101010000001010101010100000000000000000011111182eeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeee
000000000000000101010101000000000000000010101010100000000000000022222182eeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeee
000000000000001010101000000000000000000000010101010000000000000088888182eeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeee
000000000000010101000000000000000000000000000010101000000000000011111182eeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeee
000000000000101010000000000000000000000000000001010100000000000011111182bbbbbbbb66666666bb666666ee666666bb666666eee66666bbbbbbbb
000000000001010100000000000000000000000000000000101010000000000022222182bbbbbbbb6eeeeeeebb6bbbbbee6eeee6bb6bbbb6eee6eeeebbbbbbbb
000000000010101000000000000000000000000000000000010101000000000088888182bbbbbbbb6eeeeeeebb6bbbbbee6eeee6bb6bbbb6eee6eeeebbbbbbbb
000000000101000000000000000000000000000000000000000010100000000011111182bbbbbbbb66666666bb6bbbbbee6eeee6bb666666eee66666bbbbbbbb
0000000010100000000000000000000000000000000000000000010100000000eeee1182bbbbbbbbeeeeeee6bb6bbbbbee6eeee6bb6bb6bbeee6eeeebbbbbbbb
0000000101000000000000000000000000000000000000000000001010000000eeeeeeeebbbbbbbbeeeeeee6bb6bbbbbee6eeee6bb6bb66beee6eeeebbbbbbbb
0000001010000000000000000000000000000000000000000000000101000000eeeeeeeebbbbbbbbeeeeeee6bb6bbbbbee6eeee6bb6bbb66eee6eeeebbbbbbbb
0000000101000000000000000000000000000000000000000000001010100000eeeeeeeebbbbbbbb66666666bb666666ee666666bb6bbbb6eee66666bbbbbbbb
0000101010000000000000000000000000000000000000000000000101010000bbbbbbbbeeeeeeee66666666ee666666bbbbbbbbeeeeeeeebbbbbbbbeeeeeeee
0000010100000000000000000000000000000000000000000000000010100000bbbbbbbbeeeeeeee6bbbbbbbee6eeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeee
0000101000000000000000000000000000000000000000000000000001010000bbbbbbbbeeeeeeee6bbbbbbbee6eeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeee
0001010000000000000000000000000000000000000000000000000000101000bbbbbbbbeeeeeeee6bbbbbbbee6eeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeee
0010100000000000000000000000000000000000000000000000000000010100bbbbbbbbeeeeeeee66666666ee6eeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeee
0001010000000000000000000000000000000000000000000000000000101000bbbbbbbbeeeeeeeebbbbbbb6ee6eeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeee
0010100000000000000000000000000000000000000000000000000000010100bbbbbbbbeeeeeeeebbbbbbb6ee6eeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeee
0101000000000000000000000000000000000000000000000000000000001010bbbbbbbbeeeeeeee66666666ee666666bbbbbbbbeeeeeeeebbbbbbbbeeeeeeee
0010100000000000000000000000000000000000000000000000000000010100eeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbb
0101000000000000000000000000000000000000000000000000000000001010eeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbb
1010000000000000000000000000000000000000000000000000000000000101eeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbb
0101000000000000000000000000000000000000000000000000000000001010eeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbb
1010000000000000000000000000000000000000000000000000000000000101eeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbb
0101000000000000000000000000000000000000000000000000000000001010eeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbb
1010000000000000000000000000000000000000000000000000000000000101eeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbb
0100000000000000000000000000000000000000000000000000000000000010eeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbb
1010000000000000000000000000000000000000000000000000000000000101bbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeee
1010000000000000000000000000000000000000000000000000000000000101bbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeee
0100000000000000000000000000000000000000000000000000000000000010bbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeee
1010000000000000000000000000000000000000000000000000000000000101bbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeee
0101000000000000000000000000000000000000000000000000000000001010bbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeee
1010000000000000000000000000000000000000000000000000000000000101bbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeee
0101000000000000000000000000000000000000000000000000000000001010bbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeee
1010000000000000000000000000000000000000000000000000000000000101bbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeee
0101000000000000000000000000000000000000000000000000000000001010eeeeeeeeb888888beeeeeeeeb111111beeeeeeeebbbbbbbb1818181129191912
0010100000000000000000000000000000000000000000000000000000010100eeeeeeee88777788eeeeeeee11988811eeeeeeeebbbbbbbb8181818191919191
0101000000000000000000000000000000000000000000000000000000001010eeeeeeee87777778eeeeeeee19988881eeeeeeeebbbbbbbb1818181119191911
0010100000000000000000000000000000000000000000000000000000010100eeeeeeee87788778eeeeeeee19911881eeeeeeeebbbbbbbb8181818191919191
0001010000000000000000000000000000000000000000000000000000101000eeeeeeee87788778eeeeeeee19911881eeeeeeeebbbbbbbb1818181119191911
0010100000000000000000000000000000000000000000000000000000010100eeeeeeee87777778eeeeeeee19999981eeeeeeeebbbbbbbb8181818191919191
0001010000000000000000000000000000000000000000000000000000101000eeeeeeee88777788eeeeeeee11999911eeeeeeeebbbbbbbb1818181119191911
0000101000000000000000000000000000000000000000000000000001010000eeeeeeeeb888888beeeeeeeeb119111beeeeeeeebbbbbbbb2111111221111112
0000010100000000000000000000000000000000000000000000000010100000bbbbbbbbeeeeeeeebbbbbbbbeee91eeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeee
0000101010000000000000000000000000000000000000000000000101010000bbbbbbbbeeeeeeeebbbbbbbbeee81eeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeee
0000010101000000000000000000000000000000000000000000001010100000bbbbbbbbeeeeeeeebbbbbbbbeee81eeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeee
0000001010000000000000000000000000000000000000000000000101000000bbbbbbbbeeeeeeeebbbbbbbbeee91eeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeee
0000000101000000000000000000000000000000000000000000001010000000bbbbbbbbeeeeeeeebbbbbbbbeee91eeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeee
0000000010100000000000000000000000000000000000000000010100000000bbbbbbbbeeeeeeeebbbbbbbbeee81eeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeee
0000000001010000000000000000000000000000000000000000101000000000bbbbbbbbeeeeeeeebbbbbbbbeee81eeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeee
0000000000101010000000000000000000000000000000000101010000000000bbbbbbbbeeeeeeeebbbbbbbbeee91eeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeee
0000000000010101000000000000000000000000000000001010100000000000eeeeeeeeb111111beeeeeeeeb8891bbaeeeeeeeebbbbbbbbeeeeeeeebbbbbbbb
0000000000001010100000000000000000000000000000010101000000000000eeeeeeee11988811eeeeeeee811816aaeeeeeeeebbbbbbbbeeeeeeeebbbbbbbb
0000000000000101010000000000000000000000000000101010000000000000eeeeeeee19988881eeeeeeee81186daaeeeeeeeebbbbbbbbeeeeeeeebbbbbbbb
0000000000000010101010000000000000000000000101010100000000000000eeeeeeee19911889988998899886d9aaeeeeeeeebbbbbbbbeeeeeeeebbbbbbbb
0000000000000001010101010000000000000000101010101000000000000000eeeeeeee1991188111111111116d99aaeeeeeeeebbbbbbbbeeeeeeeebbbbbbbb
0000000000000000001010101010000000000101010101000000000000000000eeeeeeee19999981eeeeeeeeb6d999a9eeeeeeeebbbbbbbbeeeeeeeebbbbbbbb
0000000000000000000101010101010110101010101010000000000000000000eeeeeeee11999911eeeeeeeeb9aaaa9aeeeeeeeebbbbbbbbeeeeeeeebbbbbbbb
0000000000000000000000101010101001010101010000000000000000000000eeeeeeeeb111111beeeeeeee9aaaa9a9eeeeeeeebbbbbbbbeeeeeeeebbbbbbbb
__label__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000070000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000007000000000000000000000000000002000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000070000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000c0000000000000000000000000000000000007000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000001c7c100000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000c0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000cccccc0000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000070000000ccccccc0000110000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000cccc117c00000001000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000cccc1111110001000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000cc1c111111111000101000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000c111111ccccc11111100100000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000cc1cc1cccc7cc11111000100100000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000c1111ccccccccccc00000000010000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000cc111177cc7cc000000000000000000000000000000000000000000000000000
000000000000002000000000000000000000000000000000000000000000000cc1111c7ccccc0000000000000000000000000000000000000000000000000000
000000000000008000000000000000000000000000000000000000000000000c7c117771cc100000001100000000000000000000000000000000000000000000
00000000000028782000000000000000000000000000000000000000000000ccc7cc7c11111100111c1100000000000000000000000000000000000000000000
00000000000000800000000000000000000000000000000000000000000000c7cc7c7111c111111c7cc000000000000000000000000000000000000000000000
000000000000002000000000000000000000000000000000000000000000007cc7777ccccc1cc77cccc100000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000007cc7177cccccccc77cc00cc0000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000007ccc11cccccc7777cc00000cc000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000007cc1117ccc1771ccc0000ccccc01100000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000007cc11c77ccc1111c11001ccc0000100000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000ccc11cc7ccc11111111110000001110000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000007cc1cc177ccc1111111ccc000001000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000ccccc11ccccccccc1ccc7cc0000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000ccccc11cccc77ccccc7777c1100000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000c7c7111cccccccccc7777c11110000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000cc7c11111ccccc7777c11111100000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000c7cc1111000cccc11111111000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000ccc7cc1110000001111c111100000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000cc7cccc11000000001cc00000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000c7c7cc111111000111100000001000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000cc7cc111111c111111100010010000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000cc7cc11111111cccc000110000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000ccc7cc1c1111ccc1001100000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000cccc11c1111c11110000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000cccc111111110000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000700000000000000000c7c7ccc1000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000ccccc10000000000000000000000000000000a00000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000700000000007000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000070000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000020000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000080000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000002878200000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000080000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000020000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000007000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000
000000000000000000000000000000770007700770777000000000777007707770077000000000c0000000000000000000000000000000000000000000000000
00000000000000000000000000000070707070700070000700000070707070070070000000001c7c100000000000000000000000000000000000000000000000
000000000000000000000000000000707070707000770000000000770070700700777000000000c0000000000000000000000000000000000000000000000000
00000000000000000000000000000070707070707070000700000070707070070000700000000010000000000000000000000000000000000000000000000000
00000000000000000000000000000077707700777077700000000077707700777077000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
07000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000700000000000000000000000000000000000000000000000000070000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000

__gff__
0280808080808080808080018080818002808080808080808080800180808180028080808080800000000001808080800280800080808000000000008080808000000000000000000000000000808000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000100000000000000000000000202020101010000000000000000000002020201020100000000000000000000020202010101000000000000000000000000102080800000000000000000000000001020404000000000000000000000000000000000
__map__
090a0a0a0a0a0a0a0a0a0a0a0a0a0a0b090a0a0a0a0a0a0a0a0a0a0a0a0a0a0b090a0a0a0a0a0a0a0a0a0a0a0a0a0a0b090a0a0a0a0a0a0a0a0a0a0a0a0a0a0b090a0a0a0a0a0a0a0a0a0a0a0a0a0a0b090a0a0a0a0a0a0a0a0a0a0a0a0a0a0b090a0a0a0a0a0a0a0a0a0a0a0a0a0a0b090a0a0a0a0a0a0a0a0a0a0a0a0a0a0b
192f2f2e2f2f2f2f2f2f2f2f2f2f2f1b19012f2f2f2f2f2f2f2f01012f2f2f05062f2f2f2f2f2f2f2f2f2f2f2f2f2e1b062f2f2f2f2f2f2f2f2f2f2f2f2f2f1b062f2f2f2f2f2f2f2f2f2f2f2f2f2f1b062f2f2f2f2f2f2f2f2f2f2f2f2f2f1b062f2f2f2f2f2f2f2f2f2f2f2f2f2f1b062f2f2f2f2f2f2f2f2f2f2f2f2f2f1b
192f2f2e2f2f2f2f2f2e2e2e2f2f2f1b19012f2f2f2f2f2f2f2f01012f2f2f15162f2f2f2f2f2f1f2f2e2f2f2e2f2e1b162f2f2f2f2f2f2f2f2f2f2f2f2f2f1b162f2f2f2f2f2f2f2f2f2f2f2f2f2f1b162f2f2f2f2f2f2f2f2f2f2f2f2f2f1b162f2f2f2f2f2f2f2f2f2f2f2f2f2f1b162f2f2f2f2f2f2f2f2f2f2f2f2f2f1b
192f2f2e2e2e2f2f2f2f2f2e2e2e2e1b192f2f2f2f2e2e2e2f2f01012f2d2d1b192f2f2e2e2e2f2f2f2e2f2f2e2f2e1b192f2f2f2f2f2f2f2f2f2f2f2f2f2f1b192f2f2f2f2f2f2f2f2f2f2f2f2f2f1b192f2f2f2f2f2f2f2f2f2f2f2f2f2f1b192f2f2f2f2f2f2f2f2f2f2f2f2f2f1b192f2f2f2f2f2f2f2f2f2f2f2f2f2f1b
192f1f2f2f2e2f2f2f2f2f2f2f2f2f1b192f2f2f2f2e2e2f2f2f01012f2d2d1b192f2f2e2e2e2f2f2f2e2e2e2e2f2f1b192f2f2f2f2f2f2f2f2f2f2f2f2f2f1b192f2f2f2f2f2f2f2f2f2f2f2f2f2f1b192f2f2f2f2f2f2f2f2f2f2f2f2f2f1b192f2f2f2f2f2f2f2f2f2f2f2f2f2f1b192f2f2f2f2f2f2f2f2f2f2f2f2f2f1b
192f2f2f2f2e2f2f2f2f2f2f2f2f2f1b192f2f2f2f2f2f2f2f2f012f2d2d2d1b192f2f2e2e2e2f2f2f2f2f2f2f2f2e1b192f2f2f2f2f2f2f2f2f2f2f2f2f2f1b192f2f2f2f2f2f2f2f2f2f2f2f2f2f1b192f2f2f2f2f2f2f2f2f2f2f2f2f2f1b192f2f2f2f2f2f2f2f2f2f2f2f2f2f1b192f2f2f2f2f2f2f2f2f2f2f2f2f2f1b
192f2f2f2f2e2f2f2f0101012f2f2f1b192f2f2f2f2f2f2f2f2e2e2f2d2d2d1b192f2f2f2f2f2f2f2f2f1f2f2f2f2e1b192f2f2f2f2f2f2f2f2f2f2f2f2f2f1b192f2f2f2f2f2f2f2f2f2f2f2f2f2f1b192f2f2f2f2f2f2f2f2f2f2f2f2f2f1b192f2f2f2f2f2f2f2f2f2f2f2f2f2f1b192f2f2f2f2f2f2f2f2f2f2f2f2f2f1b
192f2f2e2e2e2f2f2f01012f2f2f2f1b192f2f2f2f2e2e2e2e2e2d2d2d2d2d1b192f2f2f2f2f2f2f2f2e2e2e2f2e2e1b192f2f2f2f2f2f2f2f2f2f2f2f2f2f1b192f2f2f2f2f2f2f2f2f2f2f2f2f2f1b192f2f2f2f2f2f2f2f2f2f2f2f2f2f1b192f2f2f2f2f2f2f2f2f2f2f2f2f2f1b192f2f2f2f2f2f2f2f2f2f2f2f2f2f1b
192f2f2e2e2e2f2f2f01012f1f2f2f1b192f2f2f2f2e2f2f2f2d2d2d2d2d2d1b192f2f2e2e2e2f2f2f2e2e2e2f2f2f1b192f2f2f2f2f2f2f2f2f2f2f2f2f2f1b192f2f2f2f2f2f2f2f2f2f2f2f2f2f1b192f2f2f2f2f2f2f2f2f2f2f2f2f2f1b192f2f2f2f2f2f2f2f2f2f2f2f2f2f1b192f2f2f2f2f2f2f2f2f2f2f2f2f2f1b
192f2f2e2e2e2f2f2f01012f2f2f2f05062f2f2f2f2e2f1f2f2f2f2d2d2d2d1b192f2f2e2e2e2f2f2f2e2e2e2f2f2f1b192f2f2f2f2f2f2f2f2f2f2f2f2f2f1b192f2f2f2f2f2f2f2f2f2f2f2f2f2f1b192f2f2f2f2f2f2f2f2f2f2f2f2f2f1b192f2f2f2f2f2f2f2f2f2f2f2f2f2f1b192f2f2f2f2f2f2f2f2f2f2f2f2f2f1b
192f2f2f2f2f2f2f2f0101012f2f2f15162f2f2f2e2e2f2f2f2f2f2f2f2f2f1b192f2f2e2e2e2f2f2f2f2f2f2f2f2f1b192f2f2f2f2f2f2f2f2f2f2f2f2f2f1b192f2f2f2f2f2f2f2f2f2f2f2f2f2f1b192f2f2f2f2f2f2f2f2f2f2f2f2f2f1b192f2f2f2f2f2f2f2f2f2f2f2f2f2f1b192f2f2f2f2f2f2f2f2f2f2f2f2f2f1b
192f2f2f2f2f2f2f2f0101012f2f2f1b192f1f2f2e2e2e2e2e2e2e2e2e2f2f1b192f2f2f2f2f2f2f2f2f1f2f2f2f2f1b062f2f2f2f2f2f2f2f2f2f2f2f2f2f1b062f2f2f2f2f2f2f2f2f2f2f2f2f2f1b062f2f2f2f2f2f2f2f2f2f2f2f2f2f1b062f2f2f2f2f2f2f2f2f2f2f2f2f2f1b062f2f2f2f2f2f2f2f2f2f2f2f2f2f1b
192f1f2e2e2e2e2f2f2e2e2e2f2f2f1b192f2f2f2f2f2f2f2f2f2f2f2f2f2f1b192f2f2f2f2f2f2f2f2e2e2e2f2f2f1b162f2f2f2f2f2f2f2f2f2f2f2f2f2f1b162f2f2f2f2f2f2f2f2f2f2f2f2f2f1b162f2f2f2f2f2f2f2f2f2f2f2f2f2f1b162f2f2f2f2f2f2f2f2f2f2f2f2f2f1b162f2f2f2f2f2f2f2f2f2f2f2f2f2f1b
192f2f2f2f2e2e2f2f2f2f2e2f2f2f1b192f2f2f2f2f2f2f2f2f2f2f2f2f2f1b192f2f2e2e2e2f2f2f2e2e2e2f2f2f1b192f2f2f2f2f2f2f2f2f2f2f2f2f2f1b192f2f2f2f2f2f2f2f2f2f2f2f2f2f1b192f2f2f2f2f2f2f2f2f2f2f2f2f2f1b192f2f2f2f2f2f2f2f2f2f2f2f2f2f1b192f2f2f2f2f2f2f2f2f2f2f2f2f2f1b
192f2f2f2f2e2e2f2f2f2f2e2f2f2f1b192f2f2f2f2f2f2f2f2f2f2f2f2f2f1b192f2f2e2e2e2f2f2f2e2e2e2f2f2f1b192f2f2f2f2f2f2f2f2f2f2f2f2f2f1b192f2f2f2f2f2f2f2f2f2f2f2f2f2f1b192f2f2f2f2f2f2f2f2f2f2f2f2f2f1b192f2f2f2f2f2f2f2f2f2f2f2f2f2f1b192f2f2f2f2f2f2f2f2f2f2f2f2f2f1b
292a2a2a2a2a2a2a2a2a2a2a2a2a2a2b292a2a2a2a2a2a2a2a2a2a2a2a2a2a2b292a2a2a2a2a2a2a2a2a2a2a2a07082b292a2a2a2a2a2a2a2a2a2a2a2a2a2a2b292a2a2a2a2a2a2a2a2a2a2a2a2a2a2b292a2a2a2a2a2a2a2a2a2a2a2a2a2a2b292a2a2a2a2a2a2a2a2a2a2a2a2a2a2b292a2a2a2a2a2a2a2a2a2a2a2a2a2a2b
090a0a0a0a0a0a0a17180a0a0a0a0a0b090a0a0a0a0a0a0a0a0a0a0a0a0a0a0b090a0a0a0a0a0a0a0a0a0a0a0a17180b090a0a0a0a0a0a0a0a0a0a0a0a0a0a0b090a0a0a0a0a0a0a0a0a0a0a0a0a0a0b090a0a0a0a0a0a0a0a0a0a0a0a0a0a0b090a0a0a0a0a0a0a0a0a0a0a0a0a0a0b090a0a0a0a0a0a0a0a0a0a0a0a0a0a0b
192f2f0f2f2f2f2e2f2f2f2e2e2e2e1b062f2f2f2f2f2f2f2f2f2f2f2f2f2f1b062f2f2f2f2f2f2f2f2f01012f2d2d05062f2f2f2f2f2f2f2f2f2f2f2f2f2f1b062f2f2f2f2f2f2f2f2f2f2f2f2f2f1b062f2f2f2f2f2f2f2f2f2f2f2f2f2f1b062f2f2f2f2f2f2f2f2f2f2f2f2f2f1b062f2f2f2f2f2f2f2f2f2f2f2f2f2f1b
192f1f1f2f2f2f2e1f1f2f2e1e2e2e1b162f2f2f2f2f2f2f2f2f2f2f2f2f2f1b162f2f2f2f2f2f2f2f2f01012f2f2d15162f2f0101012f2f2f2f2f2f2f2f2f1b162f2f2f2f2f2f2f2f2f2f2f2f2f2f1b162f2f2f2f2f2f2f2f2f2f2f2f2f2f1b162f2f2f2f2f2f2f2f2f2f2f2f2f2f1b162f2f2f2f2f2f2f2f2f2f2f2f2f2f1b
192f01012f2f2f2e1f1f2e2e1e1e2e1b192f2f2f2f2f2f2f2f2f2f2f2f2f2f1b192f2f2f2f2f2f2f2f2f0101012f2f1b192f2f0101012f1f010101012f2f2f1b192f2f2f2f2f2f2f2f2f2f2f2f2f2f1b192f2f2f2f2f2f2f2f2f2f2f2f2f2f1b192f2f2f2f2f2f2f2f2f2f2f2f2f2f1b192f2f2f2f2f2f2f2f2f2f2f2f2f2f1b
192f1f1f2f2f2f2f1f1f2f2f1e1e2f1b192f2f2f2f2f2f2f2f2f2f2f2f2f2f1b192f2f2f2f2f2f2f2f2f2f010101011b192f2f0101012f2f01010101012f2f1b192f2f2f2f2f2f2f2f2f2f2f2f2f2f1b192f2f2f2f2f2f2f2f2f2f2f2f2f2f1b192f2f2f2f2f2f2f2f2f2f2f2f2f2f1b192f2f2f2f2f2f2f2f2f2f2f2f2f2f1b
192f2f2f2f2f0f0f090a0b2f2f2f2f1b192f2f2f2f2f2f2f2f2f2f2f2f2f2f1b192f2f2f2f2f2f2f2f2f2f2f0101011b192f2f2f2f2f2f2f010101012e2e2e1b192f2f2f2f2f2f2f2f2f2f2f2f2f2f1b192f2f2f2f2f2f2f2f2f2f2f2f2f2f1b192f2f2f2f2f2f2f2f2f2f2f2f2f2f1b192f2f2f2f2f2f2f2f2f2f2f2f2f2f1b
192f2f2f2f0f0f0c191a1b2f2f2f2f1b192f2f2f2f2f2f2f2f2f2f2f2f2f2f1b192f2f2f2f2f2f2f2f2f2f2f2f2f2f1b192f2f2f2f2f2f2f01010101012f2f1b192f2f2f2f2f2f2f2f2f2f2f2f2f2f1b192f2f2f2f2f2f2f2f2f2f2f2f2f2f1b192f2f2f2f2f2f2f2f2f2f2f2f2f2f1b192f2f2f2f2f2f2f2f2f2f2f2f2f2f1b
192f2f2f0f0f0c0c191a1b2f2f2f2f1b192f2f2f2f2f2f2f2f2f2f2f2f2f2f1b192f2f2f2f2f2f2f2f2f2f2f2f2f2f1b192f2f0101012f2f010101012f2f2f1b192f2f2f2f2f2f2f2f2f2f2f2f2f2f1b192f2f2f2f2f2f2f2f2f2f2f2f2f2f1b192f2f2f2f2f2f2f2f2f2f2f2f2f2f1b192f2f2f2f2f2f2f2f2f2f2f2f2f2f1b
192e2f2f0f0c0c0c191a1b2f2f2f2f1b192f2f2f2f2f2f2f2f2f2f2f2f2f2f1b192f2f2f2f2f2f2f2f2f2f2f2f2f2f1b192f2f0101012f2f2f2f2f2f2f2f2f1b192f2f2f2f2f2f2f2f2f2f2f2f2f2f1b192f2f2f2f2f2f2f2f2f2f2f2f2f2f1b192f2f2f2f2f2f2f2f2f2f2f2f2f2f1b192f2f2f2f2f2f2f2f2f2f2f2f2f2f1b
192e2f2f0f0c0c0c191a1b2f2f2f2f1b192f2f2f2f2f2f2f2f2f2f2f2f2f2f1b192f2f2f2f2f2f2f2f2f2f2f2f2f2f1b192f2f0101012f2f2f2f2f2f2f2f2f1b192f2f2f2f2f2f2f2f2f2f2f2f2f2f1b192f2f2f2f2f2f2f2f2f2f2f2f2f2f1b192f2f2f2f2f2f2f2f2f2f2f2f2f2f1b192f2f2f2f2f2f2f2f2f2f2f2f2f2f1b
192e2f2f0f0f0f0f292a2b2f2f2f2f1b192f2f2f2f2f2f2f2f2f2f2f2f2f2f1b192f2f2f2f2f2f2f2f2f2f2f2f2f2f1b192f1f2f2f2f2f2f2f2f0101012f2f1b192f2f2f2f2f2f2f2f2f2f2f2f2f2f1b192f2f2f2f2f2f2f2f2f2f2f2f2f2f1b192f2f2f2f2f2f2f2f2f2f2f2f2f2f1b192f2f2f2f2f2f2f2f2f2f2f2f2f2f1b
192e2f2f2f2f2f2f2f2f2f2f2f2f2f1b062f2f2f2f2f2f2f2f2f2f2f2f2f2f1b062f2f2f2f2f2f2f2f2f2f2f2f2f2f1b192f2f2f2f2f2f2f2f2f0101012f2f05062f2f2f2f2f2f2f2f2f2f2f2f2f2f1b062f2f2f2f2f2f2f2f2f2f2f2f2f2f1b062f2f2f2f2f2f2f2f2f2f2f2f2f2f1b062f2f2f2f2f2f2f2f2f2f2f2f2f2f1b
192e2f2f2f2f2f2f2f2f2f2f2f2f2f1b162f2f2f2f2f2f2f2f2f2f2f2f2f2f1b162f2f2f2f2f2f2f2f2f2f2f2f2f2f1b192f2f2f2f0101012f2f0101012f2f15162f2f2f2f2f2f2f2f2f2f2f2f2f2f1b162f2f2f2f2f2f2f2f2f2f2f2f2f2f1b162f2f2f2f2f2f2f2f2f2f2f2f2f2f1b162f2f2f2f2f2f2f2f2f2f2f2f2f2f1b
192e2e2e2e2e2e2e2e2e2e2e2e2e2e1b192f2f2f2f2f2f2f2f2f2f2f2f2f2f1b192f2f2f2f2f2f2f2f2f2f2f2f2f2f1b1901012f2f0101012f2f2f2f2f2f2f1b192f2f2f2f2f2f2f2f2f2f2f2f2f2f1b192f2f2f2f2f2f2f2f2f2f2f2f2f2f1b192f2f2f2f2f2f2f2f2f2f2f2f2f2f1b192f2f2f2f2f2f2f2f2f2f2f2f2f2f1b
190f0f0f0f0f0f0f0f0f0f0f0f0f0f1b192f2f2f2f2f2f2f2f2f2f2f2f2f2f1b192f2f2f2f2f2f2f2f2f2f2f2f2f2f1b1901012f2f0101012f2f2f2f2f2f2f1b192f2f2f2f2f2f2f2f2f2f2f2f2f2f1b192f2f2f2f2f2f2f2f2f2f2f2f2f2f1b192f2f2f2f2f2f2f2f2f2f2f2f2f2f1b192f2f2f2f2f2f2f2f2f2f2f2f2f2f1b
292a2a2a2a2a2a2a2a2a2a2a2a2a2a2b292a2a2a2a2a2a2a2a2a2a2a2a2a2a2b292a2a2a2a2a2a2a2a2a2a2a2a2a2a2b292a2a2a2a2a2a2a2a2a2a2a2a2a2a2b292a2a2a2a2a2a2a2a2a2a2a2a2a2a2b292a2a2a2a2a2a2a2a2a2a2a2a2a2a2b292a2a2a2a2a2a2a2a2a2a2a2a2a2a2b292a2a2a2a2a2a2a2a2a2a2a2a2a2a2b
__sfx__
000800000171002710037200472005720060100801023000230002300023000230002300023000230002300023000230002300023000230002300023000230002300023000230002300023000230002300023000
000e00001602016020170201902018020195001d50018700187201b72019720197200d5000c5000b5000c5000b5001872018720107201072018720197201650016500175000f5001672017700177001572000600
000a00000061000610006100061000610006100061000610006100061000610340003400034000340003400034000340003400034000340003400034000340003400034000340000000033000330003300033000
001200000d0200e0200d0200c02008020080200802008020080200b0200b020080200602005020040200102000020000200550006500065000650002020040200202010200142001420014200152000002000020
0008000000f0000f00006000060003a3003a3011a2012a2013a3002a3003a3003a300ea2010a2011a2002a2002a3001a3008a2007a2006a2004a1004a1005a1003a1003a1004a1003a1003a1001a1000a1000a10
001200000351004510055100651005510045100451005510065100451003510015100251003510035100351003510035100351001510045100451003510025100051000510025000250001500005000051000510
000700002c0002c0002c0002c0001b0101b0102c0002c0002c0002c0002c0002c0002c0002c00018010180102c00000000280002800028000280002800028000280001d0101d0102800028000280002800028000
000b0000140200c0200b020100200a020050200e020120200702010020190200d02005020160200e02021020160200c020140201002008020170201502018020170200e0200e02009020130200b0201502014020
000b00001071011710117101471012710117102051028510205101f5101e5101e5101c510185101c51012710127101371012710117101a7101a7101a7101a5102551027510225101f51021510265102351018510
001100001c1001c1001c10014510165001950017500175101c1001c1001920002700007001c1001c1001c1000e51005700017000c510095000a5101c1001c1001c1001c1001c1000b51010500105001251013510
0011000028000280002800013720280002800028000280002800028000280000d7200a70012700280002800028000280002800028000127202800028000280002800028000280000d72012700000000000000000
000200001c1001c1001c1001c1001c1001c1001c1001c1001c1001c1001c1001c1001c1001c1001c1001c1001c1001c1001c1001c1001c1001c1001c1001c1001c1001c1001c1000000000000000000000000000
010200000000023040230402304023040230402304023040230402304023040230402304023040230402304023040230402304023040230402304023040230402304023040230402304023040230402304023040
01020000000001c1401c1401c1401c1401c1401c1401c1401c1401c1401c1401c1401c1401c1401c1401c1401c1401c1401c1401c1401c1401c1401c1401c1401c1401c1401c1401c1401c1401c1401c1401c140
010400002304023040000002204022040220402204022040220402204022040220402204022040220402204022040220402204022040220402204022040220402204022040220402204022040220402204022040
010400001c1401c140000001b1401b1401b1401b1401b1401b1401b1401b1401b1401b1401b1401b1401b1401b1401b1401b1401b1401b1401b1401b1401b1401b1401b1401b1401b1401b1401b1401b1401b140
010400002204022040220402204022040220402204022040220402204022040220402204022040220402204022040220402204022040220402204022040220402204022040220402204022040220402204022040
010400001b1401b1401b1401b1401b1401b1401b1401b1401b1401b1401b1401b1401b1401b1401b1401b1401b1401b1401b1401b1401b1401b1401b1401b1401b1401b1401b1401b1401b1401b1401b1401b140
010200002204022040220402204022040220402204022040220402204022040220402204022040220402204022040220400000000000000000000000000000000000022040220402204022040220402204022040
010200001b1401b1401b1401b1401b1401b1401b1401b1401b1401b1401b1401b1401b1401b1401b1401b1401b1401b140000000000000000000000000000000000001b1401b1401b1401b1401b1401b1401b140
010200002204022040220402204022040220402204022040220402204022040220402204022040220402204022040220402204022040220402204022040220402204022040220402204000000000000000000000
010200001b1401b1401b1401b1401b1401b1401b1401b1401b1401b140000000000000000000000000000000000000000000000000000a1400a1400a1400a1400a1400a1400a1400a1400a140000000f1400f140
010200000f1400f1400f1400f1400f1400f1400f14000000111401114011140111401114011140111401114011140000001214012140121401214012140121401214012140121401214012140121401214012140
010200001214012140121401214012140121401214012140121401214012140121401214012140121401214012140121401214012140121401214012140121401214012140121401214012140121401214012140
010200000000000000000000000000000000000000000000200402004020040200402004020040200402004020040200402004020040200402004020040200402004020040200402004020040200402004020040
01020000121401214012140121401214012140121400000000000000001b1401b1401b1401b1401b1401b1401b1401b1401b1401b1401b1401b1401b1401b1401b1401b1401b1401b1401b1401b1401b1401b140
010200002004020040200402004020040200402004020040200402004020040000000000023040230402304023040230402304023040230402304023040230402304023040230402304023040230402304023040
010200001b1401b1401b1401b1401b1401b1401b1401b1401b1401b1401b1401b1401b14000000000002814028140281402814028140281402814028140281402814028140281402814028140281402814028140
010200002304023040230402304023040230402304023040230402304023040230402304023040230402304023040230402304023040230402304023040230402304023040230402304023040230402304023040
010200002814028140281402814028140281402814028140281402814028140281402814028140281402814028140281402814028140281402814028140281402814028140281402814028140281402814028140
010200002304023040230402304023040230402304023040230402304023040230402304023040230402304023040230402304000000000000000000000340403404034040340403404034040340403404034040
010200002814028140281402814028140281402814028140281402814028140281402814028140281402814028140281402814028140281400000000000000000000028140281402814028140281402814028140
010200003404034040340403404034040340403404034040000003304033040330403304033040330403304033040330403304033040330403304033040330403304033040000002f0402f0402f0402f0402f040
010200002814028140281402814028140281402814028140281402814000000271402714027140271402714027140271402714027140271402714027140271402714027140271402714000000231402314023140
010200002f0402f0402f0402f0402f0402f0402f0402f0402f0402f0402f0402f040000002c0402c0402c0402c0402c0402c0402c0402c0402c0402c0402c0402c0402c0402c0402c0402c0402c0400000028040
010200002314023140231402314023140231402314023140231402314023140231402314023140000002014020140201402014020140201402014020140201402014020140201402014020140201402014020140
010200002804028040280402804028040280402804028040280402804028040280402804028040280402804028040280402804028040280402804028040280402804028040280402804028040280402804028040
01020000000001c1401c1401c1401c1401c1401c1401c1401c1401c1401c1401c1401c1401c1401c1401c1401c1401c1401c1401c1401c1401c1401c1401c1401c1401c1401c1401c1401c1401c1401c1401c140
010800002804028040280402804028040280402804028040280402804028040280402804028040280402804028040280402804028040000000000000000230402304023040230402304023040230402304023040
010800001c1401c1401c1401c1401c1401c1401c1401c1401c1401c1401c1401c1401c1401c1401c1401c1401c1401c1401c1401c1401c1400000000000000001c1401c1401c1401c1401c1401c1401c1401c140
010200002304023040230402304023040230402304023040230402304023040230402304023040230402304023040000000000022040220402204022040220402204022040220402204022040220402204022040
010200001c1401c1401c1401c1401c1401c1401c1401c1401c1401c1401c1401c1401c1401c1401c1401c1401c1401c1401c14000000000001b1401b1401b1401b1401b1401b1401b1401b1401b1401b1401b140
010800002204022040220402204022040220402204022040220402204022040220402204022040220402204022040220402204022040220402204022040220402204022040220402204022040220402204022040
010800001b1401b1401b1401b1401b1401b1401b1401b1401b1401b1401b1401b1401b1401b1401b1401b1401b1401b1401b1401b1401b1401b1401b1401b1401b1401b1401b1401b1401b1401b1401b1401b140
010200002204022040220402204022040220402204022040220402204022040220402204022040220402204022040220402204022040220402204022040220402204022040220402204022040220402204000000
010200001b1401b1401b1401b1401b1401b1401b1401b1401b1401b1401b1401b1401b1401b1401b1401b1401b1401b1401b1401b1401b1401b1401b1401b1401b1401b1401b1401b1401b1401b1401b1401b140
010200000000000000000000000000000000002204022040220402204022040220402204022040220402204022040220402204022040220402204022040220402204022040220402204022040220402204022040
000200001b14000000000000000000000000000000000000081400814008140081400814008140081400814008140081400814008140081400814008140081400814000000081400814008140081400814008140
010200002204022040220402204022040220402204022040220402204022040220402204022040220402204022040220402204022040220402204022040220402204022040220402204022040220402204022040
010200000814008140081400814008140081400814008140081400814008140000000a1400a1400a1400a1400a1400a1400a1400a1400a140000000a1400a1400a1400a1400a1400a1400a1400a1400a1400a140
010200000a1400a1400a1400a1400a1400a1400a140000000a1400a1400a1400a1400a1400a1400a1400a1400a140000000b1400b1400b1400b1400b1400b1400b1400b1400b1400b1400b1400b1400b1400b140
010200002204022040220402204022040220402204022040220402204022040220402204022040220400000000000000000000000000000002004020040200402004020040200402004020040200402004020040
010200000b1400b1400b140000000b1400b1400b1400b1400b1400b1400b1400b1400b1400b1400b1400b1400b1400b1400b1400b1400b140000000f1400f1400f1400f1400f1400f1400f1400f1400f1400f140
010200002004020040200402004020040200402004020040200402004020040200402004020040200402004020040200402004020040200402004020040200400000000000230402304023040230402304023040
010200000f1400f1400f1400f1400f1400f1400f140000000f1400f1400f1400f1400f1400f1400f1400f1400f1400f1400f1400f1400f1400f1400f1400f1400f140000001c1401c1401c1401c1401c1401c140
010200000000000000000000000034040340403404034040340403404034040340403404034040340403404034040340403404034040340400000033040330403304033040330403304033040330403304033040
010200000000000000000000000028140281402814028140281402814028140281402814028140281402814028140281402814028140281400000027140271402714027140271402714027140271402714027140
0102000033040330403304033040330403304033040000002f0402f0402f0402f0402f0402f0402f0402f0402f0402f0402f0402f0402f0402f0402f0402f0402f040000002c0402c0402c0402c0402c0402c040
010200002714027140271402714027140271402714000000231402314023140231402314023140231402314023140231402314023140231402314023140231402314000000201402014020140201402014020140
010200002c0402c0402c0402c0402c0402c0402c0402c0402c0402c0402c040000002804028040280402804028040280402804028040280402804028040280402804028040280402804028040280402804028040
010200002014020140201402014020140201402014020140201402014020140000001c1401c1401c1401c1401c1401c1401c1401c1401c1401c1401c1401c1401c1401c1401c1401c1401c1401c1401c1401c140
010200002804028040280402804028040280402804028040280402804028040280402804028040280402804028040280402804028040280400000000000000000000000000000002304023040230402304023040
010200001c1401c1401c1401c1401c1401c1401c1401c1401c1401c1401c1401c1401c1401c1401c1401c1401c1401c1401c1401c1401c1400000000000000000000000000000001c1401c1401c1401c1401c140
010400002304023040230402304023040230402304023040230402304023040230402304023040230400000022040220402204022040220402204022040220402204022040220402204022040220402204022040
__music__
00 00014344
00 02034344
00 04054344
00 06074344
00 08094344
00 0a0b4344
00 0c0d4344
00 0e0f4344
00 10114344
00 12134344
00 14154344
00 16424344
00 17424344
00 18194344
00 1a1b4344
00 1c1d4344
00 1e1f4344
00 20214344
00 22234344
00 24254344
00 26274344
00 28294344
00 2a2b4344
00 2c2d4344
00 2e2f4344
00 30314344
00 30324344
00 33344344
00 35364344
00 00014344
00 37384344
00 393a4344
00 3b3c4344
00 08094344
00 3d3e4344
00 3f424344
