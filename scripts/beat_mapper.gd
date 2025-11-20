extends Node

# ==========================
# Señales
# ==========================
signal recording_started()
signal recording_stopped()
signal map_saved(path: String)

# ==========================
# Tipos de moles
# ==========================
enum MoleType {
	NORMAL,    # J - Mole normal
	BONUS,     # K - Mole que requiere varios clicks
	SWIPE      # L - Mole que hay que jalar hacia arriba
}

# ==========================
# Estado
# ==========================
var is_recording: bool = false
var recorded_beats: Array[Dictionary] = []
var music_player: AudioStreamPlayer2D
var start_time: float = 0.0
var current_song_name: String = ""

# Teclas de mapeo
const KEY_NORMAL = KEY_J
const KEY_BONUS = KEY_K
const KEY_SWIPE = KEY_L

# Teclas de control
const KEY_START_RECORD = KEY_F5
const KEY_STOP_RECORD = KEY_F6
const KEY_SAVE_MAP = KEY_F7

# ==========================
# Inicialización
# ==========================
func _ready():
	set_process_input(false)  # Solo activar cuando se necesite

# ==========================
# Configurar grabación
# ==========================
func setup_recording(audio_player: AudioStreamPlayer2D, song_name: String):
	music_player = audio_player
	current_song_name = song_name
	print("🎵 Mapper configurado para: ", song_name)

# ==========================
# Iniciar grabación
# ==========================
func start_recording():
	if not music_player:
		push_error("❌ No hay AudioStreamPlayer configurado")
		return
	
	is_recording = true
	recorded_beats.clear()
	start_time = Time.get_ticks_msec() / 1000.0
	
	music_player.play()
	set_process_input(true)
	
	recording_started.emit()
	print("🔴 GRABACIÓN INICIADA - Presiona J/K/L para marcar beats")
	print("   F6: Detener | F7: Guardar")

# ==========================
# Detener grabación
# ==========================
func stop_recording():
	if not is_recording:
		return
	
	is_recording = false
	set_process_input(false)
	
	if music_player.playing:
		music_player.stop()
	
	_sort_beats()
	recording_stopped.emit()
	
	print("⏹️ GRABACIÓN DETENIDA")
	print("📊 Total de beats: ", recorded_beats.size())

# ==========================
# Input durante grabación
# ==========================
func _input(event):
	if not is_recording:
		return
	
	if event is InputEventKey and event.pressed and not event.echo:
		var timestamp = music_player.get_playback_position()
		
		match event.keycode:
			KEY_NORMAL:
				_add_beat(timestamp, MoleType.NORMAL)
			KEY_BONUS:
				_add_beat(timestamp, MoleType.BONUS)
			KEY_SWIPE:
				_add_beat(timestamp, MoleType.SWIPE)
			KEY_STOP_RECORD:
				stop_recording()
			KEY_SAVE_MAP:
				stop_recording()
				save_map()

# ==========================
# Agregar beat
# ==========================
func _add_beat(timestamp: float, type: MoleType):
	var beat = {
		"time": snappedf(timestamp, 0.001),  # Precisión de milisegundos
		"type": type
	}
	recorded_beats.append(beat)
	
	var type_name = ["NORMAL", "BONUS", "SWIPE"][type]
	print("✓ Beat %d: %.3fs [%s]" % [recorded_beats.size(), timestamp, type_name])

# ==========================
# Ordenar beats por tiempo
# ==========================
func _sort_beats():
	recorded_beats.sort_custom(func(a, b): return a["time"] < b["time"])

# ==========================
# Guardar mapa
# ==========================
func save_map() -> bool:
	if recorded_beats.is_empty():
		push_error("❌ No hay beats para guardar")
		return false
	
	var file_path = "user://maps/%s_map.json" % current_song_name
	
	# Crear directorio si no existe
	DirAccess.make_dir_recursive_absolute("user://maps")
	
	var map_data = {
		"song_name": current_song_name,
		"total_beats": recorded_beats.size(),
		"created_at": Time.get_datetime_string_from_system(),
		"beats": recorded_beats
	}
	
	var file = FileAccess.open(file_path, FileAccess.WRITE)
	if not file:
		push_error("❌ Error al crear archivo: ", FileAccess.get_open_error())
		return false
	
	file.store_string(JSON.stringify(map_data, "\t"))
	file.close()
	
	map_saved.emit(file_path)
	print("💾 Mapa guardado: ", file_path)
	print("📍 Ubicación real: ", ProjectSettings.globalize_path(file_path))
	return true

# ==========================
# Cargar mapa
# ==========================
func load_map(song_name: String) -> Dictionary:
	var file_path = "user://maps/%s_map.json" % song_name
	
	if not FileAccess.file_exists(file_path):
		push_error("❌ No existe mapa para: ", song_name)
		return {}
	
	var file = FileAccess.open(file_path, FileAccess.READ)
	if not file:
		push_error("❌ Error al abrir archivo: ", FileAccess.get_open_error())
		return {}
	
	var json_string = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var error = json.parse(json_string)
	
	if error != OK:
		push_error("❌ Error al parsear JSON: ", json.get_error_message())
		return {}
	
	print("✅ Mapa cargado: ", song_name)
	print("📊 Beats totales: ", json.data["total_beats"])
	return json.data

# ==========================
# Verificar si existe mapa
# ==========================
func has_map(song_name: String) -> bool:
	var file_path = "user://maps/%s_map.json" % song_name
	return FileAccess.file_exists(file_path)

# ==========================
# Obtener estadísticas del mapa
# ==========================
func get_map_stats(song_name: String) -> Dictionary:
	var map_data = load_map(song_name)
	if map_data.is_empty():
		return {}
	
	var stats = {
		"total": map_data["total_beats"],
		"normal": 0,
		"bonus": 0,
		"swipe": 0
	}
	
	for beat in map_data["beats"]:
		match beat["type"]:
			MoleType.NORMAL:
				stats["normal"] += 1
			MoleType.BONUS:
				stats["bonus"] += 1
			MoleType.SWIPE:
				stats["swipe"] += 1
	
	return stats
