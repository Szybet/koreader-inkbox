#!/usr/bin/env lua

require 'Test.More'

plan(6)

if not require_ok 'Spore.Middleware.Runtime' then
    skip_rest "no Spore.Middleware.Runtime"
    os.exit()
end
local mw = require 'Spore.Middleware.Runtime'

local req = require 'Spore.Request'.new({})
type_ok( req, 'table', "Spore.Request.new" )

local cb = mw.call( {}, req )
type_ok( cb, 'function' )

local n = 1000000
if package.loaded['luacov'] then
    n = n / 200
end
for _ = 1, n do --[[no op]] end
local res = { headers = {} }
is( res, cb(res) )
local header = res.headers['x-spore-runtime']
type_ok( header, 'string' )
diag(header)
local val = tonumber(header)
ok( val > 0 )
