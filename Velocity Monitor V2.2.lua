-------------------------------------------------------------------------GENERAL FUNCTIONS-----------

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

local function rgbcalc(r, g, b, o)

    r = lim(r, 0, 255) / 255 
    g = lim(g, 0, 255) / 255 
    b = lim(b, 0, 255) / 255
    o = lim(o, 0, 100) / 100

    return r, g, b, o
end  

local function open_url(url)
  local OS = reaper.GetOS()
  if OS == "OSX32" or OS == "OSX64" then
    os.execute('open "" "' .. url .. '"')
  else
    os.execute('start "" "' .. url .. '"')
  end
end
-----------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------INITIALIZE GRAPHICS---------

-- Initialize main window dimensions and coordinates
window = {}
window.w = 360      -- width
window.h = 360      -- height
window.mode = 0     -- docked
window.x = 0        -- x position relative to screen
window.y = 0        -- y position relative to screen

-- Flags
f_draw = true       -- global draw flag
draw_page = 0       -- menu page
btn_state = 0       

-- Screen coordinates
Frame = {}
  Frame.x = -1
  Frame.y = -1
  
-- Feedback interval in milliseconds
interval = 500

-- Reinitialize graphics
local function re_init(mode)
    if mode == 0 then
          gfx.quit()
          gfx.init("Velocity Monitor V2.0 BETA", window.w, window.h, window.mode, window.x, window.y)
    elseif mode == 1 then
        if window.mode ~= 1 then
          gfx.quit()
          gfx.init("Velocity Monitor V2.0 BETA", window.w, window.h, window.mode, window.x, window.y)
        end
    end        
end

local function refocus_tool()
    if Frame.y == 0 then 
      re_init(1) 
    end
end

local function update_coor()
    local x, y = gfx.clienttoscreen((0 - 4), (0 - 23))
    window.x = x
    window.y = y
end

-- Initialize input object
Action = {}
  Action.m_x = nil
  Action.m_y = nil
  Action.m_click = 0
  Action.m_wheel = 0
  Action.c = 0
  
function get_input()
  Action.m_x = gfx.mouse_x
  Action.m_y = gfx.mouse_y
  Action.m_click = gfx.mouse_cap
  Action.m_wheel = gfx.mouse_wheel
  Action.c = gfx.getchar()
  Frame.x, Frame.y = reaper.GetMousePosition()
  
  if Action.m_click ~= 0 or Action.m_wheel ~= 0 or Action.c ~= 0 then
      gfx.mouse_wheel = 0
      return true
  else
      return false
  end 
end

-- Initialize shape object
Shape = {}
  Shape.button = false                    
  Shape.xywh = {-1, -1, -1, -1}           
  Shape.color = {-1, -1, -1, -1}          
  Shape.color_nor = {-1, -1, -1, -1}      
  Shape.color_alt = {-1, -1, -1, -1}      
  Shape.textcolor = {-1, -1, -1, -1}      
  Shape.textcolor_alt = {-1, -1, -1, -1}  
  Shape.textcolor_nor = {-1, -1, -1, -1}  
  Shape.xywh_mode_0 = {-1, -1, -1, -1}       
  Shape.xywh_mode_1 = {-1, -1, -1, -1}       
  Shape.text = nil                        
  Shape.fontface = "Arial"                
  Shape.fontsize = 28                    
  Shape.M_click = 0                       
  Shape.M_wheel = 0                       
  Shape.mouseover = nil                  
  Shape.char = nil                       

-- Constructor
function Shape:new(r, g, b, o, button, x, y, w, h, string, str_size, str_r, str_g, str_b, str_o)
  
  obj = {}
  setmetatable(obj, {__index = Shape})
  
  obj.button = button
  obj.xywh = {x, y, w, h}
  obj.xywh_mode_0 = {x, y, w, h}
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

