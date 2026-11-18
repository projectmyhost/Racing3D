extends Node

var _hover_player: AudioStreamPlayer
var _click_player: AudioStreamPlayer
var _music_player: AudioStreamPlayer
var _sfx_pool: Array[AudioStreamPlayer] = []
const SFX_POOL_SIZE: int = 6
var _pool_index: int = 0

var _sounds: Dictionary = {}

var master_volume: float = 1.0
var music_volume: float = 0.7
var sfx_volume: float = 0.85
var mute_all: bool = false
var music_enabled: bool = true
var sfx_enabled: bool = true

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	_hover_player = AudioStreamPlayer.new()
	_hover_player.bus = "SFX" if _has_bus("SFX") else "Master"
	add_child(_hover_player)

	_click_player = AudioStreamPlayer.new()
	_click_player.bus = "SFX" if _has_bus("SFX") else "Master"
	add_child(_click_player)

	_music_player = AudioStreamPlayer.new()
	_music_player.bus = "Music" if _has_bus("Music") else "Master"
	add_child(_music_player)

	for i in range(SFX_POOL_SIZE):
		var p = AudioStreamPlayer.new()
		p.bus = "SFX" if _has_bus("SFX") else "Master"
		add_child(p)
		_sfx_pool.append(p)

	_load_sound_assets()

	# Connect with SaveManager if already loaded
	if has_node("/root/SaveManager"):
		var sm = get_node("/root/SaveManager")
		if sm.has_signal("settings_changed"):
			sm.settings_changed.connect(_on_settings_changed)
		_sync_from_save_manager()

func _has_bus(bus_name: String) -> bool:
	return AudioServer.get_bus_index(bus_name) != -1

func _sync_from_save_manager() -> void:
	if not has_node("/root/SaveManager"):
		return
	var sm = get_node("/root/SaveManager")
	master_volume = float(sm.get_setting("master_volume", 1.0))
	music_volume = float(sm.get_setting("music_volume", 0.7))
	sfx_volume = float(sm.get_setting("sfx_volume", 0.85))
	mute_all = bool(sm.get_setting("mute_all", false))
	music_enabled = bool(sm.get_setting("music_enabled", true))
	sfx_enabled = bool(sm.get_setting("ui_sfx_enabled", true))
	_apply_audio_volumes()

func _on_settings_changed() -> void:
	_sync_from_save_manager()

func _apply_audio_volumes() -> void:
	var effective_master = 0.0 if mute_all else master_volume
	var effective_music = 0.0 if (mute_all or not music_enabled) else (master_volume * music_volume)
	var effective_sfx = 0.0 if (mute_all or not sfx_enabled) else (master_volume * sfx_volume)

	# Update AudioServer buses if present
	if _has_bus("Master"):
		var master_idx = AudioServer.get_bus_index("Master")
		AudioServer.set_bus_volume_db(master_idx, linear_to_db(max(effective_master, 0.0001)))
		AudioServer.set_bus_mute(master_idx, mute_all)

	if _has_bus("Music"):
		var music_idx = AudioServer.get_bus_index("Music")
		AudioServer.set_bus_volume_db(music_idx, linear_to_db(max(music_volume, 0.0001)))
		AudioServer.set_bus_mute(music_idx, mute_all or not music_enabled)

	if _has_bus("SFX"):
		var sfx_idx = AudioServer.get_bus_index("SFX")
		AudioServer.set_bus_volume_db(sfx_idx, linear_to_db(max(sfx_volume, 0.0001)))
		AudioServer.set_bus_mute(sfx_idx, mute_all or not sfx_enabled)

	# Direct player volume fallbacks
	if _hover_player:
		_hover_player.volume_db = linear_to_db(max(effective_sfx, 0.0001))
	if _click_player:
		_click_player.volume_db = linear_to_db(max(effective_sfx, 0.0001))
	for p in _sfx_pool:
		if p:
			p.volume_db = linear_to_db(max(effective_sfx, 0.0001))
	if _music_player:
		_music_player.volume_db = linear_to_db(max(effective_music, 0.0001))

func _load_sound_assets() -> void:
	var sound_files = {
		"ui_hover": "res://assets/audio/ui_hover.wav",
		"ui_click": "res://assets/audio/ui_click.wav",
		"engine": "res://assets/audio/engine.wav",
		"race_countdown": "res://assets/audio/race_countdown.wav",
		"race_finish": "res://assets/audio/race_finish.wav"
	}

	for key in sound_files.keys():
		var path = sound_files[key]
		if ResourceLoader.exists(path):
			_sounds[key] = load(path)
		else:
			_sounds[key] = _generate_fallback_stream(key)

func _generate_fallback_stream(sound_type: String) -> AudioStreamWAV:
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = 44100
	stream.stereo = false
	
	var samples_count = 4410 # 100ms
	var bytes = PackedByteArray()
	bytes.resize(samples_count * 2)

	var freq = 880.0 if sound_type == "ui_hover" else 440.0
	for i in range(samples_count):
		var t = float(i) / 44100.0
		var env = exp(-t * 20.0)
		var val = sin(2.0 * PI * freq * t) * env * 0.5
		var sample_int = int(clampf(val, -1.0, 1.0) * 32767.0)
		bytes.encode_s16(i * 2, sample_int)

	stream.data = bytes
	return stream

func play_hover_sfx() -> void:
	if mute_all or not sfx_enabled or sfx_volume <= 0.0:
		return
	if _sounds.has("ui_hover") and _sounds["ui_hover"] != null:
		_hover_player.stream = _sounds["ui_hover"]
		_hover_player.play()

func play_click_sfx() -> void:
	if mute_all or not sfx_enabled or sfx_volume <= 0.0:
		return
	if _sounds.has("ui_click") and _sounds["ui_click"] != null:
		_click_player.stream = _sounds["ui_click"]
		_click_player.play()

func play_sfx(sound_name: String) -> void:
	if mute_all or not sfx_enabled or sfx_volume <= 0.0:
		return
	
	var stream = null
	if _sounds.has(sound_name):
		stream = _sounds[sound_name]
	elif _sounds.has("ui_" + sound_name):
		stream = _sounds["ui_" + sound_name]
	elif _sounds.has("race_" + sound_name):
		stream = _sounds["race_" + sound_name]

	if stream != null:
		var p = _sfx_pool[_pool_index]
		_pool_index = (_pool_index + 1) % _sfx_pool.size()
		p.stream = stream
		p.play()

func test_sound() -> void:
	play_click_sfx()

# Setting setters
func set_master_volume(val: float) -> void:
	master_volume = clampf(val, 0.0, 1.0)
	_apply_audio_volumes()

func set_music_volume(val: float) -> void:
	music_volume = clampf(val, 0.0, 1.0)
	_apply_audio_volumes()

func set_sfx_volume(val: float) -> void:
	sfx_volume = clampf(val, 0.0, 1.0)
	_apply_audio_volumes()

func set_mute_all(val: bool) -> void:
	mute_all = val
	_apply_audio_volumes()

func set_music_enabled(val: bool) -> void:
	music_enabled = val
	_apply_audio_volumes()

func set_sfx_enabled(val: bool) -> void:
	sfx_enabled = val
	_apply_audio_volumes()
