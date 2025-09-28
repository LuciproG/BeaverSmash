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

# ==========================
# Condición de victoria
# ==========================
const WIN_THRESHOLD: int = 300   # 🔥 Ajusta este valor para balancear

# ==========================
# Ready
# ==========================
func _ready():
	play_button.pressed.connect(_on_play_button_pressed)
	beat_timer.timeout.connect(_on_beat)
	music.finished.connect(_on_music_finished)   # ✅ Detectar cuando termina la canción

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
			var pos = Vector2(start_x + col * SPACING, start_y + row * SPACING)
			grid_positions.append(pos)

# ==========================
# Procesar input (A/D)
# ==========================
func _process(delta):
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
	mole.mole_whacked.connect(_on_mole_whacked)
	mole.mole_expired.connect(_on_mole_expired)

	occupied_cells[cell_index] = true
	game_layer.add_child(mole)

# ==========================
# Mole expirada
# ==========================
func _on_mole_expired(mole):
	occupied_cells[mole.cell_index] = false
	tickets += miss_value
	print("Mole perdida! Tickets: %d" % tickets)
	_update_ticket_label("miss")
	_check_game_over()
	mole.queue_free()

# ==========================
# Mole golpeada
# ==========================
func _on_mole_whacked(mole):
	occupied_cells[mole.cell_index] = false
	tickets += hit_value
	print("Mole golpeada! Tickets: %d" % tickets)
	_update_ticket_label("hit")
	_check_game_over()
	mole.queue_free()

# ==========================
# Actualizar el label
# ==========================
func _update_ticket_label(event: String = ""):
	ticket_label.text = "🎟️ Tickets: %d (%s)" % [tickets, mode]

	# Efecto de color según evento
	if event == "hit":
		ticket_label.modulate = Color(0, 1, 0)   # Verde
	elif event == "miss":
		ticket_label.modulate = Color(1, 0, 0)   # Rojo
	else:
		ticket_label.modulate = Color(1, 1, 1)   # Blanco

	# Hacemos que vuelva al blanco luego de 0.3s
	await get_tree().create_timer(0.3).timeout
	ticket_label.modulate = Color(1, 1, 1)

# ==========================
# Verificar si se acabaron los tickets
# ==========================
func _check_game_over():
	if tickets <= 0:
		print("Game Over! (sin tickets)")
		_end_game(false)

# ==========================
# Callback cuando la música termina
# ==========================
func _on_music_finished():
	print("La canción terminó!")
	if tickets >= WIN_THRESHOLD:
		_end_game(true)
	else:
		_end_game(false)

# ==========================
# Terminar juego
# ==========================
func _end_game(won: bool):
	beat_timer.stop()
	music.stop()
	play_button.visible = true

	if won:
		print("🎉 Has ganado con %d tickets!" % tickets)
	else:
		print("❌ Game Over. Tickets finales: %d" % tickets)

# ==========================
# Botón Play
# ==========================
func _on_play_button_pressed():
	play_button.visible = false
	tickets = 10   # 🔥 Reiniciar tickets al empezar
	_update_ticket_label()
	music.play()
	beat_timer.start()
