local S = mesecons_extras.getter

local intl = {}
intl.mux_desc   = S("Mesecon Multiplexer")
intl.demux_desc = S("Mesecon Demultiplexer")
intl.channel = S("Channel No.")
intl.save = S("Save")

local digiline_rules = {mux = {}, demux = {}}
local mesecon_rules  = {mux = {}, demux = {}}

local CHANNEL_PREFIX = "mesecons_extras_mux_"

if not minetest.get_modpath("digilines") then
	minetest.log("warning", "[Mesecons Extras] Multiplexer needs digilines mod.")
	return
end


--------------------------------------
-- Functions
--------------------------------------
local function create_digiline_rules()
	local function set_rules(base_rules, target)
		for param2 = 0, 3 do
			local rules = table.copy(base_rules)
			for i = 0, param2 do
				rules = digiline:rotate_rules_left(rules)
			end
			target[#target + 1] = rules
		end
	end

	set_rules({{x =  1, y = 0, z = 0}}, digiline_rules.demux)
	set_rules({{x = -1, y = 0, z = 0}}, digiline_rules.mux)
end

local function create_mesecon_rules()
	local function set_rules(base_rules, target)
		for param2 = 0, 3 do
			local rules = table.copy(base_rules)
			for i = 0, param2 do
				rules = mesecon.rotate_rules_left(rules)
			end
			target[#target + 1] = rules
		end
	end

	local demux_rules = {
		{x =  0, y = 0, z = -1, name="red"},
		{x = -1, y = 0, z =  0, name="green"},
		{x =  0, y = 0, z =  1, name="blue"},
	}
	local mux_rules = {
		{x =  0, y = 0, z = -1, name="red"},
		{x =  1, y = 0, z =  0, name="green"},
		{x =  0, y = 0, z =  1, name="blue"},
	}
	set_rules(demux_rules, mesecon_rules.demux)
	set_rules(mux_rules,   mesecon_rules.mux)
end

local function get_digiline_rules(m_type)
	return function(node)
		return digiline_rules[m_type][node.param2 + 1]
	end
end

local function get_mesecon_output_rules(m_type, red, green, blue)
	return function(node)
		local rules = mesecon_rules[m_type][node.param2 + 1]
		local result = {}
		if red then
			result[#result + 1] = rules[1]
		end
		if green then
			result[#result + 1] = rules[2]
		end
		if blue then
			result[#result + 1] = rules[3]
		end
		return result
	end
end

local function get_mesecon_input_rules(m_type)
	return function(node)
		return mesecon_rules[m_type][node.param2 + 1]
	end
end

local function update_infotext(pos, desc)
	local meta = minetest.get_meta(pos)
	meta:set_string("infotext", desc .. "\n" .. intl.channel .. meta:get_int("channel_no"))
end

local function update_formspec(pos, desc)
	local meta = minetest.get_meta(pos)
	local ch_list = "1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16"
	local ch_idx = meta:get_int("channel_no")

	meta:set_string("formspec", "size[6,2]" ..
		"bgcolor[#00000000]" ..
 		"background[0,0;6,2;mesecons_extras_form_bg.png;true]" ..
 		"label[0,0;" .. desc .. "]" ..
		"label[1,0.8;" .. intl.channel .. "]" ..
		"dropdown[1,1.3;3;channel_no;" .. ch_list .. ";" .. ch_idx .. "]" ..
		"button_exit[4,1.3;2,0.8;save;" .. intl.save .. "]"
 	)
end

local function on_construct(desc)
	return function(pos)
		local meta = minetest.get_meta(pos)
		meta:set_int("channel_no", 1)
		update_formspec(pos, desc)
		update_infotext(pos, desc)
	end
end

local function on_rotate(pos, node, user, mode, new_param2)
	local result = mesecons_extras.rotate_simple(pos, node, user, mode, new_param2)
	digiline:update_autoconnect(pos)
	return result
end

local function on_punch(desc)
	return function(pos, node, puncher)
		update_formspec(pos, desc)
		update_infotext(pos, desc)
	end
end

local function on_receive_fields(desc)
	return function(pos, formname, fields, sender)
		if mesecons_extras.is_protected(pos, sender) then
			return
		end

		local meta = minetest.get_meta(pos)
		if fields.save then
			meta:set_int("channel_no", fields.channel_no)
			update_formspec(pos, desc)
			update_infotext(pos, desc)
		end
	end
end

local function update_node(m_type, pos, node, msg, change_mesecon_signal)
	local defs = minetest.registered_nodes[node.name]
	local stats = {
		r = defs.stats.red,
		g = defs.stats.green,
		b = defs.stats.blue
	}
	local msg = string.split(msg, ":")
	local output_rule = {}

	if msg[2] == "R" then
		stats.r = msg[1] == "ON"
		output_rule = get_mesecon_output_rules(m_type, true, false, false)(node)
	elseif msg[2] == "G" then
		stats.g = msg[1] == "ON"
		output_rule = get_mesecon_output_rules(m_type, false, true, false)(node)
	elseif msg[2] == "B" then
		stats.b = msg[1] == "ON"
		output_rule = get_mesecon_output_rules(m_type, false, false, true)(node)
	end

	if change_mesecon_signal then
		if msg[1] == "ON" then
			mesecon.receptor_on(pos, output_rule)
		else
			mesecon.receptor_off(pos, output_rule)
		end
	end

	node.name = "mesecons_extras:signal_" .. m_type
	if stats.r or stats.g or stats.b then
		node.name = node.name .. "_" .. (stats.r and "R" or "") .. (stats.g and "G" or "") .. (stats.b and "B" or "")
	end
	minetest.swap_node(pos, node)
end

local function digiline_receive(m_type)
	return function(pos, node, channel, msg)
		local meta = minetest.get_meta(pos)
		local channel_str = CHANNEL_PREFIX .. meta:get_int("channel_no")

		if channel == channel_str then
			update_node(m_type, pos, node, msg, true)
		end
	end
end

local function create_digiline_message(color, stat)
	local msg_color = {
		["red"]   = "R",
		["green"] = "G",
		["blue"]  = "B",
	}
	return (stat and "ON" or "OFF") .. ":" .. msg_color[color]
end

local function mesecon_action(m_type, stat)
	return function(pos, node, rule)
		local meta = minetest.get_meta(pos)
		local msg = create_digiline_message(rule.name, stat)
		local channel = CHANNEL_PREFIX .. meta:get_int("channel_no")
		update_node(m_type, pos, node, msg, false)
		digiline:receptor_send(pos, get_digiline_rules(m_type)(node), channel, msg)
	end
end

local function register_node(m_type, desc)
	local top_tile = "mesecons_extras_" .. m_type .. "_top.png"
	local tiles
	local digiline_defs
	local mesecon_defs

	if m_type == "mux" then
		tiles = {
			top_tile,
			top_tile .. "^[transformFY",
			"mesecons_extras_" .. m_type .. "_side_blue_off.png",
			"mesecons_extras_" .. m_type .. "_side_red_off.png",
			"mesecons_extras_" .. m_type .. "_side_digiline.png",
			"mesecons_extras_" .. m_type .. "_side_green_off.png"
		}
		digiline_defs = {
			receptor = {rules = get_digiline_rules(m_type)},
		}
		mesecon_defs = {
			effector = {
				rules = get_mesecon_input_rules(m_type),
				action_change = function (pos, node, rule, newstate)
					if newstate == "on" then
						mesecon_action(m_type, true)(pos, node, rule)
					end
				end
 			}
 		}
	else
		tiles = {
			top_tile,
			top_tile .. "^[transformFY",
			"mesecons_extras_" .. m_type .. "_side_blue_off.png",
			"mesecons_extras_" .. m_type .. "_side_red_off.png",
			"mesecons_extras_" .. m_type .. "_side_green_off.png",
			"mesecons_extras_" .. m_type .. "_side_digiline.png"
		}
		digiline_defs = {
			effector = {
				rules = get_digiline_rules(m_type),
				action = digiline_receive(m_type)
			}
		}
		mesecon_defs = {
			receptor = {
				state = mesecon.state.off,
				rules = get_mesecon_output_rules(m_type, true, true, true)
			}
 		}
	end

	minetest.register_node("mesecons_extras:signal_" .. m_type, {
		description = desc,
		inventory_image = top_tile,
		wield_image = top_tile,
		tiles = tiles,
		drawtype = "nodebox",
		node_box = {
			type = "fixed",
			fixed = {
				{-0.5, -0.5, -0.5, 0.5, -0.375, 0.5},
			}
		},

		paramtype = "light",
		paramtype2 = "facedir",
		sunlight_propagates = true,
		walkable = true,
		groups = {cracky = 2, oddly_breakable_by_hand = 3},
		sounds = default.node_sound_stone_defaults(),
		stats = {},

		on_construct = on_construct(desc),
		on_rotate = on_rotate,
		on_punch = on_punch(desc),
		on_receive_fields = on_receive_fields(desc),

 		digiline = digiline_defs,
 		mesecons = mesecon_defs
	})

	for _, r in ipairs({true, false}) do
	for _, g in ipairs({true, false}) do
	for _, b in ipairs({true, false}) do
		if r or g or b then
			local tiles
			local top_on_tile = top_tile
			local side_r_tile = "mesecons_extras_" .. m_type .. "_side_red_off.png"
			local side_g_tile = "mesecons_extras_" .. m_type .. "_side_green_off.png"
			local side_b_tile = "mesecons_extras_" .. m_type .. "_side_blue_off.png"
			local suffix = ""
			local stats = {}

			if r then
				side_r_tile = "mesecons_extras_" .. m_type .. "_side_red_on.png"
				top_on_tile = top_on_tile .. "^mesecons_extras_" .. m_type .. "_top_red_on.png"
				suffix = suffix .. "R"
				stats.red = true
			end
			if g then
				side_g_tile = "mesecons_extras_" .. m_type .. "_side_green_on.png"
				top_on_tile = top_on_tile .. "^mesecons_extras_" .. m_type .. "_top_green_on.png"
				suffix = suffix .. "G"
				stats.green = true
			end
			if b then
				side_b_tile = "mesecons_extras_" .. m_type .. "_side_blue_on.png"
				top_on_tile = top_on_tile .. "^mesecons_extras_" .. m_type .. "_top_blue_on.png"
				suffix = suffix .. "B"
				stats.blue = true
			end

			if m_type == "mux" then
				tiles = {
					top_on_tile,
					top_on_tile .. "^[transformFY",
					side_b_tile,
					side_r_tile,
					"mesecons_extras_" .. m_type .. "_side_digiline.png",
					side_g_tile
				}
 				digiline_defs = {
 					receptor = {rules = get_digiline_rules(m_type)},
 				}
 				mesecon_defs = {
 					effector = {
 						rules = get_mesecon_input_rules(m_type),
						action_change = function (pos, node, rule, newstate)
							mesecon_action(m_type, newstate == "on")(pos, node, rule)
						end
 					}
 				}
			else
				tiles = {
					top_on_tile,
					top_on_tile .. "^[transformFY",
					side_b_tile,
					side_r_tile,
					side_g_tile,
					"mesecons_extras_" .. m_type .. "_side_digiline.png"
				}
 				digiline_defs = {
					effector = {
						rules = get_digiline_rules(m_type),
						action = digiline_receive(m_type)
					}
 				}
 				mesecon_defs = {
 					receptor = {
 						state = mesecon.state.on,
 						rules = get_mesecon_output_rules(m_type, r, g, b)
 					},
					effector = {
						rules = get_mesecon_input_rules(m_type)
					}
 				}
			end

			minetest.register_node("mesecons_extras:signal_" .. m_type .. "_" .. suffix, {
				description = desc .. " (ON)",
				tiles = tiles,
				drawtype = "nodebox",
				node_box = {
					type = "fixed",
					fixed = {
						{-0.5, -0.5, -0.5, 0.5, -0.375, 0.5},
					}
				},

				paramtype = "light",
				paramtype2 = "facedir",
				sunlight_propagates = true,
				walkable = true,
				groups = {cracky = 2, oddly_breakable_by_hand = 3, not_in_creative_inventory = 1},
				sounds = default.node_sound_stone_defaults(),
				stats = stats,
				drop = "mesecons_extras:signal_" .. m_type,

				on_rotate = screwdriver.disallow,
				on_punch = on_punch(desc),
				on_receive_fields = on_receive_fields(desc),

				digiline = digiline_defs,
				mesecons = mesecon_defs
			})
		end
	end
	end
	end
end


--------------------------------------
-- Node definitions
--------------------------------------
create_digiline_rules()
create_mesecon_rules()

register_node("mux", intl.mux_desc)
register_node("demux", intl.demux_desc)


--------------------------------------
-- Craft recipe definitions
--------------------------------------
minetest.register_craft({
	output = "mesecons_extras:signal_mux",
	recipe = {
		{"default:steel_ingot", "digilines:wire_std_00000000",              "default:steel_ingot"},
		{"mesecons:mesecon",    "mesecons_luacontroller:luacontroller0000", "mesecons:mesecon"},
		{"default:steel_ingot", "mesecons:mesecon",                         "default:steel_ingot"}
	}
})

minetest.register_craft({
	output = "mesecons_extras:signal_demux",
	recipe = {
		{"default:steel_ingot", "mesecons:mesecon",                         "default:steel_ingot"},
		{"mesecons:mesecon",    "mesecons_luacontroller:luacontroller0000", "mesecons:mesecon"},
		{"default:steel_ingot", "digilines:wire_std_00000000",              "default:steel_ingot"}
	}
})
