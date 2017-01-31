local modpath = minetest.get_modpath(minetest.get_current_modname())
local worldpath = minetest.get_worldpath()

mesecons_extras = {}

-- Support intllib
if minetest.get_modpath("intllib") then
	mesecons_extras.getter = intllib.Getter()
else
	mesecons_extras.getter = function(s) return s end
end

-- Load settings
mesecons_extras.settings = {
	enable_basic_circuits = true,
	enable_inv_checker = true,
	enable_switches = true,
	enable_transmitter = true,
	enable_pressure_plate = true,
	enable_multiplexer = true,

	inv_checker_interval = 1.0
}

for name, v in pairs(mesecons_extras.settings) do
	local setting_data = nil
	local setting_name = "mesecons_extras." .. name
	if type(v) == "boolean" then
		setting_data = minetest.setting_getbool(setting_name)
	else
		setting_data = minetest.setting_get(setting_name)
		if type(v) == "number" then
			setting_data = tonumber(setting_data)
		end
	end

	if setting_data ~= nil then
		mesecons_extras.settings[name] = setting_data
	end
end

-- Load modules
local module_names = {
	enable_basic_circuits = {
		"clock",
		"pulse",
		"counter",
		"delayer",
		"toggle"
	},
	enable_inv_checker = {
		"inv_checker",
	},
	enable_switches = {
		"button",
		"switch"
	},
	enable_transmitter = {
		"transmitter",
		"receiver"
	},
	enable_pressure_plate = {
		"pplate"
	},
	enable_multiplexer = {
		"multiplexer"
	}
}

dofile(modpath.."/functions.lua")
dofile(modpath.."/material.lua")
for name, modules in pairs(module_names) do
	if mesecons_extras.settings[name] then
		for _, filename in ipairs(modules) do
			dofile(modpath .. "/" .. filename .. ".lua")
		end
	end
end

-- Register function for ActionQueue
mesecon.queue:add_function("mesecons_extras_change_status", function (pos, status, before, after, rules, meta_updates)
	if not status or not before or not after or not rules then
		return
	end

	local node = minetest.get_node(pos)
	if node.name ~= before then
		return
	end
	node.name = after
	minetest.swap_node(pos, node)
	if status == "on" then
		mesecon.receptor_on(pos, rules)
	else
		mesecon.receptor_off(pos, rules)
	end

	if meta_updates then
		local meta = minetest.get_meta(pos)
		for k,v in pairs(meta_updates) do
			local t = type(v)
			if t == "string" then
				meta:set_string(k, v)
			elseif t == "number" then
				if math.floor(v) == v then
					meta:set_int(k, v)
				else
					meta:set_float(k, v)
				end
			end
		end

		-- update_infotext
		local func = minetest.registered_items[after].do_update_infotext
		if func then
			func(meta)
		end
	end
end)


minetest.log("action", "[Mesecons Extras] Loaded!")
