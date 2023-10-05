#!/usr/bin/env lua

require 'Test.More'

plan(12)

if not require_ok 'Spore.Middleware.Auth.Basic' then
    skip_rest "no Spore.Middleware.Auth.Basic"
    os.exit()
end
local mw = require 'Spore.Middleware.Auth.Basic'

local req = require 'Spore.Request'.new({ spore = {} })
type_ok( req, 'table', "Spore.Request.new" )
type_ok( req.headers, 'table' )
is( req.headers['authorization'], nil )

local r = mw.call({}, req)
is( req.headers['authorization'], nil, "authorization is not set" )
is( r, nil )

local data = { username = 'john', password = 's3kr3t' }
r = mw.call(data, req)
is( req.headers['authorization'], nil, "authorization is not set" )
is( r, nil )

req.env.spore.authentication = true
r = mw.call(data, req)
local auth = req.headers['authorization']
type_ok( auth, 'string', "authorization is set" )
is( auth:sub(1, 6), "Basic ", "starts by 'Basic '" )
local unenc = require 'mime'.unb64(auth:sub(7))
is( unenc, "john:s3kr3t", "john:s3kr3t" )
is( r, nil )
