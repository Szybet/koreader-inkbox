#!/usr/bin/env lua

require 'Test.More'

if not pcall(require, 'crypto') then
    skip_all 'no crypto'
end

plan(27)

local response = { status = 200, headers = {} }
require 'Spore.Protocols'.request = function (req)
    return response
end -- mock

if not require_ok 'Spore.Middleware.Auth.OAuth' then
    skip_rest "no Spore.Middleware.Auth.OAuth"
    os.exit()
end
local mw = require 'Spore.Middleware.Auth.OAuth'

local req = require 'Spore.Request'.new({ spore = { params = {} } })
type_ok( req, 'table', "Spore.Request.new" )
type_ok( req.headers, 'table' )

local r = mw.call({}, req)
is( r, nil )

local data = {
    oauth_consumer_key    = 'xxx',
    oauth_consumer_secret = 'yyy',
    oauth_token           = '123',
    oauth_token_secret    = '456',
}
r = mw.call(data, req)
is( r, nil )

local old_generate_timestamp = mw.generate_timestamp
local old_generate_nonce = mw.generate_nonce

data = {
    realm = 'Photos',
    oauth_consumer_key    = 'dpf43f3p2l4k3l03',
    oauth_consumer_secret = 'kd94hf93k423kf44',
    oauth_callback        = 'http://printer.example.com/ready',
}
req = require 'Spore.Request'.new({
    REQUEST_METHOD = 'POST',
    SERVER_NAME = 'photos.example.net',
    PATH_INFO = '/initiate',
    spore = {
        authentication = true,
        url_scheme = 'https',
        params = {},
        method = {},
    }
})
mw.generate_timestamp = function () return '137131200' end
mw.generate_nonce = function () return 'wIjqoS' end
r = mw.call(data, req)
is( r, response )
is( req.url, 'https://photos.example.net/initiate' )
is( req.env.spore.oauth_signature_base_string, "POST&https%3A%2F%2Fphotos.example.net%2Finitiate&oauth_callback%3Dhttp%253A%252F%252Fprinter.example.com%252Fready%26oauth_consumer_key%3Ddpf43f3p2l4k3l03%26oauth_nonce%3DwIjqoS%26oauth_signature_method%3DHMAC-SHA1%26oauth_timestamp%3D137131200" )
is( req.headers['authorization'], [[OAuth realm="Photos", oauth_consumer_key="dpf43f3p2l4k3l03", oauth_signature_method="HMAC-SHA1", oauth_signature="74KNZJeDHnMBp0EMJ9ZHt%2FXKycU%3D", oauth_timestamp="137131200", oauth_nonce="wIjqoS", oauth_callback="http%3A%2F%2Fprinter.example.com%2Fready"]] )

data = {
    realm = 'Photos',
    oauth_consumer_key    = 'dpf43f3p2l4k3l03',
    oauth_consumer_secret = 'kd94hf93k423kf44',
    oauth_token           = 'hh5s93j4hdidpola',
    oauth_token_secret    = 'hdhd0244k9j7ao03',
    oauth_verifier        = 'hfdp7dh39dks9884',
}
req = require 'Spore.Request'.new({
    REQUEST_METHOD = 'POST',
    SERVER_NAME = 'photos.example.net',
    SERVER_PORT = '443',
    PATH_INFO = '/token',
    spore = {
        authentication = true,
        url_scheme = 'https',
        params = {},
        method = {},
    }
})
mw.generate_timestamp = function () return '137131201' end
mw.generate_nonce = function () return 'walatlh' end
r = mw.call(data, req)
is( r, response )
is( req.url, 'https://photos.example.net:443/token' )
is(req.env.spore.oauth_signature_base_string, "POST&https%3A%2F%2Fphotos.example.net%2Ftoken&oauth_consumer_key%3Ddpf43f3p2l4k3l03%26oauth_nonce%3Dwalatlh%26oauth_signature_method%3DHMAC-SHA1%26oauth_timestamp%3D137131201%26oauth_token%3Dhh5s93j4hdidpola%26oauth_verifier%3Dhfdp7dh39dks9884")
is(req.headers['authorization'], [[OAuth realm="Photos", oauth_consumer_key="dpf43f3p2l4k3l03", oauth_signature_method="HMAC-SHA1", oauth_signature="gKgrFCywp7rO0OXSjdot%2FIHF7IU%3D", oauth_timestamp="137131201", oauth_nonce="walatlh", oauth_token="hh5s93j4hdidpola", oauth_verifier="hfdp7dh39dks9884"]])

