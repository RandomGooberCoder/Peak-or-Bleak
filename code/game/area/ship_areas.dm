/*

### This file contains a list of all the areas in any potential ship. Format is as follows:

/area/CATEGORY/OR/DESCRIPTOR/NAME 	(you can make as many subdivisions as you want)
	name = "NICE NAME" 				(not required but makes things really nice)
	icon = 'ICON FILENAME' 			(defaults to 'icons/turf/areas.dmi')
	icon_state = "NAME OF ICON" 	(defaults to "unknown" (blank))
	requires_power = FALSE 				(defaults to true)
	ambientsounds = list()				(defaults to grabbing from GENERIC_INDEX on area init.
	override it as "ambientsounds = list('sound/ambience/signal.ogg')" or setting its ambience_index to something else.

NOTE: there are two lists of areas in the end of this file: centcom and station itself. Please maintain these lists valid. --rastaf0

*/


/*-----------------------------------------------------------------------------*/

/area/space
	icon_state = "space"
	requires_power = TRUE
	always_unpowered = TRUE
	dynamic_lighting = DYNAMIC_LIGHTING_DISABLED
	power_light = FALSE
	power_equip = FALSE
	power_environ = FALSE
	area_flags = UNIQUE_AREA | CAVES_ALLOWED | MOB_SPAWN_ALLOWED
	outdoors = TRUE
	flags_1 = CAN_BE_DIRTY_1

/area/space/nearstation
	icon_state = "space_near"
	dynamic_lighting = DYNAMIC_LIGHTING_IFSTARLIGHT

/area/start
	name = "start area"
	icon_state = "start"
	requires_power = FALSE
	dynamic_lighting = DYNAMIC_LIGHTING_DISABLED

/area/testroom
	requires_power = FALSE
	name = "Test Room"
	icon_state = "storage"

/area/hyperspace
	icon_state = "space"
	requires_power = TRUE
	always_unpowered = TRUE
	dynamic_lighting = DYNAMIC_LIGHTING_DISABLED
	power_light = FALSE
	power_equip = FALSE
	power_environ = FALSE
	area_flags = UNIQUE_AREA | CAVES_ALLOWED | MOB_SPAWN_ALLOWED
	outdoors = TRUE
	flags_1 = CAN_BE_DIRTY_1

//EXTRA

/area/asteroid
	name = "Asteroid"
	icon_state = "asteroid"
	area_flags = UNIQUE_AREA | CAVES_ALLOWED | MOB_SPAWN_ALLOWED
	flags_1 = CAN_BE_DIRTY_1
	min_ambience_cooldown = 70 SECONDS
	max_ambience_cooldown = 220 SECONDS

/area/aux_base
	name = "Auxiliary Base Construction"
	icon_state = "aux_base_construction"

// SHIP AREAS //

/area/ship
	dynamic_lighting = DYNAMIC_LIGHTING_FORCED
	always_unpowered = FALSE
	area_flags = VALID_TERRITORY | SHIP_SMOOTHING | NO_RANDOM_LIGHT_BREAKAGE // Loading the same shuttle map at a different time will produce distinct area instances.
	icon_state = "shuttle"
	flags_1 = CAN_BE_DIRTY_1
	/// The mobile port attached to this area
	var/obj/docking_port/mobile/mobile_port

/area/ship/Destroy()
	mobile_port = null
	. = ..()

//Returns how many shuttles are missing a skipovers on a given turf, this usually represents how many shuttles have hull breaches on this turf. This only works if this is the actual area of T when called.
//TODO: optimize this somehow
/area/ship/proc/get_missing_shuttles(turf/T)
	var/i = 0
	var/BT_index = length(T.baseturfs)
	var/area/ship/A
	var/obj/docking_port/mobile/S
	var/list/shuttle_stack = list(mobile_port) //Indexing through a list helps prevent looped directed graph errors.
	while(i++ < shuttle_stack.len)
		S = shuttle_stack[i]
		A = S.underlying_turf_area[T]
		if(istype(A) && A.mobile_port)
			shuttle_stack |= A.mobile_port //This ensures a shuttle is only iterated through once
		.++
	for(BT_index in 1 to length(T.baseturfs))
		if(ispath(T.baseturfs[BT_index], /turf/baseturf_skipover/shuttle))
			.--

/area/ship/PlaceOnTopReact(turf/T, list/new_baseturfs, turf/fake_turf_type, flags)
	. = ..()
	if(!length(new_baseturfs) || !ispath(new_baseturfs[1], /turf/baseturf_skipover/shuttle) || length(new_baseturfs) > 1)
		return //Only add missing baseturfs if a shuttle is landing or player made plating is being added (player made is inferred to be a new_baseturf list of 1 and no fake_turf_type)
	for(var/i in 1 to get_missing_shuttles(T)) //Keep track of shuttles with hull breaches on this turf
		new_baseturfs.Insert(1,/turf/baseturf_skipover/shuttle)

/area/ship/connect_to_shuttle(obj/docking_port/mobile/M)
	link_to_shuttle(M)

/area/ship/proc/link_to_shuttle(obj/docking_port/mobile/M)
	mobile_port = M

/area/ship/proc/reset_shuttle_smoothing(obj/docking_port/mobile/requesting_shuttle)
	if(mobile_port == requesting_shuttle) //We only proceed with smoothing if the mobile ports match.
		//A bit of copypasta since we don't want to run Initialize().
		for(var/turf/updated_turf as turf in src)
			QUEUE_SMOOTH(updated_turf)
			QUEUE_SMOOTH_NEIGHBORS(updated_turf)
		for(var/obj/structure/updated_structure as obj in src)
			if(updated_structure.smooth & (USES_SMOOTHING))
				QUEUE_SMOOTH(updated_structure)
				QUEUE_SMOOTH_NEIGHBORS(updated_structure)
				if(updated_structure.smooth & SMOOTH_DIAGONAL)
					icon_state = ""

/area/ship/virtual_z()
	if(mobile_port)
		return mobile_port.virtual_z()
	return ..()

/// External Areas ///
/area/ship/external
	name = "External"
	icon_state = "space_near"
	dynamic_lighting = DYNAMIC_LIGHTING_IFSTARLIGHT
