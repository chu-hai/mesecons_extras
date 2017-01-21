local S = mesecons_extras.getter

minetest.register_craftitem("mesecons_extras:code_clock", {
	image = "mesecons_extras_material_book1.png",
	description=S("Code: Clock Circuit")
})

minetest.register_craftitem("mesecons_extras:code_pulse", {
	image = "mesecons_extras_material_book2.png",
	description=S("Code: Pulse Circuit")
})

minetest.register_craftitem("mesecons_extras:code_counter", {
	image = "mesecons_extras_material_book3.png",
	description=S("Code: Counter Circuit")
})

minetest.register_craftitem("mesecons_extras:code_delayer", {
	image = "mesecons_extras_material_book4.png",
	description=S("Code: Delay Circuit")
})

minetest.register_craftitem("mesecons_extras:code_toggle", {
	image = "mesecons_extras_material_book5.png",
	description=S("Code: Toggle Circuit")
})


minetest.register_craft({
	output = 'mesecons_extras:code_clock',
	recipe = {
		{'default:paper', '', ''},
		{'default:paper', 'default:mese_crystal_fragment', 'dye:black'},
		{'default:paper', '', ''},
	}
})

minetest.register_craft({
	type = "shapeless",
	output = 'mesecons_extras:code_pulse',
	recipe = {'mesecons_extras:code_clock'}
})

minetest.register_craft({
	type = "shapeless",
	output = 'mesecons_extras:code_counter',
	recipe = {'mesecons_extras:code_pulse'}
})

minetest.register_craft({
	type = "shapeless",
	output = 'mesecons_extras:code_delayer',
	recipe = {'mesecons_extras:code_counter'}
})

minetest.register_craft({
	type = "shapeless",
	output = 'mesecons_extras:code_toggle',
	recipe = {'mesecons_extras:code_delayer'}
})

minetest.register_craft({
	type = "shapeless",
	output = 'mesecons_extras:code_clock',
	recipe = {'mesecons_extras:code_toggle'}
})
