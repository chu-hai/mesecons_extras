local S = mesecons_extras.getter

local intl = {}
intl.desc = S("Inventory Checker")
intl.ui_target_desc = S("Check Target:")
intl.ui_target_inv = S("Inventory Name:")
intl.ui_target_na = S("Not available")
intl.ui_invert_signal = S("Invert Mesecon signal")

local inv_checker_formname = "mesecons_extras:inv_checker_formspec_"

local default_target_inv_list = {
	["default:furnace"]			= "fuel",
	["default:furnace_active"]	= "fuel",
}


--------------------------------------
-- Functions
--------------------------------------
local function get_output_rules(node)
	local rules = {}

	local ignore = minetest.wallmounted_to_dir(node.param2)
	for key, value in ipairs(mesecon.rules.default) do
		if not vector.equals(ignore, value) then
			table.insert(rules, value)
		end
	end
	return rules
end

local function get_first_inv(tbl)
	local func,t = pairs(tbl)
	local key = func(t)
	return key
end

local function get_default_inv(t_name, metatbl)
	local inv_name = default_target_inv_list[t_name]
	if not inv_name then
		inv_name = metatbl.inventory["main"] and "main" or get_first_inv(metatbl.inventory) or "n/a"
	end
	return inv_name
end

local function get_dropdown_data(tbl, inv_name)
	local data = ""
	local count = 0
	local selected = 0

	for inv, _ in pairs(tbl) do
		if count ~= 0 then
			data = data .. ","
		end
		data = data .. inv
		count = count + 1
		if inv_name == inv then
			selected = count
		end
	end
	return data, selected
end

local function create_formspec(pos, node)
	local meta = minetest.get_meta(pos)
	local t_invname = meta:get_string("target_inv")
	local t_pos = vector.add(pos, minetest.wallmounted_to_dir(node.param2))
	local t_meta = minetest.get_meta(t_pos)
	local t_name = minetest.get_node(t_pos).name
	local metatbl = t_meta:to_table()

	local form = "size[8.5,4]"..
				 "bgcolor[#00000000]" ..
				 "background[0,0;8.5,4;mesecons_extras_form_bg.png;true]"..
				 "label[0.2,0.1;"..intl.desc.."]"..
				 "label[1,1;"..intl.ui_target_desc.."]"..
				 "label[1,2.15;"..intl.ui_target_inv.."]"..
				 "box[3.5,0.65;1,1;#0f0f0f]"

	if t_name ~= "air" then
		form = form .. "item_image[3.6,0.7;1,1;"..t_name.."]"
	end

	if get_first_inv(metatbl.inventory) then
		local str,idx = get_dropdown_data(metatbl.inventory, t_invname)
		form = form .. "dropdown[3.5,2;4;invlist;"..str..";"..idx.."]"
	else
		form = form .. "label[3.55,2.15;"..intl.ui_target_na.."]"
	end

	form = form .. "checkbox[1,3;invert_signal;"..intl.ui_invert_signal..";"..meta:get_string("invert_signal").."]"

	return form
end

local function on_construct(pos)
	local meta = minetest.get_meta(pos)
	local node = minetest.get_node(pos)
	local t_pos = vector.add(pos, minetest.wallmounted_to_dir(node.param2))
	local t_meta = minetest.get_meta(t_pos)
	local t_name = minetest.get_node(t_pos).name
	local metatbl = t_meta:to_table()

	meta:set_string("target_inv", get_default_inv(t_name, metatbl))
	meta:set_string("target_nodename", t_name)
	meta:set_string("invert_signal", "false")

	minetest.get_node_timer(pos):start(mesecons_extras.settings.inv_checker_interval)
end

local function on_rightclick(pos, node, clicker, itemstack, pointed_thing)
	local formspec = create_formspec(pos, node)
	local formname = inv_checker_formname .. minetest.pos_to_string(pos)
	minetest.show_formspec(clicker:get_player_name(), formname, formspec)
end

local function on_timer(pos)
	local node = minetest.get_node(pos)
	local meta = minetest.get_meta(pos)
	local t_invname = meta:get_string("target_inv")
	local t_pos = vector.add(pos, minetest.wallmounted_to_dir(node.param2))
	local t_meta = minetest.get_meta(t_pos)
	local t_name = minetest.get_node(t_pos).name
	local metatbl = t_meta:to_table()

	if t_name ~= meta:get_string("target_nodename") then
		if not metatbl.inventory[t_invname] then
			meta:set_string("target_inv", get_default_inv(t_name, metatbl))
		end
		meta:set_string("target_nodename", t_name)
	end

	if not get_first_inv(metatbl.inventory) then
		if node.name ~= "mesecons_extras:inv_checker_inactive" then
			node.name = "mesecons_extras:inv_checker_inactive"
			minetest.swap_node(pos, node)
			mesecon.receptor_off(pos, get_output_rules(node))
		end
	else
		local t_empty = t_meta:get_inventory():is_empty(t_invname)
		if meta:get_string("invert_signal") == "true" then
			t_empty = not t_empty
		end

		if t_empty and node.name ~= "mesecons_extras:inv_checker_active_off" then
			node.name = "mesecons_extras:inv_checker_active_off"
			minetest.swap_node(pos, node)
			mesecon.receptor_off(pos, get_output_rules(node))
		elseif not t_empty and node.name ~= "mesecons_extras:inv_checker_active_on" then
			node.name = "mesecons_extras:inv_checker_active_on"
			minetest.swap_node(pos, node)
			mesecon.receptor_on(pos, get_output_rules(node))
		end
	end

	minetest.get_node_timer(pos):start(mesecons_extras.settings.inv_checker_interval)
	return false
