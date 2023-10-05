#!/usr/bin/env lua

require 'Test.More'

plan(20)

package.loaded['socket.http'] = {
    request = function (req)
        like(req.url, "^http://proxy.myorg:8080/restapi/show", "proxy")
        local host = req.headers['host']
        is( host, 'services.org', "host" )
        local auth = req.headers['proxy-authorization']
        type_ok( auth, 'string', "proxy-authorization is set" )
        is( auth:sub(1, 6), "Basic ", "starts by 'Basic '" )
        local unenc = require 'mime'.unb64(auth:sub(7))
        is( unenc, "john:s3kr3t", "john:s3kr3t" )
        req.sink('dummy') -- body
        return req, 200, {}
    end -- mock
}

local Spore = require 'Spore'

if not require_ok 'Spore.Middleware.Proxy.Basic' then
    skip_rest "no Spore.Middleware.Proxy.Basic"
    os.exit()
end

local client = Spore.new_from_spec './test/api.json'
client:enable('Proxy.Basic', {
    proxy    = 'http://proxy.myorg:8080',
    username = 'john',
    password = 's3kr3t',
})

local r = client:get_info()
is( r.body, 'dummy' )

client:reset_middlewares()
client:enable 'Proxy.Basic'

error_like( function ()
    client:get_info()
end, "no HTTP_PROXY", "no HTTP_PROXY" )

os.getenv = function () return 'http://john:s3kr3t@proxy.myorg:8080' end --mock

r = client:get_info()
is( r.body, 'dummy' )

r = client:get_info()
is( r.body, 'dummy' )
