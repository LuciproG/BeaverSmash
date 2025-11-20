extends Node

# ==========================
# Señales
# ==========================
signal song_finished()
signal game_over()
signal tickets_changed(new_value: int)

# ==========================
# Referencias
# ==========================
@onready var game_layer = get_parent().get_node("GameLayer")
@onready var beat_timer = $BeatTimer
@onready var beat_player = $BeatPlayer  # Nuevo: reproductor de mapas
var mole_scene = preload("res://scenes/mole.tscn")

# Modo de juego
var use_beat_map: bool = true  # Usar mapa o sistema antiguo de BPM

# ==========================
# Configuración
# ==========================
const GRID_SIZE = 3
const SPACING = 220  # Ajustado para la imagen
const FAST_BPM = 148.0
const SLOW_BPM = 78.0
const WIN_THRESHOLD = 30

# Estado del juego
var tickets: int = 10
var mode: String = "fast"
var hit_value: int = 1
var miss_value: int = -1

# Sistema de grid
var grid_positions: Array[Vector2] = []
var occupied_cells: Array[bool] = []

# ==========================
# Inicialización
# ==========================
func _ready():
	_generate_grid()
	occupied_cells.resize(GRID_SIZE * GRID_SIZE)
	occupied_cells.fill(false)
	
	beat_timer.wait_time = 60.0 / FAST_BPM
	beat_timer.timeout.connect(_on_beat)

func _generate_grid():
	grid_positions.clear()
	var screen_size = get_viewport().get_visible_rect().size
	
	# Ajustar para tu imagen específica
	var grid_width = (GRID_SIZE - 1) * SPACING
	var grid_height = (GRID_SIZE - 1) * SPACING * 0.65  # Ajustado verticalmente
	
	# Centrar en pantalla con offset para tu imagen
	var start_x = screen_size.x / 2.0 - grid_width / 2.0 - 20
	var start_y = screen_size.y / 2.0 - grid_height / 2.0 + 30

	for row in range(GRID_SIZE):
		for col in range(GRID_SIZE):
			var pos = Vector2(start_x + col * SPACING, start_y + row * SPACING)
			grid_positions.append(pos)
	
	print("✅ Grid generado: ", grid_positions.size(), " posiciones")
	print("Primera posición: ", grid_positions[0])
	print("Última posición: ", grid_positions[grid_positions.size() - 1])

# ==========================
# Control del juego
# ==========================
func start_game(music_player: AudioStreamPlayer, song_name: String):
	tickets = 10
	mode = "fast"
	hit_value = 1
	miss_value = -1
	beat_timer.wait_time = 60.0 / FAST_BPM
	occupied_cells.fill(false)
	
	# Limpiar moles existentes
	for child in game_layer.get_children():
		child.queue_free()
	
	tickets_changed.emit(tickets)
	
	music_player.play()
	music_player.finished.connect(_on_music_finished, CONNECT_ONE_SHOT)
	beat_timer.start()

func _on_music_finished():
	beat_timer.stop()
	song_finished.emit()

# ==========================
# Sistema de moles
# ==========================
func _on_beat():
	_spawn_mole()

func _spawn_mole():
	var free_cells = []
	for i in range(occupied_cells.size()):
		if not occupied_cells[i]:
			free_cells.append(i)

	if free_cells.is_empty():
		return

	var cell_index = free_cells[randi() % free_cells.size()]
	var mole = mole_scene.instantiate()
	mole.position = grid_positions[cell_index]
	mole.cell_index = cell_index
	mole.lifetime = 2.5 if mode == "slow" else 2.0

	mole.mole_whacked.connect(_on_mole_whacked)
	mole.mole_expired.connect(_on_mole_expired)

	occupied_cells[cell_index] = true
	game_layer.add_child(mole)

func _on_mole_whacked(mole):
	occupied_cells[mole.cell_index] = false
	tickets += hit_value
	tickets_changed.emit(tickets)
	_check_game_over()

func _on_mole_expired(mole):
	occupied_cells[mole.cell_index] = false
	tickets += miss_value
	tickets_changed.emit(tickets)
	_check_game_over()
	mole.queue_free()

func _check_game_over():
	if tickets <= 0:
		beat_timer.stop()
		game_over.emit()

# ==========================
# Cambio de modo (A/D)
# ==========================
func _process(_delta):
	if not beat_timer.is_stopped():
		if Input.is_action_just_pressed("mode_slow"):
			mode = "slow"
			hit_value = 2
			miss_value = -3
			beat_timer.wait_time = 60.0 / SLOW_BPM
		elif Input.is_action_just_pressed("mode_fast"):
			mode = "fast"
			hit_value = 1
			miss_value = -1
			beat_timer.wait_time = 60.0 / FAST_BPM
