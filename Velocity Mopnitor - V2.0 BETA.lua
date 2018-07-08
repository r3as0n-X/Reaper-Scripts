--[[
.. Reascript Name: Velocity Monitor
.. Description: Monitor notes in specified intervals while adjusting velocity in the velocity lane of the MIDI editors.
.. Author: r3as0n_X
.. Licence: GPL v3
.. Reaper 5.92
.. SWS extensions v2.9.7
.. Version: 2.0 BETA
--]] 

local function msg(text)
  reaper.ShowConsoleMsg(tostring(text).."\n")
end

local function lim(value, lower, upper)
    if lower ~= nil and value < lower then
        value = lower
    elseif upper ~= nil and value > upper then
        value = upper
    end
    return value
end

t1, t2, t3, t4 = 0


-- Main window dimensions are set here
window_w = 360
window_h = 360

-- Initialize drawing flag for draw_objects() function
draw_flag = 1
draw_page = 0   -- 0 for main page, 1 for about page

-- Translate rgb matrices from 0-255 to 0-1
local function rgbcalc(r, g, b, o)

    r = lim(r, 0, 255) / 255 
    g = lim(g, 0, 255) / 255 
    b = lim(b, 0, 255) / 255
    o = lim(o, 0, 100) / 100

    return r, g, b, o
end  

-- Declare "Shape" class
Shape = {}
  Shape.button = false                    -- False for no button, true for button
  Shape.xywh = {-1, -1, -1, -1}           -- Shape top left position x, y and width, height. If h is zero, then shape is circle
  Shape.color = {-1, -1, -1, -1}          -- Display color for filling
  Shape.color_nor = {-1, -1, -1, -1}      -- Normal color for filling
  Shape.color_alt = {-1, -1, -1, -1}      -- Alternate color for filling
  Shape.textcolor = {-1, -1, -1, -1}      -- Color for text
  Shape.textcolor_alt = {-1, -1, -1, -1}  -- Color for text
  Shape.textcolor_nor = {-1, -1, -1, -1}  -- Color for text
  Shape.xywh_alt = {-1, -1, -1, -1}       -- Shape top left position x, y and width, height. If h is zero, then shape is circle
  Shape.text = nil                        -- Text
  Shape.fontface = "Arial"                -- Font family
  Shape.fontsize = 28                     -- Specify default font size, 0 for default size
  Shape.M_click = 0                       -- Mouse button clicked
  Shape.M_wheel = 0                       -- Mouse wheel
  Shape.mouseover = nil                  -- True if mouse is over shape, else nil
  Shape.char = nil                        -- Character pressed

-- New object constructor
function Shape:new(r, g, b, o, button, x, y, w, h, string, str_size, str_r, str_g, str_b, str_o)
  
  obj = {}
  setmetatable(obj, {__index = Shape})
  
  obj.button = button
  obj.xywh = {x, y, w, h}
  obj.color = {r, g, b, o}
  obj.color_nor = {r, g, b, o}

  
  if string ~= nil then
      obj.text = string
      obj.textcolor = {str_r, str_g, str_b, str_o}
      obj.textcolor_nor = {str_r, str_g, str_b, str_o}
      
      if str_size > 0 then
          obj.fontsize = lim(str_size, 8, 100)
      end
      
      gfx.setfont(1, obj.fontface, obj.fontsize)
      
      if obj.xywh[3] == 0 and obj.xywh[4] ~= 0 then 
          obj.xywh[3], obj.xywh[4] = gfx.measurestr(obj.text)
      elseif obj.xywh[3] == 0 and obj.xywh[4] == 0 then
          w, h = gfx.measurestr(obj.text)
          obj.xywh[3] = math.sqrt(w*w + h*h) / 2
      end
  end 
  
  return obj
end


-- Capture mouse events
local function mouseevents(obj)
  local m_w = gfx.mouse_wheel
  local m_c = gfx.mouse_cap
  local c = gfx.getchar()
  
  if m_w > 0 then
    m_w = 1
    gfx.mouse_wheel = 0
  elseif m_w < 0 then
    m_w = -1
    gfx.mouse_wheel = 0
  end
  
  obj.M_click = m_c
  obj.M_wheel = m_w
  obj.char = c
