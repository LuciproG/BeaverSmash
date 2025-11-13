extends Control

signal song_confirmed(song_data: Dictionary)
signal back_pressed()

var songs := [
	{
		"name": "Acceleration", 
		"duration": "2:34", 
		"high_score": 50750,
		"audio_path": "res://assets/music/Daydream Origins.mp3"
	},
	{
		"name": "After Dark", 
		"duration": "1:30", 
		"high_score": 30500,
		"audio_path": "res://assets/music/Menu Music.mp3"
	}
]

var selected_index: int = -1

func _ready():
	set_anchors_preset(Control.PRESET_FULL_RECT)
	
	# Esperar un frame antes de construir UI
	await get_tree().process_frame
	_build_ui()

func _build_ui():
	# Fondo oscuro
	var bg = ColorRect.new()
	bg.color = Color(0.15, 0.15, 0.15, 1.0)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	
	# Contenedor principal
	var main_vbox = VBoxContainer.new()
	main_vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	main_vbox.add_theme_constant_override("separation", 20)
	add_child(main_vbox)
	
	# Espaciador superior
	var spacer_top = Control.new()
	spacer_top.custom_minimum_size = Vector2(0, 50)
	main_vbox.add_child(spacer_top)
	
	# Título
	var title = Label.new()
	title.text = "SELECCIONA UNA CANCIÓN"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 48)
	main_vbox.add_child(title)
	
	# Espaciador
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 30)
	main_vbox.add_child(spacer)
	
	# Lista de canciones (centrada)
	var center_container = CenterContainer.new()
	center_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_vbox.add_child(center_container)
	
	var song_vbox = VBoxContainer.new()
	song_vbox.add_theme_constant_override("separation", 15)
	center_container.add_child(song_vbox)
	
	# Crear botón por cada canción
	for i in range(songs.size()):
		var btn = Button.new()
		btn.text = songs[i]["name"] + "\n⏱ " + songs[i]["duration"] + "  |  🏆 " + str(songs[i]["high_score"])
		btn.custom_minimum_size = Vector2(600, 100)
		btn.add_theme_font_size_override("font_size", 24)
		btn.pressed.connect(_on_song_pressed.bind(i))
		song_vbox.add_child(btn)
	
	# Botones inferiores
	var button_hbox = HBoxContainer.new()
	button_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	button_hbox.add_theme_constant_override("separation", 20)
	main_vbox.add_child(button_hbox)
	
	# Botón volver
	var back_btn = Button.new()
	back_btn.text = "← VOLVER"
	back_btn.custom_minimum_size = Vector2(200, 60)
	back_btn.add_theme_font_size_override("font_size", 20)
	back_btn.pressed.connect(_on_back_pressed)
	button_hbox.add_child(back_btn)
	
	# Botón jugar
	var play_btn = Button.new()
	play_btn.name = "PlayButton"
	play_btn.text = "▶ JUGAR"
	play_btn.custom_minimum_size = Vector2(300, 60)
	play_btn.add_theme_font_size_override("font_size", 24)
	play_btn.disabled = true
	play_btn.pressed.connect(_on_play_pressed)
	button_hbox.add_child(play_btn)
	
	# Espaciador inferior
	var spacer_bottom = Control.new()
	spacer_bottom.custom_minimum_size = Vector2(0, 50)
	main_vbox.add_child(spacer_bottom)
	
	print("✅ UI del selector construida exitosamente")

func _on_song_pressed(index: int):
	selected_index = index
	
	# Actualizar highlight de botones
	var song_vbox = get_node_or_null("ColorRect/VBoxContainer/CenterContainer/VBoxContainer")
	if song_vbox:
		for i in range(song_vbox.get_child_count()):
			var btn = song_vbox.get_child(i)
			if btn is Button:
				if i == index:
					btn.modulate = Color(0.5, 0.8, 1.0)
				else:
					btn.modulate = Color.WHITE
	
	# Habilitar botón de jugar
	var play_btn = find_child("PlayButton", true, false)
	if play_btn:
		play_btn.disabled = false
	
	print("Canción seleccionada: ", songs[index]["name"])

func _on_play_pressed():
	if selected_index >= 0 and selected_index < songs.size():
		song_confirmed.emit(songs[selected_index])
		print("Iniciando juego con: ", songs[selected_index]["name"])

func _on_back_pressed():
	back_pressed.emit()
	print("Volviendo al menú")
