extends Node2D

# ==========================
# Variables y escenas
# ==========================
@onready var music = $Music
@onready var menu_music = $MenuMusic
@onready var play_button = $CanvasLayer/playButton
@onready var game_layer = $GameLayer
@onready var beat_timer = $BeatTimer
@onready var mole_scene = preload("res://scenes/mole.tscn")
@onready var ticket_label = $CanvasLayer/ticketLabel
@onready var cts_text = $CanvasLayer/CTStext  # Label de texto inicial
@onready var countdown_label = $CanvasLayer/CountdownLabel
@onready var countdown_sound = $CountdownSound
@onready var countdown_go_sound = $CountdownGoSound
@onready var a_key = $AKey
@onready var d_key = $DKey


# Pantallas de fin de juego
@onready var win_screen_scene = preload("res://scenes/WinScreen.tscn")
@onready var game_over_scene = preload("res://scenes/GameOverScreen.tscn")

var end_screen: Node = null   # Referencia a pantalla activa

# Configuración de la grilla
const GRID_SIZE = 3
const SPACING = 260
var grid_positions: Array[Vector2] = []
var occupied_cells: Array[bool] = []

# Sistema de tickets
var tickets: int = 10
var final_score: int = 0  # Guardará el puntaje final
var mode: String = "fast"

# Valores de BPM
const FAST_BPM = 148.0
const SLOW_BPM = 78.0  # Ajustado al 60% del fast

# Sistema de puntos
var hit_value: int = 1
var miss_value: int = -1

# Umbral para ganar
const WIN_THRESHOLD = 30

# ==========================
# Ready
# ==========================
func _ready():
	#menu_music.loop = true
	menu_music.play()
	countdown_label.visible = false
	play_button.pressed.connect(_on_play_button_pressed)
	beat_timer.timeout.connect(_on_beat)
	music.finished.connect(_on_song_finished)
	a_key.visible = false
	d_key.visible = false

	_generate_grid()
	occupied_cells.resize(grid_positions.size())
	occupied_cells.fill(false)

	beat_timer.wait_time = 60.0 / FAST_BPM
	beat_timer.autostart = false
	beat_timer.one_shot = false

	# Mostrar solo el CTStext y play_button al inicio, ocultar tickets
	cts_text.visible = true
	play_button.visible = true
	ticket_label.visible = false

	# Fade-in inicial del menú
	cts_text.modulate.a = 0.0
	var tween_text = cts_text.create_tween()
	tween_text.tween_property(cts_text, "modulate:a", 1.0, 0.5)

	play_button.modulate.a = 0.0
	var tween_button = play_button.create_tween()
	tween_button.tween_property(play_button, "modulate:a", 1.0, 0.5)

# ==========================
# Generar grilla centrada
# ==========================
func _generate_grid():
	grid_positions.clear()
	var screen_size = get_viewport_rect().size
	var grid_width = (GRID_SIZE - 1) * SPACING * 1.0
	var grid_height = (GRID_SIZE - 1) * SPACING * 0.1
	var start_x = screen_size.x / 2.0 - grid_width / 2.0
	var start_y = screen_size.y / 2.0 - grid_height / 2.0 - 45.0

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
		miss_value = -3
		beat_timer.wait_time = 60.0 / SLOW_BPM
		print("Modo cambiado a LENTO (88 BPM)")
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

	# Ajustar lifetime según modo
	if mode == "slow":
		mole.lifetime = 2.5
	else:
		mole.lifetime = 2.0

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
	# Liberar celda
	occupied_cells[mole.cell_index] = false

	# Actualizar tickets
	tickets += hit_value
	_update_ticket_label("hit")
	_check_game_over()

	# Cambiar sprite al frame golpeado
	if mole.has_node("Sprite2D"):
		var sprite = mole.get_node("Sprite2D")
		if sprite.texture is AtlasTexture:
			sprite.region_enabled = true
			sprite.region_rect = Rect2(Vector2(160,200), Vector2(152,192))
		elif sprite.texture is SpriteFrames:
			# Si es AnimatedSprite2D
			sprite.frame = 1  # índice del frame "golpeado"

	# Desactivar CollisionShape para que no reciba más clicks
	if mole.has_node("CollisionShape2D"):
		mole.get_node("CollisionShape2D").disabled = true

	# Cancelar LifetimeTimer para que no lo borre prematuramente
	if mole.has_node("LifetimeTimer"):
		mole.get_node("LifetimeTimer").stop()

	# Esperar 0.3 segundos y eliminar la mole
	await get_tree().create_timer(0.3).timeout
	if is_instance_valid(mole):
		mole.queue_free()

