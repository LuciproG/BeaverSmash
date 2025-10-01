extends Node

# ==========================
# Variables y escenas
# ==========================
@onready var menu_music = $MenuMusic # Música del menú
@onready var play_button = $playButton # Botón de incio (Imagen de portada)
@onready var cts_text = $CTStext  # Label de texto inicial
@onready var song_selector_menu = preload("res://scenes/SongSelector.tscn") # Menú de canciones

# ==========================
# Al iniciar el juego
# ==========================
func _ready():
	menu_music.play() # Iniciar música
	# Cuando se precione iniciar cambie de escena
	play_button.pressed.connect(_on_play_button_pressed) 

# ==========================
# Botón Play
# ==========================
func _on_play_button_pressed():
	if menu_music.playing: # Cuando inicie el juego
		menu_music.stop() #Pausar música del menú
	
	# Elimina el menú inicial
	get_tree().current_scene.queue_free() 
	# Inicia la escena precargada
	var change_menu = song_selector_menu.instantiate()
	# Añadir la escena precargada al root
	get_tree().root.add_child(change_menu)
	
# ==========================
# Salir con ESC
# ==========================
func _input(event): # Detecta cualquier entrada del teclado
	# Si la tecla fue presionada
	if event is InputEventKey and event.pressed:
		# Si la tecla es ESC, cierra el juego
		if event.keycode == Key.KEY_ESCAPE:
			get_tree().quit()
