#!/usr/bin/env lua

require 'Test.More'

plan(6)

if not require_ok 'Spore.Middleware.Logging' then
    skip_rest "no Spore.Middleware.Logging"
    os.exit()
end
local mw = require 'Spore.Middleware.Logging'

local req = require 'Spore.Request'.new({ sporex = {} })
type_ok( req, 'table', "Spore.Request.new" )

local r = mw.call( {}, req )
is( req.env.sporex.logger, nil, "sporex.logger is not set" )
is( r, nil )

r = mw.call( { logger = "MyLogger" }, req )
is( req.env.sporex.logger, "MyLogger", "sporex.logger is set" )
is( r, nil )
