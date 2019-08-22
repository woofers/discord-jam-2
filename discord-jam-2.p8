pico-8 cartridge // http://www.pico-8.com
version 16
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

local ember = {}
make_object(ember, sprite)

function ember:init(x, y, screen)
   sprite.init(self)
   self:set_location(x, y)
   self.screen = screen
   self.radius = random(0, 2)
   self.color = 9
end

function ember:update(dt)
   sprite.update(dt)
   local speed = 30
   local multiplier = random(1, 5)
   self.y += speed * multiplier * dt
   if (not screen:is_visible(self.x, self.y, self.radius, self.radius)) then
      local respawn_zone = random(0, 40)
      self.y = respawn_zone
   end
end

function ember:render(dt)
   sprite.render(dt)
   draw_rectangle(self.x, self.y, self.radius, self.radius, self.color)
end

local embers = {}
make_object(embers, gameobject)

function embers:init()
   self.embers = {}
   local embers_size = 140
   local max_height = 0
   local min_height = screen_size - 1
   local min_width = 0
   local max_width = screen_size - 1

   for i = 1, embers_size do
      self.embers[i] = ember(random(min_width, max_width), random(max_height, min_height), screen(0, 0))
   end
end

function embers:update(dt)
   for i = 1, #self.embers do
      self.embers[i]:update(dt)
   end
end

function embers:render(dt)
   for i = 1, #self.embers do
      self.embers[i]:render(dt)
   end
end

local tile = {}
make_object(tile, sprite)

function tile:init(id, x, y)
   sprite.init(self, x, y)
   self.id = id
   self.size = tile_size
   self.flag = fget(id)
end

function tile:has_flag(flag)
   return not (band(self.flag, flag) == 0)
end

function tile:update(dt)
   sprite.update(dt)
end

function tile:render(dt)
   sprite.render(dt)
   spr(self.id, self.x, self.y, self.size / tile_size, self.size / tile_size)
end

local room = {}
make_object(room, sprite)