end


-- Check whether mouse is over the shape
function Shape:mouseaction()

  local x = gfx.mouse_x
  local y = gfx.mouse_y
  
  if self.xywh[4] > 0 then
      local shape_x = self.xywh[1] - self.xywh[3] / 2
      local shape_y = self.xywh[2] - self.xywh[4] / 2
      if x > shape_x and x < shape_x + self.xywh[3] and y > shape_y and y < shape_y + self.xywh[4] then
          self.mouseover = true
          mouseevents(self)
          return true
      else
          self.M_click = 0; self.M_wheel = 0; self.char = nil
          self.mouseover = false
          return false
      end
  elseif self.xywh[4] == 0 then
      local dist = math.sqrt((self.xywh[1] - x)*(self.xywh[1] - x) + (self.xywh[2]-y)*(self.xywh[2]-y))                                 ------------Problem
      if dist < self.xywh[3] then
          self.mouseover = true
          mouseevents(self)
          return true
      else
          self.M_click = 0; self.M_wheel = 0; self.char = nil
          self.mouseover = false
          return false
      end
  end
end


-- Draw the shape
function Shape:drawshape()

    if self.color[4] == -1 then         -- Fill or no fill according to opacity specified and set color matrices
        op = 100
    else
        op = self.color[4]             
    end
    gfx.set(rgbcalc(self.color[1], self.color[2], self.color[3], op))
    gfx.setfont(1, self.fontface, self.fontsize)  
    
    -- Draw shapes
    if self.xywh[4] > 0 then           -- If shape is rectangle
        local x = self.xywh[1] - (self.xywh[3] / 2)
        local y = self.xywh[2] - (self.xywh[4] / 2)
        if self.color[4] == -1 then 
        gfx.rect(x, y, self.xywh[3], self.xywh[4], 0)
        else
        gfx.rect(x, y, self.xywh[3], self.xywh[4], 1)
        end
    elseif self.xywh[4] == 0 then      --If shape is circle
        if self.color[4] == -1 then
        gfx.circle(self.xywh[1], self.xywh[2], self.xywh[3], 0)
        else 
        gfx.circle(self.xywh[1], self.xywh[2], self.xywh[3], 1)
        end
    end
    
    -- Draw string
    if self.text ~= nil then
        gfx.set(rgbcalc(self.textcolor[1], self.textcolor[2], self.textcolor[3], self.textcolor[4]))
        local w, h = gfx.measurestr(self.text)
        gfx.x = self.xywh[1] - (w / 2)
        gfx.y = self.xywh[2] - (h / 2)
        gfx.drawstr(self.text)
    end
    
end

-- Place the shape relative to main window
function Shape:place(x_ref, x, y_ref, y)

    if self.xywh[4] ~= 0 then   -- Place rectangle
        if x_ref == "left" then
            self.xywh[1] = 0 + self.xywh[3] / 2 + x
        elseif x_ref == "center" then
            self.xywh[1] = window_w / 2 + x
        elseif x_ref == "right" then
            self.xywh[1] = window_w - self.xywh[3] / 2 + x
        end
      
        if y_ref == "top" then
            self.xywh[2] = 0 + self.xywh[4] / 2 + y
        elseif y_ref == "center" then
            self.xywh[2] = window_h / 2 + y
        elseif y_ref == "bottom" then
            self.xywh[2] = window_h - self.xywh[4] / 2 + y
        end
    end
        
    if self.xywh[4] == 0  then     -- Place circle
        if x_ref == "left" then
            self.xywh[1] = 0 + self.xywh[3] + x
        elseif x_ref == "center" then
            self.xywh[1] = window_w / 2 + x
        elseif x_ref == "right" then
            self.xywh[1] = window_w - self.xywh[3] + x
        end
      
        if y_ref == "top" then
            self.xywh[2] = 0 + self.xywh[3] + y
        elseif y_ref == "center" then
            self.xywh[2] = window_h / 2 + y
        elseif y_ref == "bottom" then
            self.xywh[2] = window_h - self.xywh[3] + y
        end        
    end  
        
end

