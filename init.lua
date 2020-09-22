anchorstone = {}

local S = minetest.get_translator()

local stone_sound = default.node_sound_stone_defaults()
local stone_texture = "default_stone.png"
local cobble_texture = "default_stone_block.png"
local anchorstone_trigger_breaks_sound = "default_tool_breaks"

local preserved_source_key = "preserved_source"
local anchorstone_name = "anchorstone:anchorstone"
local anchorstone_displaced_name = "anchorstone:displaced"


local anchorstone_resettable = minetest.settings:get_bool("anchorstone_resettable", true)
local anchorstone_ore = minetest.settings:get_bool("anchorstone_ore", true)
local anchorstone_trigger_uses = tonumber(minetest.settings:get("anchorstone_trigger_uses")) or 0

local trigger_stack_size = 99
local trigger_wear_amount = 0
local trigger_tool_capabilities = nil
if anchorstone_trigger_uses ~= 0 then
	trigger_stack_size = 1
	trigger_wear_amount = math.ceil(65535 / anchorstone_trigger_uses)
	trigger_tool_capabilities = {
        full_punch_interval=1.5,
        max_drop_level=1,
        groupcaps={},
        damage_groups = {},
    }
end

local preserve_anchorstone_meta = function(pos, oldnode, oldmeta, drops)
	local preserved_source = oldmeta[preserved_source_key]
	if preserved_source == nil then
		preserved_source = minetest.pos_to_string(pos)
	end
	for index, itemstack in pairs(drops) do
		if itemstack:get_name() == anchorstone_displaced_name then
			itemstack_meta = itemstack:get_meta()
			itemstack_meta:set_string(preserved_source_key, preserved_source)
			itemstack_meta:set_string("description", S("Anchorstone from @1", preserved_source))
		end
	end
end

minetest.register_node(anchorstone_name, {
	description = S("Native Anchorstone"),
	_doc_items_longdesc = S('A strange mineral that has become mystically bonded to the location in space that it has rested in for so long.'),
	_doc_items_usagehelp = S('When dug out and relocated native anchorstone becomes "displaced" anchorstone. It retains an affinity for the location it was bonded to that can be exploited to teleport objects there, with the right tools.'),
	drawtype = "normal",
	tiles = {stone_texture.."^anchorstone_spark.png"},
	is_ground_content = true,
	node_box = {type="regular"},
	sounds = stone_sound,
	groups = {cracky = 3, stone = 1},
	drop = anchorstone_displaced_name,
	preserve_metadata = preserve_anchorstone_meta,
})

local particle_node_pos_spread = vector.new(0.5,0.5,0.5)
local particle_user_pos_spread = vector.new(0.5,1.5,0.5)
local particle_speed_spread = vector.new(0.1,0.1,0.1)
local min_spark_delay = 30
local max_spark_delay = 120

minetest.register_node(anchorstone_displaced_name, {
	description = S("Displaced Anchorstone"),
	_doc_items_longdesc = S("Anchorstone that bonded to one location but that has been relocated somewhere else."),
	_doc_items_usagehelp = S("Displaced anchorstone would really rather be back in its original location. The bond isn't strong enough to drag it there spontaneously, but the residual spatial tension can be used to teleport other objects there with the right tools."),
	drawtype = "normal",
	tiles = {cobble_texture.."^anchorstone_spark_saturated.png"},
	is_ground_content = true,
	node_box = {type="regular"},
	sounds = stone_sound,
	groups = {cracky = 3, stone = 1, not_in_creative_inventory = 1},
	stack_max = 1,

	preserve_metadata = preserve_anchorstone_meta,
	
	-- Called after constructing node when node was placed using
	-- minetest.item_place_node / minetest.place_node.
	-- If return true no item is taken from itemstack.
	-- `placer` may be any valid ObjectRef or nil.
	after_place_node = function(pos, placer, itemstack, pointed_thing)
		local item_meta = itemstack:get_meta()
		local preserved_source = item_meta:get(preserved_source_key)
		if preserved_source and minetest.string_to_pos(preserved_source) then
			local node_meta = minetest.get_meta(pos)
			node_meta:set_string(preserved_source_key, preserved_source)
			node_meta:mark_as_private(preserved_source_key)
			local node_timer = minetest.get_node_timer(pos)
			node_timer:start(math.random(min_spark_delay, max_spark_delay))
		else
			-- metadata was lost somehow, alas.
			minetest.set_node(pos, {name = anchorstone_name})
		end
	end,
	
	on_blast = function(pos, intensity)
		local meta = minetest.get_meta(pos)
		local preserved_source = meta:get(preserved_source_key)
		if preserved_source then
			local preserved_source_pos = minetest.string_to_pos(preserved_source)
			if preserved_source_pos then
				local item = ItemStack(anchorstone_displaced_name)
				local item_meta = item:get_meta()
				item_meta:set_string(preserved_source_key, preserved_source)
				minetest.item_drop(item, nil, pos)
			end
		end
		minetest.set_node(pos, {name = "air"})
	end,
	
	on_timer = function(pos, elapsed)
		local meta = minetest.get_meta(pos)
		local preserved_source = meta:get(preserved_source_key)
		if preserved_source then
			local preserved_source_pos = minetest.string_to_pos(preserved_source)
			if preserved_source_pos then
				local dir = vector.multiply(vector.direction(pos, preserved_source_pos), 3)
				minetest.add_particlespawner({
					amount = 10,
					time = 0.5,
					minpos = vector.subtract(pos, particle_node_pos_spread),
					maxpos = vector.add(pos, particle_node_pos_spread),
					minvel = vector.subtract(dir, particle_speed_spread),
					maxvel = vector.add(dir, particle_speed_spread),
					minacc = {x=0, y=0, z=0},
					maxacc = {x=0, y=0, z=0},
					minexptime = 1,
					maxexptime = 3,
					minsize = 1,
					maxsize = 1,
					collisiondetection = false,
					vertical = false,
					texture = "anchorstone_spark.png",
				})			

				local node_timer = minetest.get_node_timer(pos)
				node_timer:start(math.random(min_spark_delay, max_spark_delay))
				return
			end
		end
		-- metadata was lost somehow, revert to anchorstone
		minetest.set_node(pos, {name = anchorstone_name})
	end,	
})

