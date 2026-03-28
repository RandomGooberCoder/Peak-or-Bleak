/*
All ShuttleMove procs go here
*/

/************************************Base procs************************************/

// Called on every turf in the shuttle region, returns a bitflag for allowed movements of that turf
// returns the new move_mode (based on the old)
/turf/proc/fromShuttleMove(turf/newT, move_mode)
	if(!(move_mode & MOVE_AREA) || !isshuttleturf(src))
		return move_mode

	return move_mode | MOVE_TURF | MOVE_CONTENTS

// Called from the new turf before anything has been moved
// Only gets called if fromShuttleMove returns true first
// returns the new move_mode (based on the old)
/turf/proc/toShuttleMove(turf/oldT, move_mode, obj/docking_port/mobile/shuttle)
	. = move_mode
	if(!(. & MOVE_TURF))
		return

	for(var/atom/movable/thing as anything in contents)
		if(ismob(thing))
			if(isliving(thing))
				var/mob/living/M = thing
				if(M.buckled)
					M.buckled.unbuckle_mob(M, 1)
				if(M.pulledby)
					M.pulledby.stop_pulling()
				M.stop_pulling()
				M.visible_message(span_warning("[shuttle] slams into [M]!"))
				SSblackbox.record_feedback("tally", "shuttle_gib", 1, M.type)
				log_attack("[key_name(M)] was shuttle gibbed by [shuttle].")
				if(isanimal(M))
					qdel(M)
				else
					//you're going to get, unequivocally, fucked up
					M.apply_damage(400, BRUTE, forced = TRUE, spread_damage = TRUE)
					M.apply_damage(100, BRUTE, BODY_ZONE_CHEST, forced = TRUE)
					M.apply_damage(100, BRUTE, BODY_ZONE_HEAD, forced = TRUE)
					if(istype(M, /mob/living/carbon))
						var/mob/living/carbon/mob = M // Fix it ~Hal
						//for(var/obj/item/bodypart/limb in mob.bodyparts)
						//	limb.check_wounding(list(WOUND_BLUNT = 50), 50)
					M.spawn_gibs()


		else //non-living mobs shouldn't be affected by shuttles, which is why this is an else
			if(!isobj(thing))
				qdel(thing)
				continue
			var/obj/object = thing
			if(object.resistance_flags & LANDING_PROOF)
				continue
			qdel(thing)

// Called on the old turf to move the turf data
/turf/proc/onShuttleMove(turf/newT, list/movement_force, move_dir, shuttle_layers)
	if(newT == src) // In case of in place shuttle rotation shenanigans.
		return
	//Destination turf changes
	//Baseturfs is definitely a list or this proc wouldnt be called
	var/depth = 0
	for(var/k in 0 to baseturfs.len-2) //2 less than the length because we never want to cut the entire baseturf list.
		if(baseturfs[baseturfs.len-k] != /turf/baseturf_skipover/shuttle)
			continue
		shuttle_layers--
		if(!shuttle_layers)
			depth = k + 1
			break
	if(!depth)
		CRASH("A turf queued to move via shuttle somehow had no skipover in baseturfs. [src]([type]):[loc]")

	//The current type is added to the old baseturfs with CopyOnTop, so the next index after the old turf would be 2 more than the current baseturfs length.
	var/inject_index = islist(newT.baseturfs) ? newT.baseturfs.len + 2 : 3
	newT.CopyOnTop(src, 1, depth, TRUE, CHANGETURF_DEFER_CHANGE)
	var/area/ship/new_loc = get_area(newT)
	if(istype(new_loc) && new_loc.mobile_port) //Keep track of hull breached shuttles
		for(var/i in 0 to new_loc.get_missing_shuttles(newT)) //Start at 0 because get_missing_shuttles() will report 1 less missing shuttle because of the CopyOnTop()
			newT.baseturfs.Insert(inject_index, /turf/baseturf_skipover/shuttle)

	return TRUE