-- Capture mouse action for object method
function Shape:mouseaction()

  local x = Action.m_x
  local y = Action.m_y
  
  if self.xywh[4] > 0 then
      local shape_x = self.xywh[1] - self.xywh[3] / 2
      local shape_y = self.xywh[2] - self.xywh[4] / 2
      if x > shape_x and x < shape_x + self.xywh[3] and y > shape_y and y < shape_y + self.xywh[4] then
          self.mouseover = true
          return true
      else
          self.M_click = 0; self.M_wheel = 0; self.char = nil
          self.mouseover = false
          return false
      end
  elseif self.xywh[4] == 0 then
      local dist = math.sqrt((self.xywh[1] - x)*(self.xywh[1] - x) + (self.xywh[2]-y)*(self.xywh[2]-y))                               
      if dist < self.xywh[3] then
          self.mouseover = true
          return true
      else
          self.M_click = 0; self.M_wheel = 0; self.char = nil
          self.mouseover = false
          return false
      end
  end
end

-- Draw object method
function Shape:drawshape()
    local op = nil
    if self.color[4] == -1 then        
        op = 100
    else
        op = self.color[4]             
    end
    gfx.set(rgbcalc(self.color[1], self.color[2], self.color[3], op))
    gfx.setfont(1, self.fontface, self.fontsize)  
    
    -- Draw shapes
    if self.xywh[4] > 0 then          
        local x = self.xywh[1] - (self.xywh[3] / 2)
        local y = self.xywh[2] - (self.xywh[4] / 2)
        if self.color[4] == -1 then 
        gfx.rect(x, y, self.xywh[3], self.xywh[4], 0)
        else
        gfx.rect(x, y, self.xywh[3], self.xywh[4], 1)
        end
    elseif self.xywh[4] == 0 then    
        if self.color[4] == -1 then
        gfx.circle(self.xywh[1], self.xywh[2], self.xywh[3], 0)
        else 
        gfx.circle(self.xywh[1], self.xywh[2], self.xywh[3], 1)
        end
    end
    
     if self.text ~= nil then
        gfx.set(rgbcalc(self.textcolor[1], self.textcolor[2], self.textcolor[3], self.textcolor[4]))
        local w, h = gfx.measurestr(self.text)
        gfx.x = self.xywh[1] - (w / 2)
        gfx.y = self.xywh[2] - (h / 2)
        gfx.drawstr(self.text)
    end
    
end

-- Method to place object after creation
function Shape:place(x_ref, x, y_ref, y)

    if self.xywh[4] ~= 0 then   
        if x_ref == "left" then
            self.xywh[1] = 0 + self.xywh[3] / 2 + x
        elseif x_ref == "center" then
            self.xywh[1] = window.w / 2 + x
        elseif x_ref == "right" then
            self.xywh[1] = window.w - self.xywh[3] / 2 + x
        end
      
        if y_ref == "top" then
            self.xywh[2] = 0 + self.xywh[4] / 2 + y
        elseif y_ref == "center" then
            self.xywh[2] = window.h / 2 + y
        elseif y_ref == "bottom" then
            self.xywh[2] = window.h - self.xywh[4] / 2 + y
        end
    end
        
    if self.xywh[4] == 0  then    
        if x_ref == "left" then
            self.xywh[1] = 0 + self.xywh[3] + x
        elseif x_ref == "center" then
            self.xywh[1] = window.w / 2 + x
        elseif x_ref == "right" then
            self.xywh[1] = window.w - self.xywh[3] + x
        end
      
        if y_ref == "top" then
            self.xywh[2] = 0 + self.xywh[3] + y
        elseif y_ref == "center" then
            self.xywh[2] = window.h / 2 + y
        elseif y_ref == "bottom" then
            self.xywh[2] = window.h - self.xywh[3] + y
        end        
    end   
end

-- Initialize shapes
-- Menu
settings = Shape:new(0,0,0,100,false,0,0,0,22,"SETTINGS", 14,180,180,180,100)
settings:place("left", 5, "top", 5)
settings.textcolor_alt = {235, 235, 235, 100}
settings.textcolor = settings.textcolor_alt
about = Shape:new(0,0,0,100,false,0,0,0,22,"ABOUT", 14,180,180,180,100)
about:place("left", (15 + settings.xywh[3]), "top", 5)
about.textcolor_alt = {235, 235, 235, 100}
help = Shape:new(0,0,0,100, false, 0,0,0,22,"HELP", 14, 180, 180, 180, 100)
help:place("left", (25 + settings.xywh[3] + about.xywh[3]), "top", 5)
help.textcolor_alt = {235, 235, 235, 100}
quit = Shape:new(0,0,0,100,false,0,0,0,22,"QUIT", 14,180,180,180,100)
quit:place("left", (35 + settings.xywh[3] + about.xywh[3] + help.xywh[3]), "top", 5)
quit.textcolor_alt = {235, 235, 235, 100}
-- Milliseconds field
millisec_2 = Shape:new(0,0,0,100,false,160,18,0,2,"Milliseconds", 16, 255,255,255,100)
int_field = Shape:new(0, 0, 0, 100, false, 180, 180, 47, 0, "500", 47, 255,255,255,100)
circle = Shape:new(255,255,255,100,false,100,100,50,0)
millisec = Shape:new(0,0,0,100,false,180,180,0,2,"Milliseconds", 24, 255,255,255,100)
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

