--
-- Sequoia
--

local modname = "sequoia"
local modpath = minetest.get_modpath(modname)
local mg_name = minetest.get_mapgen_setting("mg_name")

-- internationalization boilerplate
local S = minetest.get_translator(minetest.get_current_modname())

--Sequoia Grow Function

local function grow_new_sequoia(pos)
	if not default.can_grow(pos) then
		-- try a bit later again
		minetest.get_node_timer(pos):start(math.random(240, 600))
		return
	end
	minetest.remove_node(pos)
	minetest.place_schematic({x = pos.x-7, y = pos.y-4, z = pos.z-7}, modpath.."/schematics/sequoia_03.mts", "0", nil, true)
end

--
-- Decoration
--

if mg_name ~= "singlenode" then
	local place_on, biomes

	if minetest.get_modpath("redw") then
		place_on = {"redw:dirt", "redw:dirt_with_grass"}
		biomes = "redwood_forest"
	else
		place_on = "default:dirt_with_grass"
		biomes = "grassland"
	end

	local decoration_definition = {
		deco_type = "schematic",
		place_on = place_on,
		sidelen = 16,
		noise_params = {
			spread = {x = 250, y = 250, z = 250},
			octaves = 3,
			persist = 0.66
		},
		y_min = 1,
		flags = "place_center_x, place_center_z, force_placement",
		rotation = "random"
	}

	local function register_decorations(definition)
		-- sequoia small
		local sequoia_small = table.copy(definition)
		sequoia_small.name = "sequoia:sequoia_small"
		sequoia_small.noise_params.offset = 0.008
		sequoia_small.noise_params.scale = 0.0004
		sequoia_small.noise_params.seed = 67
		sequoia_small.schematic = modpath .. "/schematics/sequoia_01.mts"
		sequoia_small.place_offset_y = -1

		minetest.register_decoration(sequoia_small)

		-- sequoia medium
		local sequoia_medium = table.copy(definition)
		sequoia_medium.name = "sequoia:sequoia_medium"
		sequoia_medium.noise_params.offset = 0.008
		sequoia_medium.noise_params.scale = 0.0004
		sequoia_medium.noise_params.seed = 345
		sequoia_medium.schematic = modpath .. "/schematics/sequoia_02.mts"
		sequoia_medium.place_offset_y = -1

		minetest.register_decoration(sequoia_medium)

		-- sequoia giant
		local sequoia_giant = table.copy(definition)
		sequoia_giant.name = "sequoia:sequoia_giant"
		sequoia_giant.noise_params.offset = 0.0008
		sequoia_giant.noise_params.scale = 0.00004
		sequoia_giant.noise_params.seed = 23
		sequoia_giant.schematic = modpath .. "/schematics/sequoia_03.mts"
		sequoia_giant.place_offset_y = -2

		minetest.register_decoration(sequoia_giant)
	end

	if mg_name == "v6" then
		decoration_definition.y_max = 80

		register_decorations(decoration_definition)
	else
		decoration_definition.biomes = {biomes}
		decoration_definition.y_max = 5000

		register_decorations(decoration_definition)
	end
end

--
-- Nodes
--

minetest.register_node("sequoia:sapling", {
	description = S("Sequoia Tree Sapling"),
	drawtype = "plantlike",
	tiles = {"sequoia_sapling.png"},
	inventory_image = "sequoia_sapling.png",
	wield_image = "sequoia_sapling.png",
	paramtype = "light",
	sunlight_propagates = true,
	walkable = false,
	on_timer = grow_new_sequoia,
	selection_box = {
		type = "fixed",
		fixed = {-4 / 16, -0.5, -4 / 16, 4 / 16, 7 / 16, 4 / 16}
	},
	groups = {snappy = 2, dig_immediate = 3, flammable = 2,
		attached_node = 1, sapling = 1},
	sounds = default.node_sound_leaves_defaults(),

	on_construct = function(pos)
		minetest.get_node_timer(pos):start(math.random(2400, 4800))
	end,

	on_place = function(itemstack, placer, pointed_thing)
		itemstack = default.sapling_on_place(itemstack, placer, pointed_thing,
			"sequoia:sapling",
			-- minp, maxp to be checked, relative to sapling pos
			-- minp_relative.y = 1 because sapling pos has been checked
			{x = -2, y = 1, z = -2},
			{x = 2, y = 6, z = 2},
			-- maximum interval of interior volume check
			4)

		return itemstack
	end,
})