-- Initialize shapes
----------------------------------------------------------------------------------Menu
settings = Shape:new(0,0,0,100,false,0,0,0,22,"SETTINGS", 14,180,180,180,100)
settings:place("left", 5, "top", 5)
settings.textcolor_alt = {235, 235, 235, 100}
settings.textcolor = settings.textcolor_alt
about = Shape:new(0,0,0,100,false,0,0,0,22,"ABOUT", 14,180,180,180,100)
about:place("left", (15 + settings.xywh[3]), "top", 5)
about.textcolor_alt = {235, 235, 235, 100}
quit = Shape:new(0,0,0,100,false,0,0,0,22,"QUIT", 14,180,180,180,100)
quit:place("left", (25 + settings.xywh[3] + about.xywh[3]), "top", 5)
quit.textcolor_alt = {235, 235, 235, 100}

----------------------------------------------------------------------------------Page 0
-- Interval setting region
int_field = Shape:new(0, 0, 0, 100, false, 180, 180, 47, 0, "500", 47, 255,255,255,100)
int_field:place("center", 0, "center", 0)
circle = Shape:new(255,255,255,100,false,100,100,50,0)
circle:place("center", 0, "center", 0)
millisec = Shape:new(0,0,0,100,false,180,180,0,2,"Milliseconds", 24, 255,255,255,100)
millisec:place("center", 0, "top", 100)
-- LEDs
noteon_led_ring = Shape:new(50,50,50,-1, false, 0,0,6,0)
noteon_led_ring:place("right", -15, "top", 15)
noteon_led = Shape:new(100,0,0,100, false, 0,0,5,0)
noteon_led.color_alt = {255,0,0,100}
noteon_led.xywh[1] = noteon_led_ring.xywh[1]
noteon_led.xywh[2] = noteon_led_ring.xywh[2]

take_led_ring = Shape:new(50,50,50,-1, false, 0,0,6,0)
take_led_ring:place("right", -15, "top", 35)
take_led = Shape:new(100,100,0,100, false, 0,0,5,0)
take_led.color_alt = {255,255,0,100}
take_led.xywh[1] = take_led_ring.xywh[1]
take_led.xywh[2] = take_led_ring.xywh[2]

note_led_ring = Shape:new(50,50,50,-1, false, 0,0,6,0)
note_led_ring:place("right", -15, "top", 55)
note_led = Shape:new(0,100,0,100, false, 0,0,5,0)
note_led.color_alt = {0, 255, 0, 100}
note_led.xywh[1] = note_led_ring.xywh[1]
note_led.xywh[2] = note_led_ring.xywh[2]
-- LED text
txt_noteon = Shape:new(0,0,0,100,false,0,0,0,2,"Note On", 16, 200,200,200,100)
txt_noteon:place("right", -40, "top", 13)
txt_take = Shape:new(0,0,0,100,false,0,0,0,2,"Midi Editor", 16, 200,200,200,100)
txt_take:place("right", -40, "top", 33)
txt_note = Shape:new(0,0,0,100,false,0,0,0,2,"Active Note", 16, 200,200,200,100)
txt_note:place("right", -40, "top", 53)
-- Title
VelMon = Shape:new(0,0,0,100,false,0,0,0,2,"Velocity Monitor", 17,200,200,200,100)
VelMon:place("center", 0, "bottom", -30)  
Beta = Shape:new(0,0,0,100,false,0,0,0,2,"V2.0 - BETA", 15,200,200,200,100)
Beta:place("center", 0, "bottom", -12)  
RedCircle = Shape:new(255,0,0,0,false,0,0,180,0)
RedCircle:place("center", 0, "bottom", 293)  