# ==========================
# Actualizar el label
# ==========================
func _update_ticket_label(event: String = ""):
	ticket_label.text = "🎟️: " + str(tickets) + " (" + mode + ")"

	if event == "hit":
		ticket_label.modulate = Color(0, 1, 0)
	elif event == "miss":
		ticket_label.modulate = Color(1, 0, 0)
	else:
		ticket_label.modulate = Color(1, 1, 1)

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
	a_key.visible = false
	d_key.visible = false
	# Ocultar puntaje actual
	ticket_label.visible = false
	final_score = tickets  # guarda el puntaje actual antes de mostrar la pantalla

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
	
	# Mostrar puntaje final en el Label
	var score_label = end_screen.get_node("finalScoreLabel")
	score_label.text = str(final_score)

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
	a_key.visible = true
	d_key.visible = true
	
	if end_screen and is_instance_valid(end_screen):
		end_screen.queue_free()
		end_screen = null

	# Fade-out menú (play_button + CTStext)
	var tween_button = play_button.create_tween()
	tween_button.tween_property(play_button, "modulate:a", 0.0, 0.5)
	tween_button.tween_callback(Callable(play_button, "hide"))

	var tween_text = cts_text.create_tween()
	tween_text.tween_property(cts_text, "modulate:a", 0.0, 0.5)
	tween_text.tween_callback(Callable(cts_text, "hide"))

	play_button.visible = false
	cts_text.visible = false
	ticket_label.visible = true

	tickets = 10
	mode = "fast"
	hit_value = 1
	miss_value = -1
	beat_timer.wait_time = 60.0 / FAST_BPM

	_update_ticket_label()  # actualizar el label inmediatamente

	# Limpiar grid y moles
	occupied_cells.fill(false)
	for child in game_layer.get_children():
		if is_instance_valid(child):
			child.queue_free()

	_start_countdown()

# ==========================
# Main Menu Button
# ==========================
func _on_main_menu_pressed():
	#menu_music.loop = true
	menu_music.play()

	if end_screen and is_instance_valid(end_screen):
		end_screen.queue_free()
		end_screen = null

	# Fade-in del play_button
	play_button.visible = true
	play_button.modulate.a = 0.0
	var tween_button = play_button.create_tween()
	tween_button.tween_property(play_button, "modulate:a", 1.0, 0.5)

	# Fade-in del CTStext
	cts_text.visible = true
	cts_text.modulate.a = 0.0
	var tween_text = cts_text.create_tween()
	tween_text.tween_property(cts_text, "modulate:a", 1.0, 0.5)

	ticket_label.visible = false

	# Resetear valores del juego
	tickets = 10
	mode = "fast"
	hit_value = 1
	miss_value = -1
	beat_timer.wait_time = 60.0 / FAST_BPM

	_update_ticket_label()  # actualizar label para mostrar puntaje correcto al volver

# ==========================
# Botón Play
# ==========================
func _on_play_button_pressed():
	a_key.visible = true
	d_key.visible = true
	if menu_music.playing:
		menu_music.stop()
	
	# Fade-out menú (play_button + CTStext)
	var tween_button = play_button.create_tween()
	tween_button.tween_property(play_button, "modulate:a", 0.0, 0.5)
	tween_button.tween_callback(Callable(play_button, "hide"))

	var tween_text = cts_text.create_tween()
	tween_text.tween_property(cts_text, "modulate:a", 0.0, 0.5)
	tween_text.tween_callback(Callable(cts_text, "hide"))

	play_button.visible = false
	cts_text.visible = false
	ticket_label.visible = true

	# Reiniciar valores del juego
	tickets = 10
	mode = "fast"
	hit_value = 1
	miss_value = -1
	beat_timer.wait_time = 60.0 / FAST_BPM

	_update_ticket_label()  # actualizar label inmediatamente

	_start_countdown()


# ==========================
# Countdown antes de iniciar
# ==========================
func _start_countdown() -> void:
	countdown_label.visible = true
	for i in [3, 2, 1]:
		countdown_label.text = str(i)
		countdown_sound.play()  # Sonido normal
		await get_tree().create_timer(1.0).timeout
	countdown_label.text = "GO!"
	countdown_go_sound.play()  # Sonido especial para GO!
	await get_tree().create_timer(1.0).timeout
	countdown_label.visible = false
	ticket_label.visible = true
	music.play()
	beat_timer.start()

# ==========================
# Salir con ESC
# ==========================
func _input(event):
	if event is InputEventKey and event.pressed:
		if event.keycode == Key.KEY_ESCAPE:
			get_tree().quit()
