local modpath = minetest.get_modpath(minetest.get_current_modname())
local worldpath = minetest.get_worldpath()

mesecons_extras = {}

-- Support intllib
if minetest.get_modpath("intllib") then
	mesecons_extras.getter = intllib.Getter()
else
	mesecons_extras.getter = function(s) return s end
end

-- Load config file
local m_conf_file = modpath.."/mesecons_extras.conf"
local w_conf_file = worldpath.."/mesecons_extras.conf"
if file_exists(w_conf_file) then
	minetest.log("action", "[Mesecons Extras] Configuration file found at world directory.")
	mesecons_extras.config = Settings(w_conf_file)
elseif file_exists(m_conf_file) then
	minetest.log("action", "[Mesecons Extras] Configuration file found at mod directory.")
	mesecons_extras.config = Settings(m_conf_file)
end

-- Load modules
dofile(modpath.."/functions.lua")
dofile(modpath.."/material.lua")

local module_names = {
	"clock",
	"pulse",
	"counter",
	"delayer",
	"toggle",
	"button",
	"switch",
	"inv_checker",
	"transmitter",
	"receiver",
	"pplate",
	"multiplexer"
}

for _, name in ipairs(module_names) do
	local enable_load = mesecons_extras.config and (mesecons_extras.config:get_bool("enable_"..name) ~= false)

	if not mesecons_extras.config or enable_load then
		dofile(modpath.."/"..name..".lua")
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