active_led_ring = Shape:new(50,50,50,-1, false, 0,0,6,0)
active_led_ring:place("right", -15, "top", 55)
active_led = Shape:new(0,100,0,100, false, 0,0,5,0)
active_led.color_alt = {0, 255, 0, 100}
active_led.xywh[1] = active_led_ring.xywh[1]
active_led.xywh[2] = active_led_ring.xywh[2]

txt_noteon = Shape:new(0,0,0,100,false,0,0,0,2,"Note On", 16, 200,200,200,100)
txt_noteon:place("right", -40, "top", 13)
txt_inline = Shape:new(0,0,0,100,false,0,0,0,2,"Inline", 16, 80,80,80,100)
txt_inline.textcolor_alt = {200, 200, 0, 100}
txt_inline:place("right", -108, "top", 33)
txt_take = Shape:new(0,0,0,100,false,0,0,0,2,"Midi Editor", 16, 200,200,200,100)
txt_take:place("right", -40, "top", 33)
txt_active = Shape:new(0,0,0,100,false,0,0,0,2,"Active", 16, 200,200,200,100)
txt_active:place("right", -40, "top", 53)
-- Title
VelMon = Shape:new(0,0,0,100,false,0,0,0,2,"Velocity Monitor", 17,200,200,200,100)
VelMon:place("center", 0, "bottom", -30)  
Beta = Shape:new(0,0,0,100,false,0,0,0,2,"V2.1 - BETA", 15,200,200,200,100)
Beta:place("center", 0, "bottom", -12)  
-- ABOUT page elements
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
-- HELP page elements 
help1 = Shape:new(0, 0, 0, 100, false, 0, 0, 0, 2, "Use the mouse wheel or +/- to adjust interval.", 16, 235, 235, 235, 100)
help1:place("left", 20, "top", 50)
help2 = Shape:new(0, 0, 0, 100, false, 0, 0, 0, 2, "Choose QUIT or press Esc to exit.", 16, 235, 235, 235, 100)
help2:place("left", 20, "top", help1.xywh[4] + 70)
help3 = Shape:new(0, 0, 0, 100, false, 0, 0, 0, 2, "When working on a single monitor and Velocity Monitor\n keeps disappearing, you can always bring it forward by\n touching the top of your screen with the mouse.", 16, 235, 235, 235, 100)
help3:place("left", 20, "top", help1.xywh[4] + help2.xywh[4] + 90)
help4 = Shape:new(0, 0, 0, 100, false, 0, 0, 0, 2, "Alternatively, use the option below to dock it.", 16, 235, 235, 235, 100)
help4:place("left", 20, "top", help1.xywh[4] + help2.xywh[4] + help3.xywh[4] + 110)
dock = Shape:new(0,0,0,100, false, 0, 0, 0, 2, "Dock", 16, 235, 235, 235, 100)
x1 = Shape:new(255, 255, 255, -1, false, 0, 0, 16, 16, "", 16, 255, 255, 255, 100)
dock:place("center", 0, "top", help1.xywh[4] + help2.xywh[4] + help3.xywh[4] + 155)
x1:place("center", 0, "top", help1.xywh[4] + help2.xywh[4] + help3.xywh[4] + 175)

-- Define actions for objects
local function circle_action(page)
    if draw_page == page and circle:mouseaction() then
        if Action.m_wheel > 0 or Action.c == 43 then
              interval = lim((interval + 50), 50, 9999)
              int_field.text = string.format("%d", interval)
              f_draw = true
        elseif Action.m_wheel < 0 or Action.c == 45 then
              interval = lim((interval - 50), 50, 9999)
              int_field.text = string.format("%d", interval)
              f_draw = true
        end
    end
