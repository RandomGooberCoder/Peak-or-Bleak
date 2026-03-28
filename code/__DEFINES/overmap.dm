/// The filepath used to store the admin-controlled next round outpost map override.
#define SAFEZONE_OVERRIDE_FILEPATH "data/safezone_override.json"

/// Amount of times the overmap generator will attempt to place something before giving up
#define MAX_OVERMAP_PLACEMENT_ATTEMPTS 5

/// The fraction of non-voters that will be added to the transfer option when the vote is finalized.
#define TRANSFER_FACTOR clamp((world.time / (1 MINUTES) - 120) / 240, 0, 1)

#define OVERMAP_GENERATOR_NONE "none"
#define OVERMAP_GENERATOR_SOLAR "solar_system"
#define OVERMAP_GENERATOR_RANDOM "random"
#define OVERMAP_GENERATOR_JSON "json"

///Used to get the turf on the "physical" overmap representation.
#define OVERMAP_TOKEN_TURF(x_pos, y_pos, system) locate(system.overmap_vlevel.low_x + system.overmap_vlevel.reserved_margin + x_pos - 1, system.overmap_vlevel.low_y + system.overmap_vlevel.reserved_margin + y_pos - 1, system.overmap_vlevel.z_value)

//Used by ships
#define INTERACTION_OVERMAP_DOCK "Dock to Specific Location"
#define INTERACTION_OVERMAP_QUICKDOCK "Quick Dock"
#define INTERACTION_OVERMAP_HAIL "Hail"
#define INTERACTION_OVERMAP_INTERDICTION "Reverse Dock (Interdiction)"
//Used by empty space
#define INTERACTION_OVERMAP_SETSIGNALSPRITE "Set Signal Appearance"
//Used by jump points
#define INTERACTION_OVERMAP_JUMPTO "Bluespace Jump to Target System"
//Used to end an interaction if a target object has them
#define INTERACTION_OVERMAP_SELECTED "ERROR" //use this to end the interaction without failing

//All the 'shipmodules' a ship can have.
#define SHIPMODULE_BSDRIVE "bluespace_drive"
#define SHIPMODULE_HELMCONSOLE "helm_console"
#define SHIPMODULE_TRANSPONDER "transponder"
#define SHIPMODULE_CLOAKING "cloaking"

// Burn direction defines
#define BURN_NONE 0
#define BURN_STOP -1

// Ship join modes. The string values are player-facing, so be careful modifying them. Be sure to update ShipSelect.js if you add to/change these!
#define SHIP_JOIN_MODE_CLOSED "Locked"
#define SHIP_JOIN_MODE_APPLY "Apply"
#define SHIP_JOIN_MODE_OPEN "Open"

// Ship application states. Some of the string values are player-facing, so be careful modifying them.
#define SHIP_APPLICATION_UNFINISHED "unfinished"
#define SHIP_APPLICATION_CANCELLED "cancelled"
#define SHIP_APPLICATION_PENDING "pending"
#define SHIP_APPLICATION_ACCEPTED "accepted"
#define SHIP_APPLICATION_DENIED "denied"

#define ORES_TO_COLORS_LIST list()

GLOBAL_LIST_INIT(planet_names, null)

GLOBAL_LIST_INIT(planet_prefixes, null)

///Name of the file used for ship name random selection, if any new categories are added be sure to add them to the schema, too!
#define SHIP_NAMES_FILE "ship_names.json"
