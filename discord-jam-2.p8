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

max_planets = 6

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

function queue:next()
   if self:is_empty() then return end
   self.cursor += 1
   if self.cursor > self.last then
      self.cursor = self.first
   end
   return self.queue[self.cursor]
end

function queue:prev()
   if self:is_empty() then return end
   self.cursor -= 1
   if self.cursor < self.first then
      self.cursor = self.last
   end
   return self.queue[self.cursor]
end

function queue:remaining()
   return self.last - self.cursor
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

local planet = {}
make_object(planet, sprite)

function planet:init(i)
   local next_planet = 37
   local planet_offset = 10
   if not (mod(i, 2) == 0) then
      self.y = 20
   else
      self.y = 80
   end
   self.x = planet_offset + next_planet * (i - 1)
   self.color = (random(0, 2) == 1)
end

function planet:update(dt)
end

function planet:render(dt)
   if self.color then
      red_pallet()
   end
   draw_planet(self.x, self.y)
   reset_pallet()
end

function red_pallet()
   pal(1, 2)
   pal(7, 9)
   pal(12, 8)
end

local player = {}

make_object(player, sprite)

function player:init(x, y, planets)
   self.radius = 2
   self.speed = 15
   self.x = x
   self.y = y
   self.r = 0
   self.ray_distance = 44
   self.planets = planets
   self.planet_colors = {1, 2, 7, 8, 9, 12}
   self:reset(t)
   self:change_planet()
end

function player:reset(t)
   t = t or 0
   self.t = t
end

function player:update(dt)
   local jump_time = 0.9
   if jump_time >= self.count then
      self.count += dt
      local x = self.translate_x * dt / jump_time
      local y = self.translate_y * dt / jump_time
      self.x += x
      self.y += y
      self.r += self.new_r * dt / jump_time
   else
      local rotation = dt * self.speed * 360
      local time = 360 / rotation
      local scale = dt * self.speed
      self.t += dt
      self.t = mod(self.t, time)
      self.x += self:move_x(self.t, scale)
      self.y += self:move_y(self.t, scale)
      self.r = self:rotate_r(self.t, dt)
      self.r = mod(self.r, 360)
      if btnp(x_key) then
         if self:can_jump(dt) then
            local direction = -1
            if (0 <= self.r and self.r <= 180) then direction = 1 end
            self:change_planet(mod(self.t + time / 2, time), direction)
         else
            self:die()
         end
      end
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

end

function player:rotate_r(t, dt)
   return self:rotation_speed(dt) * t + 90
end

function player:rotation_speed(dt)
   return dt * self.speed * 360
end

function player:move_x(t, scale)
  return sin(t * scale) * scale * self.radius
end

function player:move_y(t, scale)
  return cos(t * scale) * scale * self.radius
end

function player:change_planet(t, p)
   p = p or 1
   t = t or 0
   local offset_x = 28
   local offset_y = 10
   if p >= 0 then
      self.planet = self.planets:next()
   else
      self.planet = self.planets:prev()
   end
   if self.planets:remaining() <= 2 then
      self.planets:pop()
      self.planets:push(planet(self.planets:count()))
   end
   local new_pos = { x=self.planet.x + offset_x, y=self.planet.y + offset_y }
   local offset_pos = self:set_pos(t)
   new_pos.x += offset_pos.x
   new_pos.y += offset_pos.y
   self.new_r = mod(self:rotate_r(t, step) - self.r, 360)
   self.translate_x = new_pos.x - self.x
   self.translate_y = new_pos.y - self.y
   self.count = 0
   self:reset(t)
end

function player:render(dt)
   draw_player(self.x, self.y, self.r)
   draw_ray = true
   if draw_ray then
      local x, y = self:ray_location(self.ray_distance)
      pset(x, y, 7)
      pset(x + 1, y, 7)
      pset(x, y + 1, 7)
      pset(x + 2, y, 7)
      pset(x, y + 2, 7)
   end
end

function player:can_jump(dt)
   local x, y = self:ray_location(self.ray_distance)
   local colors = { pget(x, y), pget(x + 1, y), pget(x, y + 1), pget(x + 2, y), pget(x, y + 2) }
   for i=1, #self.planet_colors do
      for j=1, #colors do
         if colors[j] == self.planet_colors[i] then
            return true
         end
      end
   end
   return false
