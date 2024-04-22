better_nametags = {}
better_nametags.allowSneak=true
better_nametags.tags = {}
better_nametags.players = {}

minetest.settings:set_bool("unlimited_player_transfer_distance", false)
minetest.settings:set("player_transfer_distance", (
	minetest.settings:get("active_object_send_range_blocks") or 3
))

local defaultNameFunction = function(_) return _:get_player_name() end
local defaultCheckFunction= function(_) return false end

better_nametags.register_tag = function(tagName, color, checkFunction, nameFunction, rankWeight) 
	if nameFunction == nil then
		nameFunction = defaultNameFunction
	end
	if checkFunction == nil then
		checkFunction = defaultCheckFunction
	end
	better_nametags.tags[tagName] = {
		title = tagName,
		Color = color,
		has = checkFunction,
		getName = nameFunction,
		weight = rankWeight,
	}
end

minetest.register_on_leaveplayer(function(player)
	better_nametags.players[player:get_player_name()] = nil
end)

if not minetestd then
	dofile(minetest.get_modpath("better_nametags").."/service.lua")
	dofile(minetest.get_modpath("better_nametags").."/tag_types.lua")
	local dt = 0
	minetest.register_globalstep(function(dtime) 
		if dt < 0.5 then
			dt = dt + dtime
			return
		end
		dt = 0
		
		for _,player in pairs(minetest.get_connected_players()) do
			better_nametags.update_nametag(player)
		end
	end)
else
	minetestd.register_service("better_nametags", {
		start = function() 
			dofile(minetest.get_modpath("better_nametags").."/service.lua")
			dofile(minetest.get_modpath("better_nametags").."/tag_types.lua")
			minetestd.services.better_nametags.enabled = true
			return true
		end,
		stop = function() 
			better_nametags.players = {}
			minetestd.playerctl.steps.better_nametags = nil
			minetestd.services.better_nametags.enabled = false
		end,
		depends = {playerctl=true},
		
	})
	
end