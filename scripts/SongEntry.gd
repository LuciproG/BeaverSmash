extends Button
## Fila: miniatura + nombre + duración + high-score.
signal song_selected(data: Dictionary)

@onready var icon_rect: TextureRect = $HBoxContainer/Icon
@onready var name_label: Label = $HBoxContainer/VBoxContainer/NameLabel
@onready var duration_label: Label = $HBoxContainer/VBoxContainer/MetaRow/DurationLabel
@onready var score_label: Label = $HBoxContainer/VBoxContainer/MetaRow/ScoreLabel

@export var song_name: String = ""
@export var duration: String = ""
@export var high_score: int = 0
@export var thumbnail: Texture2D     # miniatura 64×64 de la fila
@export var right_preview: Texture2D # imagen grande para el panel derecho

func _ready() -> void:
	custom_minimum_size.y = max(custom_minimum_size.y, 84)  # altura mínima visible
	_refresh()
	pressed.connect(_on_pressed)

func _refresh() -> void:
	if name_label:     name_label.text = song_name
	if duration_label: duration_label.text = "Duración: %s" % duration
	if score_label:    score_label.text = "High-score: %d" % high_score
	if icon_rect:      icon_rect.texture = thumbnail

func _on_pressed() -> void:
	song_selected.emit({
		"name": song_name,
		"duration": duration,
		"high_score": high_score,
		"thumbnail": thumbnail,
		"preview": right_preview
	})
