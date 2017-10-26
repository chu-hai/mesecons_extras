local S = mesecons_extras.getter

local intl = {}
intl.desc = S("Pulse Circuit")
intl.output_time = S("Output Time (0.1 sec ~ 5.0 sec)")
intl.second = S("sec")

local default_output_time = 0.5
local min_output_time = 0.1
local max_output_time = 5.0
local formname_prefix = "mesecons_extras:pulse_formspec_"


--------------------------------------
-- Functions
--------------------------------------
local function update_infotext(meta)
	meta:set_string("infotext", intl.desc .. " [" .. meta:get_string("output_time") .. intl.second .. "]")
end

local function create_formspec(pos, node)
	local meta = minetest.get_meta(pos)
	local output_time = meta:get_string("output_time")
	local form = "size[6.4,2]" ..
				 "bgcolor[#00000000]" ..
				 "background[0,0;6.4,2;mesecons_extras_form_bg.png;true]" ..
				 "label[0,0;" .. intl.desc .. "]" ..
				 "field[0.5,0.8;6,2;output_time;" .. intl.output_time .. ";" .. output_time .. "]"

	update_infotext(meta)
	return form
end

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

local function activate(pos, node, link, newstate)
	if link.name ~= "input" then
		return
	end

	local meta = minetest.get_meta(pos)
	node.name = "mesecons_extras:mesecons_extras_pulse_active_on"
	minetest.swap_node(pos, node)
	mesecon.receptor_on(pos, get_output_rules(node))

	mesecon.queue:add_action(pos, "mesecons_extras_change_status",
		{
			"off",
			"mesecons_extras:mesecons_extras_pulse_active_on",
			"mesecons_extras:mesecons_extras_pulse",
			get_output_rules(node)
		},
		tonumber(meta:get_string("output_time")), nil
	)
end

local function reset(pos, node, link, newstate)
	if link.name ~= "input" then
		node.name = "mesecons_extras:mesecons_extras_pulse"
		minetest.swap_node(pos, node)
		mesecon.receptor_off(pos, get_output_rules(node))
	end
end

local function on_construct(pos)
	local meta = minetest.get_meta(pos)
	meta:set_string("output_time", default_output_time)
end

local function on_rightclick(pos, node, clicker, itemstack, pointed_thing)
	if mesecons_extras.is_protected(pos, clicker) then
		return
	end

	local formspec = create_formspec(pos, node)
	local formname = formname_prefix .. minetest.pos_to_string(pos)
	minetest.show_formspec(clicker:get_player_name(), formname, formspec)
end


--------------------------------------
-- Register callbacks
--------------------------------------
minetest.register_on_player_receive_fields(function(player, formname, fields)
	if not string.match(formname, "^" .. formname_prefix) then
		return
	end

	local pos = minetest.string_to_pos(string.sub(formname, string.len(formname_prefix) + 1))
	local meta = minetest.get_meta(pos)
	local num

	if fields.output_time then
		num = tonumber(fields.output_time)
		if num then
			num = math.min(math.max(num, min_output_time), max_output_time)
			num = math.floor(num * 10) / 10
			meta:set_string("output_time", num)
			update_infotext(meta)
		end
	end

	return true
end)


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

	{-0.3125, -0.3125, -0.0625, -0.125, -0.25, 0},
	{-0.1875, -0.3125, 0, -0.125, -0.25, 0.125},
	{-0.125, -0.3125, 0.0625, 0.0625, -0.25, 0.125},
	{0, -0.3125, -0.125, 0.0625, -0.25, 0.0625},
	{0.0625, -0.3125, -0.125, 0.25, -0.25, -0.0625},
	{0.1875, -0.3125, -0.0625, 0.25, -0.25, 0.0625},
	{0.25, -0.3125, 0, 0.3125, -0.25, 0.0625},
}

minetest.register_node("mesecons_extras:mesecons_extras_pulse", {
	description = intl.desc,
	tiles = {
		"mesecons_extras_pulse_top.png",
		"mesecons_extras_common_bottom.png",
		"mesecons_extras_common_side.png",
		"mesecons_extras_common_side.png",
		"mesecons_extras_common_side.png",
		"mesecons_extras_common_side.png"
	},
	inventory_image = "mesecons_extras_pulse_top.png",
	wield_image = "mesecons_extras_pulse_top.png",
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
			action_on = activate
		}
	}
})

minetest.register_node("mesecons_extras:mesecons_extras_pulse_active_on", {
	description = intl.desc,
	tiles = {
		"mesecons_extras_pulse_top_active_on.png",
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
	drop = "mesecons_extras:mesecons_extras_pulse",

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
			action_on = reset
		}
	}
})


--------------------------------------
-- Craft recipe definitions
--------------------------------------
minetest.register_craft({
	output = "mesecons_extras:mesecons_extras_pulse",
	recipe = {
		{"",                  "mesecons_extras:code_pulse",               ""},
		{"mesecons:mesecon",  "mesecons_luacontroller:luacontroller0000", "mesecons:mesecon"},
		{"stairs:slab_stone", "stairs:slab_stone",                        "stairs:slab_stone"},
	}
})


--------------------------------------
-- Backwards compatibility
--------------------------------------
minetest.register_lbm({
	name = "mesecons_extras:pulse_erase_formspec",
	nodenames = {"mesecons_extras:mesecons_extras_pulse",
				 "mesecons_extras:mesecons_extras_pulse_active_on"},
	run_at_every_load = true,
	action = function(pos, node)
		local meta = minetest.get_meta(pos)
		if meta:get_string("formspec") then
			meta:set_string("formspec", nil)
		end
	end
})
