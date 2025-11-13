extends Node

# ==========================
# Señales
# ==========================
signal play_button_pressed()
signal retry_pressed()
signal main_menu_pressed()

# ==========================
# Referencias de nodos
# ==========================
@onready var canvas_layer = get_parent().get_node("CanvasLayer")
@onready var cts_text = canvas_layer.get_node_or_null("CTStext")
@onready var play_button = canvas_layer.get_node_or_null("playButton")
@onready var ticket_label = canvas_layer.get_node_or_null("ticketLabel")
@onready var countdown_label = canvas_layer.get_node_or_null("CountdownLabel")

# AKey y DKey pueden estar en CanvasLayer o en Main
var a_key: Node
var d_key: Node

@onready var countdown_sound = get_parent().get_node("CountdownSound")
@onready var countdown_go_sound = get_parent().get_node("CountdownGoSound")

# Escenas de fin de juego
var win_screen_scene = preload("res://scenes/WinScreen.tscn")
var game_over_scene = preload("res://scenes/GameOverScreen.tscn")

var current_end_screen: Node = null

# ==========================
# Inicialización
# ==========================
func _ready():
	# Buscar AKey y DKey (pueden estar en CanvasLayer o Main)
	a_key = canvas_layer.get_node_or_null("AKey")
	if not a_key:
		a_key = get_parent().get_node_or_null("AKey")
	
	d_key = canvas_layer.get_node_or_null("DKey")
	if not d_key:
		d_key = get_parent().get_node_or_null("DKey")
	
	if play_button:
		play_button.pressed.connect(_on_play_pressed)
	
	# Conectar game manager para actualizar tickets
	var game_manager = get_parent().get_node_or_null("GameManager")
	if game_manager and game_manager.has_signal("tickets_changed"):
		game_manager.tickets_changed.connect(_update_tickets)

# ==========================
# Mostrar/Ocultar elementos
# ==========================
func show_menu():
	if cts_text:
		cts_text.visible = true
	if play_button:
		play_button.visible = true
	if ticket_label:
		ticket_label.visible = false
	if countdown_label:
		countdown_label.visible = false
	if a_key:
		a_key.visible = false
	if d_key:
		d_key.visible = false

func hide_menu():
	if cts_text:
		cts_text.visible = false
	if play_button:
		play_button.visible = false

func show_game_ui():
	if ticket_label:
		ticket_label.visible = true
	if a_key:
		a_key.visible = true
	if d_key:
		d_key.visible = true
	if countdown_label:
		countdown_label.visible = false

# ==========================
# Countdown
# ==========================
func show_countdown():
	countdown_label.visible = true
	for i in [3, 2, 1]:
		countdown_label.text = str(i)
		countdown_sound.play()
		await get_tree().create_timer(1.0).timeout
	countdown_label.text = "GO!"
	countdown_go_sound.play()
	await get_tree().create_timer(1.0).timeout
	countdown_label.visible = false

# ==========================
# Actualizar tickets
# ==========================
func _update_tickets(value: int):
	var game_manager = get_parent().get_node("GameManager")
	ticket_label.text = "🎟️: " + str(value) + " (" + game_manager.mode + ")"

# ==========================
# Pantallas de fin de juego
# ==========================
func show_end_screen(won: bool, score: int):
	ticket_label.visible = false
	a_key.visible = false
	d_key.visible = false
	
	# Limpiar pantalla anterior
	if current_end_screen and is_instance_valid(current_end_screen):
		current_end_screen.queue_free()
	
	# Crear nueva pantalla
	var scene = win_screen_scene if won else game_over_scene
	current_end_screen = scene.instantiate()
	get_parent().add_child(current_end_screen)
	
	# Configurar puntaje
	var score_label = current_end_screen.get_node("finalScoreLabel")
	score_label.text = str(score)
	
	# Conectar botones
	var retry_btn = current_end_screen.get_node("retryButton")
	var menu_btn = current_end_screen.get_node("mainMenuButton")
	
	retry_btn.pressed.connect(_on_retry_btn_pressed)
	menu_btn.pressed.connect(_on_menu_btn_pressed)

func _on_retry_btn_pressed():
	if current_end_screen:
		current_end_screen.queue_free()
		current_end_screen = null
	retry_pressed.emit()

func _on_menu_btn_pressed():
	if current_end_screen:
		current_end_screen.queue_free()
		current_end_screen = null
	main_menu_pressed.emit()

func _on_play_pressed():
	play_button_pressed.emit()
