local S = mesecons_extras.getter

local intl = {}
intl.desc = S("Switch")


--------------------------------------
-- Functions
--------------------------------------
local function switch_turn_on(name_on)
	return function(pos, node)
		minetest.swap_node(pos, {name = name_on, param2=node.param2})
		mesecon.receptor_on(pos, mesecon.rules.buttonlike_get(node))
		minetest.sound_play("mesecons_extras_click", {pos=pos})
	end
end

local function switch_turn_off(name_off)
	return function(pos, node)
		minetest.swap_node(pos, {name = name_off, param2=node.param2})
		mesecon.receptor_off(pos, mesecon.rules.buttonlike_get(node))
		minetest.sound_play("mesecons_extras_click", {pos=pos})
	end
end

local function register_switch(basename, description, drawtype, recipe, output_count,
							   tiles_off, tiles_on,
							   nodebox_off, nodebox_on,
							   mesh_off, mesh_on,
							   selection_box, inv_image, wield_image)

 	local nodename = basename
 	local nodename_off = nodename .. "_off"
 	local nodename_on = nodename .. "_on"

	for _, stat in pairs({"off", "on"}) do
		local tmp_name
		local tmp_tiles
		local tmp_nbox
		local tmp_mesh
		local tmp_groups
		local tmp_light_source
		local tmp_mesecon_state
		local tmp_change_state

		if stat == "off" then
			tmp_name = nodename_off
			tmp_tiles = table.copy(tiles_off)
			tmp_mesh = mesh_off
			tmp_nbox = nodebox_off and table.copy(nodebox_off) or nil
			tmp_groups = {cracky = 2, oddly_breakable_by_hand = 3, mesecon_needs_receiver = 1}
			tmp_light_source = 0
			tmp_mesecon_state = mesecon.state.off
			tmp_change_state = switch_turn_on(nodename_on)
		else
			tmp_name = nodename_on
			tmp_tiles = table.copy(tiles_on)
			tmp_mesh = mesh_on
			tmp_nbox = nodebox_on and table.copy(nodebox_on) or nil
			tmp_groups = {cracky = 2, oddly_breakable_by_hand = 3, mesecon_needs_receiver = 1, not_in_creative_inventory = 1}
			tmp_light_source = 8
			tmp_mesecon_state = mesecon.state.on
			tmp_change_state = switch_turn_off(nodename_off)
		end

		minetest.register_node(tmp_name, {
			description = description,
			drawtype = drawtype,
			inventory_image = inv_image,
			wield_image = wield_image,
			tiles = tmp_tiles,
			selection_box = selection_box,
			node_box = tmp_nbox,
			mesh = tmp_mesh,

			paramtype = "light",
			paramtype2 = "facedir",
			legacy_wallmounted = true,
			walkable = false,
			sunlight_propagates = true,
			light_source = tmp_light_source,

			groups = tmp_groups,
			drop = nodename_off,

			on_punch = tmp_change_state,
			on_rightclick = tmp_change_state,

			sounds = default.node_sound_stone_defaults(),
			mesecons = {receptor = {
				state = tmp_mesecon_state,
				rules = mesecon.rules.buttonlike_get
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
-- Global Functions
--------------------------------------
function mesecons_extras.register_normal_switch(basename, description, recipe, output_count,
												tiles_off, tiles_on, inv_image, wield_image)
	register_switch(basename, description, "normal", recipe, output_count,
					tiles_off, tiles_on,
					nil, nil,
					nil, nil,
					nil, inv_image, wield_image)
end


function mesecons_extras.register_nodebox_switch(basename, description, recipe, output_count,
												 tiles_off, tiles_on,
												 nodebox_off, nodebox_on,
												 selection_box, inv_image, wield_image)
	register_switch(basename, description, "nodebox", recipe, output_count,
					tiles_off, tiles_on,
					nodebox_off, nodebox_on,
					nil, nil,
					selection_box, inv_image, wield_image)
end

function mesecons_extras.register_mesh_switch(basename, description, recipe, output_count,
											  tiles_off, tiles_on,
											  mesh_off, mesh_on,
											  selection_box, inv_image, wield_image)
	register_switch(basename, description, "mesh", recipe, output_count,
					tiles_off, tiles_on,
					nil, nil,
					mesh_off, mesh_on,
					selection_box, inv_image, wield_image)
end

--------------------------------------
-- Register switch
--------------------------------------
local sw_off_tiles = {
	"mesecons_extras_switch_top.png",
	"mesecons_extras_switch_bottom.png",
	"mesecons_extras_switch_right.png",
	"mesecons_extras_switch_left.png",
	"mesecons_extras_switch_back.png",
	"mesecons_extras_switch_off.png"
}

local sw_on_tiles = {
	"mesecons_extras_switch_top.png",
	"mesecons_extras_switch_bottom.png",
	"mesecons_extras_switch_right.png",
	"mesecons_extras_switch_left.png",
	"mesecons_extras_switch_back.png",
	"mesecons_extras_switch_on.png"
}


local sw_off_nodebox = {
	type = "fixed",
	fixed = {
		{-0.3125, -0.4375, 0.4375, 0.3125, 0.4375, 0.5},
		{-0.0625, -0.125, 0.375, 0.0625, 0, 0.4375}
	}
}

local sw_on_nodebox = {
	type = "fixed",
	fixed = {
		{-0.3125, -0.4375, 0.4375, 0.3125, 0.4375, 0.5},
		{-0.0625, 0, 0.375, 0.0625, 0.125, 0.4375}
	}
}

local sw_selection_box = {
	type = "fixed",
	fixed = {-0.3125, -0.4375, 0.4375, 0.3125, 0.4375, 0.5}
}

local sw_recipe = {
	{"default:steel_ingot", "stairs:slab_stone", "default:steel_ingot"},
	{"mesecons:mesecon",    "",                  "mesecons:mesecon"}
}

mesecons_extras.register_nodebox_switch("mesecons_extras:switch", intl.desc, sw_recipe, 2,
										sw_off_tiles, sw_on_tiles,
										sw_off_nodebox, sw_on_nodebox,
										sw_selection_box)
