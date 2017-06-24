local S = mesecons_extras.getter

local intl = {}
intl.desc = S("Delay Circuit")
intl.delay_time = S("Delay Time (0.1 sec ~ 10 sec)")
intl.second = S("sec")

local default_delay_time = 0.5
local min_delay_time = 0.1
local max_delay_time = 10

local stage_inactive = 1
local stage_active = 2
local stage_off_delay = 3


--------------------------------------
-- Functions
--------------------------------------
local function update_infotext(meta)
	meta:set_string("infotext", intl.desc .. " [" .. meta:get_float("delay_time") .. intl.second .. "]")
end

local function update_formspec(meta)
	meta:set_string("formspec", "size[6.4,2]" ..
		"bgcolor[#00000000]" ..
		"background[0,0;6.4,2;mesecons_extras_form_bg.png;true]" ..
		"label[0,0;" .. intl.desc .. "]" ..
		"field[0.5,0.8;6,2;delay_time;" .. intl.delay_time .. ";${delay_time}]"
	)

	update_infotext(meta)
end

local function get_output_rules(node)
	local rules = {{x = 0, y = 0, z = 1}}
	for i = 0, node.param2 do
		rules = mesecon.rotate_rules_left(rules)
	end
	return rules
end

local function get_input_rules(node)
	local rules = {{x = 0, y = 0, z = -1}}
	for i = 0, node.param2 do
		rules = mesecon.rotate_rules_left(rules)
	end
	return rules
end

local function activate(pos, node)
	local meta = minetest.get_meta(pos)

	node.name = "mesecons_extras:mesecons_extras_delayer_active_off"
	minetest.swap_node(pos, node)
	mesecon.receptor_off(pos, get_output_rules(node))
	meta:set_int("stage", stage_active)

	mesecon.queue:add_action(pos, "mesecons_extras_change_status",
		{
			"on",
			"mesecons_extras:mesecons_extras_delayer_active_off",
			"mesecons_extras:mesecons_extras_delayer_active_on",
			get_output_rules(node)
		},
		meta:get_float("delay_time"), nil
	)

end

local function deactivate(pos, node)
	local meta = minetest.get_meta(pos)

	if meta:get_int("stage") == stage_off_delay then
		return
	end
	meta:set_int("stage", stage_off_delay)

	mesecon.queue:add_action(pos, "mesecons_extras_change_status",
		{
			"off",
			"mesecons_extras:mesecons_extras_delayer_active_on",
			"mesecons_extras:mesecons_extras_delayer",
			get_output_rules(node),
			{stage = stage_inactive}
		},
		meta:get_float("delay_time"), nil
	)
end

local function on_construct(pos)
	local meta = minetest.get_meta(pos)
	meta:set_float("delay_time", default_delay_time)
	meta:set_int("stage", stage_inactive)

	update_formspec(meta)
end

local function on_receive_fields(pos, formname, fields, sender)
	local meta = minetest.get_meta(pos)
	local num

	if mesecons_extras.is_protected(pos, sender) then
		return
	end

	if fields.delay_time then
		num = tonumber(fields.delay_time)
		if num then
			num = math.min(math.max(num, min_delay_time), max_delay_time)
			num = math.floor(num * 10) / 10
			meta:set_float("delay_time", num)
			update_infotext(meta)
		end
	end
end

local function on_punch(pos, node, puncher)
	local meta = minetest.get_meta(pos)

	update_formspec(meta)
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

	{-0.25, -0.3125, -0.0625, 0.25, -0.25, 0.0625},
	{0, -0.3125, -0.125, 0.1875, -0.25, 0.125},
	{-0.0625, -0.3125, -0.1875, 0.125, -0.25, -0.125},
	{-0.0625, -0.3125, 0.125, 0.125, -0.25, 0.1875},
}

minetest.register_node("mesecons_extras:mesecons_extras_delayer", {
	description = intl.desc,
	tiles = {
		"mesecons_extras_delayer_top.png",
		"mesecons_extras_common_bottom.png",
		"mesecons_extras_common_side.png",
		"mesecons_extras_common_side.png",
		"mesecons_extras_common_side.png",
		"mesecons_extras_common_side.png"
	},
	inventory_image = "mesecons_extras_delayer_top.png",
	wield_image = "mesecons_extras_delayer_top.png",
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
	on_receive_fields = on_receive_fields,
	on_punch = on_punch,

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

for _, stat in pairs({"on", "off"}) do
	minetest.register_node("mesecons_extras:mesecons_extras_delayer_active_" .. stat, {
		description = intl.desc,
		tiles = {
			"mesecons_extras_delayer_top_active_" .. stat .. ".png",
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
		drop = "mesecons_extras:mesecons_extras_delayer",

		on_receive_fields = on_receive_fields,
		on_punch = on_punch,

		on_rotate = screwdriver.disallow,

		sounds = default.node_sound_stone_defaults(),
		mesecons = {
			receptor = {
				state = ((stat == "on") and mesecon.state.on or mesecon.state.off),
				rules = get_output_rules
			},
			effector = {
				rules = get_input_rules,
				action_off = deactivate
			}
		}
	})
end


--------------------------------------
-- Craft recipe definitions
--------------------------------------
minetest.register_craft({
	output = "mesecons_extras:mesecons_extras_delayer",
	recipe = {
		{"",                  "mesecons_extras:code_delayer",             ""},
		{"mesecons:mesecon",  "mesecons_luacontroller:luacontroller0000", "mesecons:mesecon"},
		{"stairs:slab_stone", "stairs:slab_stone",                        "stairs:slab_stone"},
	}
})
