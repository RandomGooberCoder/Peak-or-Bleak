/datum/weather_controller
	/// What possible weather types will be rolled naturally here, assoc list of type to weight. You'll still be able to call different weathers by events and such
	var/list/possible_weathers
	/// The lowest interval between one naturally occuring weather and another
	var/wait_interval_low = 10 MINUTES
	/// The highest interval between one naturally occuring weather and another
	var/wait_interval_high = 15 MINUTES
	/// What will be the next weather type rolled, rolled before initializing it for barometers
	var/next_weather_type
	/// When will the next weather will be rolled, also read by barometers
	var/next_weather = 0
	/// Current weathers this controller is handling. Associative of type to reference
	var/list/current_weathers
	/// The linked map zone of our controller
	var/datum/map_zone/mapzone
	/// Percentage of how much we're blocking the sky, for the day/night controller to read from
	var/skyblock = 0
	/// A simple cache to make sure we dont call updates with no changes
	var/last_checked_skyblock = 0
	/// Common cache for possible weathers list
	var/static/list/possible_weathers_cache = list()

