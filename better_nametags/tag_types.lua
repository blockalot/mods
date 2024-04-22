--[[
better_nametags.register_tag(
	"default", 
	"#DDDDDD", 
	function(_) return true end, 
	function(player) return (player:get_player_name().." ("..(player:get_hp()/2).." ♥)") end,
	0
)

better_nametags.register_tag(
	"lowhealth", 
	"#DD0000", 
	function(player) 
		return (player:get_hp() < 8)
	end, 
	function(player) return (player:get_player_name().." ("..(player:get_hp()/2).." ♥)") end,
	2 
)

better_nametags.register_tag(
	"midhealth",
	"#EBE18F",
	function(player)
		return (player:get_hp() < 13)
	end, 
	function(player) return (player:get_player_name().." ("..(player:get_hp()/2).." ♥)") end,
	1 
)]]
better_nametags.register_tag(
	"default", 
	--Unique name of the tag, overwrites if the name already exists.
	"#DDDDDD", 
	--Color. Hexidecimal value, ideally
	function(_) return true end, 
	-- A boolean function with one parameter that will recieve a player: 
	-- "true" means the player meets the criteria for having their nametag be this
	nil,
	-- getName function. If nil, this will use the default:
	-- function(player) return player:get_player_name() end
	0
	-- Weight of the tag. 
	-- When a player meets multiple tags' criteria, the highest weighted will apply. 
	-- Negative values disable the tag entirely
)

better_nametags.register_tag(
	"moderator", 
	"#45C045",
	function(player) 
		return minetest.check_player_privs(player, {ban=true}) end, 
	function(player) 
		return ("[M] "..player:get_player_name()) 
	end,
	98
)

better_nametags.register_tag(
	"admin", 
	"#FF5555",
	function(player) 
		return minetest.check_player_privs(player, {server=true}) 
	end, 
	function(player) 
		return ("[A] "..player:get_player_name()) 
	end,
	100
)

better_nametags.register_tag(
	"witchcraft_invisible", 
	"#00000000",
	function(player) 
		if not invisibility then return false end
		if invisibility[player:get_player_name()] then return true end
		return false
	end, 
	function(player) 
		return " " 
	end,
	150
)

better_nametags.register_tag(
	"sneaking", 
	"#00000000",
	function(player) 
		return better_nametags.allowSneak and player:get_player_control().sneak
	end, 
	function(player) 
		return " "
	end,
	1e309
)