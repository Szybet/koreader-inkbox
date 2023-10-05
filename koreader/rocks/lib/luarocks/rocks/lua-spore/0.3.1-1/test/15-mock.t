#!/usr/bin/env lua

local Spore = require 'Spore'
local url = require 'socket.url'

require 'Test.More'

plan(5)

if not require_ok 'Spore.Middleware.Mock' then
    skip_rest "no Spore.Middleware.Mock"
    os.exit()
end

local server = {
    function (req)
        return req.env.spore.params.user == 'John.Doe'
    end,
    function (req)
        return {
            status = 404,
            headers = {},
            body = 'Who are you?',
        }
    end,

    '/show',
    function (req)
        local uri = url.parse(req.url)
        return {
            status = 200,
            headers = {},
            body = uri.query,
        }
    end,
}
local client = Spore.new_from_spec './test/api.json'
client:enable('Mock', server)

local r = client:get_info{ user = 'unknown' }
is( r.status, 200 )
is( r.body, 'user=unknown' )

r = client:get_info{ user = 'John.Doe' }
is( r.status, 404 )
is( r.body, 'Who are you?' )

