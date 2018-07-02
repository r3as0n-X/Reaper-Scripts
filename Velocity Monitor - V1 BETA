-- Initialize global variables
cur_time = reaper.time_precise()
cur_take = nil
cur_note = -1
cur_track = nil
cur_track_input = -1
interval = 0.500

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
  if dt > interval then
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

-- UI
local function mousearea(x, y, w, h)
  local msx = gfx.mouse_x
  local msy = gfx.mouse_y

  if msx > x and msx < (x + w) and msy > y and msy < (y + h) then
    return true
  else 
    return false
  end
end

function settext()
-- Title
gfx.setfont(1, "Arial", 18)
title = "Interval in milliseconds"
title_w, title_h = gfx.measurestr(title)
title_x = (360 - title_w) / 2 
title_y = 10
gfx.x = title_x
gfx.y = title_y
gfx.drawstr(title)

-- SetInterval
gfx.setfont(1, "Arial", 21)
setint = tostring(interval * 1000)
setint_w, setint_h = gfx.measurestr(setint)
setint_x = (360 - setint_w) / 2
setint_y = 40 
gfx.x = setint_x
gfx.y = setint_y
gfx.drawstr(setint)

-- About script
gfx.setfont(1, "Arial", 15)
about = "This script provides audio monitoring in specified intervals\n while working on velocities in the velicity lane of the MIDI \neditor / inline MIDI editor."
about_w, about_h = gfx.measurestr(about)
about_x = (360 - about_w) / 2
about_y = 90 
gfx.x = about_x
gfx.y = about_y
gfx.drawstr(about)

-- Use mousewheel
gfx.setfont(1, "Arial", 15)
hint = "Use mouse wheel or +/- to adjust  |  Press Esc to exit"
hint_w, hint_h = gfx.measurestr(hint)
hint_x = (360 - hint_w) / 2
hint_y = 155 
gfx.x = hint_x
gfx.y = hint_y
gfx.drawstr(hint)
end

-- Adjust interval
function mousewheel()
  local f = gfx.mouse_wheel
  local char = gfx.getchar()  
  if f > 0 or char == 43 then
    interval = interval + 0.050
    gfx.mouse_wheel = 0
    settext()
  elseif f < 0 or char == 45 then
    gfx.mouse_wheel = 0
    if interval >= 0.100 then
      interval = interval - 0.050
      settext()
    end
  end
end


-- Main loop
local function main()
  reaper.ClearConsole()

  
  -- Check for active takes and prepare track
 local take = reaper.MIDIEditor_GetTake(reaper.MIDIEditor_GetActive())
  if take ~= nil then  -- Check if take is valid
        checktake(take)  
        local note = reaper.MIDI_EnumSelNotes(cur_take, -1)
        if note > -1 then  -- note selected
              checknote(note)
              if checktime() and checklane() then
                noteoff(cur_take, cur_note)
                noteon(cur_take, cur_note)
              elseif not checklane() then
                noteoff(cur_take, cur_note)
              end
        elseif note == -1 then -- no note selected
              noteoff(cur_take, cur_note)
              cur_note = note
        end
  elseif take == nil then   -- no valid take
        if cur_take ~= nil then
          noteoff(cur_take, cur_note)
          cur_take = take
        end
  end

  -- Adjust interval
  if mousearea(setint_x, setint_y, setint_w, setint_h) then
    mousewheel()
  end 
--[[
    --Check conditions and play note
    local note = reaper.MIDI_EnumSelNotes(cur_take, -1)
    if conditions(note) == 1 then
      noteoff(cur_take, cur_note)
      cur_note = note
      noteon(cur_take, cur_note)
    elseif conditions(note) == 2 then
      noteoff(cur_take, cur_note)
      cur_note = note
    end 
  end
  ]]
  -- Exit condition
  local char = gfx.getchar()
  if char ~= 27 and char ~= -1 then
    reaper.defer(main)
  else
    gfx.quit()
  end
  
  gfx.update()
end

gfx.init("Velocity Monitor - V1.0 BETA", 360, 180, 0, 0, 0)
settext()
main()  


--[[  
  if take ~= nil then
    local note = reaper.MIDI_EnumSelNotes(take, -1)
    local win, seg, det = reaper.BR_GetMouseCursorContext()
    local retval, inline, ntrow, cclane, cclaneval, cclaneid = reaper.BR_GetMouseCursorContext_MIDI()
    local position = reaper.BR_GetMouseCursorContext_Position()
    reaper.ShowConsoleMsg(note .. "\n")
    retval, sel, muted, start, ending, chan, pitch, vel = reaper.MIDI_GetNote(take, note)
    reaper.ShowConsoleMsg(chan .. " | " .. pitch .." | ".. vel)
    local time2 = reaper.time_precise()
    local dt = time2 - time1
    reaper.ShowConsoleMsg("\n"..dt.."\n")
    --reaper.ShowConsoleMsg(gfx.mouse_cap .. "\n")
    --reaper.ShowConsoleMsg(gfx.mouse_x)
    --reaper.ShowConsoleMsg("\nwindow: "..win.."\nsegment: "..seg.."\ndetails: "..det)
    reaper.ShowConsoleMsg("\n\nnoterow: "..ntrow.."\ncclane: "..cclane.."\ncclanevalue: "..cclaneval.."\ncclaneid: "..cclaneid)
    reaper.ShowConsoleMsg("\n\nposition: "..position.."\n\n")

      if dt > interval then
      reaper.StuffMIDIMessage(0, 0x90 + chan, pitch, vel)
      time1 = time2
      end
  end
  ]]
