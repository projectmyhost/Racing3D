class_name VehicleRegistry
extends RefCounted

# Central Vehicle Registry.
# Maps string identifiers to VehicleConfig resources.
# Adding or removing a vehicle requires zero changes to physics code.

const CONFIGS_DIRECTORY: String = "res://vehicles/configs/"
const DEFAULT_VEHICLE_ID: String = "sedan"

static var _configs_cache: Dictionary = {}
static var _is_initialized: bool = false

static func initialize() -> void:
	if _is_initialized:
		return
	_configs_cache.clear()
	
	# Scan configs directory
	var dir = DirAccess.open(CONFIGS_DIRECTORY)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while not file_name.is_empty():
			if not dir.current_is_dir() and file_name.ends_with(".tres"):
				var full_path = CONFIGS_DIRECTORY + file_name
				var cfg = load(full_path) as VehicleConfig
				if cfg and not cfg.id.is_empty():
					_configs_cache[cfg.id.to_lower()] = cfg
			file_name = dir.get_next()
		dir.list_dir_end()
	
	_is_initialized = true

static func get_config(vehicle_id: String) -> VehicleConfig:
	if not _is_initialized or _configs_cache.is_empty():
		initialize()
		
	var key = vehicle_id.strip_edges().to_lower()
	if _configs_cache.has(key):
		return _configs_cache[key]
		
	# Fallback aliases for legacy names
	match key:
		"starter_gt":
			if _configs_cache.has("sedan"): return _configs_cache["sedan"]
		"apex_cruiser":
			if _configs_cache.has("coupe"): return _configs_cache["coupe"]
		"phantom_turbo", "ghini", "italia", "rb22", "gtr", "veloce":
			if _configs_cache.has("sport"): return _configs_cache["sport"]
			
	if _configs_cache.has(DEFAULT_VEHICLE_ID):
		return _configs_cache[DEFAULT_VEHICLE_ID]
		
	if _configs_cache.size() > 0:
		return _configs_cache.values()[0]
		
	push_error("VehicleRegistry: No vehicle configs found in " + CONFIGS_DIRECTORY)
	return null

static func has_config(vehicle_id: String) -> bool:
	if not _is_initialized:
		initialize()
	var key = vehicle_id.strip_edges().to_lower()
	return _configs_cache.has(key)

static func get_all_ids() -> Array[String]:
	if not _is_initialized:
		initialize()
	var ids: Array[String] = []
	for k in _configs_cache.keys():
		ids.append(k)
	return ids

static func get_all_configs() -> Array[VehicleConfig]:
	if not _is_initialized:
		initialize()
	var list: Array[VehicleConfig] = []
	for v in _configs_cache.values():
		list.append(v)
	return list

static func register_config(config: VehicleConfig) -> void:
	if not _is_initialized:
		initialize()
	if config and not config.id.is_empty():
		_configs_cache[config.id.to_lower()] = config