data = {
    realm = 'Photos',
    oauth_consumer_key    = 'dpf43f3p2l4k3l03',
    oauth_consumer_secret = 'kd94hf93k423kf44',
    oauth_token           = 'nnch734d00sl2jdk',
    oauth_token_secret    = 'pfkkdhi9sl3r4s00',
}
req = require 'Spore.Request'.new({
    REQUEST_METHOD = 'GET',
    SERVER_NAME = 'photos.example.net',
    PATH_INFO = '/photos',
    QUERY_STRING = 'file=vacation.jpg&size=original',
    spore = {
        authentication = true,
        url_scheme = 'http',
        params = {},
        method = {},
    }
})
mw.generate_timestamp = function () return '137131202' end
mw.generate_nonce = function () return 'chapoH' end
r = mw.call(data, req)
is( r, response )
is( req.url, 'http://photos.example.net/photos?file=vacation.jpg&size=original' )
is( req.env.spore.oauth_signature_base_string, "GET&http%3A%2F%2Fphotos.example.net%2Fphotos&file%3Dvacation.jpg%26oauth_consumer_key%3Ddpf43f3p2l4k3l03%26oauth_nonce%3DchapoH%26oauth_signature_method%3DHMAC-SHA1%26oauth_timestamp%3D137131202%26oauth_token%3Dnnch734d00sl2jdk%26size%3Doriginal")
is( req.headers['authorization'], [[OAuth realm="Photos", oauth_consumer_key="dpf43f3p2l4k3l03", oauth_signature_method="HMAC-SHA1", oauth_signature="MdpQcU8iPSUjWoN%2FUDMsK2sui9I%3D", oauth_timestamp="137131202", oauth_nonce="chapoH", oauth_token="nnch734d00sl2jdk"]] )

data = {
    realm = 'Example',
    oauth_signature_method= 'PLAINTEXT',
    oauth_consumer_key    = 'jd83jd92dhsh93js',
    oauth_consumer_secret = 'ja893SD9',
    oauth_callback        = 'http://client.example.net/cb?x=1',
}
req = require 'Spore.Request'.new({
    REQUEST_METHOD = 'POST',
    SERVER_NAME = 'server.example.com',
    PATH_INFO = '/request_temp_credentials',
    spore = {
        authentication = true,
        url_scheme = 'https',
        params = {},
        method = {},
    }
})
r = mw.call(data, req)
is( r, response )
is( req.url, 'https://server.example.com/request_temp_credentials' )
is( req.headers['authorization'], [[OAuth realm="Example", oauth_consumer_key="jd83jd92dhsh93js", oauth_signature_method="PLAINTEXT", oauth_signature="ja893SD9%26", oauth_callback="http%3A%2F%2Fclient.example.net%2Fcb%3Fx%3D1"]] )

data = {
    realm = 'Example',
    oauth_signature_method= 'PLAINTEXT',
    oauth_consumer_key    = 'jd83jd92dhsh93js',
    oauth_consumer_secret = 'ja893SD9',
    oauth_token           = 'hdk48Djdsa',
    oauth_token_secret    = 'xyz4992k83j47x0b',
    oauth_verifier        = '473f82d3',
}
req = require 'Spore.Request'.new({
    REQUEST_METHOD = 'POST',
    SERVER_NAME = 'server.example.com',
    PATH_INFO = '/request_token',
    spore = {
        authentication = true,
        url_scheme = 'https',
        params = {},
        method = {},
    }
})
r = mw.call(data, req)
is( r, response )
is( req.url, 'https://server.example.com/request_token' )
is( req.headers['authorization'], [[OAuth realm="Example", oauth_consumer_key="jd83jd92dhsh93js", oauth_signature_method="PLAINTEXT", oauth_signature="ja893SD9%26xyz4992k83j47x0b", oauth_token="hdk48Djdsa", oauth_verifier="473f82d3"]])

data = {
    realm = 'Example',
    oauth_consumer_key    = '9djdj82h48djs9d2',
    oauth_consumer_secret = 'j49sk3j29djd',
    oauth_token           = 'kkk9d7dh3k39sjv7',
    oauth_token_secret    = 'dh893hdasih9',
}
req = require 'Spore.Request'.new({
    REQUEST_METHOD = 'POST',
    SERVER_NAME = 'example.com',
    SERVER_PORT = '80',
    PATH_INFO = '/request',
    QUERY_STRING = 'b5=%3D%253D&a3=a&c%40=&a2=r%20b',
    spore = {
        authentication = true,
        url_scheme = 'http',
        payload = 'c2&a4=2+q',
        params = {},
        method = {},
    }
})
req.headers['content-type'] = 'application/x-www-form-urlencoded'
mw.generate_timestamp = function () return '137131201' end
mw.generate_nonce = function () return '7d8f3e4a' end
r = mw.call(data, req)
is( r, response )
is( req.url, 'http://example.com:80/request?b5=%3D%253D&a3=a&c%40=&a2=r%20b' )
is( req.env.spore.oauth_signature_base_string, "POST&http%3A%2F%2Fexample.com%2Frequest&a2%3Dr%2520b%26a3%3Da%26a4%3D2%2520q%26b5%3D%253D%25253D%26c%2540%3D%26c2%3D%26oauth_consumer_key%3D9djdj82h48djs9d2%26oauth_nonce%3D7d8f3e4a%26oauth_signature_method%3DHMAC-SHA1%26oauth_timestamp%3D137131201%26oauth_token%3Dkkk9d7dh3k39sjv7" )

mw.generate_timestamp = old_generate_timestamp
mw.generate_nonce = old_generate_nonce

error_like( function ()
    data.realm = nil
    data.oauth_signature_method = 'UNKNOWN'
    mw.call(data, req)
end, "UNKNOWN is not supported" )

