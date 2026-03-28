SUBSYSTEM_DEF(mapping)
	name = "Mapping"
	init_order = INIT_ORDER_MAPPING
	flags = SS_NO_FIRE

	var/list/nuke_tiles = list()
	var/list/nuke_threats = list()

	var/datum/map_config/config
	var/datum/map_config/next_map_config
	var/datum/map_adjustment/map_adjustment

	var/map_voted = FALSE

	var/list/map_templates = list()
	var/list/map_load_marks = list() //The game scans thru the map and looks for marks, then adds them to this list for caching

	var/list/ruins_templates = list()
	var/datum/space_level/isolated_ruins_z //Created on demand during ruin loading.

	var/list/shuttle_templates = list()
	var/list/shelter_templates = list()

	var/list/areas_in_z = list()

	var/list/turf/unused_turfs = list()				//Not actually unused turfs they're unused but reserved for use for whatever requests them. "[zlevel_of_turf]" = list(turfs)
	var/list/datum/turf_reservations		//list of turf reservations
	var/list/used_turfs = list()				//list of turf = datum/turf_reservation

	var/list/reservation_ready = list()
	var/clearing_reserved_turfs = FALSE

	// Z-manager stuff
	var/station_start  // should only be used for maploading-related tasks
	var/space_levels_so_far = 0
	///list of all z level datums in the order of their z (z level 1 is at index 1, etc.)
	var/list/datum/space_level/z_list
	///list of all z level indices that form multiz connections and whether theyre linked up or down
	///list of lists, inner lists are of the form: list("up or down link direction" = TRUE)
	var/list/multiz_levels = list()
	var/datum/space_level/transit
	var/datum/space_level/empty_space
	var/num_of_res_levels = 1
	/// True when in the process of adding a new Z-level, global locking
	var/adding_new_zlevel = FALSE

	///this is a list of all the world_traits we have from things like god interventions
	var/list/active_world_traits = list()
	///antag retainer
	var/datum/antag_retainer/retainer

	/// List of all map zones
	var/list/map_zones = list()
	/// Translation of virtual level ID to a virtual level reference
	var/list/virtual_z_translation = list()

	var/list/ship_purchase_list
	var/list/planet_types = list()
	var/list/outpost_templates = list()
	var/list/ruin_types_list = list()
	var/list/ruin_types_probabilities = list()
	var/list/mission_pois = list()

	///All possible biomes in assoc list as type || instance
	var/list/biomes = list()

//dlete dis once #39770 is resolved
/datum/controller/subsystem/mapping/proc/HACK_LoadMapConfig()
	if(!config)
#ifdef FORCE_MAP
		config = load_map_config(FORCE_MAP)
#else
		config = load_map_config(error_if_missing = FALSE)
#endif

/datum/controller/subsystem/mapping/PreInit()
	HACK_LoadMapConfig()
	// After assigning a config datum to var/config, we check which map ajudstment fits the current config
	for(var/datum/map_adjustment/each_adjust as anything in subtypesof(/datum/map_adjustment))
		if(config.map_file && initial(each_adjust.map_file_name) != config.map_file)
			continue
		map_adjustment = new each_adjust() // map_adjustment has multiple procs that'll be called from needed places (i.e. job_change)
		log_world("Loaded '[config.map_file]' map adjustment.")
		break
	return ..()

/datum/controller/subsystem/mapping/Initialize(timeofday)
	retainer = new
	if(initialized)
		return
	if(config.defaulted)
		var/old_config = config
		config = global.config.defaultmap
		if(!config || config.defaulted)
			to_chat(world, "<span class='boldannounce'>Unable to load next or default map config, defaulting to Vanderlin</span>")
			config = old_config
	if(map_adjustment)
		map_adjustment.on_mapping_init()
		log_world("Applied '[map_adjustment.map_file_name]' map adjustment: on_mapping_init()")
	loadWorld()
	repopulate_sorted_areas()
	process_teleport_locs()			//Sets up the wizard teleport locations
	initialize_biomes()
	preloadTemplates()
	// Add the transit level
	transit = add_new_zlevel("Transit/Reserved", list(ZTRAIT_RESERVED = TRUE))
	repopulate_sorted_areas()
	initialize_reserved_level(transit.z_value)
	generate_z_level_linkages()
	return ..()