// Called on the new turf after everything has been moved
/turf/proc/afterShuttleMove(turf/oldT, rotation, list/all_towed_shuttles)
	//Dealing with the turf we left behind
	oldT.TransferComponents(src)
	//src.base_icon_state = oldT.base_icon_state
	SEND_SIGNAL(oldT, COMSIG_TURF_AFTER_SHUTTLE_MOVE, src) //Mostly for decals

	if(rotation)
		shuttleRotate(rotation) //see shuttle_rotate.dm

	//find the boundary between the shuttle that left and what remains
	var/area/ship/ship_area = loc
	if(!istype(ship_area))
		return TRUE

	//Only run this code if it's a ship area
	var/obj/docking_port/mobile/top_shuttle = ship_area.mobile_port
	var/shuttle_layers = -1 * ship_area.get_missing_shuttles(src)
	for(var/index in 1 to length(all_towed_shuttles))
		var/obj/docking_port/mobile/M = all_towed_shuttles[index]
		if(!M.underlying_turf_area[src])
			continue
		shuttle_layers++
		if(M == top_shuttle)
			break
	var/BT_index = length(baseturfs)
	var/BT
	for(var/i in 1 to shuttle_layers)
		while(BT_index)
			BT = baseturfs[BT_index--]
			if(BT == /turf/baseturf_skipover/shuttle)
				break
	if(!BT_index && length(baseturfs))
		CRASH("A turf queued to clean up after a shuttle dock somehow didn't have enough skipovers in baseturfs. [oldT]([oldT.type]):[oldT.loc]")

	if(BT_index != length(baseturfs))
		oldT.ScrapeAway(baseturfs.len - BT_index, CHANGETURF_FORCEOP|CHANGETURF_DEFER_CHANGE)

	return TRUE

/turf/proc/lateShuttleMove(turf/oldT)
	AfterChange()
	oldT.AfterChange()


/////////////////////////////////////////////////////////////////////////////////////

// Called on every atom in shuttle turf contents before anything has been moved
// returns the new move_mode (based on the old)
// WARNING: Do not leave turf contents in beforeShuttleMove or dock() will runtime
/atom/movable/proc/beforeShuttleMove(turf/newT, rotation, move_mode, obj/docking_port/mobile/moving_dock)
	SHOULD_CALL_PARENT(TRUE)
	return move_mode

// Called on atoms to move the atom to the new location
/atom/movable/proc/onShuttleMove(turf/newT, turf/oldT, list/movement_force, move_dir, obj/docking_port/stationary/old_dock, obj/docking_port/mobile/moving_dock, list/obj/docking_port/mobile/towed_shuttles)
	SHOULD_CALL_PARENT(TRUE)
	if(newT == oldT) // In case of in place shuttle rotation shenanigans.
		return

	if(loc != oldT) // This is for multi tile objects
		return

	abstract_move(newT)

	return TRUE

// Called on atoms after everything has been moved
/atom/movable/proc/afterShuttleMove(turf/oldT, list/movement_force, shuttle_dir, shuttle_preferred_direction, move_dir, rotation)
	SHOULD_CALL_PARENT(TRUE)
	if(light)
		update_light()
	if(rotation)
		shuttleRotate(rotation)
	update_parallax_contents()
	return TRUE

/atom/movable/proc/lateShuttleMove(turf/oldT, list/movement_force, move_dir)
	SHOULD_CALL_PARENT(TRUE)
	if(!movement_force || anchored)
		return
	var/throw_force = movement_force["THROW"]
	if(!throw_force)
		return
	var/turf/target = get_edge_target_turf(src, move_dir)
	var/range = throw_force * 10
	range = CEILING(rand(range-(range*0.1), range+(range*0.1)), 10)/10
	var/speed = range/5
	safe_throw_at(target, range, speed, force = MOVE_FORCE_EXTREMELY_STRONG)

/////////////////////////////////////////////////////////////////////////////////////

// Called on areas before anything has been moved
// returns the new move_mode (based on the old)
/area/proc/beforeShuttleMove(list/shuttle_areas)
	if(!shuttle_areas[src])
		return NONE
	return MOVE_AREA

// Called on areas to move their turf between areas
/area/proc/onShuttleMove(turf/oldT, turf/newT, area/underlying_old_area)
	if(newT == oldT) // In case of in place shuttle rotation shenanigans.
		return TRUE

	contents -= oldT
	underlying_old_area.contents += oldT
	oldT.change_area(src, underlying_old_area)
	//The old turf has now been given back to the area that turf originaly belonged to

	var/area/old_dest_area = newT.loc
	parallax_movedir = old_dest_area.parallax_movedir

	old_dest_area.contents -= newT
	contents += newT
	newT.change_area(old_dest_area, src)
	return TRUE

// Called on areas after everything has been moved
/area/proc/afterShuttleMove(new_parallax_dir)
	parallax_movedir = new_parallax_dir
	return TRUE

/area/proc/lateShuttleMove()
	return

/************************************Turf move procs************************************/

/************************************Area move procs************************************/

/************************************Machinery move procs************************************/

/************************************Item move procs************************************/

