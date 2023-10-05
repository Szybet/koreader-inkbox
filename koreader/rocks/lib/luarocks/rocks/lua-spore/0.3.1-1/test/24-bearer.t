#!/usr/bin/env lua

require 'Test.More'

plan(11)

if not require_ok 'Spore.Middleware.Auth.Bearer' then
    skip_rest "no Spore.Middleware.Auth.Bearer"
    os.exit()
end
local mw = require 'Spore.Middleware.Auth.Bearer'

local req = require 'Spore.Request'.new({ spore = {} })
type_ok( req, 'table', "Spore.Request.new" )
type_ok( req.headers, 'table' )
is( req.headers['authorization'], nil )

local r = mw.call({}, req)
is( req.headers['authorization'], nil, "authorization is not set" )
is( r, nil )

local data = { bearer_token = 'ACCESS_TOKEN' }
r = mw.call(data, req)
is( req.headers['authorization'], nil, "authorization is not set" )
is( r, nil )

req.env.spore.authentication = true
r = mw.call(data, req)
local auth = req.headers['authorization']
type_ok( auth, 'string', "authorization is set" )
is( auth, "Bearer ACCESS_TOKEN", "Bearer" )
is( r, nil )
