#!/usr/bin/env lua

require 'Test.More'

plan(6)

local headers = {}
package.loaded['socket.http'] = {
    request = function (req) return req, 200, headers end -- mock
}

local Spore = require 'Spore'

local client = Spore.new_from_spec './test/api.json'

local res = client:get_user_info{ payload = 'opaque data', user = 'john' }
is( res.headers, headers, "without middleware" )

client:enable 'Format.JSON'
res = client:get_user_info{ payload = 'opaque data', user = 'john' }
is( res.headers, headers, "with middleware" )

client:enable 'UserAgent'
res = client:get_info()
is( res.headers, headers, "with middleware" )

package.loaded['Spore.Middleware.Dummy'] = {}
local dummy_resp = { status = 200 }
require 'Spore.Middleware.Dummy'.call = function (self, req)
    return dummy_resp
end

client:reset_middlewares()
client:enable 'Dummy'
res = client:get_info()
is( res, dummy_resp )

dummy_resp.status = 599
res = client:get_info()
is( res, dummy_resp )

local async_resp = { status = 201 }
package.loaded['Spore.Middleware.Async'] = {}
require('Spore.Middleware.Async').call = function(args, req)
    local result
    -- mock async task such as http request that runs this in callback
    result = async_resp
    coroutine.status(args.thread)
    return coroutine.create(function() coroutine.yield(result) end)
end

local co = coroutine.create(function()
    res = client:get_info()
    is( res.status, async_resp.status )
end)
client:reset_middlewares()
client:enable('Async', {thread = co})
while coroutine.status(co) ~= 'dead' do
    coroutine.resume(co)
end