local trigger_help_addendum = ""
if anchorstone_trigger_uses > 0 then
	trigger_help_addendum = S(" This tool can be used @1 times before breaking.", anchorstone_trigger_uses)
end

local trigger_def = {
	description = S("Anchorstone Trigger"),
	_doc_items_longdesc = S("A triggering device that allows teleportation via displaced anchorstone."),
	_doc_items_usagehelp = S("When applied to a piece of displaced anchorstone this tool becomes entangled in the connection it has to its original location and is magically dragged there (along with whatever's holding on to it).") .. trigger_help_addendum,
	inventory_image = "anchorstone_spark.png^anchorstone_tool_base.png",
	stack_max = trigger_stack_size,
	tool_capabilites = trigger_tool_capabilities,
	sound = {
		breaks = anchorstone_trigger_breaks_sound,
	},
	on_use = function(itemstack, user, pointed_thing)
		if pointed_thing.type ~= "node" then
			return itemstack
		end
		
		local pos = pointed_thing.under
		local node = minetest.get_node(pos)

		if not node then
			return itemstack
		end
		if node.name ~= anchorstone_displaced_name then
			return itemstack
		end
		
		local node_meta = minetest.get_meta(pos)
		if not node_meta then
			return itemstack
		end

		local preserved_source_string = node_meta:get(preserved_source_key)
		if not preserved_source_string then
			return itemstack
		end
		
		local preserved_pos = minetest.string_to_pos(preserved_source_string)
		if not preserved_pos then
			return itemstack
		end
		
		local old_pos = user:get_pos()
		old_pos.y = old_pos.y + 0.5

		local speed = vector.multiply(vector.direction(old_pos, preserved_pos), 5/0.5)
		minetest.add_particlespawner({
			amount = 100,
			time = 0.1,
			minpos = vector.subtract(old_pos, particle_node_pos_spread),
			maxpos = vector.add(old_pos, particle_user_pos_spread),
			minvel = vector.subtract(speed, particle_speed_spread),
			maxvel = vector.add(speed, particle_speed_spread),
			minacc = {x=0, y=0, z=0},
			maxacc = {x=0, y=0, z=0},
			minexptime = 0.1,
			maxexptime = 0.5,
			minsize = 1,
			maxsize = 1,
			collisiondetection = false,
			vertical = false,
			texture = "anchorstone_spark.png",
		})		
		minetest.sound_play({name="anchorstone_teleport_from"}, {pos = old_pos}, true)
	
		user:set_pos({x=preserved_pos.x, y=preserved_pos.y-0.5, z=preserved_pos.z})
		
		preserved_pos = vector.subtract(preserved_pos, speed)
		minetest.add_particlespawner({
			amount = 100,
			time = 0.1,
			minpos = vector.subtract(preserved_pos, particle_node_pos_spread),
			maxpos = vector.add(preserved_pos, particle_user_pos_spread),
			minvel = vector.subtract(speed, particle_speed_spread),
			maxvel = vector.add(speed, particle_speed_spread),
			minacc = {x=0, y=0, z=0},
			maxacc = {x=0, y=0, z=0},
			minexptime = 0.5,
			maxexptime = 0.5,
			minsize = 1,
			maxsize = 1,
			collisiondetection = false,
			vertical = false,
			texture = "anchorstone_spark.png",
		})
		minetest.sound_play({name="anchorstone_teleport_to"}, {pos = preserved_pos}, true)
		
		if trigger_wear_amount > 0 then
			itemstack:add_wear(trigger_wear_amount)
		end
		
		return itemstack
	end
}

