#!/usr/bin/env lua

Spore = require 'Spore'

require 'Test.More'

plan(6)

error_like( [[Spore.new_from_lua(true)]],
            "bad argument #1 to new_from_lua %(table expected, got boolean%)" )

error_like( [[Spore.new_from_lua({}, true)]],
            "bad argument #2 to new_from_lua %(table expected, got boolean%)" )

local client = Spore.new_from_lua{
    base_url = 'http://services.org/restapi/',
    methods = {
        get_info = {
            path = '/show',
            method = 'GET',
        },
    },
}
type_ok( client, 'table' )
type_ok( client.enable, 'function' )
type_ok( client.reset_middlewares, 'function' )
type_ok( client.get_info, 'function' )