/************************************Mob move procs************************************/

/mob/onShuttleMove(turf/newT, turf/oldT, list/movement_force, move_dir, obj/docking_port/stationary/old_dock, obj/docking_port/mobile/moving_dock, list/obj/docking_port/mobile/towed_shuttles)
	if(!move_on_shuttle)
		return
	. = ..()

/mob/afterShuttleMove(turf/oldT, list/movement_force, shuttle_dir, shuttle_preferred_direction, move_dir, rotation)
	if(!move_on_shuttle)
		return
	. = ..()
	if(client && movement_force)
		var/shake_force = max(movement_force["THROW"], movement_force["KNOCKDOWN"])
		if(buckled)
			shake_force *= 0.25
		shake_camera(src, shake_force, 1)

/mob/living/lateShuttleMove(turf/oldT, list/movement_force, move_dir)
	if(buckled)
		return

	. = ..()

	var/knockdown = movement_force["KNOCKDOWN"]
	if(knockdown)
		Paralyze(knockdown)
/************************************Structure move procs************************************/
/obj/structure/shuttle/beforeShuttleMove(turf/newT, rotation, move_mode, obj/docking_port/mobile/moving_dock)
	. = ..()
	if(. & MOVE_AREA)
		. |= MOVE_CONTENTS

/obj/structure/ladder/beforeShuttleMove(turf/newT, rotation, move_mode, obj/docking_port/mobile/moving_dock)
	. = ..()
	if (!(resistance_flags & INDESTRUCTIBLE))
		disconnect()

/obj/structure/ladder/afterShuttleMove(turf/oldT, list/movement_force, shuttle_dir, shuttle_preferred_direction, move_dir, rotation)
	. = ..()
	if (!(resistance_flags & INDESTRUCTIBLE))
		LateInitialize()

/obj/structure/ladder/onShuttleMove(turf/newT, turf/oldT, list/movement_force, move_dir, obj/docking_port/stationary/old_dock, obj/docking_port/mobile/moving_dock, list/obj/docking_port/mobile/towed_shuttles)
	if (resistance_flags & INDESTRUCTIBLE)
		// simply don't be moved
		return FALSE
	return ..()
/************************************Misc move procs************************************/

/atom/movable/lighting_object/onShuttleMove()
	SHOULD_CALL_PARENT(FALSE)
	return FALSE

/obj/docking_port/mobile/beforeShuttleMove(turf/newT, rotation, move_mode, obj/docking_port/mobile/moving_dock)
	. = ..()
	if(moving_dock == src)
		. |= MOVE_CONTENTS

/obj/docking_port/mobile/onShuttleMove(turf/newT, turf/oldT, list/movement_force, move_dir, obj/docking_port/stationary/old_dock, obj/docking_port/mobile/moving_dock, list/obj/docking_port/mobile/towed_shuttles)
	//while im sure this thing has never ever been set to false, we check for it anyways
	if(!moving_dock.can_move_docking_ports)
		return FALSE
	//are we not being towed by another ship or are we not the ship thats moving? if neither, ignore
	if(!(towed_shuttles[src] || moving_dock == src))
		return FALSE

	return ..()

/obj/docking_port/stationary/onShuttleMove(turf/newT, turf/oldT, list/movement_force, move_dir, obj/docking_port/stationary/old_dock, obj/docking_port/mobile/moving_dock, list/obj/docking_port/mobile/towed_shuttles)
	//while im sure this thing has never ever been set to false, we check for it anyways
	if(!moving_dock.can_move_docking_ports)
		return FALSE
		//Never take our old port
	if(old_dock == src)
		return FALSE
	//Don't take the docking port from the ship we undocked from, either
	if(old_dock && old_dock.owner_ship && old_dock.owner_ship.docked == src)
		return FALSE
	//are we a stationary docking port of the main docking port? if not, we get ignored
	if(!(src in moving_dock.docking_points))
		return FALSE
	//check if we are a docking port of a towed shuttle, if we are, we get towed along when the mainship moves, if not, we get ignored
	for(var/obj/docking_port/mobile/checked_port as anything in towed_shuttles)
		var/port_in_towed_ports = FALSE
		if(src in checked_port.docking_points)
			port_in_towed_ports = TRUE
			break
		//towed_shuttles[docked]: are we towing a docked ship? If so, let us load. The point of this appears to be to let pre-spawned subshuttles work.
		//Basically, if we are not in the towed ports OR towing a ship, dont move us.
		if(!port_in_towed_ports && !towed_shuttles[docked])
			return FALSE
	return ..()
