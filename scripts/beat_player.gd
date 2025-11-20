extends Node

# ==========================
# Señales
# ==========================
signal spawn_mole(mole_type: int)  # Emite cuando debe aparecer una mole
signal playback_started()
signal playback_finished()

# ==========================
# Estado
# ==========================
var is_playing: bool = false
var beats_queue: Array[Dictionary] = []
var current_beat_index: int = 0
var music_player: AudioStreamPlayer2D
var check_timer: Timer

# Precisión del sistema (en segundos)
const CHECK_INTERVAL = 0.016  # ~60 FPS (cada frame)
const SPAWN_TOLERANCE = 0.05  # 50ms de tolerancia

# ==========================
# Inicialización
# ==========================
func _ready():
	# Crear timer para verificar beats
	check_timer = Timer.new()
	check_timer.wait_time = CHECK_INTERVAL
	check_timer.timeout.connect(_check_beats)
	add_child(check_timer)

# ==========================
# Iniciar reproducción
# ==========================
func play_map(audio_player: AudioStreamPlayer2D, song_name: String) -> bool:
	music_player = audio_player
	
	# Cargar mapa
	var beat_mapper = get_node("/root/Main/BeatMapper")
	if not beat_mapper:
		push_error("❌ BeatMapper no encontrado")
		return false
	
	var map_data = beat_mapper.load_map(song_name)
	if map_data.is_empty():
		push_error("❌ No se pudo cargar el mapa")
		return false
	
	# Preparar beats
	beats_queue = map_data["beats"].duplicate(true)
	current_beat_index = 0
	is_playing = true
	
	# Conectar señal de fin de música
	if not music_player.finished.is_connected(_on_music_finished):
		music_player.finished.connect(_on_music_finished)
	
	# Iniciar música y verificación
	music_player.play()
	check_timer.start()
	
	playback_started.emit()
	print("▶️ Reproduciendo mapa: ", song_name)
	print("📊 Beats totales: ", beats_queue.size())
	return true

# ==========================
# Verificar beats constantemente
# ==========================
func _check_beats():
	if not is_playing or current_beat_index >= beats_queue.size():
		return
	
	var current_time = music_player.get_playback_position()
	
	# Procesar todos los beats que ya deberían haber ocurrido
	while current_beat_index < beats_queue.size():
		var beat = beats_queue[current_beat_index]
		var beat_time = beat["time"]
		
		# Si el beat ya pasó su momento
		if current_time >= beat_time - SPAWN_TOLERANCE:
			_spawn_beat(beat)
			current_beat_index += 1
		else:
			break  # El siguiente beat aún no llega

# ==========================
# Generar mole del beat
# ==========================
func _spawn_beat(beat: Dictionary):
	var mole_type = beat["type"]
	spawn_mole.emit(mole_type)
	
	var type_name = ["NORMAL", "BONUS", "SWIPE"][mole_type]
	print("🎯 Spawn: %.3fs [%s]" % [beat["time"], type_name])

# ==========================
# Música terminada
# ==========================
func _on_music_finished():
	stop_playback()
	playback_finished.emit()
	print("✅ Reproducción finalizada")

# ==========================
# Detener reproducción
# ==========================
func stop_playback():
	is_playing = false
	check_timer.stop()
	current_beat_index = 0
	beats_queue.clear()

# ==========================
# Obtener progreso
# ==========================
func get_progress() -> Dictionary:
	if beats_queue.is_empty():
		return {"current": 0, "total": 0, "percentage": 0.0}
	
	return {
		"current": current_beat_index,
		"total": beats_queue.size(),
		"percentage": float(current_beat_index) / beats_queue.size() * 100.0
	}
