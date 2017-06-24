local S = mesecons_extras.getter

local intl = {}
intl.r_desc = S("Round Button")
intl.s_desc = S("Small Button")


--------------------------------------
-- Functions
--------------------------------------
local function button_turn_on(name_off, name_on)
	return function(pos, node)
		minetest.swap_node(pos, {name = name_on, param2=node.param2})
		mesecon.receptor_on(pos, mesecon.rules.buttonlike_get(node))
		minetest.sound_play("mesecons_extras_click", {pos=pos})

		mesecon.queue:add_action(pos, "mesecons_extras_change_status",
			{
				"off",
				name_on,
				name_off,
				mesecon.rules.buttonlike_get(node)
			},
			0.3, nil
		)
	end
end

local function register_button(basename, description, drawtype, recipe, output_count,
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
		local tmp_click

		if stat == "off" then
			tmp_name = nodename_off
			tmp_tiles = table.copy(tiles_off)
			tmp_mesh = mesh_off
			tmp_nbox = nodebox_off and table.copy(nodebox_off) or nil
			tmp_groups = {cracky = 2, oddly_breakable_by_hand = 3, mesecon_needs_receiver = 1}
			tmp_light_source = 0
			tmp_mesecon_state = mesecon.state.off
			tmp_click = button_turn_on(nodename_off, nodename_on)
		else
			tmp_name = nodename_on
			tmp_tiles = table.copy(tiles_on)
			tmp_mesh = mesh_on
			tmp_nbox = nodebox_on and table.copy(nodebox_on) or nil
			tmp_groups = {cracky = 2, oddly_breakable_by_hand = 3, mesecon_needs_receiver = 1, not_in_creative_inventory = 1}
			tmp_light_source = 8
			tmp_mesecon_state = mesecon.state.on
			tmp_click = nil
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

			on_punch = tmp_click,
			on_rightclick = tmp_click,

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
function mesecons_extras.register_normal_button(basename, description, recipe, output_count,
												tiles_off, tiles_on, inv_image, wield_image)
	register_button(basename, description, "normal", recipe, output_count,
					tiles_off, tiles_on,
					nil, nil,
					nil, nil,
					nil, inv_image, wield_image)
end


function mesecons_extras.register_nodebox_button(basename, description, recipe, output_count,
												 tiles_off, tiles_on,
												 nodebox_off, nodebox_on,
												 selection_box, inv_image, wield_image)
	register_button(basename, description, "nodebox", recipe, output_count,
					tiles_off, tiles_on,
					nodebox_off, nodebox_on,
					nil, nil,
					selection_box, inv_image, wield_image)
end

function mesecons_extras.register_mesh_button(basename, description, recipe, output_count,
											  tiles_off, tiles_on,
											  mesh_off, mesh_on,
											  selection_box, inv_image, wield_image)
	register_button(basename, description, "mesh", recipe, output_count,
					tiles_off, tiles_on,
					nil, nil,
					mesh_off, mesh_on,
					selection_box, inv_image, wield_image)
end


--------------------------------------
-- Register button (Round Button)
--------------------------------------
local rb_off_tiles = {
	"mesecons_extras_btn_top.png",
	"mesecons_extras_btn_bottom.png",
	"mesecons_extras_btn_right.png",
	"mesecons_extras_btn_left.png",
	"mesecons_extras_btn_back.png",
	"mesecons_extras_btn_off.png"
}

local rb_on_tiles = {
	"mesecons_extras_btn_top.png",
	"mesecons_extras_btn_bottom.png",
	"mesecons_extras_btn_right.png",
	"mesecons_extras_btn_left.png",
	"mesecons_extras_btn_back.png",
	"mesecons_extras_btn_on.png"
}


local rb_off_nodebox = {
	type = "fixed",
	fixed = {
		{-0.3125, -0.3125, 0.4375, 0.3125, 0.3125, 0.5},
		{-0.1875, -0.375, 0.4375, 0.1875, 0.375, 0.5},
		{-0.375, -0.1875, 0.4375, 0.375, 0.1875, 0.5},
		{-0.1875, -0.1875, 0.375, 0.1875, 0.1875, 0.4375},
		{-0.0625, -0.25, 0.375, 0.0625, 0.25, 0.4375},
		{-0.25, -0.0625, 0.375, 0.25, 0.0625, 0.4375},
	}
}

local rb_on_nodebox = {
	type = "fixed",
	fixed = {
		{-0.3125, -0.3125, 0.4375, 0.3125, 0.3125, 0.5},
		{-0.1875, -0.375, 0.4375, 0.1875, 0.375, 0.5},
		{-0.375, -0.1875, 0.4375, 0.375, 0.1875, 0.5},
		{-0.1875, -0.1875, 0.415, 0.1875, 0.1875, 0.4375},
		{-0.0625, -0.25,   0.415, 0.0625, 0.25, 0.4375},
		{-0.25, -0.0625,   0.415, 0.25, 0.0625, 0.4375},
	}
}

local rb_selection_box = {
	type = "fixed",
	fixed = { -0.375, -0.375, 0.3125, 0.375, 0.375, 0.5 }
}

local rb_recipe = {{"mesecons:mesecon", "stairs:slab_stone", "stairs:slab_stone"}}

mesecons_extras.register_nodebox_button("mesecons_extras:round_button", intl.r_desc, rb_recipe, 2,
										rb_off_tiles, rb_on_tiles,
										rb_off_nodebox, rb_on_nodebox,
										rb_selection_box)

-- Backward compatible
minetest.register_alias("mesecons_extras:button_off", "mesecons_extras:round_button_off")

--------------------------------------
-- Register button (Small Button)
--------------------------------------
local sb_off_tiles = {
	"mesecons_extras_sbtn_top.png",
	"mesecons_extras_sbtn_bottom.png",
	"mesecons_extras_sbtn_right.png",
	"mesecons_extras_sbtn_left.png",
	"mesecons_extras_sbtn_back.png",
	"mesecons_extras_sbtn_off.png"
}

local sb_on_tiles = {
	"mesecons_extras_sbtn_top.png",
	"mesecons_extras_sbtn_bottom.png",
	"mesecons_extras_sbtn_right.png",
	"mesecons_extras_sbtn_left.png",
	"mesecons_extras_sbtn_back.png",
	"mesecons_extras_sbtn_on.png"
}

local sb_off_nodebox = {
	type = "fixed",
	fixed = {
		{-0.25, -0.1875, 0.4375, 0.25, 0.1875, 0.5},
		{-0.125, -0.0625, 0.375, 0.125, 0.0625, 0.5},
	}
}

local sb_on_nodebox = {
	type = "fixed",
	fixed = {
		{-0.25, -0.1875, 0.4375, 0.25, 0.1875, 0.5},
		{-0.125, -0.0625, 0.415, 0.125, 0.0625, 0.5},
	}
}

local sb_selection_box = {
	type = "fixed",
	fixed = {-0.25, -0.1875, 0.4375, 0.25, 0.1875, 0.5}
}

local sb_recipe = {{"mesecons:mesecon", "stairs:slab_stone"}}

mesecons_extras.register_nodebox_button("mesecons_extras:small_button", intl.s_desc, sb_recipe, 2,
										sb_off_tiles, sb_on_tiles,
										sb_off_nodebox, sb_on_nodebox,
										sb_selection_box)
