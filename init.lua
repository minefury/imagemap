-- Created by Maxim Kartashev, Maja Kartasheva, 2017
--
-- This is free and unencumbered software released into the public domain.

imagemap = {}

imagemap.modpath = minetest.get_modpath(minetest.get_current_modname())
local ie = minetest.request_insecure_environment()

package.path = package.path..";"..imagemap.modpath.."/png/?.lua"
require 'png'

dofile(imagemap.modpath.."/mapgen.lua")

-- Set mapgen parameters
minetest.register_on_mapgen_init(function(mgparams)
    minetest.set_mapgen_setting("mgname", "singlenode")
    minetest.set_mapgen_params({mgname="singlenode"})
end)

-- On generated function
minetest.register_on_generated(function(minp, maxp, seed)
    -- actually generate landscape
    imagemap.generate_landscape(minp, maxp)
end)

local load_map_cmd = {
    params = "<image>",
    description = "loads image and creates a map from it",
    privs = {privs=false},
    func = imagemap.create_map
}

minetest.register_chatcommand("map", load_map_cmd)

minetest.register_on_joinplayer(function(player)
    --give player privs and teleport to surface
    local pname = player:get_player_name()
    minetest.chat_send_player(pname, "Hello")
    local privs = minetest.get_player_privs(pname)
    privs.fly = true
    privs.fast = true
    privs.noclip = true
    privs.time = true
    privs.teleport = true
    privs.worldedit = true
    minetest.set_player_privs(pname, privs)
    local ppos = player:getpos()
    player:setpos({x=0, y=10, z=0})
    minetest.chat_send_player(pname, "You have been moved to the surface")
    return true
end)