--------------------------------------------------------------------------------Page 1
abt1 = Shape:new(0,0,0,100, false, 0,0,0,2,"Velocity Monitor", 16, 235,235,235,100)
abt1:place("center", 0, "top", 70)
abt2 = Shape:new(0,0,0,100, false, 0,0,0,2,"Version : 2.0 BETA", 16, 235,235,235,100)
abt2:place("center", 0, "top", 95)
abt3 = Shape:new(0,0,0,100, false, 0,0,0,2,"Author : R3as0n_X", 16, 235,235,235,100)
abt3:place("center", 0, "top", 120)
abt4 = Shape:new(0,0,0,100, false, 0,0,0,2,"Bug reports/Suggestions :\n   reason.n@gmail.com", 16, 235,235,235,100)
abt4:place("center", 0, "top", 145)
abt5 = Shape:new(0,0,0,100, false, 0,0,0,2,"If this script helps you in your work, \n      consider making a donation :", 17, 235,235,235,100)
abt5:place("center", 0, "top", 200)
Donation = Shape:new(180,180,0,100, false, 0,0,50,0,"Donate", 28, 0,0,0,100)
Donation:place("center", 0, "top", 245)
Donation.textcolor_alt = {0,0,255,100}

local function open_url(url)
  local OS = reaper.GetOS()
  if OS == "OSX32" or OS == "OSX64" then
    os.execute('open "" "' .. url .. '"')
  else
    os.execute('start "" "' .. url .. '"')
  end
end

local function d_nation()
    if Donation:mouseaction() then
        Donation.textcolor = Donation.textcolor_alt
        if Donation.M_click == 1 then
            open_url("http://www.yorgospanagiotopoulos.com")
            Donation.M_click = 0
        end
    else
        Donation.textcolor = Donation.textcolor_nor
    end
    -- and Donation.M_click == 1 then
end      

local function noteon_blink_on()
    led_time = reaper.time_precise()
    noteon_led.color = noteon_led.color_alt
    noteon_led:drawshape()
    draw_flag = 1
end   

local function noteon_blink_off(dt)
      local time = reaper.time_precise()
      if dt < time - led_time then
      noteon_led.color = noteon_led.color_nor
      draw_flag = 1
      end
end

local function check_menu()
    if settings:mouseaction() and settings.M_click == 1 then
        settings.textcolor = settings.textcolor_alt
        about.textcolor = about.textcolor_nor
        quit.textcolor = quit.textcolor_nor
        draw_page = 0
        draw_flag = 1
    elseif about:mouseaction() and about.M_click == 1 then
        settings.textcolor = settings.textcolor_nor
        about.textcolor = about.textcolor_alt
        quit.textcolor = quit.textcolor_nor
        draw_page = 1
        draw_flag = 1
    elseif quit:mouseaction() and quit.M_click == 1 then
        settings.textcolor = settings.textcolor_nor
        about.textcolor = about.textcolor_nor
        quit.textcolor = quit.textcolor_alt
        draw_page = 2
        draw_flag = 1
    end
end

local function draw_menu()
  settings:drawshape()
  about:drawshape()
  quit:drawshape()
end

local function draw_objects()
if draw_flag == 1 then
    draw_menu()
    if draw_page == 0 then
          
          -- Interval setting
          circle:drawshape()
          int_field:drawshape()
          millisec:drawshape()
          -- Leds
          noteon_led_ring:drawshape()
          noteon_led:drawshape()
          take_led_ring:drawshape()
          take_led:drawshape()
          note_led_ring:drawshape()
          note_led:drawshape()
          -- Led text
          txt_noteon:drawshape()
          txt_take:drawshape()
          txt_note:drawshape()
          
          VelMon:drawshape()
          Beta:drawshape()
          RedCircle:drawshape()
          draw_flag = 0
    elseif draw_page == 1 then
        abt1:drawshape()
        abt2:drawshape()
        abt3:drawshape()
        abt4:drawshape()
        abt5:drawshape()
        Donation:drawshape()
    end
draw_flag = 0
end    
end

--------------------------------------------------------------------------------------------------------------MIDI IMPLEMENTATION-----------------------------------
--------------------------------------------------------------------------------------------------------------------------------------------------------------------


-- Initialize global variables
cur_time = reaper.time_precise()
led_time = 0
cur_take = nil
cur_note = -1
cur_track = nil
cur_track_input = -1
interval = 500

-- Note on
local function noteon(take, note)
  local retval, sel, muted, start, ending, chan, pitch, vel = reaper.MIDI_GetNote(take, note)
  reaper.StuffMIDIMessage(0, 0x90 + chan, pitch, vel)
end