/datum/controller/subsystem/mapping/proc/generate_z_level_linkages()
	for(var/z_level in 1 to length(z_list))
		generate_linkages_for_z_level(z_level)

/datum/controller/subsystem/mapping/proc/generate_linkages_for_z_level(z_level)
	if(!isnum(z_level) || z_level <= 0)
		return FALSE

	if(multiz_levels.len < z_level)
		multiz_levels.len = z_level

	var/z_above = level_trait(z_level, ZTRAIT_UP)
	var/z_below = level_trait(z_level, ZTRAIT_DOWN)
	if(!(z_above == TRUE || z_above == FALSE || z_above == null) || !(z_below == TRUE || z_below == FALSE || z_below == null))
		stack_trace("Warning, numeric mapping offsets are deprecated. Instead, mark z level connections by setting UP/DOWN to true if the connection is allowed")
	multiz_levels[z_level] = new /list(LARGEST_Z_LEVEL_INDEX)
	multiz_levels[z_level][Z_LEVEL_UP] = !!z_above
	multiz_levels[z_level][Z_LEVEL_DOWN] = !!z_below

/datum/controller/subsystem/mapping/Recover()
	flags |= SS_NO_INIT
	initialized = SSmapping.initialized
	map_templates = SSmapping.map_templates
	ruins_templates = SSmapping.ruins_templates
	shuttle_templates = SSmapping.shuttle_templates
	shelter_templates = SSmapping.shelter_templates
	unused_turfs = SSmapping.unused_turfs
	turf_reservations = SSmapping.turf_reservations
	used_turfs = SSmapping.used_turfs

	config = SSmapping.config
	next_map_config = SSmapping.next_map_config

	clearing_reserved_turfs = SSmapping.clearing_reserved_turfs

	z_list = SSmapping.z_list

	ship_purchase_list = SSmapping.ship_purchase_list
	planet_types = SSmapping.planet_types
	outpost_templates = SSmapping.outpost_templates

#define INIT_ANNOUNCE(X) to_chat(world, "<span class='boldannounce'>[X]</span>"); log_world(X)
/datum/controller/subsystem/mapping/proc/LoadGroup(list/errorList, name, path, files, list/traits, list/default_traits, silent = FALSE)
	. = list()
	var/start_time = REALTIMEOFDAY

	if (!islist(files))  // handle single-level maps
		files = list(files)

	// check that the total z count of all maps matches the list of traits
	var/total_z = 0
	var/list/parsed_maps = list()
	for (var/file in files)
		var/full_path = "_maps/[path]/[file]"
		var/datum/parsed_map/pm = new(file(full_path))
		var/bounds = pm?.bounds
		if (!bounds)
			errorList |= full_path
			continue
		parsed_maps[pm] = total_z  // save the start Z of this file
		total_z += bounds[MAP_MAXZ] - bounds[MAP_MINZ] + 1

	if (!length(traits))  // null or empty - default
		for (var/i in 1 to total_z)
			traits += list(default_traits)
	else if (total_z != traits.len)  // mismatch
		INIT_ANNOUNCE("WARNING: [traits.len] trait sets specified for [total_z] z-levels in [path]!")
		if (total_z < traits.len)  // ignore extra traits
			traits.Cut(total_z + 1)
		while (total_z > traits.len)  // fall back to defaults on extra levels
			traits += list(default_traits)

	// preload the relevant space_level datums
	var/start_z = world.maxz + 1
	var/i = 0
	for (var/level in traits)
		add_new_zlevel("[name][i ? " [i + 1]" : ""]", level, reserve_completely = TRUE)
		++i

	// load the maps
	for (var/P in parsed_maps)
		var/datum/parsed_map/pm = P
		if (!pm.load(1, 1, start_z + parsed_maps[P], no_changeturf = TRUE))
			errorList |= pm.original_path

	log_game("Loaded [name] in [(REALTIMEOFDAY - start_time)/10]s!")

	return parsed_maps