minetest.register_node("sequoia:trunk", {
	description = S("Sequoia Trunk"),
	tiles = {
		"sequoia_trunk_top.png",
		"sequoia_trunk_top.png",
		"sequoia_trunk.png"
	},
	groups = {tree = 1, choppy = 2, oddly_breakable_by_hand = 1, flammable = 2},
	sounds = default.node_sound_wood_defaults(),
	paramtype2 = "facedir",
	on_place = minetest.rotate_node,
})

-- Sequoia wood
minetest.register_node("sequoia:wood", {
	description = S("Sequoia Wood Planks"),
	tiles = {"sequoia_wood.png"},
	is_ground_content = false,
	groups = {wood = 1, choppy = 2, oddly_breakable_by_hand = 1, flammable = 3},
	sounds = default.node_sound_wood_defaults(),
})

-- Sequoia leaves
minetest.register_node("sequoia:leaves", {
	description = S("Sequoia Leaves"),
	drawtype = "allfaces_optional",
	tiles = {"sequoia_leaves.png"},
	paramtype = "light",
	walkable = true,
	waving = 1,
	groups = {snappy = 3, leafdecay = 3, leaves = 1, flammable = 2},
	drop = {
		max_items = 1,
		items = {
			{items = {"sequoia:sapling"}, rarity = 20},
			{items = {"sequoia:leaves"}}
		}
	},
	sounds = default.node_sound_leaves_defaults(),
	after_place_node = default.after_place_leaves,
})

--
-- Craftitems
--

--
-- Recipes
--

minetest.register_craft({
	output = "sequoia:wood 4",
	recipe = {{"sequoia:trunk"}}
})

minetest.register_craft({
	type = "fuel",
	recipe = "sequoia:trunk",
	burntime = 30,
})

minetest.register_craft({
	type = "fuel",
	recipe = "sequoia:wood",
	burntime = 7,
})

default.register_leafdecay({
	trunks = {"sequoia:trunk"},
	leaves = {"sequoia:leaves"},
	radius = 3,
})

-- Fence
if minetest.settings:get_bool("cool_fences", true) then
	local fence = {
		description = S("Sequoia Wood Fence"),
		texture =  "sequoia_wood.png",
		material = "sequoia:wood",
		groups = {choppy = 2, oddly_breakable_by_hand = 2, flammable = 2},
		sounds = default.node_sound_wood_defaults(),
	}
	default.register_fence("sequoia:fence", table.copy(fence))
	fence.description = S("Sequoia Fence Rail")
	default.register_fence_rail("sequoia:fence_rail", table.copy(fence))

end

-- Stairs
if minetest.get_modpath("moreblocks") then -- stairsplus/moreblocks
	stairsplus:register_all("sequoia", "wood", "sequoia:wood", {
		description = S("Sequoia Wood"),
		tiles = {"sequoia_wood.png"},
		sunlight_propagates = true,
		groups = {choppy = 2, oddly_breakable_by_hand = 1, flammable = 3},
		sounds = default.node_sound_wood_defaults()
	})
	minetest.register_alias_force("stairs:stair_sequoia_wood", "sequoia:stair_wood")
	minetest.register_alias_force("stairs:stair_outer_sequoia_wood", "sequoia:stair_wood_outer")
	minetest.register_alias_force("stairs:stair_inner_sequoia_wood", "sequoia:stair_wood_inner")
	minetest.register_alias_force("stairs:slab_sequoia_wood", "sequoia:slab_wood")

	-- for compatibility
	minetest.register_alias_force("stairs:stair_sequoia_trunk", "sequoia:stair_wood")
	minetest.register_alias_force("stairs:stair_outer_sequoia_trunk", "sequoia:stair_wood_outer")
	minetest.register_alias_force("stairs:stair_inner_sequoia_trunk", "sequoia:stair_wood_inner")
	minetest.register_alias_force("stairs:slab_sequoia_trunk", "sequoia:slab_wood")
elseif minetest.get_modpath("stairs") then
	stairs.register_stair_and_slab(
		"sequoia_wood",
		"sequoia:wood",
		{choppy = 2, oddly_breakable_by_hand = 2, flammable = 2},
		{"sequoia_wood.png"},
		S("Sequoia Wood Stair"),
		S("Sequoia Wood Slab"),
		default.node_sound_wood_defaults()
	)
end

-- Support for bonemeal
if minetest.get_modpath("bonemeal") ~= nil then
	bonemeal:add_sapling({
		{"sequoia:sapling", grow_new_sequoia, "soil"},
	})
end

-- Support for flowerpot
if minetest.global_exists("flowerpot") then
	flowerpot.register_node("sequoia:sapling")
end
