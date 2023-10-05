#!/usr/bin/env lua

require 'Test.More'

if not pcall(require, 'lxp.lom') then
    skip_all 'no xml'
end

plan(12)

local doc = [[
<?xml version="1.0"?>
<application>
  <resources base="http://services.org:9999/restapi/">
    <resource path="show">
      <method name="GET" id="get_info">
        <request>
          <param name="user" type="xsd:string" style="query" required="true"/>
          <param name="border" type="xsd:string" style="query" required="false"/>
        </request>
        <response status="200" />
      </method>
    </resource>
  </resources>
</application>
]]
require 'Spore.Protocols'.slurp = function ()
    return doc
end -- mock

require 'Spore'.new_from_lua = function (t)
    return t
end --mock

local m = require 'Spore.WADL'
type_ok( m, 'table', "Spore.WADL" )
is( m, package.loaded['Spore.WADL'] )

type_ok( m.new_from_wadl, 'function' )
type_ok( m.convert, 'function' )

local spec = m.new_from_wadl('mock')
local meth = spec.methods.get_info
type_ok( meth, 'table' )
is( meth.base_url, 'http://services.org:9999/restapi/' )
is( meth.path, 'show' )
is( meth.method, 'GET' )
is( #meth.required_params, 1 )
is( meth.required_params[1], 'user' )
is( #meth.optional_params, 1 )
is( meth.optional_params[1], 'border' )
