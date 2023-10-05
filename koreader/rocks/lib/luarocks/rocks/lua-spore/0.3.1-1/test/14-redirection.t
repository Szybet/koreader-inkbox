#!/usr/bin/env lua

require 'Test.More'

plan(5)

package.loaded['socket.http'] = {
    request = function (req) return req, 222, {} end -- mock
}

if not require_ok 'Spore.Middleware.Redirection' then
    skip_rest "no Spore.Middleware.Redirection"
    os.exit()
end
local mw = require 'Spore.Middleware.Redirection'

local req = require 'Spore.Request'.new({ spore = {} })
type_ok( req, 'table', "Spore.Request.new" )

local cb = mw.call( {}, req )
type_ok( cb, 'function' )

local res = { status = 200, headers = {} }
local r = cb(res)
is( r, res )

res = { status = 301, headers = { location = "http://next.org" } }
r = cb(res)
is( r.status, 222 )
