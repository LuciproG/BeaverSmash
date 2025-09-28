extends Node2D

# ==========================
# Variables y escenas
# ==========================
@onready var music = $Music
@onready var play_button = $CanvasLayer/playButton
@onready var game_layer = $GameLayer
@onready var beat_timer = $BeatTimer
@onready var mole_scene = preload("res://scenes/mole.tscn")
@onready var ticket_label = $CanvasLayer/ticketLabel

# Pantallas de fin de juego
@onready var win_screen_scene = preload("res://scenes/WinScreen.tscn")
@onready var game_over_scene = preload("res://scenes/GameOverScreen.tscn")

var end_screen: Node = null   # Referencia a pantalla activa

# Configuración de la grilla
const GRID_SIZE = 3
const SPACING = 120
var grid_positions: Array[Vector2] = []
var occupied_cells: Array[bool] = []

# Sistema de tickets
var tickets: int = 10
var mode: String = "fast"

# Valores de BPM
const FAST_BPM = 148.0
const SLOW_BPM = 74.0

# Sistema de puntos
var hit_value: int = 1
var miss_value: int = -1

# Umbral para ganar
const WIN_THRESHOLD = 300

# ==========================
# Ready
# ==========================
func _ready():
	play_button.pressed.connect(_on_play_button_pressed)
	beat_timer.timeout.connect(_on_beat)
	music.finished.connect(_on_song_finished)

	_generate_grid()
	occupied_cells.resize(grid_positions.size())
	occupied_cells.fill(false)

	beat_timer.wait_time = 60.0 / FAST_BPM
	beat_timer.autostart = false
	beat_timer.one_shot = false

	_update_ticket_label()

# ==========================
# Generar grilla centrada
# ==========================
func _generate_grid():
	grid_positions.clear()
	var screen_size = get_viewport_rect().size
	var grid_width = (GRID_SIZE - 1) * SPACING
	var grid_height = (GRID_SIZE - 1) * SPACING
	var start_x = screen_size.x / 2.0 - grid_width / 2.0
	var start_y = screen_size.y / 2.0 - grid_height / 2.0 + 120.0

	for row in range(GRID_SIZE):
		for col in range(GRID_SIZE):
			grid_positions.append(Vector2(start_x + col * SPACING, start_y + row * SPACING))

# ==========================
# Procesar input (A/D)
# ==========================
func _process(_delta):
	if Input.is_action_just_pressed("mode_slow"):
		mode = "slow"
		hit_value = 2
		miss_value = -2
		beat_timer.wait_time = 60.0 / SLOW_BPM
		print("Modo cambiado a LENTO (74 BPM)")
		_update_ticket_label()
	elif Input.is_action_just_pressed("mode_fast"):
		mode = "fast"
		hit_value = 1
		miss_value = -1
		beat_timer.wait_time = 60.0 / FAST_BPM
		print("Modo cambiado a RÁPIDO (148 BPM)")
		_update_ticket_label()

# ==========================
# Callback en cada beat
# ==========================
func _on_beat():
	_spawn_mole()

# ==========================
# Spawn de moles
# ==========================
func _spawn_mole():
	var free_cells = []
	for i in range(occupied_cells.size()):
		if not occupied_cells[i]:
			free_cells.append(i)

	if free_cells.size() == 0:
		return

	var cell_index = free_cells[randi() % free_cells.size()]
	var mole = mole_scene.instantiate()
	mole.position = grid_positions[cell_index]
	mole.cell_index = cell_index

	# Godot 4: usar Callable para is_connected
	var whack_callable = Callable(self, "_on_mole_whacked")
	var expire_callable = Callable(self, "_on_mole_expired")

	if not mole.mole_whacked.is_connected(whack_callable):
		mole.mole_whacked.connect(whack_callable)
	if not mole.mole_expired.is_connected(expire_callable):
		mole.mole_expired.connect(expire_callable)

	occupied_cells[cell_index] = true
	game_layer.add_child(mole)

# ==========================
# Mole expirada
# ==========================
func _on_mole_expired(mole):
	occupied_cells[mole.cell_index] = false
	tickets += miss_value
	_update_ticket_label("miss")
	_check_game_over()
	mole.queue_free()

# ==========================
# Mole golpeada
# ==========================
func _on_mole_whacked(mole):
	occupied_cells[mole.cell_index] = false
	tickets += hit_value
	_update_ticket_label("hit")
	_check_game_over()
	mole.queue_free()

# ==========================
# Actualizar el label
# ==========================
func _update_ticket_label(event: String = ""):
	ticket_label.text = "🎟️ Tickets: " + str(tickets) + " (" + mode + ")"

	if event == "hit":
		ticket_label.modulate = Color(0, 1, 0)   # Verde
	elif event == "miss":
		ticket_label.modulate = Color(1, 0, 0)   # Rojo
	else:
		ticket_label.modulate = Color(1, 1, 1)   # Blanco

	await get_tree().create_timer(0.3).timeout
	ticket_label.modulate = Color(1, 1, 1)

# ==========================
# Verificar si se acabaron los tickets
# ==========================
func _check_game_over():
	if tickets <= 0:
		_end_game(false)

# ==========================
# Canción terminada
# ==========================
func _on_song_finished():
	if tickets >= WIN_THRESHOLD:
		_end_game(true)
	else:
		_end_game(false)

# ==========================
# Pantallas de fin de juego
# ==========================
func _end_game(won: bool):
	if not beat_timer.is_stopped():
		beat_timer.stop()
	if music.playing:
		music.stop()

	# Limpiar pantalla anterior
	if end_screen and is_instance_valid(end_screen):
		end_screen.queue_free()
		end_screen = null

	# Limpiar moles restantes
	for child in game_layer.get_children():
		if is_instance_valid(child):
			child.queue_free()

	# Instanciar pantalla correcta
	end_screen = (win_screen_scene if won else game_over_scene).instantiate()
	add_child(end_screen)

	# Fade-in Godot 4
	end_screen.modulate.a = 0.0
	var t = end_screen.create_tween()
	t.tween_property(end_screen, "modulate:a", 1.0, 0.5)

	# Conectar botones de fin de juego
	var retry_button = end_screen.get_node("retryButton")
	var main_menu_button = end_screen.get_node("mainMenuButton")
	var retry_callable = Callable(self, "_on_retry_pressed")
	var menu_callable = Callable(self, "_on_main_menu_pressed")

	if not retry_button.pressed.is_connected(retry_callable):
		retry_button.pressed.connect(retry_callable)
	if not main_menu_button.pressed.is_connected(menu_callable):
		main_menu_button.pressed.connect(menu_callable)

# ==========================
# Retry
# ==========================
func _on_retry_pressed():
	if end_screen and is_instance_valid(end_screen):
		end_screen.queue_free()
		end_screen = null

	play_button.visible = false
	tickets = 10
	mode = "fast"
	hit_value = 1
	miss_value = -1
	beat_timer.wait_time = 60.0 / FAST_BPM

	# Limpiar grid y moles
	occupied_cells.fill(false)
	for child in game_layer.get_children():
		if is_instance_valid(child):
			child.queue_free()

	_update_ticket_label()
	music.play()
	beat_timer.start()

# ==========================
# Main Menu Button
# ==========================
func _on_main_menu_pressed():
	if end_screen and is_instance_valid(end_screen):
		end_screen.queue_free()
		end_screen = null

	play_button.visible = true

# ==========================
# Botón Play
# ==========================
func _on_play_button_pressed():
	play_button.visible = false
	music.play()
	beat_timer.start()
