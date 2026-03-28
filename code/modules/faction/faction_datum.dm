#define FACTION_SORT_INDEPENDENT 100 // Independents first because of majority
#define FACTION_SORT_DEFAULT 50 // Everything else in the middle
#define FACTION_SORT_ASPAWN 0 // Frontiersmen and Ramzi on the bottom because of rarity

/datum/faction
	var/name
	/// Primarly to be used for backend stuff.
	var/short_name
	/// Parent faction of this faction, used for allowed factions and information
	var/parent_faction
	/// List of prefixes that ships of this faction uses
	var/list/prefixes
	/// List/Typecache of factions that this faction is allowed to interact with. Non-recursive.
	var/list/allowed_factions = list()
	/// The official language of this faction. Galactic Common by default.
	var/official_language = /datum/language/common
	/// Theme color for this faction, currently only used for the wiki
	var/color = "#ffffff"
	/// Contrast color for this faction, used for links on the wiki
	var/contrast_color
	/// Background color for this faction, for use under black text
	var/background_color
	/// Whether or not this faction should be able to use prefixes that aren't their own (see: Frontiersmen using Indie prefixes)
	var/check_prefix = TRUE
	/// Sorting order for factions
	var/order = FACTION_SORT_DEFAULT
	/// Whether or not this faction is hidden from the autowiki ships table (see: Unknown, used for ruins but has no ships)
	var/wiki_hidden = FALSE

/datum/faction/New()
	if(!short_name)
		short_name = uppertext(copytext_char(name, 3))

	if(!contrast_color)
		contrast_color = "#[invert_hex(copytext_char(color, 2))]"
	if(!background_color)
		var/list/hsl = rgb2num(color, COLORSPACE_HSL)
		background_color = rgb(hsl[1], min(hsl[2], 50), max(hsl[3], 66), space=COLORSPACE_HSL)

	//All subtypes of this faction, all subtypes of specifically allowed factions, and SPECIFICALLY the parent faction (no subtypes) are allowed.
	//Try not to nest factions too deeply, yeah?
	allowed_factions += src
	allowed_factions = typecacheof(allowed_factions)
	allowed_factions[parent_faction] = TRUE

/// Easy way to check if something is "allowed", checks to see if it matches the name or faction typepath because factions are a fucking mess
/datum/faction/proc/allowed_faction(value_to_check)
	//do we have the same faction even if one is a define?
	if(value_to_check == name)
		return TRUE
	return is_type_in_typecache(value_to_check, allowed_factions)

/datum/faction/independent