end

function player:ray_location(r)
   return rotate(self.x + r, self.y, self.x + 5, self.y + 10, (-self.r + 90) / 360)
end

function draw_planet(x, y)
   spr(12, x, y, 4, 5)
end

function draw_redstar(x, y)
    spr(11, x, y)
end

function draw_bluestar(x, y)
    spr(27, x, y)
end

function draw_player(x, y, r)
   r = r or 0
   spr_r(32, x, y, r, 2, 2)
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

local menu = {}
make_object(menu, gameobject)

function menu:init(states)
   self.game_states = states
   self.stars = {}
   for i=1, 20 do
      local color = random(1, 11)
      if (color ~= 1 and color ~= 2 and color ~= 10) then
        color = 7
      end
      self.stars[i] = star(random(1, 128), random(1, 128),
        random(0, 1) , random(0,1), color)
   end
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
   if (btn(x_key) and not self.exit) then
      self.game_states:pop()
   end
end

function menu:render(dt)
   bg(0)
   blinking_text(dt)
   -- draw white stars
   for i=1, #self.stars do
      self.stars[i]:render(dt)
   end
   print("name", 17, 105, 7)
   print("press space to start", 32, 113, blink_color)

   -- draw planet
   draw_planet(61, 34)
   -- draw color stars
   draw_redstar(12, 43)
   draw_redstar(103, 87)
   draw_bluestar(37, 29)
   draw_bluestar(76, 99)
end

local play = {}
make_object(play, gameobject)

function play:init(states)
   self.game_states = states
   self.stars = {}
   for i=1, 40 do
      self.stars[i] = star(random(1, 128), random(1, 128))
   end
   self.planets = queue()
   for i=1, max_planets do
      self.planets:push(planet(i))
   end
   self.player = player(50, 10, self.planets)
end

function play:create()
end

function play:destroy()

end

function play:update(dt)
   for i=1, #self.stars do
      self.stars[i]:update(dt)
   end
   self.planets:update(dt)
   self.player:update(dt)
end

function play:render(dt)
   reset_pallet()
   for i=1, #self.stars do
      self.stars[i]:render(dt)
   end
   self.planets:render(dt)
   self.player:render(dt)
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

   print("cpu "..cpu, 0 * screen_size + 32, 0 * screen_size + 8, cpu_color)
   print("mem "..mem, 0 * screen_size + 32, 0 * screen_size + 16, mem_color)
   print("mem min "..min_mem, 0 * screen_size + 32, 0 * screen_size + 24, 6)
   print("mem max "..max_mem, 0 * screen_size + 32, 0 * screen_size + 32, 6)
end

function _init()
   reset_pallet()

   game_states = stack()
   game_states:push(play(game_states))
   game_states:push(menu(game_states))
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

