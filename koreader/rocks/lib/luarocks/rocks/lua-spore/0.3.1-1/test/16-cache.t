#!/usr/bin/env lua

require 'Test.More'

plan(8)

local i = 0
package.loaded['socket.http'] = {
    request = function (req)
        i = i + 1
        req.sink(tostring(i))
        return req, 200, {}
    end -- mock
}

local Spore = require 'Spore'

if not require_ok 'Spore.Middleware.Cache' then
    skip_rest "no Spore.Middleware.Cache"
    os.exit()
end

local client = Spore.new_from_spec './test/api.json'

local r = client:get_info()
is( r.body, '1' )
r = client:get_info()
is( r.body, '2', "not cached" )

client:enable 'Cache'
r = client:get_info()
is( r.body, '3' )

r = client:get_info{ user = 'john' }
is( r.body, '4' )

r = client:get_info()
is( r.body, '3', "cached" )

r = client:get_info{ user = 'john' }
is( r.body, '4', "cached" )

require 'Spore.Middleware.Cache'.reset()

r = client:get_info()
is( r.body, '5', "reset" )