-- Note off
local function noteoff(take, note)
  local retval, sel, muted, start, ending, chan, pitch, vel = reaper.MIDI_GetNote(take, note)
  reaper.StuffMIDIMessage(0, 0x90 + chan, pitch, 0x00)
end

-- Check if track is changed, set/restore input, arm for recording and monitoring
local function checktrack(take)
  track = reaper.GetMediaItemTake_Track(take)
  if track ~= cur_track then
    if cur_track ~= nil then
    reaper.SetMediaTrackInfo_Value(cur_track, "I_RECINPUT", cur_track_input)
    end
    cur_track = track
    cur_track_input = reaper.GetMediaTrackInfo_Value(cur_track, "I_RECINPUT")
    reaper.SetMediaTrackInfo_Value(cur_track, "I_RECINPUT", 6112)
    reaper.ClearAllRecArmed()
    reaper.SetMediaTrackInfo_Value(cur_track, "I_RECARM", 1)
    reaper.SetMediaTrackInfo_Value(cur_track, "I_RECMON", 1)
  end
end

-- Check if take has changed and arm track accordingly
local function checktake(take)  
  if take ~= cur_take then
    if cur_note ~= -1 and cur_take ~= nil then
      noteoff(cur_take, cur_note) -- Note off before changing takes
    end
    checktrack(take)
    cur_take = take
  end
end

-- Check if note has changed
local function checknote(note)
  if note ~= cur_note then
    noteoff(cur_take, cur_note)
    cur_note = note
  end
end

-- Check time passed from last noteon message
local function checktime()
  local time = reaper.time_precise()
  local dt = time - cur_time
  if dt > interval/1000 then
    cur_time = time
    return true
  else
    return false
  end
end

-- Check if mouse is in the velocity lane
local function checklane()
  local win, seg, det = reaper.BR_GetMouseCursorContext()
  local retval, inline, ntrow, cclane, cclaneval, cclaneid = reaper.BR_GetMouseCursorContext_MIDI()
    if cclane == 0x200 then
      return true
    else  
      return false
    end
end




--------------------------------------------------------------------------------------------------------------MAIN FUNCTION-----------------------------------------
--------------------------------------------------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------------------------------------------

local function Main()
    reaper.ClearConsole()
    msg()
    
     -- Check for active takes and prepare track
    local take = reaper.MIDIEditor_GetTake(reaper.MIDIEditor_GetActive())
     if take ~= nil then  -- Check if take is valid
          
          take_led.color = take_led.color_alt
          draw_flag = 1
     
           checktake(take)  
           local note = reaper.MIDI_EnumSelNotes(cur_take, -1)
           if note > -1 then  -- note selected
           
                note_led.color = note_led.color_alt
                draw_flag = 1
                
                 checknote(note)
                 if checktime() and checklane() then
                   noteon_blink_on()
                   noteoff(cur_take, cur_note)
                   noteon(cur_take, cur_note)
                 elseif not checklane() then
                   noteoff(cur_take, cur_note)
                 end
           elseif note == -1 then -- no note selected
           
                note_led.color = note_led.color_nor
                draw_flag = 1
                
                 noteoff(cur_take, cur_note)
                 cur_note = note
           end
     elseif take == nil then   -- no valid take
     
          take_led.color = take_led.color_nor
          draw_flag = 1
          
           if cur_take ~= nil then
             noteoff(cur_take, cur_note)
             cur_take = take
           end
     end
    noteon_blink_off(0.1)
    
    check_menu()
    d_nation()
    if circle:mouseaction() and circle.M_wheel ~= 0 then
        interval = lim((interval + 50*circle.M_wheel), 50, 9999)
        int_field.text = string.format("%d", interval)
        draw_flag = 1
    end

    draw_objects()

    char = gfx.getchar()
    if char ~= 27 and char ~= -1 and draw_page ~= 2 then
        reaper.defer(Main)
    else
        if cur_track ~= nil then
        reaper.SetMediaTrackInfo_Value(cur_track, "I_RECINPUT", cur_track_input)
        end
        gfx.quit()
    end
    
        
    gfx.update()
end

gfx.init("Velocity Monitor V2.0 BETA", window_w, window_h, 0, 0, 0)
draw_objects()
Main()
