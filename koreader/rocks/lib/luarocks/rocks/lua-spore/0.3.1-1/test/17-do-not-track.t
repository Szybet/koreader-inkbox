#!/usr/bin/env lua

require 'Test.More'

plan(6)

if not require_ok 'Spore.Middleware.DoNotTrack' then
    skip_rest "no Spore.Middleware.DoNotTrack"
    os.exit()
end
local mw = require 'Spore.Middleware.DoNotTrack'

local req = require 'Spore.Request'.new({})
type_ok( req, 'table', "Spore.Request.new" )
type_ok( req.headers, 'table' )
is( req.headers['x-do-not-track'], nil )

local r = mw.call( {}, req )
is( req.headers['x-do-not-track'], 1, "x-do-not-track is set" )
is( r, nil )

