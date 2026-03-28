#define GENERIC_SATELLITE_MESSAGE "NOTICE: Local sector authorities prohibit tampering with satellite. Aborting."
/**
 * # Fluff Object
 *
 * These overmap objects for decoration, unlike /datum/overmap/customizable_object these are premade, and as such are prefered over those for use in static sectors.
 */
/datum/overmap/fluff
	name = "overmap fluff"
	token_icon_state = "customizable"
	char_rep = "~"

	///Fluff means no real interactions
	interaction_options = null

	///Some fluff objects have dir sprites, this is kept in case they are used
	var/dir

	//TODO: move this to /datum/overmap
	///Changes the color taken from the star system when the system's override_object_colors is on.
	var/overmap_color_type = null

	///You can set a custom message when a ship attempts to dock, for flavor
	var/docking_message

	/// Simple var that toggles the flag overlay outposts have on/off, intended to show that this place is "inhabited"
	var/flag_overlay = FALSE

/datum/overmap/fluff/alter_token_appearance()
	. = ..()

	if(flag_overlay)
		token.cut_overlays()
		token.add_overlay("colonized")
	if(dir)
		token.setDir(dir)
	//TODO: move this to /datum/overmap
	if(!current_overmap.override_object_colors)
		return
	//fallback if overmap_color_type is not set
	if(!overmap_color_type)
		token.color = current_overmap.secondary_structure_color

	current_overmap.post_edit_token_state(src)

/datum/overmap/fluff/pre_docked(datum/overmap/dock_requester, override_dock)
	if(!docking_message)
		return ..()
	return new /datum/docking_ticket(_docking_error = docking_message)

// customizable objects serve no purpose other than for mappers to customize the objects saved into jsons exactly how they want.
/datum/overmap/fluff/customizable_object
	name = "rename me"
	token_icon_state = "customizable"

/datum/overmap/fluff/customizable_object/alter_token_appearance()
	. = ..()
	if(!desc)
		desc = {"
		[span_boldnotice("To customize this object for preperation to export it")]
		[span_notice("View Variables")] this object.
		[span_notice("Select option")] --> [span_notice("View Variables Of Parent Datum")].
		Edit the vars '[span_notice("name, desc, token_icon_state, interference_power, overmap_color_type, default_color, and/or docking_message")]'
		If during editing you need to see the icon state update, call [span_notice("alter_token_appearance()")] with no arguments on the datum.
		After this, the object should up as-is once you import it ingame.
		"}
