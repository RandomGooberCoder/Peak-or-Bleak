/datum/planet_type
	///The name we show on examine
	var/name = "planet"
	///The description we show on examine
	var/desc = "A planet."
	///The ID tag this planet uses. Depreciated
	var/planet = null
	///The ID  tag for the set of ruins this planet uses
	var/ruin_type = null
	///The mapgen we set when we are used
	var/mapgen = null
	///The fallback turf if mapgen fails.
	var/default_baseturf = null
	///The gravity we set. If higher than 1, slowdown effects will be applied
	var/gravity = 0
	///The weather we set when we are used
	var/weather_controller_type = null
	///The icon state on the token
	var/icon_state = "globe"
	///The color we set the token to, note this is overridden by fancy overmaps
	var/color = "#ffffff"
	///Our weight when picking a new overmap object
	var/weight = 40
	///Do we not self destruct when a ship undocks with no players left behind?
	var/preserve_level = FALSE
	///The sound we play when we are landed on. Not recommended outside of stingers.
	var/landing_sound
	///We read from this list to let players know the most common ores on this planet, otherwise does nothing.
	var/list/primary_ores
	///Do we 'selfloop' like the overmap? Probably should only enable this on space levels
	var/selfloop = FALSE
	///How much of a radio message we mess up on nearby or on landed/orbitting ships
	var/interference_power = 0

/datum/planet_type/asteroid

/datum/planet_type/spaceruin
