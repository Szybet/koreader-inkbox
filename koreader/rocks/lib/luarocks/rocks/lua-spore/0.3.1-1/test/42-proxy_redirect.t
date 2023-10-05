#!/usr/bin/env lua

require 'Test.More'

plan(14)

package.loaded['socket.http'] = {
    request = function (req)
        if req.url:match "^http://proxy.myorg:8080/restapi/show" then
            like(req.url, "^http://proxy.myorg:8080/restapi/show", "proxy initial")
            local host = req.headers['host']
            is( host, 'services.org', "host initial" )
            local auth = req.headers['proxy-authorization']
            type_ok( auth, 'string', "proxy-authorization is set" )
            is( auth:sub(1, 6), "Basic ", "starts by 'Basic '" )
            local unenc = require 'mime'.unb64(auth:sub(7))
            is( unenc, "john:s3kr3t", "john:s3kr3t" )
            return req, 301, { location = 'http://services.net/v2/rest/show' }
        else
            like(req.url, "^http://proxy.myorg:8080/v2/rest/show", "proxy redirect")
            local host = req.headers['host']
            is( host, 'services.net', "host redirect" )
            local auth = req.headers['proxy-authorization']
            type_ok( auth, 'string', "proxy-authorization is set" )
            is( auth:sub(1, 6), "Basic ", "starts by 'Basic '" )
            local unenc = require 'mime'.unb64(auth:sub(7))
            is( unenc, "john:s3kr3t", "john:s3kr3t" )
            req.sink('dummy') -- body
            return req, 200, {}
        end
    end -- mock
}

local Spore = require 'Spore'

if not require_ok 'Spore.Middleware.Redirection' then
    skip_rest "no Spore.Middleware.Redirection"
    os.exit()
end

if not require_ok 'Spore.Middleware.Proxy.Basic' then
    skip_rest "no Spore.Middleware.Proxy.Basic"
    os.exit()
end

local client = Spore.new_from_spec './test/api.json'
client:enable 'Redirection'
client:enable('Proxy.Basic', {
    proxy    = 'http://proxy.myorg:8080',
    username = 'john',
    password = 's3kr3t',
})

local r = client:get_info()
is( r.status, 200 )
is( r.body, 'dummy' )

