-- Custom rotate function
function mesecons_extras.rotate_simple(pos, node, user, mode, new_param2)
	if mode == screwdriver.ROTATE_FACE then
		mesecon.on_dignode(pos, node)	-- remove old connections

		node.param2 = new_param2
		minetest.swap_node(pos, node)
		mesecon.on_placenode(pos, node)
	end

	return mode == screwdriver.ROTATE_FACE
end
