local S = mesecons_extras.getter

local intl = {}
intl.desc = S("Directional Mesecon Signal Receiver")
intl.mode = S("Fixed Distance Mode")

local min_dist = 2
local max_dist = 4
local formname_prefix = "mesecons_extras:receiver_formspec_"


--------------------------------------
-- Functions
--------------------------------------
local function get_input_rules(dist)
	return function(node)
		return {vector.multiply(minetest.facedir_to_dir(node.param2), -1 * dist)}
	end
end

local function create_formspec(pos, node)
	local meta = minetest.get_meta(pos)
	local mode = meta:get_string("fixed_mode") == "on" and "true" or "false"
	local form = "size[7.4,2]" ..
				 "bgcolor[#00000000]" ..
				 "background[0,0;7.4,2;mesecons_extras_form_bg.png;true]" ..
				 "label[0,0;" .. intl.desc .. "]" ..
				 "checkbox[1.2,0.8;fixed_mode;" .. intl.mode .. ";" .. mode .. "]"

	return form
end

local function on_construct(pos)
	local meta = minetest.get_meta(pos)

	meta:set_string("fixed_mode", "off")
end

local function on_rightclick(pos, node, clicker, itemstack, pointed_thing)
	if mesecons_extras.is_protected(pos, clicker) then
		return
	end

	local formspec = create_formspec(pos, node)
	local formname = formname_prefix .. minetest.pos_to_string(pos)
	minetest.show_formspec(clicker:get_player_name(), formname, formspec)
end

local function can_change_distance(pos, player)
	local result = true
	local meta = minetest.get_meta(pos)

	if mesecons_extras.is_protected(pos, player) then
		result = false
	elseif meta:get_string("fixed_mode") == "on" then
		result = false
	end

	return result
end

local function distance_change(dist, stat)
	return function(pos, node, puncher)
		if can_change_distance(pos, puncher) then
			local new_dist = ((dist + 1) > max_dist) and min_dist or dist + 1
			node.name = "mesecons_extras:mesecon_receiver_" .. stat .. "_" .. new_dist
			minetest.swap_node(pos, node)
			mesecon.on_placenode(pos, node)
		end
	end
end

local function on_rotate(pos, node, user, mode, new_param2)
	node.param2 = new_param2
	minetest.swap_node(pos, node)
	mesecon.on_placenode(pos, node)

	return false
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

	if fields.fixed_mode then
		meta:set_string("fixed_mode", (fields.fixed_mode == "true" and "on" or "off"))
	end

	return true
end)


--------------------------------------
-- Node definitions
--------------------------------------
for dist = min_dist, max_dist do
	minetest.register_node("mesecons_extras:mesecon_receiver_off_" .. dist, {
		description = intl.desc,
		tiles = {
			"mesecons_extras_receiver_side" .. dist .. "_off.png^[transformR180",
			"mesecons_extras_receiver_side" .. dist .. "_off.png",
			"mesecons_extras_receiver_side" .. dist .. "_off.png^[transformR90",
			"mesecons_extras_receiver_side" .. dist .. "_off.png^[transformR270",
			"mesecons_extras_receiver_back_off.png",
			"mesecons_extras_receiver_front_off.png"
		},
		paramtype2 = "facedir",
		groups = {cracky = 2, oddly_breakable_by_hand = 3, not_in_creative_inventory = (dist == min_dist and 0 or 1)},
		sounds = default.node_sound_stone_defaults(),
		drop = "mesecons_extras:mesecon_receiver_off_2",

		on_construct = on_construct,
		on_rightclick = on_rightclick,
		on_punch = distance_change(dist, "off"),
 		on_rotate = on_rotate,

		after_place_node = function(pos, placer, itemstack, pointed_thing)
			if not placer then
				return
			end

			local pitch = placer:get_look_pitch() * (180 / math.pi)

			local node = minetest.get_node(pos)
			if pitch > 55 then
				node.param2 = 8
				minetest.swap_node(pos, node)
			elseif pitch < -55 then
				node.param2 = 4
				minetest.swap_node(pos, node)
			end
		end,

		mesecons = {
			receptor = {
				state = mesecon.state.off,
				rules = mesecon.rules.default
			},
			effector = {
				rules = get_input_rules(dist),
				action_on = function(pos, node)
					node.name = "mesecons_extras:mesecon_receiver_on_" .. dist
					minetest.swap_node(pos, node)
					mesecon.receptor_on(pos, mesecon.rules.default)
				end
			}
		}
	})

	minetest.register_node("mesecons_extras:mesecon_receiver_on_" .. dist, {
		description = "Directional Mesecon Signal Receive (ON)",
		tiles = {
			"mesecons_extras_receiver_side" .. dist .. "_on.png^[transformR180",
			"mesecons_extras_receiver_side" .. dist .. "_on.png",
			"mesecons_extras_receiver_side" .. dist .. "_on.png^[transformR90",
			"mesecons_extras_receiver_side" .. dist .. "_on.png^[transformR270",
			"mesecons_extras_receiver_back_on.png",
			"mesecons_extras_receiver_front_on.png"
		},
		paramtype2 = "facedir",
		groups = {cracky = 2, oddly_breakable_by_hand = 3, not_in_creative_inventory = 1},
		sounds = default.node_sound_stone_defaults(),
		drop = "mesecons_extras:mesecon_receiver_off_2",

		on_rightclick = on_rightclick,
		on_punch = distance_change(dist, "on"),
 		on_rotate = on_rotate,

		mesecons = {
			receptor = {
				state = mesecon.state.on,
				rules = mesecon.rules.default
			},
			effector = {
				rules = get_input_rules(dist),
				action_off = function(pos, node)
					node.name = "mesecons_extras:mesecon_receiver_off_" .. dist
					minetest.swap_node(pos, node)
					mesecon.receptor_off(pos, mesecon.rules.default)
				end
			}
		}
	})
end
minetest.register_alias("mesecons_extras:mesecon_receiver", "mesecons_extras:mesecon_receiver_off_2")


--------------------------------------
-- Craft recipe definitions
--------------------------------------
minetest.register_craft({
	output = "mesecons_extras:mesecon_receiver_off_2 1",
	recipe = {
		{"default:mese_crystal_fragment", "default:mese_crystal_fragment", "default:mese_crystal_fragment"},
		{"",                              "default:mese_crystal_fragment", ""},
		{"default:steel_ingot",           "mesecons:mesecon",              "default:steel_ingot"},
	}
})


--------------------------------------
-- Backwards compatibility
--------------------------------------
minetest.register_lbm({
	name = "mesecons_extras:receiver_erase_formspec",
	nodenames = {
		"mesecons_extras:mesecon_receiver_off_2",
		"mesecons_extras:mesecon_receiver_off_3",
		"mesecons_extras:mesecon_receiver_off_4",
		"mesecons_extras:mesecon_receiver_on_2",
		"mesecons_extras:mesecon_receiver_on_3",
		"mesecons_extras:mesecon_receiver_on_4"
	},
	run_at_every_load = true,
	action = function(pos, node)
		local meta = minetest.get_meta(pos)
		if meta:get_string("formspec") then
			meta:set_string("formspec", nil)
		end
	end
})
