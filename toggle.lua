local S = mesecons_extras.getter

local intl = {}
intl.desc = S("Toggle Circuit")


--------------------------------------
-- Functions
--------------------------------------
local function get_output_rules(node)
	local rules = {{x = 0, y = 0, z = 1}}
	for i = 0, node.param2 do
		rules = mesecon.rotate_rules_left(rules)
	end
	return rules
end

local function get_input_rules(node)
	local rules = { {x =  0, y = 0, z = -1, name="input"},
					{x =  1, y = 0, z =  0, name="reset1"},
					{x = -1, y = 0, z =  0, name="reset2"},
				  }
	for i = 0, node.param2 do
		rules = mesecon.rotate_rules_left(rules)
	end
	return rules
end

local function toggle_state(pos, node)
	local meta = minetest.get_meta(pos)

	if (meta:get_string("state") == "on") then
		node.name = "mesecons_extras:mesecons_extras_toggle"
		minetest.swap_node(pos, node)
		mesecon.receptor_off(pos, get_output_rules(node))
		meta:set_string("state","off")
	else
		node.name = "mesecons_extras:mesecons_extras_toggle_active_on"
		minetest.swap_node(pos, node)
		mesecon.receptor_on(pos, get_output_rules(node))
		meta:set_string("state","on")
	end
end

local function action_on(pos, node, link, newstate)
	local meta = minetest.get_meta(pos)

	if (link.name ~= "input") then
		meta:set_string("state","on")
	end
	toggle_state(pos, node)
end

local function on_construct(pos)
	local meta = minetest.get_meta(pos)
	meta:set_string("state","off")
	meta:set_string("infotext", intl.desc)
end

local function on_rightclick(pos, node, clicker, itemstack, pointed_thing)
	local meta = minetest.get_meta(pos)
	meta:set_string("infotext", intl.desc)
end


--------------------------------------
-- Node definitions
--------------------------------------
local nodebox = {
	{-0.5, -0.5, -0.5, 0.5, -0.375, 0.5},
	{-0.25, -0.375, -0.25, 0.25, -0.3125, 0.25},
	{-0.375, -0.375, -0.125, -0.3125, -0.3125, 0.125},
	{0.3125, -0.375, -0.125, 0.375, -0.3125, 0.125},
	{-0.125, -0.375, 0.3125, 0.125, -0.3125, 0.375},
	{-0.125, -0.375, -0.375, 0.125, -0.3125, -0.3125},
	{-0.25, -0.5, -0.3125, 0.25, -0.3125, -0.25},
	{-0.25, -0.5, 0.25, 0.25, -0.3125, 0.3125},
	{-0.3125, -0.5, -0.25, -0.25, -0.3125, 0.25},
	{0.25, -0.5, -0.25, 0.3125, -0.3125, 0.25},

	{-0.25, -0.3125, 0.0625, 0.25, -0.25, 0.1875},
	{-0.0625, -0.3125, -0.25, 0.0625, -0.25, 0.0625},
}

minetest.register_node("mesecons_extras:mesecons_extras_toggle", {
	description = intl.desc,
	tiles = {
		"mesecons_extras_toggle_top.png",
		"mesecons_extras_common_bottom.png",
		"mesecons_extras_common_side.png",
		"mesecons_extras_common_side.png",
		"mesecons_extras_common_side.png",
		"mesecons_extras_common_side.png"
	},
	inventory_image = "mesecons_extras_toggle_top.png",
	wield_image = "mesecons_extras_toggle_top.png",
	drawtype = "nodebox",
	node_box = {
		type = "fixed",
		fixed = nodebox,
	},
	selection_box = {
		type = "fixed",
		fixed = {-0.5, -0.5, -0.5, 0.5, -0.375, 0.5},
	},
	walkable = true,
	groups = {cracky = 2, oddly_breakable_by_hand = 3},
	paramtype = "light",
	paramtype2 = "facedir",
	sunlight_propagates = true,

	on_construct = on_construct,
	on_rightclick = on_rightclick,
	on_rotate = mesecons_extras.rotate_simple,

	sounds = default.node_sound_stone_defaults(),
	mesecons = {
		receptor = {
			state = mesecon.state.off,
			rules = get_output_rules
		},
		effector = {
			rules = get_input_rules,
			action_on = action_on
		}
	}
})

minetest.register_node("mesecons_extras:mesecons_extras_toggle_active_on", {
	description = intl.desc,
	tiles = {
		"mesecons_extras_toggle_top_active_on.png",
		"mesecons_extras_common_bottom.png",
		"mesecons_extras_common_side.png",
		"mesecons_extras_common_side.png",
		"mesecons_extras_common_side.png",
		"mesecons_extras_common_side.png"
	},
	drawtype = "nodebox",
	node_box = {
		type = "fixed",
		fixed = nodebox,
	},
	selection_box = {
		type = "fixed",
		fixed = {-0.5, -0.5, -0.5, 0.5, -0.375, 0.5},
	},
	walkable = true,
	groups = {cracky = 2, oddly_breakable_by_hand = 3, not_in_creative_inventory = 1},
	paramtype = "light",
	paramtype2 = "facedir",
	sunlight_propagates = true,
	drop = "mesecons_extras:mesecons_extras_toggle",

	on_rightclick = on_rightclick,
	on_rotate = screwdriver.disallow,

	sounds = default.node_sound_stone_defaults(),
	mesecons = {
		receptor = {
			state = mesecon.state.on,
			rules = get_output_rules
		},
		effector = {
			rules = get_input_rules,
			action_on = action_on
		}
	}
})


--------------------------------------
-- Craft recipe definitions
--------------------------------------
minetest.register_craft({
	output = "mesecons_extras:mesecons_extras_toggle",
	recipe = {
		{"",                  "mesecons_extras:code_toggle",              ""},
		{"mesecons:mesecon",  "mesecons_luacontroller:luacontroller0000", "mesecons:mesecon"},
		{"stairs:slab_stone", "stairs:slab_stone",                        "stairs:slab_stone"},
	}
})
