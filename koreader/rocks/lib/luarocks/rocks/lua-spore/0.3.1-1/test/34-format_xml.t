#!/usr/bin/env lua

require 'Test.More'

if not pcall(require, 'lxp.lom') then
    skip_all 'no xml'
end

plan(17)

package.loaded['socket.http'] = {
    request = function (req)
        req.sink([[
<config logdir="/var/log/foo/" debugfile="/tmp/foo.debug">
  <server name="sahara" osname="solaris" osversion="2.6">
    <address>10.0.0.101</address>
    <address>10.0.1.101</address>
  </server>
  <server name="gobi" osname="irix" osversion="6.5">
    <address>10.0.0.102</address>
  </server>
  <server name="kalahari" osname="linux" osversion="2.0.34">
    <address>10.0.0.103</address>
    <address>10.0.1.103</address>
  </server>
</config>
]])
        return req, 200, {}
    end -- mock
}

if not require_ok 'Spore.Middleware.Format.XML' then
    skip_rest "no Spore.Middleware.Format.XML"
    os.exit()
end

local Spore = require 'Spore'
local client = Spore.new_from_spec('./test/api.json', {})
client:enable('Format.XML', {
    key_attr = {
        server = 'name',
    },
})

local r = client:get_info()
is( #r.body.config, 0, "with options" )
is( r.body.config.logdir, "/var/log/foo/" )
is( r.body.config.debugfile, "/tmp/foo.debug" )
is( r.body.config.server.sahara.osname, "solaris" )
is( #r.body.config.server.sahara.address, 2 )
is( r.body.config.server.sahara.address[1], "10.0.0.101" )
is( r.body.config.server.gobi.address[1], "10.0.0.102" )

client:reset_middlewares()
client:enable 'Format.XML'
r = client:get_info()
is( #r.body.config, 0, "without option" )
is( r.body.config.logdir, "/var/log/foo/" )
is( r.body.config.debugfile, "/tmp/foo.debug" )
is( #r.body.config.server, 3 )
is( r.body.config.server[1].name, "sahara" )
is( r.body.config.server[1].osname, "solaris" )
is( #r.body.config.server[1].address, 2 )
is( r.body.config.server[1].address[1], "10.0.0.101" )
is( r.body.config.server[2].address[1], "10.0.0.102" )