/datum/controller/subsystem/mapping/proc/loadWorld()
	//if any of these fail, something has gone horribly, HORRIBLY, wrong
	var/list/FailedZs = list()

	// ensure we have space_level datums for compiled-in maps
	InitializeDefaultZLevels()

	// load the station
	station_start = world.maxz + 1
	#ifdef TESTING
	INIT_ANNOUNCE("Loading [config.map_name]...")
	#endif

	LoadGroup(FailedZs, "Station", config.map_path, config.map_file, config.traits, ZTRAITS_STATION)

	var/list/otherZ = list()

	if(config.matthios_dungeon)
		otherZ += load_map_config("_maps/map_files/otherz/dungeon.json")

	for(var/map_json in config.other_z)
		otherZ += load_map_config(map_json)

	if(otherZ.len)
		for(var/datum/map_config/OtherZ in otherZ)
			LoadGroup(FailedZs, OtherZ.map_name, OtherZ.map_path, OtherZ.map_file, OtherZ.traits, ZTRAITS_STATION)

	if(SSdbcore.Connect())
		var/datum/DBQuery/query_round_map_name = SSdbcore.NewQuery({"
			UPDATE [format_table_name("round")] SET map_name = :map_name WHERE id = :round_id
		"}, list("map_name" = config.map_name, "round_id" = GLOB.round_id))
		query_round_map_name.Execute()
		qdel(query_round_map_name)

	#ifndef LOWMEMORYMODE
	// TODO: remove this when the DB is prepared for the z-levels getting reordered
	while (world.maxz < (5 - 1) && space_levels_so_far < config.space_ruin_levels)
		++space_levels_so_far
		add_new_zlevel("Empty Area [space_levels_so_far]", ZTRAITS_SPACE)

	#endif

	if(LAZYLEN(FailedZs))	//but seriously, unless the server's filesystem is messed up this will never happen
		var/msg = "RED ALERT! The following map files failed to load: [FailedZs[1]]"
		if(FailedZs.len > 1)
			for(var/I in 2 to FailedZs.len)
				msg += ", [FailedZs[I]]"
		msg += ". Yell at your server host!"
		INIT_ANNOUNCE(msg)
#undef INIT_ANNOUNCE

	// Custom maps are removed after station loading so the map files does not persist for no reason.
	if(config.map_path == "custom")
		fdel("_maps/custom/[config.map_file]")
		// And as the file is now removed set the next map to default.
		next_map_config = load_map_config(default_to_box = TRUE)


/datum/controller/subsystem/mapping/proc/maprotate()
	if(map_voted)
		map_voted = FALSE
		return

	var/players = GLOB.clients.len
	var/list/mapvotes = list()
	//count votes
	var/pmv = CONFIG_GET(flag/preference_map_voting)
	if(pmv)
		for (var/client/c in GLOB.clients)
			var/vote = c.prefs.preferred_map
			if (!vote)
				if (global.config.defaultmap)
					mapvotes[global.config.defaultmap.map_name] += 1
				continue
			mapvotes[vote] += 1
	else
		for(var/M in global.config.maplist)
			mapvotes[M] = 1

	//filter votes
	for (var/map in mapvotes)
		if (!map)
			mapvotes.Remove(map)
		if (!(map in global.config.maplist))
			mapvotes.Remove(map)
			continue
		var/datum/map_config/VM = global.config.maplist[map]
		if (!VM)
			mapvotes.Remove(map)
			continue
		if (VM.voteweight <= 0)
			mapvotes.Remove(map)
			continue
		if (VM.config_min_users > 0 && players < VM.config_min_users)
			mapvotes.Remove(map)
			continue
		if (VM.config_max_users > 0 && players > VM.config_max_users)
			mapvotes.Remove(map)
			continue

		if(pmv)
			mapvotes[map] = mapvotes[map]*VM.voteweight

	var/pickedmap = pickweight(mapvotes)
	if (!pickedmap)
		return
	var/datum/map_config/VM = global.config.maplist[pickedmap]
	message_admins("Randomly rotating map to [VM.map_name]")
	. = changemap(VM)
	if (. && VM.map_name != config.map_name)
		to_chat(world, "<span class='boldannounce'>Map rotation has chosen [VM.map_name] for next round!</span>")

/datum/controller/subsystem/mapping/proc/changemap(datum/map_config/VM)
	if(!VM.MakeNextMap())
		next_map_config = load_map_config(default_to_box = TRUE)
		message_admins("Failed to set new map with next_map.json for [VM.map_name]! Using default as backup!")
		return

	next_map_config = VM
	return TRUE
/*
/datum/controller/subsystem/mapping/proc/preloadTemplates(path = "_maps/templates/") //see master controller setup

	var/list/filelist = flist(path)
	for(var/map in filelist)
		var/datum/map_template/T = new(path = "[path][map]", rename = "[map]")
		map_templates[T.name] = T
*/

//Precache the templates via map template datums, not directly from files
//This lets us preload as many files as we want without explicitely loading ALL of them into cache (ie WIP maps or what have you)
/datum/controller/subsystem/mapping/proc/preloadTemplates()
	preloadRuinTemplates()
	preloadShuttleTemplates()
	load_ship_templates()
	preloadOutpostTemplates()
	for(var/item in subtypesof(/datum/map_template)) //Look for our template subtypes and fire them up to be used later
		var/datum/map_template/template = new item()
		map_templates[template.id] = template


/datum/controller/subsystem/mapping/proc/RequestBlockReservation(width, height, z, type = /datum/turf_reservation, turf_type_override)
	UNTIL((!z || reservation_ready["[z]"]) && !clearing_reserved_turfs)
	var/datum/turf_reservation/reserve = new type
	if(turf_type_override)
		reserve.turf_type = turf_type_override
	if(!z)
		for(var/i in levels_by_trait(ZTRAIT_RESERVED))
			if(reserve.Reserve(width, height, i))
				return reserve
		//If we didn't return at this point, theres a good chance we ran out of room on the exisiting reserved z levels, so lets try a new one
		num_of_res_levels += 1
		var/datum/space_level/newReserved = add_new_zlevel("Transit/Reserved [num_of_res_levels]", list(ZTRAIT_RESERVED = TRUE))
		initialize_reserved_level(newReserved.z_value)
		if(reserve.Reserve(width, height, newReserved.z_value))
			return reserve
	else
		if(!level_trait(z, ZTRAIT_RESERVED))
			qdel(reserve)
			return
		else
			if(reserve.Reserve(width, height, z))
				return reserve
	QDEL_NULL(reserve)

//This is not for wiping reserved levels, use wipe_reservations() for that.
/datum/controller/subsystem/mapping/proc/initialize_reserved_level(z)
	UNTIL(!clearing_reserved_turfs)				//regardless, lets add a check just in case.
	clearing_reserved_turfs = TRUE			//This operation will likely clear any existing reservations, so lets make sure nothing tries to make one while we're doing it.
	if(!level_trait(z,ZTRAIT_RESERVED))
		clearing_reserved_turfs = FALSE
		CRASH("Invalid z level prepared for reservations.")
	var/turf/A = get_turf(locate(16, 16,z))
	var/turf/B = get_turf(locate(world.maxx - 16,world.maxy - 16,z))
	var/block = block(A, B)
	for(var/t in block)
		// No need to empty() these, because it's world init and they're
		// already /turf/open/space/basic.
		var/turf/T = t
		T.flags_1 |= UNUSED_RESERVATION_TURF_1
	unused_turfs["[z]"] = block
	reservation_ready["[z]"] = TRUE
	clearing_reserved_turfs = FALSE

/datum/controller/subsystem/mapping/proc/reserve_turfs(list/turfs)
	for(var/i in turfs)
		var/turf/T = i
		T.empty(RESERVED_TURF_TYPE, RESERVED_TURF_TYPE, null, TRUE)
		LAZYINITLIST(unused_turfs["[T.z]"])
		unused_turfs["[T.z]"] |= T
		T.flags_1 |= UNUSED_RESERVATION_TURF_1
		GLOB.areas_by_type[world.area].contents += T
		CHECK_TICK

//DO NOT CALL THIS PROC DIRECTLY, CALL wipe_reservations().
/datum/controller/subsystem/mapping/proc/do_wipe_turf_reservations()
	UNTIL(initialized)							//This proc is for AFTER init, before init turf reservations won't even exist and using this will likely break things.
	for(var/i in turf_reservations)
		var/datum/turf_reservation/TR = i
		if(!QDELETED(TR))
			qdel(TR, TRUE)
	UNSETEMPTY(turf_reservations)
	var/list/clearing = list()
	for(var/l in unused_turfs)			//unused_turfs is a assoc list by z = list(turfs)
		if(islist(unused_turfs[l]))
			clearing |= unused_turfs[l]
	clearing |= used_turfs		//used turfs is an associative list, BUT, reserve_turfs() can still handle it. If the code above works properly, this won't even be needed as the turfs would be freed already.
	unused_turfs.Cut()
	used_turfs.Cut()
	reserve_turfs(clearing)



/datum/controller/subsystem/mapping/proc/reg_in_areas_in_z(list/areas)
	for(var/B in areas)
		var/area/A = B
		A.reg_in_areas_in_z()

/datum/controller/subsystem/mapping/proc/get_isolated_ruin_z()
	if(!isolated_ruins_z)
		isolated_ruins_z = add_new_zlevel("Isolated Ruins/Reserved", list(ZTRAIT_RESERVED = TRUE, ZTRAIT_ISOLATED_RUINS = TRUE))
		initialize_reserved_level(isolated_ruins_z.z_value)
	return isolated_ruins_z.z_value


//The initialization of all our marks - this is what gets the ball rolling and self-deletes the marks after the maps are loaded
/datum/controller/subsystem/mapping/proc/load_marks()
	var/list/sites = SSmapping.map_load_marks

	if(!LAZYLEN(sites)) //This should never happen unless the base map failed to load or there are 0 marks on the map
		return

	for(var/M in sites) //Start it up
		var/obj/effect/landmark/map_load_mark/mark = M

		if(!LAZYLEN(mark.templates)) //Somehow our templates are empty
			continue

		var/datum/map_template/template = SSmapping.map_templates[pick(mark.templates)] //Find our actual existing template, it should be pre-loaded
		//Pick() should just randomly pick out of the templates list, or just grab the one there if there is only one
		if(istype(template)) //If our template pick failed, it should just abort and not do anything
			if(template.load(get_turf(mark))) //Fire it up. Should use bottom left corner.  This will take the majority of loading time
				LAZYREMOVE(SSmapping.map_load_marks,mark) //Get rid of the mark from our global list of marks
				qdel(mark) //Delete the mark now that the map is loaded
			else
				//Loading the template failed somehow (template.load returned a FALSE), did you spell the paths right?
				log_world("SSMapping: Failed to load template: [template.name] ([template.mappath])")

/datum/controller/subsystem/mapping/proc/add_world_trait(datum/world_trait/trait_type, duration = 30 MINUTES)
	var/datum/world_trait/new_trait = new trait_type
	active_world_traits |= new_trait

	if(duration > 0)
		addtimer(CALLBACK(src, PROC_REF(remove_world_trait), new_trait), duration)

/datum/controller/subsystem/mapping/proc/remove_world_trait(datum/world_trait/trait_to_remove)
	active_world_traits -= trait_to_remove
	qdel(trait_to_remove)

/datum/controller/subsystem/mapping/proc/find_and_remove_world_trait(datum/world_trait/trait_to_remove)
	for(var/datum/world_trait/trait in active_world_traits)
		if(!istype(trait, trait_to_remove))
			continue
		active_world_traits -= trait
		qdel(trait)
		return TRUE
	return FALSE

/proc/has_world_trait(datum/world_trait/trait_type)
	if(!length(SSmapping.active_world_traits))
		return FALSE
	for(var/datum/world_trait/trait in SSmapping.active_world_traits)
		if(!istype(trait, trait_type))
			continue
		return TRUE
	return FALSE

/proc/add_tracked_world_trait_atom(atom/incoming, datum/world_trait/trait_type)
	if(!length(SSmapping.active_world_traits))
		return FALSE
	for(var/datum/world_trait/trait in SSmapping.active_world_traits)
		if(!istype(trait, trait_type))
			continue
		trait.add_tracked(incoming)

/proc/remove_tracked_world_trait_atom(atom/removing, datum/world_trait/trait_type)
	if(!length(SSmapping.active_world_traits))
		return FALSE
	for(var/datum/world_trait/trait in SSmapping.active_world_traits)
		if(!istype(trait, trait_type))
			continue
		trait.remove_tracked(removing)

// SHIT START
/datum/controller/subsystem/mapping/proc/get_map_zone_id(mapzone_id)
	var/datum/map_zone/returned_mapzone
	for(var/datum/map_zone/iterated_mapzone as anything in map_zones)
		if(iterated_mapzone.id == mapzone_id)
			returned_mapzone = iterated_mapzone
			break
	return returned_mapzone

/// Allocates, creates and passes a new virtual level
/datum/controller/subsystem/mapping/proc/create_virtual_level(new_name, list/traits, datum/map_zone/mapzone, width, height, allocation_type = ALLOCATION_FREE, allocation_jump = DEFAULT_ALLOC_JUMP)
	/// Because we add an implicit 1 for the coordinate calcuations.
	width--
	height--
	var/list/allocation_coords = SSmapping.get_free_allocation(allocation_type, width, height, allocation_jump)
	return new /datum/virtual_level(new_name, traits, mapzone, allocation_coords[1], allocation_coords[2], allocation_coords[1] + width, allocation_coords[2] + height, allocation_coords[3])

/// Searches for a free allocation for the passed type and size, creates new physical levels if nessecary.
/datum/controller/subsystem/mapping/proc/get_free_allocation(allocation_type, size_x, size_y, allocation_jump = DEFAULT_ALLOC_JUMP)
	var/list/allocation_list
	var/list/levels_to_check = z_list.Copy()
	var/created_new_level = FALSE
	while(TRUE)
		for(var/datum/space_level/iterated_level as anything in levels_to_check)
			if(iterated_level.allocation_type != allocation_type)
				continue
			allocation_list = find_allocation_in_level(iterated_level, size_x, size_y, allocation_jump)
			if(allocation_list)
				return allocation_list

		if(created_new_level)
			stack_trace("MAPPING: We have failed to find allocation after creating a new level just for it, something went terribly wrong")
			return FALSE
		/// None of the levels could faciliate a new allocation, make a new one
		created_new_level = TRUE
		levels_to_check.Cut()

		var/allocation_name
		switch(allocation_type)
			if(ALLOCATION_FREE)
				allocation_name = "Free Allocation"
			if(ALLOCATION_QUADRANT)
				allocation_name = "Quadrant Allocation"
			if(ALLOCATION_OCTODRANT)
				allocation_name = "Octodrant Allocation"
			else
				allocation_name = "Unaccounted Allocation"

		levels_to_check += add_new_zlevel("Generated [allocation_name] Level", allocation_type = allocation_type)

/// Finds a box allocation inside a Z level. Uses a methodical box boundary check method
/datum/controller/subsystem/mapping/proc/find_allocation_in_level(datum/space_level/level, size_x, size_y, allocation_jump)
	var/target_x = 1
	var/target_y = 1

	/// Sanity
	if(size_x > world.maxx || size_y > world.maxy)
		stack_trace("Tried to find virtual level allocation that cannot possibly fit in a physical level.")
		return FALSE

	/// Methodical trial and error method
	while(TRUE)
		var/upper_target_x = target_x+size_x
		var/upper_target_y = target_y+size_y

		var/out_of_bounds = FALSE
		if((target_x < 1 || upper_target_x > world.maxx) || (target_y < 1 || upper_target_y > world.maxy))
			out_of_bounds = TRUE

		if(!out_of_bounds && level.is_box_free(target_x, target_y, upper_target_x, upper_target_y))
			return list(target_x, target_y, level.z_value) //hallelujah we found the unallocated spot

		if(upper_target_x > world.maxx) //If we can't increment x, then the search is over
			break

		var/increments_y = TRUE
		if(upper_target_y > world.maxy)
			target_y = 1
			increments_y = FALSE
		if(increments_y)
			target_y += allocation_jump
		else
			target_x += allocation_jump

/// Adds new physical space level. DO NOT USE THIS TO LOAD SOMETHING NEW. SSmapping.get_free_allocation() will create any levels nessecary and pass you coordinates to create a new virtual level
/datum/controller/subsystem/mapping/proc/add_new_zlevel(name, traits = list(), z_type = /datum/space_level, allocation_type = ALLOCATION_FREE, reserve_completely = FALSE)
	SHOULD_NOT_SLEEP(TRUE)
	// This proc used to sleep. It caused an infuriating desynchronization: new_z would calculate, the max z would be increased, and then the proc used CHECK_TICK.
	// As a result, two space_levels could be added to the z_list, each believing itself to reside at the same z-coodinate.
	// Watch your fucking race conditions.
	var/new_z = z_list.len + 1
	if (world.maxz < new_z)
		world.incrementMaxZ()
	var/datum/space_level/S = new z_type(new_z, name, traits, allocation_type)
	z_list += S
	if(reserve_completely)
		var/datum/map_zone/mapzone = new(name)
		new /datum/virtual_level(name, traits, mapzone, 1, 1, world.maxx, world.maxy, new_z)
	SEND_GLOBAL_SIGNAL(COMSIG_GLOB_NEW_Z, args)
	generate_linkages_for_z_level(new_z)
	return S

/// Creates and passes a new map zone
/datum/controller/subsystem/mapping/proc/create_map_zone(new_name)
	return new /datum/map_zone(new_name)

#define CHECK_STRING_EXISTS(X) if(!istext(data[X])) { stack_trace("[##X] missing from json!"); continue; }
#define CHECK_LIST_EXISTS(X) if(!islist(data[X])) { stack_trace("[##X] missing from json!"); continue; }
/datum/controller/subsystem/mapping/proc/load_ship_templates()
	ship_purchase_list = list()
	var/list/filelist = flist("_maps/configs/")

	filelist = sortList(filelist)

	for(var/filename in filelist)
		var/file = file("_maps/configs/" + filename)
		if(!file)
			stack_trace("Could not open map config: [filename]")
			continue
		file = file2text(file)
		if(!file)
			stack_trace("Map config is not text: [filename]")
			continue

		var/list/data = json_decode(file)
		if(!data)
			stack_trace("Map config is not json: [filename]")
			continue

		CHECK_STRING_EXISTS("map_name")
		CHECK_STRING_EXISTS("map_path")
		CHECK_LIST_EXISTS("job_slots")
		var/datum/map_template/shuttle/S = new(data["map_path"], data["map_name"], TRUE)
		S.file_name = data["map_path"]
		S.ship_class = data["map_name"]

		if(istext(data["map_short_name"]))
			S.short_name = data["map_short_name"]
		else
			S.short_name = copytext(S.name, 1, 20)

		if(istext(data["token_icon_state"]))
			S.token_icon_state = data["token_icon_state"]

		if(istext(data["faction"]))
			var/type = text2path(data["faction"])
			if(!(type in SSfactions.factions))
				stack_trace("Invalid faction path: [data["faction"]] on [S.name]'s config! Defaulting to Independent.")
			else
				S.faction = SSfactions.factions[type]

		if(!S.faction)
			S.faction = SSfactions.factions[/datum/faction/independent]

		S.category = S.faction.name

		if(istext(data["prefix"]))
			S.prefix = data["prefix"]
		if(istext(data["manufacturer"]))
			S.manufacturer = data["manufacturer"]

		if(S.faction.check_prefix && !(S.prefix in S.faction.prefixes))
			stack_trace("Faction prefix mismatch for [S.faction.name]: [data["prefix"]] on [S.name]'s config!")

		if(!S.prefix)
			S.prefix = S.faction.prefixes[1]

		if(islist(data["namelists"]))
			S.name_categories = data["namelists"]

		if(isnum(data["unique_ship_access"]))
			S.unique_ship_access = data["unique_ship_access"]

		if(istext(data["description"]))
			S.description = data["description"]

		if(islist(data["tags"]))
			S.tags = data["tags"]

		S.job_slots = list()
		var/list/job_slot_list = data["job_slots"]
		for(var/job in job_slot_list)
			var/datum/job/job_slot
			var/value = job_slot_list[job]
			var/slots
			if(isnum(value))
				//job_slot = GLOB.name_occupations[job]
				slots = value
			else if(islist(value))
				var/datum/outfit/job/job_outfit = text2path(value["outfit"])
				if(isnull(job_outfit))
					stack_trace("Invalid job outfit: [value["outfit"]] on [S.name]'s config! Defaulting to assistant clothing.")
					job_outfit = null // COAL
				job_slot = new /datum/job(job, job_outfit)
				job_slot.display_order = length(S.job_slots)
				//job_slot.wiki_page = value["wiki_page"]
				//job_slot.officer = value["officer"]
				slots = value["slots"]

			if(!job_slot || !slots)
				stack_trace("Invalid job slot entry! [job]: [value] on [S.name]'s config! Excluding job.")
				continue

			S.job_slots[job_slot] = slots

		if(isnum(data["limit"]))
			S.limit = data["limit"]

		if(isnum(data["spawn_time_coeff"]))
			S.spawn_time_coeff = data["spawn_time_coeff"]

		if(isnum(data["officer_time_coeff"]))
			S.officer_time_coeff = data["officer_time_coeff"]

		if(isnum(data["starting_funds"]))
			S.starting_funds = data["starting_funds"]

		if(isnum(data["tranist_x_offset"]))
			S.tranist_x_offset = data["tranist_x_offset"]

		if(isnum(data["tranist_y_offset"]))
			S.tranist_y_offset = data["tranist_y_offset"]

		if(isnum(data["enabled"]) && data["enabled"])
			S.enabled = TRUE
			ship_purchase_list[S.name] = S

		if(isnum(data["space_spawn"]) && data["space_spawn"])
			S.space_spawn = TRUE

		shuttle_templates[S.file_name] = S
		map_templates[S.file_name] = S
#undef CHECK_STRING_EXISTS
#undef CHECK_LIST_EXISTS

/datum/controller/subsystem/mapping/proc/preloadRuinTemplates()
	for(var/datum/planet_type/type as anything in subtypesof(/datum/planet_type))
		planet_types[initial(type.planet)] = new type

	for(var/item in sortList(subtypesof(/datum/map_template/ruin), /proc/cmp_ruincost_priority))
		var/datum/map_template/ruin/ruin_type = item
		// screen out the abstract subtypes
		if(!initial(ruin_type.id))
			continue
		var/datum/map_template/ruin/R = new ruin_type()

		map_templates[R.name] = R
		ruins_templates[R.name] = R
		ruin_types_list[R.ruin_type] += list(R.name = R)

		var/list/ruin_entry = list()
		ruin_entry[R] = initial(R.placement_weight)
		ruin_types_probabilities[R.ruin_type] += ruin_entry

/datum/controller/subsystem/mapping/proc/preloadShuttleTemplates()
	for(var/item in subtypesof(/datum/map_template/shuttle))
		var/datum/map_template/shuttle/shuttle_type = item
		if(!(initial(shuttle_type.file_name)))
			continue

		var/datum/map_template/shuttle/S = new shuttle_type()

		shuttle_templates[S.file_name] = S

///Initialize all biomes, assoc as type || instance
/datum/controller/subsystem/mapping/proc/initialize_biomes()
	for(var/biome_path in subtypesof(/datum/biome))
		var/datum/biome/biome_instance = new biome_path()
		biomes[biome_path] += biome_instance

/datum/controller/subsystem/mapping/proc/preloadOutpostTemplates()
	for(var/datum/map_template/outpost/outpost_type as anything in subtypesof(/datum/map_template/outpost))
		var/datum/map_template/outpost/outpost_template = new outpost_type()
		outpost_templates[outpost_template.type] = outpost_template
		map_templates[outpost_template.name] = outpost_template