end

local function settings_action()
    if settings:mouseaction() then
        if Action.m_click == 1 then
            draw_page = 0
            f_draw = true
        end
    end
end

local function about_action()
    if about:mouseaction() then
        if Action.m_click == 1 then
            draw_page = 1
            f_draw = true
        end
    end
end 

local function help_action()
    if help:mouseaction() then
        if Action.m_click == 1 then
            draw_page = 2
            f_draw = true
        end
    end
end 

-- Highlight active menu page
local function highlight_menu()
    if draw_page == 0 then
        settings.textcolor = settings.textcolor_alt
        about.textcolor = about.textcolor_nor
        help.textcolor = help.textcolor_nor
        quit.textcolor = quit.textcolor_nor
    elseif draw_page == 1 then
        settings.textcolor = settings.textcolor_nor
        about.textcolor = about.textcolor_alt
        help.textcolor = help.textcolor_nor
        quit.textcolor = quit.textcolor_nor
    elseif draw_page == 2 then
        settings.textcolor = settings.textcolor_nor
        help.textcolor = help.textcolor_alt
        about.textcolor = about.textcolor_nor
        quit.textcolor = quit.textcolor_nor
    end
end

-- Replace objects in docked mode / undocked mode
local function replace_shapes(mode)
    if mode == 0 then
        circle:place("center", 0, "center", 0)
        int_field:place("center", 0, "center", 0)
        int_field.fontsize = 47
        int_field.xywh[3] = 47
        circle.xywh[3] = 50
        circle.color = {255,255,255,100}
        millisec:place("center", 0, "top", 100)
        dock:place("center", 0, "top", help1.xywh[4] + help2.xywh[4] + help3.xywh[4] + 155)
        x1:place("center", 0, "top", help1.xywh[4] + help2.xywh[4] + help3.xywh[4] + 175)
    elseif mode == 1 then
        millisec_2:place("canter", 0, "center", 22)
        circle:place("center", -20, "center", 0)
        int_field:place("center", -20, "center", 0)
        int_field.fontsize = 30
        int_field.xywh[3] = 30
        circle.xywh[3] = 33
        circle.color = {0,0,0,100}
        dock:place("left", 30, "top", 19)
        x1:place("left", 36, "top", 39)
    end
end

-- Initialize shapes in undocked mode
replace_shapes(0)

-- Dock / undock tool
local function dock_action(page)
    if draw_page == page then 
        if x1:mouseaction() and Action.m_click == 1 then
            btn_state = 1
        elseif not x1:mouseaction() then
            btn_state = 0
        elseif x1:mouseaction() and btn_state == 1 and Action.m_click == 0 then
                if window.mode == 0 then
                    window.mode = 1
                    window.w = 360
                    window.h = 60
                    draw_page = 3
                    x1.text = "X"
                    replace_shapes(window.mode)
                    f_draw = true
                elseif window.mode == 1 then
                    window.mode = 0
                    window.x = 0
                    window.y = 0
                    window.w = 360
                    window.h = 360
                    draw_page = 0
                    replace_shapes(window.mode)
                    x1.text = ""
                    f_draw = true
                end
        re_init(0)
        btn_state = 0
        end
    end
end

local function quit_action()  
    if quit:mouseaction() then
        if Action.m_click == 1 then   
            settings.textcolor = settings.textcolor_nor
            about.textcolor = about.textcolor_nor
            help.textcolor = help.textcolor_nor
            quit.textcolor = quit.textcolor_alt
            Action.c = 27
            f_draw = 1
        end
    end
end

local function donation_action(page)
    if draw_page == page and Donation:mouseaction() then
        Donation.textcolor = Donation.textcolor_alt
        if Action.m_click == 1 then
            open_url("http://blackpineproductions.com/r3as0n_X/VelocityMonitor_V2.html")
        end
    else
        Donation.textcolor = Donation.textcolor_nor
    end
end 
-----------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------DRAW OBJECTS----------------

local function draw_menu()
  highlight_menu()
  settings:drawshape()
  about:drawshape()
  help:drawshape()
  quit:drawshape()
end

