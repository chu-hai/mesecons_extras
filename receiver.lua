local S = mesecons_extras.getter

local intl = {}
intl.desc = S("Directional Mesecon Signal Receiver")
intl.mode = S("Fixed Distance Mode")

local min_dist = 2
local max_dist = 4


--------------------------------------
-- Functions
--------------------------------------
local function get_input_rules(dist)
	return function(node)
		return {vector.multiply(minetest.facedir_to_dir(node.param2), -1 * dist)}
	end
end

local function update_formspec(meta)
	local mode = meta:get_string("fixed_mode") == "on" and "true" or "false"

	meta:set_string("formspec", "size[7.4,2]" ..
		"bgcolor[#00000000]" ..
		"background[0,0;7.4,2;mesecons_extras_form_bg.png;true]"..
		"label[0,0;"..intl.desc.."]"..
		"checkbox[1.2,0.8;fixed_mode;"..intl.mode..";"..mode.."]"
	)
end

local function on_construct(pos)
	local meta = minetest.get_meta(pos)

	meta:set_string("fixed_mode", "off")
	update_formspec(meta)
end

local function can_change_distance(pos)
	local result = true
	local meta = minetest.get_meta(pos)
	update_formspec(meta)

	if meta:get_string("fixed_mode") == "on" then
		result = false
	end

	return result
end

local function distance_change(dist, stat)
	return function(pos, node, puncher)
		if can_change_distance(pos) then
			local new_dist = ((dist + 1) > max_dist) and min_dist or dist + 1
			node.name = "mesecons_extras:mesecon_receiver_"..stat.."_"..new_dist
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

local function on_receive_fields(pos, formname, fields)
	local meta = minetest.get_meta(pos)

	if fields.fixed_mode then
		meta:set_string("fixed_mode", (fields.fixed_mode == "true" and "on" or "off"))
		update_formspec(meta)
	end
end


--------------------------------------
-- Node definitions
--------------------------------------
for dist = min_dist, max_dist do
	minetest.register_node("mesecons_extras:mesecon_receiver_off_"..dist, {
		description = intl.desc,
		tiles = {
			"mesecons_extras_receiver_side"..dist.."_off.png^[transformR180",
			"mesecons_extras_receiver_side"..dist.."_off.png",
			"mesecons_extras_receiver_side"..dist.."_off.png^[transformR90",
			"mesecons_extras_receiver_side"..dist.."_off.png^[transformR270",
			"mesecons_extras_receiver_back_off.png",
			"mesecons_extras_receiver_front_off.png"
		},
		paramtype2 = "facedir",
		groups = {snappy = 2, dig_immediate = 2, not_in_creative_inventory = (dist == min_dist and 0 or 1)},
		sounds = default.node_sound_stone_defaults(),
		drop = "mesecons_extras:mesecon_receiver_off_2",

		on_construct = on_construct,
		on_receive_fields = on_receive_fields,
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
					node.name = "mesecons_extras:mesecon_receiver_on_"..dist
					minetest.swap_node(pos, node)
					mesecon.receptor_on(pos, mesecon.rules.default)
				end
			}
		}
	})

	minetest.register_node("mesecons_extras:mesecon_receiver_on_"..dist, {
		description = "Directional Mesecon Signal Receive (ON)",
		tiles = {
			"mesecons_extras_receiver_side"..dist.."_on.png^[transformR180",
			"mesecons_extras_receiver_side"..dist.."_on.png",
			"mesecons_extras_receiver_side"..dist.."_on.png^[transformR90",
			"mesecons_extras_receiver_side"..dist.."_on.png^[transformR270",
			"mesecons_extras_receiver_back_on.png",
			"mesecons_extras_receiver_front_on.png"
		},
		paramtype2 = "facedir",
		groups = {snappy = 2, dig_immediate = 2, not_in_creative_inventory = 1},
		sounds = default.node_sound_stone_defaults(),
		drop = "mesecons_extras:mesecon_receiver_off_2",

		on_receive_fields = on_receive_fields,
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
					node.name = "mesecons_extras:mesecon_receiver_off_"..dist
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
	output = 'mesecons_extras:mesecon_receiver_off_2 1',
	recipe = {
		{"default:mese_crystal_fragment", "default:mese_crystal_fragment", "default:mese_crystal_fragment"},
		{"",                              "default:mese_crystal_fragment", ""},
		{"default:steel_ingot",           "mesecons:mesecon",              "default:steel_ingot"},
	}
})

