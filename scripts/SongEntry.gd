extends Button

# ==========================
# Variables
# ==========================
@export var song_name: String = "Canción"
@export var duration: String = "00:00"
@export var high_score: int = 0
@export var illustration: Texture

signal song_selected(data: Dictionary)

func _ready():
	# Crear el layout general
	var hbox = HBoxContainer.new()
	hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER

	# ---- Imagen (TextureRect)
	var texture_rect = TextureRect.new()
	texture_rect.texture = illustration
	texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	texture_rect.custom_minimum_size = Vector2(100, 100)
	texture_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH
	hbox.add_child(texture_rect)

	# ---- Contenedor de texto (VBoxContainer)
	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 4)
	hbox.add_child(vbox)

	# ---- Labels
	var name_label = Label.new()
	name_label.text = song_name
	name_label.add_theme_font_size_override("font_size", 20)
	vbox.add_child(name_label)

	var duration_label = Label.new()
	duration_label.text = duration
	duration_label.add_theme_font_size_override("font_size", 16)
	vbox.add_child(duration_label)

	var score_label = Label.new()
	score_label.text = "High Score: %d" % high_score
	score_label.add_theme_font_size_override("font_size", 16)
	vbox.add_child(score_label)

	# ---- Añadir el HBox al botón
	add_child(hbox)

func _pressed():
	emit_signal("song_selected", {
		"name": song_name,
		"duration": duration,
		"high_score": high_score,
		"illustration": illustration
	})
