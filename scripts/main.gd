extends Node

# ==========================
# Referencias de nodos
# ==========================
@onready var menu_music = $MenuMusic
@onready var game_music = $Music
@onready var canvas_layer = $CanvasLayer

# Nodos que verificaremos
var song_selector: Control
var ui_manager: Node
var game_manager: Node

# Estados del juego
enum GameState { MENU, SONG_SELECT, PLAYING, GAME_OVER }
var current_state: GameState = GameState.MENU

# Canción seleccionada
var current_song: Dictionary = {}

# ==========================
# Inicialización
# ==========================
func _ready():
	print("🎮 Iniciando juego...")
	print("Music node type:", game_music.get_class() if game_music else "null")
	_find_or_create_nodes()
	_setup_connections()
	_show_menu()
	menu_music.play()
	
# ==========================
# Buscar o crear nodos necesarios
# ==========================
func _find_or_create_nodes():
	# Buscar SongSelector
	song_selector = canvas_layer.get_node_or_null("SongSelector")
	if not song_selector:
		print("⚠️ SongSelector no encontrado, creando...")
		song_selector = Control.new()
		song_selector.name = "SongSelector"
		canvas_layer.add_child(song_selector)
		# Asignar script
		var script = load("res://scripts/songSelector.gd")
		if script:
			song_selector.set_script(script)
	
	# Buscar UIManager
	ui_manager = get_node_or_null("UIManager")
	if not ui_manager:
		print("⚠️ UIManager no encontrado, creando...")
		ui_manager = Node.new()
		ui_manager.name = "UIManager"
		add_child(ui_manager)
		var script = load("res://scripts/ui_manager.gd")
		if script:
			ui_manager.set_script(script)
	
	# Buscar GameManager
	game_manager = get_node_or_null("GameManager")
	if not game_manager:
		print("⚠️ GameManager no encontrado, creando...")
		game_manager = Node.new()
		game_manager.name = "GameManager"
		add_child(game_manager)
		var script = load("res://scripts/game_manager.gd")
		if script:
			game_manager.set_script(script)
		# Crear BeatTimer
		var beat_timer = Timer.new()
		beat_timer.name = "BeatTimer"
		game_manager.add_child(beat_timer)
	
	print("✅ Todos los nodos verificados")

# ==========================
# Conexiones
# ==========================
func _setup_connections():
	# Esperar a que los scripts estén listos
	await get_tree().process_frame
	
	# Conectar UI Manager
	if ui_manager and ui_manager.has_signal("play_button_pressed"):
		ui_manager.play_button_pressed.connect(_on_play_pressed)
		ui_manager.retry_pressed.connect(_on_retry_pressed)
		ui_manager.main_menu_pressed.connect(_on_main_menu_pressed)
	
	# Conectar Song Selector
	if song_selector and song_selector.has_signal("song_confirmed"):
		song_selector.song_confirmed.connect(_on_song_confirmed)
		song_selector.back_pressed.connect(_on_back_to_menu)
	
	# Conectar Game Manager
	if game_manager and game_manager.has_signal("song_finished"):
		game_manager.song_finished.connect(_on_song_finished)
		game_manager.game_over.connect(_on_game_over)

# ==========================
# Cambios de estado
# ==========================
func _show_menu():
	current_state = GameState.MENU
	if menu_music:
		menu_music.play()
	if ui_manager and ui_manager.has_method("show_menu"):
		ui_manager.show_menu()
	if song_selector:
		song_selector.visible = false

func _show_song_selector():
	current_state = GameState.SONG_SELECT
	if menu_music:
		menu_music.stop()
	if ui_manager and ui_manager.has_method("hide_menu"):
		ui_manager.hide_menu()
	if song_selector:
		song_selector.visible = true

func _show_game():
	current_state = GameState.PLAYING
	if song_selector:
		song_selector.visible = false
	if ui_manager and ui_manager.has_method("show_game_ui"):
		ui_manager.show_game_ui()

# ==========================
# Callbacks
# ==========================
func _on_play_pressed():
	_show_song_selector()

func _on_song_confirmed(song_data: Dictionary):
	current_song = song_data
	print("📀 Canción confirmada: ", song_data["name"])
	print("🎵 game_music válido:", game_music != null)
	print("🎵 game_music tipo:", game_music.get_class() if game_music else "null")
	
	# Cargar música
	if song_data.has("audio_path") and ResourceLoader.exists(song_data["audio_path"]):
		var audio_stream = load(song_data["audio_path"])
		if audio_stream:
			game_music.stream = audio_stream
			print("✅ Música cargada: ", song_data["name"])
		else:
			print("❌ Error al cargar stream de audio")
	else:
		print("⚠️ Ruta de audio no existe: ", song_data.get("audio_path", "ninguna"))
	
	_show_game()
	
	if ui_manager and ui_manager.has_method("show_countdown"):
		await ui_manager.show_countdown()
	
	print("🎮 Intentando iniciar juego...")
	print("🎮 game_manager existe:", game_manager != null)
	print("🎮 game_music existe:", game_music != null)
	
	if game_manager and game_manager.has_method("start_game"):
		# Pasar el nombre de la canción para buscar el mapa
		game_manager.start_game(game_music, song_data["name"])
	else:
		print("❌ No se pudo iniciar el juego")

func _on_back_to_menu():
	_show_menu()

func _on_retry_pressed():
	_show_song_selector()

func _on_main_menu_pressed():
	_show_menu()

func _on_song_finished():
	if game_manager:
		var won = game_manager.tickets >= game_manager.WIN_THRESHOLD
		if ui_manager and ui_manager.has_method("show_end_screen"):
			ui_manager.show_end_screen(won, game_manager.tickets)

func _on_game_over():
	if game_manager and ui_manager and ui_manager.has_method("show_end_screen"):
		ui_manager.show_end_screen(false, game_manager.tickets)

# ==========================
# Input global
# ==========================
func _input(event):
	if event is InputEventKey and event.pressed and event.keycode == Key.KEY_ESCAPE:
		if current_state == GameState.SONG_SELECT:
			_on_back_to_menu()
		else:
			get_tree().quit()
