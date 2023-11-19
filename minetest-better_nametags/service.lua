minetest.register_chatcommand("players", {
	description = "List all players currently online.",
	func = function(name, _) 
		local onlineCount = #(minetest.get_connected_players())
		local listString = ""..onlineCount.." Online: "
		local iterated=1
		for _,connectedPlayer in ipairs(minetest.get_connected_players()) do
			local attr = better_nametags.get_playertag_attributes(connectedPlayer)
			if attr then
				listString=listString..minetest.colorize(attr.color, attr.text)
			else
				listString=listString..connectedPlayer:get_player_name()
			end
			if iterated < onlineCount then
				listString=listString..", "
			end
			iterated=iterated+1
		end
		core.chat_send_player(name, listString)
	end
})

better_nametags.update_nametag = function(player)
	local attr = better_nametags.get_playertag_attributes(player)
	local name = player:get_player_name()
	if not better_nametags.players[name] 
		or better_nametags.players[name].text ~= attr.text 
		or better_nametags.players[name].color ~= better_nametags.players[name].color 
	then
		better_nametags.players[name] = attr
		player:set_nametag_attributes(attr)
	end
end

if minetestd then

minetestd.playerctl.register_playerstep("better_nametags", {
	func = better_nametags.update_nametag,
	interval = 0.5
})

end

function better_nametags.get_playertag_attributes(player) 
	local pos = player:get_pos()
	local player_name = player:get_player_name()
	local tag = ""
	local highestWeight = -1
	local tagColor = "#FFFFFF"
	local tagName = player:get_player_name() or ""
	
	for _,registeredTag in pairs(better_nametags.tags) do
		if registeredTag.weight > highestWeight then
			if registeredTag.has(player) then
				tag = registeredTag.title
				highestWeight = registeredTag.weight
			end
		end
	end
	if better_nametags.tags[tag] then
		tagName = better_nametags.tags[tag].getName(player)
		tagColor = better_nametags.tags[tag].Color
	end
	
	
	return {
		text = tagName,
		color = tagColor
	}
end
