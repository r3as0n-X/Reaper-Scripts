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

window_w = 360
window_h = 360
window_mode = 0
window_x = 0
window_y = 0

draw_flag = 1
draw_page = 0  
btn_state = 0

local function re_init(mode)
    if mode == 0 then
          gfx.quit()
          gfx.init("Velocity Monitor V2.0 BETA", window_w, window_h, window_mode, window_x, window_y)
    elseif mode == 1 then
        if window_mode ~= 1 then
          gfx.quit()
          gfx.init("Velocity Monitor V2.0 BETA", window_w, window_h, window_mode, window_x, window_y)
        end
    end        
end

local function update_coor()
    local x, y = gfx.clienttoscreen((0 - 4), (0 - 23))
    window_x = x
    window_y = y
end

local function rgbcalc(r, g, b, o)

    r = lim(r, 0, 255) / 255 
    g = lim(g, 0, 255) / 255 
    b = lim(b, 0, 255) / 255
    o = lim(o, 0, 100) / 100

    return r, g, b, o
end  

Action = {}
  Action.m_x = nil
  Action.m_y = nil
  Action.m_click = 0
  Action.m_wheel = 0
  Action.c = 0

Frame = {}
  Frame.x = -1
  Frame.y = -1
  
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

function Shape:drawshape()

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

function Shape:place(x_ref, x, y_ref, y)

    if self.xywh[4] ~= 0 then   
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
        
    if self.xywh[4] == 0  then    
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

local function open_url(url)
  local OS = reaper.GetOS()
  if OS == "OSX32" or OS == "OSX64" then
    os.execute('open "" "' .. url .. '"')
  else
    os.execute('start "" "' .. url .. '"')
  end
end

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

int_field = Shape:new(0, 0, 0, 100, false, 180, 180, 47, 0, "500", 47, 255,255,255,100)
circle = Shape:new(255,255,255,100,false,100,100,50,0)
millisec = Shape:new(0,0,0,100,false,180,180,0,2,"Milliseconds", 24, 255,255,255,100)

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

txt_noteon = Shape:new(0,0,0,100,false,0,0,0,2,"Note On", 16, 200,200,200,100)
txt_noteon:place("right", -40, "top", 13)
txt_take = Shape:new(0,0,0,100,false,0,0,0,2,"Midi Editor", 16, 200,200,200,100)
txt_take:place("right", -40, "top", 33)
txt_note = Shape:new(0,0,0,100,false,0,0,0,2,"Active Note", 16, 200,200,200,100)
txt_note:place("right", -40, "top", 53)

VelMon = Shape:new(0,0,0,100,false,0,0,0,2,"Velocity Monitor", 17,200,200,200,100)
VelMon:place("center", 0, "bottom", -30)  
Beta = Shape:new(0,0,0,100,false,0,0,0,2,"V2.1 - BETA", 15,200,200,200,100)
Beta:place("center", 0, "bottom", -12)  
--RedCircle = Shape:new(255,0,0,0,false,0,0,180,0)
--RedCircle:place("center", 0, "bottom", 293)  


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

local function circle_action(page)
    if draw_page == page and circle:mouseaction() then
        if Action.m_wheel > 0 or Action.c == 43 then
              interval = lim((interval + 50), 50, 9999)
              int_field.text = string.format("%d", interval)
              draw_flag = 1
        elseif Action.m_wheel < 0 or Action.c == 45 then
              interval = lim((interval - 50), 50, 9999)
              int_field.text = string.format("%d", interval)
              draw_flag = 1
        end
    end
end

local function settings_action()
    if settings:mouseaction() then
        if Action.m_click == 1 then
            draw_page = 0
            draw_flag = 1
        end
    end
end

local function about_action()
    if about:mouseaction() then
        if Action.m_click == 1 then
            draw_page = 1
            draw_flag = 1
        end
    end
end 

local function help_action()
    if help:mouseaction() then
        if Action.m_click == 1 then
            draw_page = 2
            draw_flag = 1
        end
    end
end 

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
        circle:place("center", -20, "center", 13)
        int_field:place("center", -20, "center", 13)
        int_field.fontsize = 30
        int_field.xywh[3] = 30
        circle.xywh[3] = 33
        circle.color = {0,0,0,100}
        dock:place("left", 30, "top", 19)
        x1:place("left", 36, "top", 39)
    end
end

replace_shapes(0)

local function dock_action(page)
    if draw_page == page then 
        if x1:mouseaction() and Action.m_click == 1 then
            btn_state = 1
        elseif not x1:mouseaction() then
            btn_state = 0
        elseif x1:mouseaction() and btn_state == 1 and Action.m_click == 0 then
                if window_mode == 0 then
                    window_mode = 1
                    window_w = 360
                    window_h = 60
                    draw_page = 3
                    x1.text = "X"
                    replace_shapes(window_mode)
                    draw_flag = 1
                elseif window_mode == 1 then
                    window_mode = 0
                    window_x = 0
                    window_y = 0
                    window_w = 360
                    window_h = 360
                    draw_page = 0
                    replace_shapes(window_mode)
                    x1.text = ""
                    draw_flag = 1
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
            draw_flag = 1
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