if trigger_tool_capabilities then
	minetest.register_tool("anchorstone:trigger", trigger_def)
else
	minetest.register_craftitem("anchorstone:trigger", trigger_def)
end

minetest.register_craftitem("anchorstone:reader", {
	description = S("Anchorstone Reader"),
	_doc_items_longdesc = S("A much weaker form of the anchorstone trigger, this tool is able to determine the strength and direction of a displaced anchorstone's bond."),
	_doc_items_usagehelp = S("Simply apply this tool to a piece of displaced anchorstone and it will tell you the location it originated from."),
	inventory_image = "anchorstone_spark.png^[colorize:#8888FF:128^anchorstone_tool_base.png",
	on_use = function(itemstack, user, pointed_thing)
		if user == nil then
			return itemstack
		end
		
		if pointed_thing.type ~= "node" then
			return itemstack
		end
		
		local pos = pointed_thing.under
		local node = minetest.get_node(pos)

		if not node then
			return itemstack
		end
		if node.name ~= anchorstone_displaced_name then
			return itemstack
		end
		
		local node_meta = minetest.get_meta(pos)
		if not node_meta then
			return itemstack
		end

		local preserved_source_string = node_meta:get(preserved_source_key)
		if not preserved_source_string then
			return itemstack
		end
		
		local preserved_pos = minetest.string_to_pos(preserved_source_string)
		if not preserved_pos then
			return itemstack
		end

		minetest.chat_send_player(user:get_player_name(), S("Anchorstone origin: @1, @2m away", preserved_source_string, math.floor(vector.distance(pos, preserved_pos))))
		
		return itemstack
	end
})

-- An external API to allow convenient creation of displaced anchorstone by other mods
anchorstone.place_displaced_anchorstone_node = function(pos, destination_pos)
	minetest.set_node(pos, {name = anchorstone_displaced_name})
	local node_meta = minetest.get_meta(pos)
	node_meta:set_string(preserved_source_key, destination_pos)
	node_meta:mark_as_private(preserved_source_key)
	local node_timer = minetest.get_node_timer(pos)
	node_timer:start(math.random(min_spark_delay, max_spark_delay))
end

anchorstone.create_displaced_anchorstone_item = function(destination_pos)
	local item = ItemStack(anchorstone_displaced_name)
	local preserved_source = minetest.pos_to_string(destination_pos)
	itemstack_meta = item:get_meta()
	itemstack_meta:set_string(preserved_source_key, preserved_source)
	itemstack_meta:set_string("description", S("Anchorstone from @1", preserved_source))
	return item
end

----------------------------------------------
-- More default mod dependencies:

minetest.register_craft({
	output = "anchorstone:trigger",
	recipe = {
		{"default:steel_ingot", "default:mese_crystal_fragment", "default:steel_ingot"},
		{"default:mese_crystal_fragment", anchorstone_displaced_name, "default:mese_crystal_fragment"},
		{"default:steel_ingot", "default:mese_crystal_fragment", "default:steel_ingot"}
	}
})

if anchorstone_resettable then
	-- Allows players to do arbitrary anchorstone placement
	minetest.register_craft({
		output = anchorstone_name,
		recipe = {
			{"default:mese_crystal_fragment", "bucket:bucket_lava", "default:mese_crystal_fragment"},
			{"bucket:bucket_lava", anchorstone_displaced_name, "bucket:bucket_lava"},
			{"default:mese_crystal_fragment", "bucket:bucket_lava", "default:mese_crystal_fragment"}
		},
		replacements = {{"bucket:bucket_lava", "bucket:bucket_empty"}, {"bucket:bucket_lava", "bucket:bucket_empty"}, {"bucket:bucket_lava", "bucket:bucket_empty"}, {"bucket:bucket_lava", "bucket:bucket_empty"}},
	})
end

minetest.register_craft({
	output = "anchorstone:reader",
	recipe = {
		{"", "default:steel_ingot", ""},
		{"default:steel_ingot", anchorstone_displaced_name, "default:steel_ingot"},
		{"", "default:steel_ingot", ""}
	}
})

if anchorstone_ore then

	minetest.register_ore({
		ore_type = "scatter",
		ore = anchorstone_name,
		wherein = "default:stone",
		clust_scarcity = 32 * 32 * 32,
		-- Ore has a 1 out of clust_scarcity chance of spawning in a node.
		-- If the desired average distance between ores is 'd', set this to
		-- d * d * d.

		clust_num_ores = 6,
		clust_size = 3,

		y_min = -31000,
		y_max = 64,
	})
end