__gfx__
ee333eee000000000000ccc0000000000000000000c77cc000000000000000cc000000000000007c7000000000200000000000000000000cccccc00000000000
ee333eee0000000000cccccc0000000000000000c717c110000000000000ccccc1000000000077cccc0000000080000000000000000ccccccc00001100000000
ee333eee00000000cc1cc00000000000000000cc111111ccc0000000000cc17ccc000000001171cccc11000028782000000000000cccc117c000000010000000
ee333eee000000c771100c000000000000000c11111c1cccc0c0000000c111cc1c10000000c77ccccc1100000080000000000000cccc11111100010000000000
ee333eee0000077710011117777000000000cccc11cccc11100000000cc117c1111000000c1cc1ccc100000000200000000000cc1c1111111110001010000000
ee333eee0000c7111111777777110000000cccccccccc111100000000ccc7c771110000007cc1cccc10000000000000000000c111111ccccc111111001000000
ee333eee000c77111c777cccccc11000000cccccccc01c1111100000c1c1cc711cc100007c1ccc10ccc00000000000000000cc1cc1cccc7cc111110001001000
ee333eee000cc11ccc1cccccccc1110000cccccc1100000111100000c7ccc77ccc1110007ccccc0cccc00000000000000000c1111ccccccccccc000000000100
eefffeee00cc11ccc111ccccccc1110000ccccc11111000001110000c71ccccccc1110007ccccccccc00000000100000000cc111177cc7cc0000000000000000
eefffeee00cc1ccc11111ccccc1111000cccc111ccc1111000110000cccccccc1c110000c1c17cc00c00100000c0000000cc1111c7ccccc00000000000000000
eefffeee0cccccccc1cc10cccc1101000ccc7111ccccc11100110000cc7ccc111111000011c1ccc01cc000001c7c100000c7c117771cc1000000011000000000
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
eefffeee000cc11cc7100000000000000000ccccccc1111110000000bbbbbbbbeeeeeeeebbbbbbbbeeeeeeee7000000000c7cc1111000cccc111111110000000
eefffeee0000cccc771110011100000000000ccccc11111111000000bbbbbbbbeeeeeeeebbbbbbbbeeeeeeee0000000000ccc7cc1110000001111c1111000000
eefffeee00000c111001000010000000000000cccc11111110000000bbbbbbbbeeeeeeeebbbbbbbbeeeeeeee00000000000cc7cccc11000000001cc000000000
eefffeee000000cc111000000000000000000000ccccc11100000000bbbbbbbbeeeeeeeebbbbbbbbeeeeeeee000000000000c7c7cc1111110001111000000010
eefffeee00000000c7177c0000000000000000000000111000000000bbbbbbbbeeeeeeeebbbbbbbbeeeeeeee000000000000cc7cc111111c1111111000100100
eefffeee0000000000c77c0000000000000000000000c00000000000bbbbbbbbeeeeeeeebbbbbbbbeeeeeeee0000000000000cc7cc11111111cccc0001100000
eefffeee000000000000000000000000000000000000000000000000bbbbbbbbeeeeeeeebbbbbbbbeeeeeeee00000000000000ccc7cc1c1111ccc10011000000
eefffeee000000000000000000000000000000000000000000000000bbbbbbbbeeeeeeeebbbbbbbbeeeeeeee0000000000000000cccc11c1111c111100000000
bbb99bbbe99eeeeebb99bbbb99eeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbb10000000000000000cccc1111111100000000000
bb9499bb9999eeeeb9499bb9999eeeeebbbbbbbbeeeeeeeebbb88bbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbb0000000000000000000c7c7ccc10000000000000
bb9499979994eeeeb9499777994eeeeebbbbbbbbeeeeeee7bb88888beeeeeeeebbbbbbbbeeeeeeeebbbbbbbb00000070000000000000000ccccc100000000000
b99949077949eeee99997077949eeeeebbbbbbbbeeeeeee7b889888beeeeeeeebbbbbbbbeeeeeeeebbbbbbbb0000007000000000000000000000000000000000
b49949776699eeee49997766999eeeeebbbbbbbbeeeeee7788999988eeeeeeeebbbbbbbbeeeeeeeebbbbbbbb0000000000000000000000000000000000000000
b44997776094eeeeb49b7760e94eeeeebbbbbbbbeeee7777899a9998eeeeeeeebbbbbbbbeeeeeeeebbbbbbbb0000000000000000000000000000000000000000
77444777eee9eeeebbbb7777eeeeeeeebbbbbbbbeee7777e89aaa998eeeeeeeebbbbbbbbeeeeeeeebbbbbbbb0000000000000000000000000000000000000000
7777777beeeeeeeebbbb7777eeeeeeeebbbbbbbbeee777ee89aaaa98eeeeeeeebbbbbbbbeeeeeeeebbbbbbbb0000000000000000000000000000000000000000
7e7e7e7ebbbbbbbbeeee7ee7bbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbb
eeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbdee88eeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbb
eeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbb7de8888eeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbb
eeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbb7de898888ebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbb
eeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbb677d88999988bbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbb
eeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbb677dd899a9998bbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbb
eeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbb67ddb89aaa998bbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbb
eeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbdddbb89aaaa98bbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbb
bbbbbbbbeeeeeeeebbbb99bbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeee2222222822222228f777777528888882
bb99bbb999eeeeeebbb9499bee99eeeebbbbbbbbeeeeeee5bbbb88bbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeee12282222922822227f77775582222221
b9999b77949eeeeebbb9499be999eeeebbbbbbbbeeeeee75bbb8888beeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeee222222222222222277ffff5582222221
b9499777949eeeeebb9994997999eeeebbbbbbbbeeeeee75b888898beeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeee282222122822229277ffff5582222221
b49977774999eeeebb4949077949eeeebbbbbbbbeeee677588999988eeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeee222282222222822277ffff5582222221
b9997777e994eeeebbb497776699eeeebbbbbbbbeee677558999a998eeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeee222222822222228277ffff5582222221
b49b7667e94eeeee777777776094eeeebbbbbbbbeee6755e899aaa98eeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeee2282222222822222775555f582222221
bbbb7607eeeeeeee7777777beee9eeeebbbbbbbbeee555ee89aaaa98eeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeee22222122222229227555555f21111112
eeee7ee7bbbbbbbb7e7e7e7ebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbb
eeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbb6eeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbb
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
000000000000101010000000000000000000000000000001010100000000000011111182bbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbb
000000000001010100000000000000000000000000000000101010000000000022222182bbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbb
000000000010101000000000000000000000000000000000010101000000000088888182bbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbb
000000000101000000000000000000000000000000000000000010100000000011111182bbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbb
0000000010100000000000000000000000000000000000000000010100000000eeee1182bbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbb
0000000101000000000000000000000000000000000000000000001010000000eeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbb
0000001010000000000000000000000000000000000000000000000101000000eeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbb
0000000101000000000000000000000000000000000000000000001010100000eeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbb
0000101010000000000000000000000000000000000000000000000101010000bbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeee
0000010100000000000000000000000000000000000000000000000010100000bbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeee
0000101000000000000000000000000000000000000000000000000001010000bbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeee
0001010000000000000000000000000000000000000000000000000000101000bbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeee
0010100000000000000000000000000000000000000000000000000000010100bbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeee
0001010000000000000000000000000000000000000000000000000000101000bbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeee
0010100000000000000000000000000000000000000000000000000000010100bbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeee
0101000000000000000000000000000000000000000000000000000000001010bbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeee
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
010400002304023040230402304023040230402304023040230402304023040230402304023040230402304023040230402304023040230402304023040230402304023040230402304023040230402304023040
010400001c1401c1401c1401c1401c1401c1401c1401c1401c1401c1401c1401c1401c1401c1401c1401c1401c1401c1401c1401c1401c1401c1401c1401c1401c1401c1401c1401c1401c1401c1401c1401c140
010200002304023040230402304023040230400000000000000000000034040340403404034040340403404034040340403404034040340403404034040340403404034040340400000033040330403304033040
010200001c1401c1401c1401c1401c1401c1400000000000000000000028140281402814028140281402814028140281402814028140281402814028140281402814028140281400000027140271402714027140
0102000033040330403304033040330403304033040330403304033040330403304033040000002f0402f0402f0402f0402f0402f0402f0402f0402f0402f0402f0402f0402f0402f0402f0402f0402f04000000
010200002714027140271402714027140271402714027140271402714027140271402714000000231402314023140231402314023140231402314023140231402314023140231402314023140231402314000000
010200002c0402c0402c0402c0402c0402c0402c0402c0402c0402c0402c0402c0402c0402c0402c0402c0402c040000002804028040280402804028040280402804028040280402804028040280402804028040
010200002014020140201402014020140201402014020140201402014020140201402014020140201402014020140000001c1401c1401c1401c1401c1401c1401c1401c1401c1401c1401c1401c1401c1401c140
010400002804028040280402804028040280402804028040280402804028040280402804028040280402804028040280402804028040280402804028040280402804028040280402804028040280402804028040
010400001c1401c1401c1401c1401c1401c1401c1401c1401c1401c1401c1401c1401c1401c1401c1401c1401c1401c1401c1401c1401c1401c1401c1401c1401c1401c1401c1401c1401c1401c1401c1401c140
010200002804028040280402804028040280402804028040280402804028040280402804028040280402804028040280402804028040280402804028040280402804028040280400000000000000000000000000
010200001c1401c1401c1401c1401c1401c1401c1401c1401c1401c1401c1401c1401c1401c1401c1401c1401c1401c1401c1401c1401c1401c1401c1401c1401c1401c1401c1400000000000000000000000000
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
010200001b14000000000000000000000000000000000000081400814008140081400814008140081400814008140081400814008140081400814008140081400814000000081400814008140081400814008140
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