function room:init(x, y)
   self.room_size = screen_size / tile_size
   self:set_location(x, y)
   self.blocks = {}
   self.items = {}
   self.top = {}
   for x = 1, self.room_size do
      self.blocks[x] = {}
      for y = 1, self.room_size do
         id = mget(self.x * self.room_size + x - 1,
                   self.y * self.room_size + y - 1)

         if self:is_door(id) then
            self.top[#self.top + 1] = self:make_block(id + 128, x, y)
         elseif self:is_pushable_block(id) then
            self.items[#self.items + 1] = self:make_block(id, x, y)
            id += 1
         end

         self.blocks[x][y] = self:make_block(id, x, y)
      end
   end
end

function room:is_door(id)
    return mod(id - 5, 16) >=0
       and mod(id - 5, 16) <= 3
end

function room:is_pushable_block(id)
    return mod(id - 14, 16) == 0
end

function room:item(x, y)
   for i = 1, #self.items do
      if self.items[i]:local_x() == x
         and self.items[i]:local_y() == y then
         return self.items[i]
      end
   end
   return nil
end

function room:tile(x, y)
   local layer = self:item(x * tile_size, y * tile_size)
   if (layer) then
      return layer
   end
   local one_x = x + 1
   local one_y = y + 1
   if (not self:in_range(one_x, one_y)) return nil
   return self.blocks[one_x][one_y]
end

function room:in_range(x, y)
   return x > 0 and y > 0
      and x <= #self.blocks
      and y <= #self.blocks[x]
end

function room:make_block(id, x, y)
   return tile(id,
               self.x * self.room_size * tile_size
                  + (x - 1) * tile_size,
               self.y * self.room_size * tile_size
                  + (y - 1) * tile_size)
end

function room:update(dt)
   sprite.update(dt)
   for x = 1, #self.blocks do
      for y = 1, #self.blocks[x] do
         self.blocks[x][y]:update(dt)
      end
   end
   for i = 1, #self.items do
      self.items[i]:update(dt)
   end
   for i = 1, #self.top do
      self.top[i]:update(dt)
   end
end

function room:render_top(dt)
   sprite.render(dt)
   for i = 1, #self.top do
      self.top[i]:render(dt)
   end
end

function room:render(dt)
   sprite.render(dt)
   for x = 1, #self.blocks do
      for y = 1, #self.blocks[x] do
         self.blocks[x][y]:render(dt)
      end
   end
   for i = 1, #self.items do
      self.items[i]:render(dt)
   end
end

local ram = {}
make_object(ram, sprite)

function ram:init(x, y, level)
   sprite.init(self)
   self.start_x = x
   self.start_y = y
   self.level = level
   self:set_local_location(x, y)
   self:reset()
   local default_direction = right
   self:set_angle(default_direction)

   self.animations = {}
   self.animations["walk"] = {}
   self.animations["walk"]["speed"] = 0.1
   self.animations["walk"]["size"] = 1
   self.animations["walk"]["loop"] = 0
   self.animations["walk"]["width"] = { 2, 2 }
   self.animations["walk"]["height"] = { 2, 2 }
   self.animations["walk"][right]= { 64, 80 }
   self.animations["walk"][up]= { 96, 112 }
   self.animations["walk"][down]= { 66, 82 }
   self.animations["none"] = {}
   self.animations["none"]["speed"] = 0
   self.animations["none"]["size"] = 0
   self.animations["none"]["loop"] = 0
   self.animations["none"]["width"] = { 2, 2 }
   self.animations["none"]["height"] = { 2, 2 }
   self.animations["charge"] = {}
   self.animations["charge"]["speed"] = 0.15
   self.animations["charge"]["size"] = 2
   self.animations["charge"]["loop"] = 2
   self.animations["charge"]["width"] = { 2, 2, 2 }
   self.animations["charge"]["height"] = { 2, 2, 2 }
   self.animations["charge"][right]= { 98, 128, 130 }
   self.animations["charge"][left]= { 98, 128, 130 }
   self.animations["charge"][up]= { 98, 128, 130 }
   self.animations["charge"][down]= { 98, 128, 130 }
   self.animations["death"] = {}
   self.animations["death"]["speed"] = 0.15
   self.animations["death"]["size"] = 5
   self.animations["death"]["loop"] = 5
   self.animations["death"]["width"] = { 2, 2, 2, 1, 1, 1  }
   self.animations["death"]["height"] = { 2, 1, 1, 1, 1, 1 }
   self.animations["death"][right]= { 64, 160, 162, 176, 177, 178 }
   self.animations["death"][left]= { 64, 160, 162, 176, 177, 178 }
   self.animations["death"][up]= { 64, 160, 162, 176, 177, 178 }
   self.animations["death"][down]= { 64, 160, 162, 176, 177, 178 }
end

function ram:set_local_location(x, y)
   self:set_location(self.level.current_room.x * screen_size + x,
                     self.level.current_room.y * screen_size + y)
end

function ram:set_spawn()
   self.start_x = self.x
   self.start_y = self.y
   self.start_angle = self.angle
end

function ram:set_animation(animation)
   if (self.animation == animation) return
   self.animation = animation
   self.animation_counter = 0
   self.frame_offset = 0
end

function ram:set_angle(angle)
   if (not self.start_angle) self.start_angle = angle
   self.angle = angle
   local scale = 1
   if angle == left then
      self:set_scale(-scale, scale)
   else
      self:set_scale(scale, scale)
   end
end

function ram:is_auto_moving()
   return self.auto_move_time > 0
end

function ram:update(dt)

   sprite.update(dt)

   local x = self.x
   local y = self.y

   self.had_input = false
   if not self.locked then
     for i, key in pairs(arrows) do
        if btn(key) then
           self:set_angle(key)
           self:move(dt)
           self.had_input = true
           break
        end
     end
     if not self:is_auto_moving()
        and not self.is_dying
        and not self.had_input then
        self:set_animation("none")
     end
   end


   if (btnp(x_key)) sfx(49)
   if btn(x_key) then
      self:set_animation("charge")
      self.locked = true
   elseif self:is_finished_charging()
      and self.animation == "charge" then
      self:auto_move(1, 1.5)
   elseif self.animation == "charge" then
      self.locked = false
   end

   if self:is_auto_moving() then
      self.auto_move_time -= dt
      self:move(dt, self.auto_move_speed)
      if not self:is_auto_moving() then
         self.locked = false
      end
   end

   if self:is_colliding() and not self.is_dying then
      self.x = x
      self.y = y
      self.auto_move_time = 0
      self.locked = false
      self:set_animation("none")
   end

   local right_door = 16
   local left_door = 32
   local up_door = 64
   local down_door = 128

   if self:is_colliding(right_door) then
      self.level:move_right()
   elseif self:is_colliding(left_door) then
      self.level:move_left()
   elseif self:is_colliding(up_door) then
      self.level:move_up()
   elseif self:is_colliding(down_door) then
      self.level:move_down()
   end

   local kill = 2
   if not self:is_auto_moving()
      and self:is_colliding(kill) then
      if (not self.is_dying) self:move_grid()
      self.locked = true
      self.is_dying = true
      self:set_animation("death")
   end
   if self:is_finished_dying() then
      self:reset()
   end

   self:animate(dt)
end

function ram:move_grid()
   self.x /= tile_size
   self.y /= tile_size
   self.x = round(self.x) * tile_size
   self.y = round(self.y) * tile_size

   case =
   {
      [left] = function()
         self:translate(-tile_size, 0)
      end,

      [right] = function()
         self:translate(tile_size, 0)
      end,

      [up] = function()
         self:translate(0, -tile_size)
      end,

      [down] = function()
         self:translate(0, tile_size)
      end,
   }
   case[self.angle]()
end

function ram:animate(dt)
   if self.animation_counter >= self.animations[self.animation]["speed"] then
      self.animation_counter = 0
      self.frame_offset += 1

      if self.frame_offset > self.animations[self.animation]["size"] then
         self.frame_offset = self.animations[self.animation]["loop"]
      end
   end
   self.animation_counter += dt
end

function ram:is_finished_animation(animation)
   return self.frame_offset == self.animations[animation]["size"]
      and self.animation == animation
end

function ram:is_finished_charging()
   return self:is_finished_animation("charge")
end

function ram:is_finished_dying()
   return self:is_finished_animation("death")
end

function ram:auto_move(time, speed)
   speed = speed or 1
   self.auto_move_time = time
   self.auto_move_speed = speed
   self.locked = true
end

function ram:move(dt, multiplier)
   multiplier = multiplier or 1
   local speed = 30 * dt * multiplier
   case =
   {
      [left] = function()
         self:translate(-speed, 0)
      end,

      [right] = function()
         self:translate(speed, 0)
      end,

      [up] = function()
         self:translate(0, -speed)
      end,

      [down] = function()
         self:translate(0, speed)
      end,
   }
   case[self.angle]()
   if (not self.is_dying) self:set_animation("walk")
end


function ram:render(dt)
   sprite.render(dt)

   local x_offset = 0
   local y_offset = 1
   if self:facing_left() then
      x_offset = 3
   end

   local normal = function()
      local default = function()
         spr(self.animations["walk"][right][1],
             self.x - x_offset,
             self.y - y_offset,
             2, 1, self:facing_left())
         draw_sprite(self.animations["walk"][right][2],
                     self.x + self.frame_offset - x_offset,
                     self.y - y_offset + 8,
                     1, 1, self:facing_left())
      end

      local vertical = function()
         spr(self.animations["walk"][self.angle][1],
             self.x,
             self.y - y_offset,
             2, 1)
         spr(self.animations["walk"][self.angle][2],
             self.x + self.frame_offset,
             self.y - y_offset + 8)
      end

      local case =
      {
         [left] = default,
         [right] = default,
         [up] = vertical,
         [down] = vertical,
      }
      case[self.angle]()
   end

   local case =
   {
      ["none"] = normal,
      ["walk"] = normal,
      ["default"] = function()
         local death_fix = (self:facing_left()
                              and (2 - self.animations[self.animation]["width"][1 + self.frame_offset]) * tile_size
                              or 0)
         spr(self.animations[self.animation][self.angle][1 + self.frame_offset],
             self.x - x_offset + death_fix,
             self.y - y_offset,
             self.animations[self.animation]["width"][1 + self.frame_offset],
             self.animations[self.animation]["height"][1 + self.frame_offset],
             self:facing_left())
      end,
   }
   if case[self.animation] then
      case[self.animation]()
   else
      case["default"]()
   end
end

function ram:reset()
   self.is_dying = false
   self.animation_counter = 0
   self.animation = "none"
   self.auto_move_time = 0
   self.auto_move_speed = 1
   self.frame_offset = 0
   self.locked = false
   self:set_location(self.start_x, self.start_y)
   self:set_angle(self.start_angle)
end

local level = {}
make_object(level, sprite)

function level:init(x, y)
   self:load_room(x, y)
   self.ram = ram(tile_size, tile_size, self)
   self.screen = screen(x * screen_size, y * screen_size)
   self.camera_pan_time = 0
   self.level_load_time = 1.66
end

function level:load_room(x, y)
   if (self.is_switching) return
   self.old_room = self.current_room
   self.current_room = room(x, y)
   if self.old_room then
      self.is_switching = true
      self.ram:auto_move(self.level_load_time, 0.57)
   end
end

function level:ram_room()
   if (not self.old_room) return self.current_room
   if self.current_room.x * screen_size <= self.ram.x
      and self.current_room.x * screen_size + screen_size > self.ram.x
      and self.current_room.y * screen_size <= self.ram.y
      and self.current_room.y * screen_size + screen_size > self.ram.y then
      return self.current_room
    end
    return self.old_room
end

function level:move_down()
   self:load_room(self.current_room.x, self.current_room.y + 1)
end

function level:move_left()
   self:load_room(self.current_room.x - 1, self.current_room.y)
end

function level:move_up()
   self:load_room(self.current_room.x, self.current_room.y - 1)
end

function level:move_right()
   self:load_room(self.current_room.x + 1, self.current_room.y)
end

function level:update(dt)
   sprite.update(dt)
   if (self.old_room) self.old_room:update(dt)
   self.current_room:update(dt)

   if self.is_switching then
      self.camera_pan_time += dt

      if self.old_room then
         self.screen:translate((self.current_room.x - self.old_room.x)
                               * screen_size * dt / self.level_load_time,
                               (self.current_room.y - self.old_room.y)
                               * screen_size * dt / self.level_load_time)
      end

      if self.camera_pan_time > self.level_load_time then
         self.ram:set_spawn()
         self.camera_pan_time = 0
         self.is_switching = false

         if self.old_room then
            self.old_room:destroy()
            self.old_room = nil
         end
      end
   end

   self.ram:update(dt)
end

function level:render(dt)
   sprite.render(dt)
   if (self.old_room) self.old_room:render(dt)
   self.current_room:render(dt)
   self.ram:render(dt)
   self.current_room:render_top(dt)
   if (self.old_room) self.old_room:render_top(dt)
end

local menu = {}
make_object(menu, gameobject)

function menu:init(states)
   self.game_states = states
   self.exit_time = 0
end

function menu:create()
   self.embers = embers()
   music(0)
end

function menu:destroy()
end

function menu:update(dt)
   self.embers:update(dt)
   if (btn(x_key) and not self.exit) then
      self.exit = true
      self.exit_time = 0
      music(-1, 0)
      sfx(22)
   end
   if (self.exit) self.exit_time += dt;
end

function menu:render(dt)
   bg(8)
   self:render_flash()
   self.embers:render(dt)

   print("the devil with a new ram", 17, 105, 7)
   print("press ❎ to start", 32, 113, 7)

   -- draw frame
   draw_rectangle(39, 42, 50, 50, 9, 2, 8)

   -- draw ram
   sspr(0, 32, 16, 16, 41, 46, 80, 80)

   -- draw horns
   sspr(40, 32, 8, 8, 55, 2, 40, 40)
   sspr(40, 32, 8, 8, 34, 2, 40, 40, true)
end

function menu:render_flash()
   local delay = 0.08
   local interval = 0.2

   local frames = 12

   local black = function()
      for i = 0, 15 do
         pal(i, 0)
      end
   end
   local out = function()
      reset_pallet()
      pal(9, 6)
      pal(7, 6)
      pal(4, 6)
      pal(5, 6)
      pal(8, 5)
      pal(0, 5)
      pal(6, 6)
   end
   local dark = function()
      reset_pallet()
      pal(9, 5)
      pal(7, 5)
      pal(4, 5)
      pal(5, 5)
      pal(8, 0)
      pal(0, 0)
      pal(6, 5)
   end
   local on = function()
      pal(9, 8)
      pal(8, 7)
      pal(7, 8)
      pal(4, 8)
      pal(5, 8)
      pal(0, 7)
      pal(6, 8)
   end
   local off = reset_pallet
   local pattern = { on, off,
                     on, off,
                     on, off,
                     out, dark,
                     dark, black,
                     black }

   for i = 1, #pattern + 1 do
      if self.exit_time > delay then
         if i > #pattern then
            self.game_states:pop()
         elseif self.exit_time < (interval * i + delay) then
            pattern[i]()
            break
         end
      end
   end
end

local play = {}
make_object(play, gameobject)

function play:init(states)
   self.game_states = states
end

function play:create()
   self.level = level(0, 0)
end

function play:destroy()

end

function play:update(dt)
   self.level:update(dt)
end

function play:render(dt)
   reset_pallet()
   self.level:render(dt)
   --self:render_debug(dt)
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

   print("cpu "..cpu, self.level.current_room.x * screen_size + 32, self.level.current_room.y * screen_size + 8, cpu_color)
   print("mem "..mem, self.level.current_room.x * screen_size + 32, self.level.current_room.y * screen_size + 16, mem_color)
   print("mem min "..min_mem, self.level.current_room.x * screen_size + 32, self.level.current_room.y * screen_size + 24, 6)
   print("mem max "..max_mem, self.level.current_room.x * screen_size + 32, self.level.current_room.y * screen_size + 32, 6)
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

__gfx__
28989898989898989898989229999992bbbbbbbb2282222222222822282811122111828211111111111111111111111166666668666666616777777167777776
89898989898989898989898992222229bbbbbbbb8228888888888228228122218222182211888888888888888888881196686666766166667677771176666661
98989898989898989898989892222289bbbbbbbb2881111111111882828122218222182818122222222222222222218166666666666666667766661176666661
89898989898989898989898992222889bbbbbbbb8111128112811118281122218222118218281111111111111111828168666696616666767766661176666661
98989898989898989898989892228889bbbbbbbb1222128112812221281111111111118218211888888888888881128166668666666616667766661176666661
89898989898989898989898992288889bbbbbbbb1222128112812221281222222222218218218122222222222218128166666686666666167766661176666661
98989898989898989898989892888889bbbbbbbb1222128112812221281888888888818218218212222222222128128166866666661666667711116176666661
89898989898989898989898929999992bbbbbbbb2888128112818882281111111111118218218221222222221228128166666966666667667111111661111116
98989898289898929898989888888888eeeeeeee2111128112811112281111111111118218218222222222222228128199999998999999989aaaaaa19aaaaaa9
89898989898989898989898982222228eeeeeeee122212811281222128122222222221821821822222222222222812811998999929989999a9aaaa11a9999991
98989898989898989898989882222228eeeeeeee122212811281222128188888888881821821822222222222222812819999999999999999aa999911a9999991
89898989898989898989898982222228eeeeeeee122212811281222128111111111111821821822222222222222812819899991998999929aa999911a9999991
98989898989898989898989882222228eeeeeeee811112811281111828112221822211821821822222222222222812819999899999998999aa999911a9999991
89898989898989898989898982222228eeeeeeee288111111111188282812221822218281821822222222222222812819999998999999989aa999911a9999991
98989898989898989898989882222228eeeeeeee822888888888822822812221822218221821822222222222222812819989999999899999aa111191a9999991
29898989298989828989898288888888eeeeeeee228222222222282228281112211182821821822222222222222812819999919999999299a111111991111119
2d1d1d1d1d1d1d1d1d1d1d129888888921111112eeeeeeeebbbbbbbbeeeeeeeebbbbbbbb18218221222222221228128122222228222222282888888128888882
d1d1d1d1d1d1d1d1d1d1d1d18828282819999991eeeeeeeebbbbbbbbeeeeeeeebbbbbbbb18218212222222222128128112282222922822228288881182222221
1d1d1d1d1d1d1d1d1d1d1d1d8282828819888891eeeeeeeebb99bb99eeeeeeeebbbbbbbb18218122222222222218128122222222222222228822221182222221
d1d1d1d1d1d1d1d1d1d1d1d18828282819888891eeeeeeeebb49bb99eeeeeeeebbbbbbbb18211888888888888881128128222212282222928822221182222221
1d1d1d1d1d1d1d1d1d1d1d1d8282828819888891eeeeeeeeb9940794eeeeeeeebbbbbbbb18281111111111111111828122228222222282228822221182222221
d1d1d1d1d1d1d1d1d1d1d1d18828282819888891eeeeeeeeb4947769eeeeeeeebbbbbbbb18122222222222222222218122222282222222828822221182222221
1d1d1d1d1d1d1d1d1d1d1d1d8282828819999991eeeeeeee774477bbeeeeeeeebbbbbbbb11888888888888888888881122822222228222228811112182222221
d1d1d1d1d1d1d1d1d1d1d1d19888888921111112eeeeeeee77777bbbeeeeeeeebbbbbbbb11111111111111111111111122222122222229228111111221111112
1d1d1d1d2d1d1d121d1d1d1dbbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbb1eeeeeeeebbbbbbbb
d1d1d1d1d1d1d1d1d1d1d1d1bbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeee7bb1bbbbeeeeeeeebbbbbbbb
1d1d1d1d1d1d1d1d1d1d1d1dbbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbb
d1d1d1d1d1d1d1d1d1d1d1d1bbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeeb1bbbb7beeeeeeeebbbbbbbb
1d1d1d1d1d1d1d1d1d1d1d1dbbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbb1bbbeeeeeeeebbbbbbbb
d1d1d1d1d1d1d1d1d1d1d1d1bbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbb1beeeeeeeebbbbbbbb
1d1d1d1d1d1d1d1d1d1d1d1dbbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebb1bbbbbeeeeeeeebbbbbbbb
21d1d1d121d1d1d2d1d1d1d2bbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbb7bbeeeeeeeebbbbbbbb
bbb99bbbe99eeeeebb99bbbb99eeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeee22222228222222282888888128888882
bb9499bb9999eeeeb9499bb9999eeeeebbbbbbbbeeeeeeeebbb88bbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeee12282222922822228288881182222221
bb9499979994eeeeb9499777994eeeeebbbbbbbbeeeeeee7bb88888beeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeee22222222222222228822121182222221
b99949077949eeee99997077949eeeeebbbbbbbbeeeeeee7b889888beeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeee28222212282222928821221182222221
b49949776699eeee49997766999eeeeebbbbbbbbeeeeee7788999988eeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeee22228222222282228822221182222221
b44997776094eeeeb49b7760e94eeeeebbbbbbbbeeee7777899a9998eeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeee22222282222222828822221182222221
77444777eee9eeeebbbb7777eeeeeeeebbbbbbbbeee7777e89aaa998eeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeee22822222228222228811112182222221
7777777beeeeeeeebbbb7777eeeeeeeebbbbbbbbeee777ee89aaaa98eeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeee22222122222229228111111221111112
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
bbbbb99beeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeee2222222222bbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeee
bbbb9499eeeeeeeebbbbb99beeeeeeeebbbbbbbbeee8888888888bbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeee
bbbb9499eeeeeeeebbbb949beeeeeeeebbbbbbbbeee1111111111bbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeee
bbb99949eeeeeeeebbbb9499eeeeeeeebbbbbbbbeee1128112811bbb2811eeeebbbb1182eeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeee
bbb949977999eeeebbb999497eeeeeeebbbbbbbbeeee12811281bbbb2811111111111182eeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeee
bbbb97707749eeeebbb94997799eeeeebbbbbbbbeeee12811281bbbb2812222222222182eeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeee
777777776699eeee777777707749eeeebbbbbbbbeeee12811281bbbb2818888888888182eeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeee
777777776094eeee777777776699eeeebbbbbbbbeeee12811281bbbb2811111111111182eeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeee
7e7e7e7ebbb9bbbb7e7e7e7e6094bbbbeeeeeeeebbbb12811281eeee2811111111111182bbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbb
eeeeeeeebbbbbbbbeeeeeeeebbb9bbbbeeeeeeeebbbb12811281eeee2812222222222182bbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbb
eeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbb12811281eeee2818888888888182bbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbb
eeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbb12811281eeee2811111111111182bbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbb
eeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbb1128112811eee2811bbbbeeee1182bbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbb
eeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbb1111111111eeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbb
eeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbb8888888888eeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbb
eeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbb2222222222eeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbb
b99bbb99eeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeee
b499b9999eeeeeeeb99bbb99eeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeee
994997994eeeeeeeb499b994eeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeee
499407799eeeeeee99499799eeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeee
b49977669eeeeeee49940669eeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeee
b744776094eeeeeeb49776094eeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeee
777777bbe9eeeeee77777bbb9eeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeee
bb7bb7bbeeeeeeee77b77bbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeee
eeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbb
eee9ee99bbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbb
eee9999ebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbb
ee94974ebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbb
e494799ebb9b9bbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbb
e49766eebb999bbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbb
777709eeb4479bbbee9eeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbb
777ee9ee7770bbbbe47eeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbb
bbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeee
bbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeee
bbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeee
bbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeee
bbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeee
bbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeee
bbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeee
bbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeee
e888888ebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeeb888888beeeeeeeeb111111beeeeeeeebbbbbbbb1818181129191912
88777788bbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeee88777788eeeeeeee11988811eeeeeeeebbbbbbbb8181818191919191
87777778bbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeee87777778eeeeeeee19988881eeeeeeeebbbbbbbb1818181119191911
87788778bbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeee87788778eeeeeeee19911881eeeeeeeebbbbbbbb8181818191919191
87788778bbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeee87788778eeeeeeee19911881eeeeeeeebbbbbbbb1818181119191911
87777778bbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeee87777778eeeeeeee19999981eeeeeeeebbbbbbbb8181818191919191
88777788bbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeee88777788eeeeeeee11999911eeeeeeeebbbbbbbb1818181119191911
e888888ebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeeb888888beeeeeeeeb119111beeeeeeeebbbbbbbb2111111221111112
b111111beeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeee91eeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeee
11777711eeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeee81eeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeee
17777771eeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeee81eeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeee
17711771eeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeee91eeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeee
17711771eeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeee91eeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeee
17777771eeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeee81eeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeee
11777711eeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeee81eeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeee
b111111beeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeee91eeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeee
e111111ebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeeb111111beeeeeeeeb8891bbaeeeeeeeebbbbbbbbeeeeeeeebbbbbbbb
11d77711bbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeee11988811eeeeeeee811816aaeeeeeeeebbbbbbbbeeeeeeeebbbbbbbb
1dd77771bbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeee19988881eeeeeeee81186daaeeeeeeeebbbbbbbbeeeeeeeebbbbbbbb
1dd11771bbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeee19911889988998899886d9aaeeeeeeeebbbbbbbbeeeeeeeebbbbbbbb
1dd11771bbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeee1991188111111111116d99aaeeeeeeeebbbbbbbbeeeeeeeebbbbbbbb
1ddddd71bbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeee19999981eeeeeeeeb6d999a9eeeeeeeebbbbbbbbeeeeeeeebbbbbbbb
11dddd11bbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeee11999911eeeeeeeeb9aaaa9aeeeeeeeebbbbbbbbeeeeeeeebbbbbbbb
e111111ebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeebbbbbbbbeeeeeeeeb111111beeeeeeee9aaaa9a9eeeeeeeebbbbbbbbeeeeeeeebbbbbbbb
__gff__
0202020000102080800101010000010002020200001020404001000100000100020202000000000000010101000001000202020000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
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
