local isAndroid, _ = pcall(require, "android")
local lfs = require("libs/libkoreader-lfs")
local util = require("ffi/util")

local function probeDevice()
    util.noSDL()
    return require("device/kobo/device")
end

local dev = probeDevice()
dev:init()
return dev
