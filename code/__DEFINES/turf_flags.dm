/// Defers call of proc AfterChange in ChangeTurf.
#define CHANGETURF_DEFER_CHANGE (1 << 0)
/// This flag prevents changeturf from gathering air from nearby turfs to fill the new turf with an approximation of local air
#define CHANGETURF_IGNORE_AIR (1 << 1)
/// Prevents ChangeTurf from returning without an operation if the given path and baseturfs are identical to the pre-existing ones and the preloader is not engaged.
#define CHANGETURF_FORCEOP (1 << 2)
/// A flag for PlaceOnTop to just instance the new turf instead of calling ChangeTurf. Used for uninitialized turfs NOTHING ELSE
#define CHANGETURF_SKIP (1 << 3)
/// Inherit air from previous turf. Implies CHANGETURF_IGNORE_AIR
#define CHANGETURF_INHERIT_AIR (1 << 4)
/// Immediately recalc adjacent atmos turfs instead of queuing.
#define CHANGETURF_RECALC_ADJACENT (1 << 6)
/// Defers smoothing and starlight recalculation in ChangeTurf so that they may later be more performantly done in bulk.
#define CHANGETURF_DEFER_BATCH (1 << 7)

/// Effects
#define TURF_EFFECT_AFFECTABLE (1 << 6)
