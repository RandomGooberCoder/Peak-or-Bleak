/datum/overmap_star_system/safezone
	name = "safezone"
	has_outpost = TRUE

	//main colors, used for dockable terrestrials, and background
	primary_color = "#ffffdf"
	secondary_color = "#828282"

	//hazard colors, used for the overmap hazards and sun
	hazard_primary_color = "#a2b210"
	hazard_secondary_color = "#5757c5"

	//structure colors, used for ships and outposts/colonies
	primary_structure_color = "#fbaa51"
	secondary_structure_color = "#fb1010"

	override_object_colors = TRUE
	overmap_icon_state = "overmap"

	//dont want ruinhunters in the safe sector...
	max_overmap_dynamic_events = 0

//example of json loading 'static star systems', AKA premapped beforehand
/datum/overmap_star_system/safezone/json_example
	name = "Independent - Lymantria Teagarden Memorial"

	//overridden by the json file, but probably useful to have this here as an example
	dynamic_probabilities = list(\
		DYNAMIC_WORLD_BEACHPLANET = 10,
		DYNAMIC_WORLD_SPACERUIN = 5,
		DYNAMIC_WORLD_MOON = 20,
		)

	//json loading spawns the outpost during loading, no need to spawn it with this var
	has_outpost = FALSE

	//meant for example purposes, dont actually load this during a live round
	can_be_selected_randomly = FALSE

	//has jump point helpers in here
	can_jump_to = FALSE

	//the json file itself, you can change the directory of this if '_maps/sectors/*_starsystem.json' isn't a good enough naming scheme
	json = '_maps/sectors/teagarden_starsystem.json'

	//to avoid loading shit on top of hte map, and to copy the system information from the file
	generator_type = OVERMAP_GENERATOR_JSON