end


--------------------------------------
-- Register callbacks
--------------------------------------
minetest.register_on_player_receive_fields(function(player, formname, fields)
	if not string.match(formname, "^" .. inv_checker_formname) then
		return
	end

	local pos = minetest.string_to_pos(string.sub(formname, string.len(inv_checker_formname) + 1))
	local meta = minetest.get_meta(pos)

	if mesecons_extras.is_protected(pos, player) then
		return
	end

	if fields.invlist then
		meta:set_string("target_inv", fields.invlist)
	end

	if fields.invert_signal then
		meta:set_string("invert_signal", fields.invert_signal)
	end

	return true
end)


--------------------------------------
-- Node definitions
--------------------------------------
minetest.register_node("mesecons_extras:inv_checker_inactive", {
	description = intl.desc,
	tiles = {"mesecons_extras_invchk_inactive.png"},
	drawtype = "nodebox",
	node_box = {
		type = "wallmounted",
		wall_top    = {-0.15425, 0.1875, -0.15425, 0.15425, 0.5, 0.15425},
		wall_bottom = {-0.15425, -0.5, -0.15425, 0.15425, -0.1875, 0.15425},
		wall_side   = {-0.5, -0.15425, -0.15425, -0.1875, 0.15425, 0.15425},
	},
	walkable = true,
	groups = {cracky = 2, oddly_breakable_by_hand = 3, attached_node = 1},
	paramtype = "light",
	paramtype2 = "wallmounted",
	sunlight_propagates = true,

	on_construct = on_construct,
	on_rightclick = on_rightclick,
	on_timer = on_timer,

	on_rotate = screwdriver.disallow,

	sounds = default.node_sound_stone_defaults(),
	mesecons = {
		receptor = {
			state = mesecon.state.off,
			rules = get_output_rules,
		},
	}
})

for _, stat in pairs({"on", "off"}) do
	minetest.register_node("mesecons_extras:inv_checker_active_"..stat, {
		description = intl.desc,
		tiles = {"mesecons_extras_invchk_active_"..stat.. ".png"},
		drawtype = "nodebox",
		node_box = {
			type = "wallmounted",
			wall_top    = {-0.15425, 0.1875, -0.15425, 0.15425, 0.5, 0.15425},
			wall_bottom = {-0.15425, -0.5, -0.15425, 0.15425, -0.1875, 0.15425},
			wall_side   = {-0.5, -0.15425, -0.15425, -0.1875, 0.15425, 0.15425},
		},
		walkable = true,
		groups = {cracky = 2, oddly_breakable_by_hand = 3, attached_node = 1, not_in_creative_inventory = 1},
		paramtype = "light",
		paramtype2 = "wallmounted",
		sunlight_propagates = true,
		light_source = ((stat == "on") and 10 or 0),
		drop = "mesecons_extras:inv_checker_inactive",

		on_rightclick = on_rightclick,
		on_timer = on_timer,

		on_rotate = screwdriver.disallow,

		sounds = default.node_sound_stone_defaults(),
		mesecons = {
			receptor = {
				state = ((stat == "on") and mesecon.state.on or mesecon.state.off),
				rules = get_output_rules,
			},
		}
	})
end


--------------------------------------
-- Craft recipe definitions
--------------------------------------
minetest.register_craft({
	output = 'mesecons_extras:inv_checker 4',
	recipe = {
		{'','default:steel_ingot',''},
		{'group:wood','default:glass','group:wood'},
		{'mesecons:mesecon','mesecons:mesecon_torch','mesecons:mesecon'},
	}
})

minetest.register_alias("mesecons_extras:inv_checker", "mesecons_extras:inv_checker_inactive")


--------------------------------------
-- Backwards compatibility
--------------------------------------
minetest.register_lbm({
	name = "mesecons_extras:inv_checker_start_timer",
	nodenames = {"mesecons_extras:inv_checker_inactive",
				 "mesecons_extras:inv_checker_active_on",
				 "mesecons_extras:inv_checker_active_off"},
	run_at_every_load = true,
	action = function(pos, node)
		local meta = minetest.get_meta(pos)
		if meta:get_string("formspec") then
			meta:set_string("formspec", nil)
			minetest.get_node_timer(pos):start(mesecons_extras.settings.inv_checker_interval)
		end
	end
})
