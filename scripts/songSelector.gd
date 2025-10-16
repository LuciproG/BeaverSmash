extends Node

# ==========================
# Referencias a los nodos hijos
# ==========================
@onready var background: TextureRect = $Background
@onready var song_list: VBoxContainer = $HBoxContainer/ScrollContainer/VBoxContainer
@onready var preview_rect: TextureRect = $HBoxContainer/PreviewRect

# ==========================
# Lista de canciones
# ==========================
var songs = [
	{
		"name": "Song 1",
		"duration": "2:34",
		"high_score": 5000,
		"illustration": preload("res://assets/sprites/song_1.png"),
		"preview": preload("res://assets/sprites/song_preview_1.png")
	},
	{
		"name": "Song 2",
		"duration": "3:12",
		"high_score": 3200,
		"illustration": preload("res://assets/sprites/song_2.png"),
		"preview": preload("res://assets/sprites/song_preview_2.png")
	}
]

# ==========================
# Al iniciar
# ==========================
func _ready():
	var entry_scene = preload("res://scenes/SongEntry.tscn")

	for s in songs:
		var entry = entry_scene.instantiate()
		entry.song_name = s["name"]
		entry.duration = s["duration"]
		entry.high_score = s["high_score"]
		entry.illustration = s["illustration"]

		entry.connect("song_selected", Callable(self, "_on_song_selected"))
		song_list.add_child(entry)

# ==========================
# Cuando se selecciona una canción
# ==========================
func _on_song_selected(data: Dictionary):
	background.texture = data["illustration"]
	preview_rect.texture = data["preview"]
	print("Seleccionaste:", data["name"])

# ==========================
# Salir con ESC
# ==========================
func _input(event):
	if event is InputEventKey and event.pressed and event.keycode == Key.KEY_ESCAPE:
		get_tree().quit()
