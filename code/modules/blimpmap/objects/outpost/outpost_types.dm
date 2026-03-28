/*
	Map templates
*/

/datum/map_template/outpost
	// Necessary to stop planetary outposts from having space underneath all their turfs.
	// They were being "placed on top", so instead of their baseturf, there was just space underneath.
	// (Interestingly, this is much less of a problem for ruins: PlaceOnTop ignores the top closed turf in the baseturfs stack
	// of the new tile, meaning that placing plating on top of a wall doesn't result in a wall underneath the plating.)
	should_place_on_top = FALSE
	var/outpost_name = "Fallback Outpost"
	var/outpost_administrator = "Fallback Administration"

/datum/map_template/outpost/New(path, rename, cache)
	. = ..(path = "_maps/outpost/[name].dmm")

/datum/map_template/outpost/hangar
	var/dock_width
	var/dock_height

/datum/map_template/outpost/elevator_test
	name = "elevator_test"

/datum/map_template/outpost/elevator_indie
	name = "elevator_indie"

/datum/map_template/outpost/elevator_ice
	name = "elevator_ice"

/datum/map_template/outpost/elevator_rock
	name = "elevator_rock"

/datum/map_template/outpost/elevator_clip
	name = "elevator_clip"

/datum/map_template/outpost/elevator_cybersun
	name = "elevator_cybersun"

/*
	Independent Space Outpost //creative name!
*/
/datum/map_template/outpost/indie_space
	name = "indie_space"
	outpost_name = "Installation Trifuge"
	outpost_administrator = "Caldwell"

/datum/map_template/outpost/hangar/indie_space_20x20
	name = "hangar/indie_space_20x20"
	dock_width = 20
	dock_height = 20

/datum/map_template/outpost/hangar/indie_space_40x20
	name = "hangar/indie_space_40x20"
	dock_width = 40
	dock_height = 20

/datum/map_template/outpost/hangar/indie_space_40x40
	name = "hangar/indie_space_40x40"
	dock_width = 40
	dock_height = 40

/datum/map_template/outpost/hangar/indie_space_56x20
	name = "hangar/indie_space_56x20"
	dock_width = 56
	dock_height = 20

/datum/map_template/outpost/hangar/indie_space_56x40
	name = "hangar/indie_space_56x40"
	dock_width = 56
	dock_height = 40

/datum/overmap/outpost/no_main_level // For example and adminspawn.
	main_template = null
	elevator_template = /datum/map_template/outpost/elevator_test
	// Uses "test" hangars.
