#!/usr/bin/env lua

require 'Test.More'

plan(6)

if not require_ok 'Spore.Middleware.Parameter.Force' then
    skip_rest "no Spore.Middleware.Parameter.Force"
    os.exit()
end
local mw = require 'Spore.Middleware.Parameter.Force'

is( require 'Spore'.early_validate, false, "early_validate" )

local req = require 'Spore.Request'.new({ spore = { params = { prm1 = 0 } }})
type_ok( req, 'table', "Spore.Request.new" )
is( req.env.spore.params.prm1, 0 )

local _ = mw.call( {
    prm1 = 1,
    prm2 = 2,
}, req )
is( req.env.spore.params.prm1, 1 )
is( req.env.spore.params.prm2, 2 )

