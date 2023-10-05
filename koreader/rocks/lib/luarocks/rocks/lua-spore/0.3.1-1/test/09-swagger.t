#!/usr/bin/env lua

require 'Test.More'

plan(14)

local doc = [[
{
  "swagger": "2.0",
  "info": {
    "title": "api",
    "version": "v1",
    "description": "api for unit test"
  },
  "tags": [
    {"name": "tagged", "description": "filtered"}
  ],
  "schemes": ["http"],
  "host": "services.org:9999",
  "basePath": "/restapi",
  "paths": {
    "/show": {
      "get": {
        "operationId": "get_info",
        "summary": "blah",
        "description": "blah, blah",
        "tags": ["tagged"],
        "parameters": [
          {
            "name": "user",
            "in": "query",
            "required": true
          },
          {
            "name": "border",
            "in": "query",
            "required": false
          }
        ],
        "responses": {
          "200": {
            "description": "Ok."
          }
        }
      }
    }
  }
}
]]
require 'Spore.Protocols'.slurp = function ()
    return doc
end -- mock

require 'Spore'.new_from_lua = function (t)
    return t
end --mock

local m = require 'Spore.Swagger'
type_ok( m, 'table', "Spore.Swagger" )
is( m, package.loaded['Spore.Swagger'] )

type_ok( m.new_from_swagger, 'function' )
type_ok( m.convert, 'function' )

local spec = m.new_from_swagger('mock', {}, 'tagged')
is( spec.name, 'api' )
is( spec.version, 'v1' )
is( spec.description, 'filtered' )
is( spec.base_url, 'http://services.org:9999/restapi' )
local meth = spec.methods.get_info
type_ok( meth, 'table' )
is( meth.path, '/show' )
is( meth.method, 'GET' )

spec = m.new_from_swagger('mock', {}, 'bad tag')
type_ok( spec.methods.get_info, 'nil', "empty spec.methods" )

spec = m.new_from_swagger('mock')
type_ok( spec.methods.get_info, 'table' )
is( spec.description, 'api for unit test' )