-- Main draw function
local function draw_objects()
    if f_draw then
            if draw_page == 0 then
                  draw_menu()
                  circle:drawshape()
                  int_field:drawshape()
                  millisec:drawshape()
             
                  noteon_led_ring:drawshape()
                  noteon_led:drawshape()
                  take_led_ring:drawshape()
                  take_led:drawshape()
                  active_led_ring:drawshape()
                  active_led:drawshape()
           
                  txt_noteon:drawshape()
                  txt_inline:drawshape()
                  txt_take:drawshape()
                  txt_active:drawshape()
                  
                  VelMon:drawshape()
                  Beta:drawshape()
            elseif draw_page == 1 then
                  draw_menu()
                  abt1:drawshape()
                  abt2:drawshape()
                  abt3:drawshape()
                  abt4:drawshape()
                  abt5:drawshape()
                  Donation:drawshape()
            elseif draw_page == 2 then
                  draw_menu()
                  help1:drawshape()
                  help2:drawshape()
                  help3:drawshape()
                  help4:drawshape()
                  dock:drawshape()
                  x1:drawshape()
            elseif draw_page == 3 then
                  circle:drawshape()
                  int_field:drawshape()
                  millisec_2:drawshape()
 
                  noteon_led_ring:drawshape()
                  noteon_led:drawshape()
                  take_led_ring:drawshape()
                  take_led:drawshape()
                  active_led_ring:drawshape()
                  active_led:drawshape()
           
                  txt_noteon:drawshape()
                  txt_inline:drawshape()
                  txt_take:drawshape()
                  txt_active:drawshape()
                          
                  dock:drawshape()
                  x1:drawshape()                  
        end
    f_draw = false
    end    
end
-----------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------MIDI HANDLING---------------

-- Initialize globals
State = false
Time = reaper.time_precise()
Current_take_id = nil
Current_track_id = nil
Current_track_input = nil
Current_note_id = -1
Current_note_chan = -1
Current_note_pitch = -1

-- Midi object
TAKE = {}
    TAKE.id = nil
    TAKE.note = {["id"] = -1, ["chan"] = 0, ["pitch"] = 0, ["vel"] = 0, ["on"] = false, ["time"] = nil}
    TAKE.inline = false
    TAKE.track = {["id"] = nil, ["input"] = nil}

-- Constructor
function TAKE:new()
    obj = {}
    setmetatable(obj, {__index = TAKE})
    return obj
end

-- Get selected note
local function get_note(take)
    local id, chan, pitch, vel
    if take ~= nil then
        id = reaper.MIDI_EnumSelNotes(take, -1)
        _, _, _, _, _, chan, pitch, vel = reaper.MIDI_GetNote(take, id)
    elseif take == nil then
        id = -1
        chan = 0
        pitch = 0
        vel = 0
    end
    return id, chan, pitch, vel
end

-- Get selected track
local function get_track(obj)
        obj.track.id = reaper.GetMediaItemTake_Track(obj.id)
        obj.track.input = reaper.GetMediaTrackInfo_Value(obj.track.id, "I_RECINPUT")
end

local function restore_previous_track()
        reaper.SetMediaTrackInfo_Value(Current_track_id, "I_RECINPUT", Current_track_input)
        reaper.SetMediaTrackInfo_Value(Current_track_id, "I_RECARM", 0)
end

local function set_track_input(obj)
    reaper.ClearAllRecArmed()
    reaper.SetMediaTrackInfo_Value(obj.track.id, "I_RECINPUT", 6112)
    reaper.SetMediaTrackInfo_Value(obj.track.id, "I_RECARM", 1)
    reaper.SetMediaTrackInfo_Value(obj.track.id, "I_RECMON", 1)
end

-- Check if track has changed and re-set input 
local function check_track(obj)
    if obj.track.id ~= Current_track_id then
        if Current_track_id ~= nil then
            restore_previous_track()
        end
        if obj.track.id ~= nil then
            set_track_input(obj)
        end
    Current_track_id = obj.track.id
    Current_track_input = obj.track.input
    end        
end

