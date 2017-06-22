local S = mesecons_extras.getter

local intl = {}
intl.desc = S("Clock Circuit")
intl.max_cnt = S("Number of oscillations (set to 0 for infinity)")
intl.interval = S("Interval (seconds)")
intl.second = S("sec")
intl.infinity = S("infinity")

local default_interval = 1


--------------------------------------
-- Functions
--------------------------------------
local function update_infotext(meta)
	local str = intl.desc
	local maximum_count = meta:get_int("maximum_count")
	local counter_current = meta:get_int("counter_current")
	local interval = meta:get_float("interval")

	if maximum_count == 0 then
		str = str.." ["..intl.infinity.." : "..interval..intl.second.."]"
	else
		str = str.." ["..counter_current.."/"..maximum_count.." : "..interval..intl.second.."]"
	end

	meta:set_string("infotext", str)
end

local function update_formspec(meta)
	meta:set_string("formspec", "size[7.4,3]" ..
		"bgcolor[#00000000]" ..
		"background[0,0;7.4,3;mesecons_extras_form_bg.png;true]"..
		"label[0,0;"..intl.desc.."]"..
		"field[0.5,0.8;7,2;maximum_count;"..intl.max_cnt..";${maximum_count}]"..
		"field[0.5,2.2;7,2;interval;"..intl.interval..";${interval}]"
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
	local rules = { {x =  0, y = 0, z = -1, name="input"},
					{x =  1, y = 0, z =  0, name="reset1"},
					{x = -1, y = 0, z =  0, name="reset2"},
				  }
	for i = 0, node.param2 do
		rules = mesecon.rotate_rules_left(rules)
	end
	return rules
end

local function change_mesecon_signal(pos, node, state)
	local meta = minetest.get_meta(pos)

	if state == "off" then
		meta:set_string("state","off")
		node.name = "mesecons_extras:mesecons_extras_clock_active_off"
		minetest.swap_node(pos, node)
		mesecon.receptor_off(pos, get_output_rules(node))
	else
		meta:set_string("state","on")
		node.name = "mesecons_extras:mesecons_extras_clock_active_on"
		minetest.swap_node(pos, node)
		mesecon.receptor_on(pos, get_output_rules(node))
	end
end

local function activate(pos, node, link, newstate)
	local meta = minetest.get_meta(pos)
	local timer = minetest.get_node_timer(pos)
	if link.name == "input" then
		change_mesecon_signal(pos, node, "on")
		meta:set_int("counter_current", 1)
		timer:start(meta:get_float("interval"))
		update_infotext(meta)
	end
end

local function deactivate(pos, node)
	local meta = minetest.get_meta(pos)
	local timer = minetest.get_node_timer(pos)
	local maximum = meta:get_int("maximum_count")
	local current = meta:get_int("counter_current")
	local state = meta:get_string("state")

	if (maximum > 0 and current >= maximum and state == "off") or maximum == 0 then
		timer:stop()
		node.name = "mesecons_extras:mesecons_extras_clock"
		minetest.swap_node(pos, node)
		mesecon.receptor_off(pos, get_output_rules(node))
		meta:set_string("state","off")
		meta:set_int("counter_current", 0)

		update_infotext(meta)
	end
end

local function reset(pos, node, link, newstate)
	if link.name ~= "input" then
		local meta = minetest.get_meta(pos)
		meta:set_int("counter_current", meta:get_int("maximum_count"))
		meta:set_string("state","off")
		deactivate(pos, node)
	end
end

local function on_construct(pos)
	local meta = minetest.get_meta(pos)

	meta:set_int("maximum_count", 0)
	meta:set_float("interval", default_interval)
	meta:set_int("counter_current", 0)
	meta:set_string("state", "off")

	update_formspec(meta)
end

local function on_receive_fields(pos, formname, fields, sender)
	local meta = minetest.get_meta(pos)
	local num

	if mesecons_extras.is_protected(pos, sender) then
		return
	end

	if fields.maximum_count then
		num = tonumber(fields.maximum_count)
		if num then
			meta:set_int("maximum_count", num)
			update_infotext(meta)
		end
	end

	if fields.interval then
		num = tonumber(fields.interval)
		if num then
			if num > 0 then
				num = math.floor(num * 10) / 10
			else
				num = default_interval
			end
			meta:set_float("interval", num)
			update_infotext(meta)
		end
	end
end

local function on_timer(pos)
	local meta = minetest.get_meta(pos)
	local node = minetest.get_node(pos)
	local maximum = meta:get_int("maximum_count")
	local current = meta:get_int("counter_current")

	if meta:get_string("state") == "off" then
		change_mesecon_signal(pos, node, "on")
		if maximum > 0 then
			current = current + 1
			meta:set_int("counter_current", current)
		end
	else
		if maximum > 0 and current >= maximum then
			meta:set_string("state","off")
			deactivate(pos, node)
			return false
		else
			change_mesecon_signal(pos, node, "off")
		end
	end
	update_infotext(meta)

	return true
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

    {-0.0625, -0.3125, -0.0625, 0.0625, -0.1875, 0.0625},
    {-0.0625, -0.3125, -0.0625, 0.25, -0.25, 0.0625},
    {-0.0625, -0.3125, -0.0625, 0.0625, -0.25, 0.3125},
}

minetest.register_node("mesecons_extras:mesecons_extras_clock", {
	description = intl.desc,
	tiles = {
		"mesecons_extras_clock_top.png",
		"mesecons_extras_common_bottom.png",
		"mesecons_extras_common_side.png",
		"mesecons_extras_common_side.png",
		"mesecons_extras_common_side.png",
		"mesecons_extras_common_side.png"
	},
	inventory_image = "mesecons_extras_clock_top.png",
	wield_image = "mesecons_extras_clock_top.png",
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
			action_on = activate,
		}
	}
})

for _, stat in pairs({"on", "off"}) do
	minetest.register_node("mesecons_extras:mesecons_extras_clock_active_"..stat, {
		description = intl.desc,
		tiles = {
			"mesecons_extras_clock_top_active_"..stat..".png",
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
		drop = "mesecons_extras:mesecons_extras_clock",

		on_receive_fields = on_receive_fields,
		on_punch = on_punch,
		on_timer = on_timer,

		on_rotate = screwdriver.disallow,

		sounds = default.node_sound_stone_defaults(),
		mesecons = {
			receptor = {
				state = ((stat == "on") and mesecon.state.on or mesecon.state.off),
				rules = get_output_rules
			},
			effector = {
				rules = get_input_rules,
				action_on = reset,
				action_off = deactivate
			}
		}
	})
end

--------------------------------------
-- Craft recipe definitions
--------------------------------------
minetest.register_craft({
	output = "mesecons_extras:mesecons_extras_clock",
	recipe = {
		{"",                  "mesecons_extras:code_clock",               ""},
		{"mesecons:mesecon",  "mesecons_luacontroller:luacontroller0000", "mesecons:mesecon"},
		{"stairs:slab_stone", "stairs:slab_stone",                        "stairs:slab_stone"},
	}
})
