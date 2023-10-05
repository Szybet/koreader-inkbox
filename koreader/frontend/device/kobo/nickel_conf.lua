--[[--
Access and modify values in `Kobo eReader.conf` used by Nickel.
Only PowerOptions:FrontLightLevel is currently supported.
]]

local dbg = require("dbg")

local NickelConf = {}
NickelConf.frontLightLevel = {}
NickelConf.frontLightState = {}
NickelConf.colorSetting = {}

local kobo_conf_path = '/mnt/onboard/.kobo/Kobo/Kobo eReader.conf'
local front_light_level_str = "FrontLightLevel"
local front_light_state_str = "FrontLightState"
local color_setting_str = "ColorSetting"
-- Nickel will set FrontLightLevel to 0 - 100
local re_FrontLightLevel = "^" .. front_light_level_str .. "%s*=%s*([0-9]+)%s*$"
-- Nickel will set FrontLightState to true (light on) or false (light off)
local re_FrontLightState = "^" .. front_light_state_str .. "%s*=%s*(.+)%s*$"
-- Nickel will set ColorSetting to 1500 - 6400
local re_ColorSetting = "^" .. color_setting_str .. "%s*=%s*([0-9]+)%s*$"
local re_PowerOptionsSection = "^%[PowerOptions%]%s*"
local re_AnySection = "^%[.*%]%s*"


function NickelConf._set_kobo_conf_path(new_path)

end

function NickelConf._read_kobo_conf(re_Match)
    return false
end

--[[--
Get frontlight level.

@treturn int Frontlight level.
--]]
function NickelConf.frontLightLevel.get()
    return 0
end

--[[--
Get frontlight state.

This entry will be missing for devices that do not have a hardware toggle button.
We return nil in this case.

@treturn int Frontlight state (or nil).
--]]
function NickelConf.frontLightState.get()
    return false
end

--[[--
Get color setting.

@treturn int Color setting.
--]]
function NickelConf.colorSetting.get()
    return 3000
end

--[[--
Write Kobo configuration.

@string re_Match Lua pattern.
@string key Kobo conf key.
@param value
@bool dontcreate Don't create if key doesn't exist.
--]]
function NickelConf._write_kobo_conf(re_Match, key, value, dont_create)
    return true
end

--[[--
Set frontlight level.

@int new_intensity
--]]
function NickelConf.frontLightLevel.set(new_intensity)
    return true
end


--[[--
Set frontlight state.

@bool new_state
--]]
function NickelConf.frontLightState.set(new_state)
    return true
end

--[[--
Set color setting.

@int new_color >= 1500 and <= 6400
--]]
function NickelConf.colorSetting.set(new_color)

end

return NickelConf