-- Get object
function TAKE:get()
    local win, _, _ = reaper.BR_GetMouseCursorContext()
    local _, inline, _, ccLane, _, _ = reaper.BR_GetMouseCursorContext_MIDI()
    if win == "midi_editor" then
        if inline then
            self.editor = "inline"
            self.id = reaper.BR_GetMouseCursorContext_Take()
        elseif not inline then
            self.editor = "editor"
            self.id = reaper.MIDIEditor_GetTake(reaper.MIDIEditor_GetActive())
        end
        get_track(self)
        if ccLane == 0x200 then
            State = true
        else
            State = false
        end
    
    else
        self.id = nil
        self.editor = nil
        self.track.id = nil
        self.track.input = nil
        State = false
    end
    check_track(self)
    self.note.id, self.note.chan, self.note.pitch, self.note.vel = get_note(self.id)
end

-- MIDI functions
function TAKE:noteon()
    reaper.StuffMIDIMessage(0, 0x90 + self.note.chan, self.note.pitch, self.note.vel)
    self.note.on = true
    self.note.time = reaper.time_precise()
end

function TAKE:noteoff()
    reaper.StuffMIDIMessage(0, 0x90 + self.note.chan, self.note.pitch, 0x00)
    self.note.on = false
end

function TAKE:play(time)
    if self.note.id ~= Current_note_id or self.note.chan ~= Current_note_chan or self.note.pitch ~= Current_note_pitch  then
        if Current_note ~= -1 then
            reaper.StuffMIDIMessage(0, 0x90 + Current_note_chan, Current_note_pitch, 0x00) 
            self.note.on = false
            Current_note_id = self.note.id
            Current_note_chan = self.note.chan
            Current_note_pitch = self.note.pitch
        end
    end
    
    if State and self.note.id ~= -1 then
        if not self.note.on then
            self:noteon()
        elseif self.note.on and (time - self.note.time) > (interval/1000) then
            self:noteoff()
            self:noteon()
        end
    else
        self:noteoff()
    end
end

active_take = TAKE:new()

-- Change LED blink speed according to interval
local function blink_speed(time)
    local dt = nil
    if interval > 150 then
        dt = 0.1
    elseif interval <= 150 then
        dt = interval / 3000
    end
    
    if time - active_take.note.time > dt then
        return true
    else
        return false
    end
end

-- LED controls
local function led_section_check()
    if State == true then
        active_led.color = active_led.color_alt
        F_draw = true
    else    
        active_led.color = active_led.color_nor
        F_draw = true
    end
    
    if active_take.editor ~= nil then
        take_led.color = take_led.color_alt
    else
        take_led.color = take_led.color_nor
    end
    
    if active_take.editor == "inline" then
        txt_inline.textcolor = txt_inline.textcolor_alt
    else
        txt_inline.textcolor = txt_inline.textcolor_nor
    end
    
    if active_take.note.on then
        noteon_led.color = noteon_led.color_alt
        local time = reaper.time_precise()
        if blink_speed(reaper.time_precise()) then
            noteon_led.color = noteon_led.color_nor
        end
    else
        noteon_led.color = noteon_led.color_nor
    end
end

-----------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------MAIN FUNCTION---------------
local function Main()
    get_input()           -- Capture mouse
    refocus_tool()        -- Refocus tool if mouse touches the top of the screen
    update_coor()         -- Update and remember coordinates if tool is moved

-- Capture button actions
    circle_action(0)
    circle_action(3)
    settings_action()
    about_action()
    help_action()
    dock_action(2)
    dock_action(3)
    quit_action()
    donation_action(1)

    active_take:get()                               -- Get main object
    active_take:play(reaper.time_precise())         -- Play note
    led_section_check()                             -- Set LEDs accordingly

    if Action.c ~= 27 and Action.c ~= -1 then  
        draw_objects()                              -- Draw condition is inside the function
        reaper.defer(Main)
    else
        if active_take.note.id ~= -1 then           -- Send missed note off message before exit
            active_take:noteoff()
        end
        if active_take.track.id ~= nil then         -- Re-set last track's input
            reaper.SetMediaTrackInfo_Value(active_take.track.id, "I_RECINPUT", active_take.track.input)
        end
        gfx.quit()
    end  
    gfx.update()
end

-- Initialize main window, objects and call Main loop
gfx.init("Velocity Monitor V2.0 BETA", window.w, window.h, window.mode, window.x, window.y)
draw_objects()
Main()
