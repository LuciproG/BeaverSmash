extends Node

# Referencias a los nodos hijos
@onready var background = $TextureRect # Fondo dinámico que cambiará según canción
@onready var song_list = $ScrollContainer/VBoxContainer # Contenedor que guarda las entradas de canciones

# Lista de canciones (más adelante se puede cargar desde un archivo externo)
var songs = [
	{
		"name": "Song 1", # Nombre de la canción
		"duration": "2:34", # Duración en minutos y segundos
		"high_score": 5000, # Puntaje más alto
		"illustration": preload("res://assets/sprites/song_1.png") # Ilustración asociada
	},
	{
		"name": "Song 2",
		"duration": "3:12",
		"high_score": 3200,
		"illustration": preload("res://assets/sprites/song_2.png")
	}
]

func _ready():
	# Precargamos la escena que representa cada entrada de canción
	var entry_scene = preload("res://scenes/SongEntry.tscn")

	# Recorremos todas las canciones en la lista
	for s in songs:
		# Instanciamos una nueva tarjeta de canción
		var entry = entry_scene.instantiate()

		# Pasamos la información de la canción a la tarjeta
		entry.song_name = s["name"]
		entry.duration = s["duration"]
		entry.high_score = s["high_score"]
		entry.illustration = s["illustration"]

		# Conectamos la señal de la tarjeta a este menú
		entry.connect("song_selected", Callable(self, "_on_song_selected"))

		# Finalmente, agregamos la tarjeta al VBoxContainer
		song_list.add_child(entry)

func _on_song_selected(data: Dictionary):
	# Cuando se selecciona una canción:
	# Cambiamos la ilustración del fondo
	background.texture = data["illustration"]

	# Por ahora mostramos en consola el nombre (luego se puede usar para cargar la canción real)
	print("Seleccionaste:", data["name"])

# ==========================
# Salir con ESC
# ==========================
func _input(event): # Detecta cualquier entrada del teclado
	# Si la tecla fue presionada
	if event is InputEventKey and event.pressed:
		# Si la tecla es ESC, cierra el juego
		if event.keycode == Key.KEY_ESCAPE:
			get_tree().quit()
