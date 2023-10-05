#!/usr/bin/env lua

require 'Test.More'

if not pcall(require, 'crypto') then
    skip_all 'no crypto'
end

plan(23)

local response = { status = 200, headers = {} }
require 'Spore.Protocols'.request = function (req)
    is( req.url, "http://services.org:9999/dir/index.html", 'req.url' )
    return response
end -- mock

if not require_ok 'Spore.Middleware.Auth.Digest' then
    skip_rest "no Spore.Middleware.Auth.Digest"
    os.exit()
end
local mw = require 'Spore.Middleware.Auth.Digest'

local req = require 'Spore.Request'.new({ spore = { params = {} } })
type_ok( req, 'table', "Spore.Request.new" )
type_ok( req.headers, 'table' )

local r = mw.call({}, req)
is( r, nil )

local data = {
    username = 'Mufasa',
    password = 'Circle Of Life',
}
r = mw.call(data, req)
is( r, nil )

req.env.spore.authentication = true
local cb = mw.call(data, req)
type_ok( cb, 'function' )
is( req.headers['authorization'], nil )

local old_generate_nonce = mw.generate_nonce
mw.generate_nonce = function () return '0a4f113b' end  -- mock

req.method = 'GET'
req.url = 'http://services.org:9999/dir/index.html'
r = cb{
    status = 401,
    headers = {
        ['www-authenticate'] = [[Digest
                 realm="testrealm@host.com",
                 qop="auth,auth-int",
                 nonce="dcd98b7102dd2f0e8b11d0f600bfb0c093",
                 opaque="5ccc069c403ebaf9f0171e9517f40e41"
]]
    },
}

is( data.algorithm, 'MD5' )
is( data.nc, 1 )
is( data.realm, 'testrealm@host.com' )
is( data.qop, 'auth' )
is( data.nonce, 'dcd98b7102dd2f0e8b11d0f600bfb0c093' )
is( data.opaque, '5ccc069c403ebaf9f0171e9517f40e41' )
is( r, response )
is( req.headers['authorization'], [[Digest username="Mufasa", realm="testrealm@host.com", nonce="dcd98b7102dd2f0e8b11d0f600bfb0c093", uri="/dir/index.html", algorithm="MD5", nc=00000001, cnonce="0a4f113b", response="6629fae49393a05397450978507c4ef1", opaque="5ccc069c403ebaf9f0171e9517f40e41", qop=auth]] )

cb = mw.call(data, req)
type_ok( cb, 'function' )
is( req.headers['authorization'], [[Digest username="Mufasa", realm="testrealm@host.com", nonce="dcd98b7102dd2f0e8b11d0f600bfb0c093", uri="/dir/index.html", algorithm="MD5", nc=00000002, cnonce="0a4f113b", response="15b6bb427e3fecd23a43cb702ce447d5", opaque="5ccc069c403ebaf9f0171e9517f40e41", qop=auth]] )
r = cb(response)
is( r, response )


mw.generate_nonce = old_generate_nonce
data = {
    username = 'Mufasa',
    password = 'Circle Of Life',
}
cb = mw.call(data, req)
local _ = cb{
    status = 401,
    headers = {
        ['www-authenticate'] = [[Digest
                 algorithm="MD5",
                 realm="testrealm@host.com",
                 nonce="dcd98b7102dd2f0e8b11d0f600bfb0c093",
                 opaque="5ccc069c403ebaf9f0171e9517f40e41"
]]
    },
}
like( req.headers['authorization'], [[opaque="5ccc069c403ebaf9f0171e9517f40e41"$]], 'no qop' )


error_like( function ()
    local data = {
        username = 'Mufasa',
        password = 'Circle Of Life',
    }
    local cb = mw.call(data, req)
    local _ = cb{
        status = 401,
        headers = {
            ['www-authenticate'] = [[Digest qop="auth-int", nonce="dcd98b7102dd2f0e8b11d0f600bfb0c093"]]
        },
   }
end, "auth%-int is not supported" )

error_like( function ()
    local data = {
        username = 'Mufasa',
        password = 'Circle Of Life',
    }
    local cb = mw.call(data, req)
    local _ = cb{
        status = 401,
        headers = {
            ['www-authenticate'] = [[Digest algorithm="MD5-sess", qop="auth", nonce="dcd98b7102dd2f0e8b11d0f600bfb0c093"]]
        },
   }
end, "MD5%-sess is not supported" )
