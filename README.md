    Primaeval rocks form the road’s steep border,
        And much have they faced there, first and last,
    Of the transitory in Earth’s long order;
        But what they record in colour and cast
            Is—that we two passed. 
		 
    - At Castle Boterel, by Thomas Hardy

## Anchorstone

Native Anchorstone is a strange and magical "ore" that forms from rock that has rested so long in one place that it has in some very real way become comfortable there. Its properties are otherwise similar to normal stone in this state.

It is only when it is wrenched from that location by artificial means that the strength of this bond becomes apparent. Anchorstone that has been cut from its preferred place and moved somewhere else is called Displaced Anchorstone and the connection to its original location produces a powerful mystical "tension." You may witness the occasional buildup and release of sparks along this vector of tension as tiny particles touching the Anchorstone are spontaneously caught up and pulled by it.

This bond may be exploited in a more controlled form with the use of an Anchorstone Trigger, an arcane device that can hook into it and allow itself to be dragged along the line of tension to the Anchorstone's original source location.

If you're exploring some deep and distant cavern and you find a deposit of Native Anchorstone, retrieve a piece and you'll have a "gateway" back to that location from wherever you install it. Note that such paths are strictly one-way, however. You'll need to find Native Anchorstone at both ends if you want to establish a two-way connection.

It's also possible to craft a weaker version of the Anchorstone Trigger, the Anchorstone Reader, that can't be used for travel but that will reveal the destination that a Displaced Anchorstone will send a Trigger to.

## Optional features

Anchorstone triggers can be set by server admins to suffer wear from use, making travel costly. This is disabled by default.

Displaced Anchorstone can be "reset" into Native Anchorstone form via a recipe that costs Mese shards and four buckets of lava. This allows players to establish Anchorstone connections to any arbitrary location they want by creating Native Anchorstone, placing it, and then digging it to form Displaced Anchorstone with that new location as its source. This is enabled by default.

Anchorstone ore is enabled by default, causing small clusters of Native Anchorstone to be scattered throughout the deeps. This can be disabled.

## API

``anchorstone.place_displaced_anchorstone_node(pos, destination_pos)`` will place a Displaced Anchorstone node on the map at ``pos`` with a destination set to ``destination_pos``. Note that Displaced Anchorstone that is created with an ordinary ``minetest.set_node`` call will revert to Native Anchorstone since it won't have a destination set in its metadata.

``anchorstone.create_displaced_anchorstone_item(destination_pos)`` returns an ItemStack containing a Displaced Anchorstone node with its destination set to ``destination_pos``. Creating a Displaced Anchorstone ItemStack without using this function will cause the Displaced Anchorstone to revert to Native Anchorstone when placed, since it will have no destination set in its metadata. 
