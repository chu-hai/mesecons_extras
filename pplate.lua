local S = mesecons_extras.getter

local intl = {}
intl.s_desc = S("Stone Pressure Plate")
intl.w_desc = S("Wooden Pressure Plate")


if not minetest.get_modpath("player_events") then
	minetest.log("warning", "[Mesecons Extras] Pressure plates needs player_events mod.")
end

--------------------------------------
-- Default datas
--------------------------------------
local default_nbox_off = {
	type = "fixed",
	fixed = {
		{-0.4375, -0.5, -0.4375, 0.4375, -0.4375, 0.4375},
		{-0.3125, -0.4375, -0.3125, 0.3125, -0.375, 0.3125},
	}
}

local default_nbox_on = {
	type = "fixed",
	fixed = {
		{-0.4375, -0.5, -0.4375, 0.4375, -0.4375, 0.4375},
		{-0.3125, -0.4375, -0.3125, 0.3125, -0.406355, 0.3125},
	}
}

local default_sbox = {
	type = "fixed",
	fixed = {
		{-0.4375, -0.5, -0.4375, 0.4375, -0.375, 0.4375},
	}
}


--------------------------------------
-- Functions
--------------------------------------
local function step_in(name_on)
	return function(pos)
		local node = minetest.get_node(pos)
		node.name = name_on
		minetest.swap_node(pos, node)
		mesecon.receptor_on(pos, mesecon.rules.pplate)
		minetest.sound_play("mesecons_extras_click", {pos = pos, max_hear_distance = 8, gain = 0.6})
	end
end

local function step_out(name_off)
	return function(pos)
		local node = minetest.get_node(pos)
		node.name = name_off
		minetest.swap_node(pos, node)
		mesecon.receptor_off(pos, mesecon.rules.pplate)
	end
end

--------------------------------------
-- Global Functions
--------------------------------------
function mesecons_extras.register_pressureplate(basename, description, recipe, output_count,
												tiles_off, tiles_on,
												nodebox_off, nodebox_on,
												selection_box, inv_image, wield_image)
 	local nodename = basename
 	local nodename_off = nodename.."_off"
 	local nodename_on = nodename.."_on"


	for _, stat in pairs({"off", "on"}) do
		local tmp_name
		local tmp_tiles
		local tmp_nbox
		local tmp_groups
		local tmp_mesecon_state
		local tmp_stepin_func
		local tmp_stepout_func

		if stat == "off" then
			tmp_name = nodename_off
			tmp_tiles = table.copy(tiles_off)
			tmp_nbox = nodebox_off and table.copy(nodebox_off) or default_nbox_off
			tmp_groups = {snappy = 2, oddly_breakable_by_hand = 3}

			tmp_mesecon_state = mesecon.state.off
			tmp_stepin_func = step_in(nodename_on)
			tmp_stepout_func = nil
		else
			tmp_name = nodename_on
			tmp_tiles = table.copy(tiles_on)
			tmp_nbox = nodebox_on and table.copy(nodebox_on) or default_nbox_on
			tmp_groups = {snappy = 2, oddly_breakable_by_hand = 3, not_in_creative_inventory = 1}

			tmp_mesecon_state = mesecon.state.on
			tmp_stepin_func = nil
			tmp_stepout_func = step_out(nodename_off)
		end

		minetest.register_node(tmp_name, {
			description = description,
			drawtype = "nodebox",
			inventory_image = inv_image,
			wield_image = wield_image,
			tiles = tmp_tiles,
			selection_box = selection_box and table.copy(nodebox_on) or default_sbox,
			node_box = tmp_nbox,

			paramtype = "light",

			groups = tmp_groups,
			drop = nodename_off,

			on_playerevents_step_in = tmp_stepin_func,
			on_playerevents_step_out = tmp_stepout_func,

			sounds = default.node_sound_wood_defaults(),
			mesecons = {receptor = {
				state = tmp_mesecon_state,
				rules = mesecon.rules.pplate
			}}
		})
	end

	minetest.register_craft({
		output = string.format("%s %d", nodename_off, output_count or 1),
		recipe = recipe,
	})

	minetest.register_alias(nodename, nodename_off)
end


--------------------------------------
-- Register Pressure plates
--------------------------------------
local stone_tiles_off = {
	"mesecons_extras_pplate_stone_top_off.png",
	"mesecons_extras_pplate_stone_bottom.png",
	"mesecons_extras_pplate_stone_side_off.png",
}

local stone_tiles_on = {
	"mesecons_extras_pplate_stone_top_on.png",
	"mesecons_extras_pplate_stone_bottom.png",
	"mesecons_extras_pplate_stone_side_on.png",
}

local stone_recipe = {{"default:cobble", "mesecons:mesecon", "default:cobble"}}

mesecons_extras.register_pressureplate("mesecons_extras:stone_pplate", intl.s_desc,
										stone_recipe, 1, stone_tiles_off, stone_tiles_on)


local wood_tiles_off = {
	"mesecons_extras_pplate_wood_top_off.png",
	"mesecons_extras_pplate_wood_bottom.png",
	"mesecons_extras_pplate_wood_side_off.png",
}

local wood_tiles_on = {
	"mesecons_extras_pplate_wood_top_on.png",
	"mesecons_extras_pplate_wood_bottom.png",
	"mesecons_extras_pplate_wood_side_on.png",
}

local wood_recipe = {{"default:wood", "mesecons:mesecon", "default:wood"}}

mesecons_extras.register_pressureplate("mesecons_extras:wooden_pplate", intl.w_desc,
										wood_recipe, 1, wood_tiles_off, wood_tiles_on)
