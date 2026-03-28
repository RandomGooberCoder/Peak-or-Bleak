////////////////Area flags\\\\\\\\\\\\\\
/// If it's a valid territory for cult summoning or the CRAB-17 phone to spawn
#define VALID_TERRITORY (1<<0)
/// If mining tunnel generation is allowed in this area
#define CAVES_ALLOWED (1<<2)
/// If flora are allowed to spawn in this area randomly through tunnel generation
#define FLORA_ALLOWED (1<<3)
/// If mobs can be spawned by natural random generation
#define MOB_SPAWN_ALLOWED (1<<4)
/// Are you forbidden from teleporting to the area? (centcom, mobs, wizard, hand teleporter)
#define NOTELEPORT (1<<5)
/// Hides area from player Teleport function.
#define HIDDEN_AREA (1<<6)
/// If false, loading multiple maps with this area type will create multiple instances.
#define UNIQUE_AREA (1<<7)
/// Refers to ship areas with docking ports, telling the smoothing subsytem to only smooth tiles within the same ship.
#define SHIP_SMOOTHING (1<<8)
/// If false, allows light bulbs and light tubes to randomly break upon late initialization
#define NO_RANDOM_LIGHT_BREAKAGE (1<<9)
