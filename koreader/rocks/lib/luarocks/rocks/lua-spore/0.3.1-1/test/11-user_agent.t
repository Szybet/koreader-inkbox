#!/usr/bin/env lua

require 'Test.More'

plan(8)

if not require_ok 'Spore.Middleware.UserAgent' then
    skip_rest "no Spore.Middleware.UserAgent"
    os.exit()
end
local mw = require 'Spore.Middleware.UserAgent'

local req = require 'Spore.Request'.new({})
type_ok( req, 'table', "Spore.Request.new" )
type_ok( req.headers, 'table' )
is( req.headers['user-agent'], nil )

local r = mw.call( {}, req )
is( req.headers['user-agent'], nil, "user-agent is not set" )
is( r, nil )

r = mw.call( { useragent = "MyAgent" }, req )
is( req.headers['user-agent'], "MyAgent", "user-agent is set" )
is( r, nil )