local function noteon_blink_on()
    led_time = reaper.time_precise()
    noteon_led.color = noteon_led.color_alt
    noteon_led:drawshape()
    draw_flag = 1
end   

local function noteon_blink_off(dt)
      local time = reaper.time_precise()
      if tonumber(int_field.text) <= 150 then
          dt = tonumber(int_field.text) / 5000
      end
      if dt < time - led_time then
      noteon_led.color = noteon_led.color_nor
      draw_flag = 1
      end
end

local function draw_menu()
  highlight_menu()
  settings:drawshape()
  about:drawshape()
  help:drawshape()
  quit:drawshape()
end

local function draw_objects()
    if draw_flag == 1 then
            if draw_page == 0 then
                  draw_menu()
                  circle:drawshape()
                  int_field:drawshape()
                  millisec:drawshape()
             
                  noteon_led_ring:drawshape()
                  noteon_led:drawshape()
                  take_led_ring:drawshape()
                  take_led:drawshape()
                  note_led_ring:drawshape()
                  note_led:drawshape()
           
                  txt_noteon:drawshape()
                  txt_take:drawshape()
                  txt_note:drawshape()
                  
                  VelMon:drawshape()
                  Beta:drawshape()
--                  RedCircle:drawshape()
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
 
                  noteon_led_ring:drawshape()
                  noteon_led:drawshape()
                  take_led_ring:drawshape()
                  take_led:drawshape()
                  note_led_ring:drawshape()
                  note_led:drawshape()
           
                  txt_noteon:drawshape()
                  txt_take:drawshape()
                  txt_note:drawshape()
                          
                  dock:drawshape()
                  x1:drawshape()                  
        end
    draw_flag = 0
    end    
end

cur_time = reaper.time_precise()
led_time = 0
cur_take = nil
cur_note = -1
cur_track = nil
cur_track_input = -1
interval = 500

local function noteon(take, note)
  local retval, sel, muted, start, ending, chan, pitch, vel = reaper.MIDI_GetNote(take, note)
  reaper.StuffMIDIMessage(0, 0x90 + chan, pitch, vel)
end

local function noteoff(take, note)
  local retval, sel, muted, start, ending, chan, pitch, vel = reaper.MIDI_GetNote(take, note)
  reaper.StuffMIDIMessage(0, 0x90 + chan, pitch, 0x00)
end

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

local function checktake(take)  
  if take ~= cur_take then
    if cur_note ~= -1 and cur_take ~= nil then
      noteoff(cur_take, cur_note) 
    end
    checktrack(take)
    cur_take = take
  end
end

local function checknote(note)
  if note ~= cur_note then
    noteoff(cur_take, cur_note)
    cur_note = note
  end
end

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

local function checklane()
  local win, seg, det = reaper.BR_GetMouseCursorContext()
  local retval, inline, ntrow, cclane, cclaneval, cclaneid = reaper.BR_GetMouseCursorContext_MIDI()
    if cclane == 0x200 then
      return true
    else  
      return false
    end
end

local function Main()
    reaper.ClearConsole()
    get_input() 
    if Frame.y == 0 then 
      re_init(1) 
    end

    update_coor()

    circle_action(0)
    circle_action(3)
    settings_action()
    about_action()
    help_action()
    dock_action(2)
    dock_action(3)
    quit_action()
    donation_action(1)
      
    local take = reaper.MIDIEditor_GetTake(reaper.MIDIEditor_GetActive())
     if take ~= nil then 
          
          take_led.color = take_led.color_alt
          draw_flag = 1
     
           checktake(take)  
           local note = reaper.MIDI_EnumSelNotes(cur_take, -1)
           if note > -1 then  
           
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
           elseif note == -1 then 
           
                note_led.color = note_led.color_nor
                draw_flag = 1
                
                 noteoff(cur_take, cur_note)
                 cur_note = note
           end
     elseif take == nil then   
     
          take_led.color = take_led.color_nor
          draw_flag = 1
          
           if cur_take ~= nil then
             noteoff(cur_take, cur_note)
             cur_take = take
           end
     end
    noteon_blink_off(0.1)

    if Action.c ~= 27 and Action.c ~= -1 then  
    draw_objects()
    reaper.defer(Main)
    else
          if cur_track ~= nil then
          reaper.SetMediaTrackInfo_Value(cur_track, "I_RECINPUT", cur_track_input)
          end
        gfx.quit()
    end  
    gfx.update()
end

gfx.init("Velocity Monitor V2.0 BETA", window_w, window_h, window_mode, window_x, window_y)
draw_objects()
Main()
