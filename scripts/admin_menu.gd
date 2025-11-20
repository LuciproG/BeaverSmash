extends Control

signal map_mode_selected(song_name: String)
signal back_to_menu()

var songs := [
	{"name": "DayDreams Origins", "audio_path": "res://assets/music/Daydream Origins.mp3"},
	{"name": "After Dark", "audio_path": "res://assets/music/Menu Music.mp3"}
]

var beat_mapper: Node
var selected_song: String = ""

func _ready():
	set_anchors_preset(Control.PRESET_FULL_RECT)
	await get_tree().process_frame
	beat_mapper = get_node("/root/Main/BeatMapper")
	_build_ui()

func _build_ui():
	# Fondo
	var bg = ColorRect.new()
	bg.color = Color(0.1, 0.1, 0.15, 1.0)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	
	var main_vbox = VBoxContainer.new()
	main_vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	main_vbox.add_theme_constant_override("separation", 20)
	add_child(main_vbox)
	
	# Espaciador
	var spacer_top = Control.new()
	spacer_top.custom_minimum_size = Vector2(0, 30)
	main_vbox.add_child(spacer_top)
	
	# Título
	var title = Label.new()
	title.text = "🎮 MODO ADMIN - CREACIÓN DE MAPAS"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 40)
	title.add_theme_color_override("font_color", Color(1, 0.5, 0.5))
	main_vbox.add_child(title)
	
	# Instrucciones
	var instructions = Label.new()
	instructions.text = "Controles: J=Normal | K=Bonus | L=Swipe | F6=Detener | F7=Guardar"
	instructions.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	instructions.add_theme_font_size_override("font_size", 18)
	main_vbox.add_child(instructions)
	
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 20)
	main_vbox.add_child(spacer)
	
	# Lista de canciones
	var center = CenterContainer.new()
	center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_vbox.add_child(center)
	
	var song_vbox = VBoxContainer.new()
	song_vbox.add_theme_constant_override("separation", 15)
	center.add_child(song_vbox)
	
	for song in songs:
		var hbox = HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 20)
		
		var btn = Button.new()
		btn.text = "📍 MAPEAR: " + song["name"]
		btn.custom_minimum_size = Vector2(400, 60)
		btn.add_theme_font_size_override("font_size", 20)
		btn.pressed.connect(_on_map_song.bind(song["name"]))
		hbox.add_child(btn)
		
		# Info del mapa
		var info_label = Label.new()
		if beat_mapper and beat_mapper.has_map(song["name"]):
			var stats = beat_mapper.get_map_stats(song["name"])
			info_label.text = "✅ Mapa: %d beats (N:%d B:%d S:%d)" % [
				stats["total"], stats["normal"], stats["bonus"], stats["swipe"]
			]
			info_label.add_theme_color_override("font_color", Color(0.5, 1, 0.5))
		else:
			info_label.text = "❌ Sin mapa"
			info_label.add_theme_color_override("font_color", Color(1, 0.5, 0.5))
		info_label.add_theme_font_size_override("font_size", 16)
		info_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		hbox.add_child(info_label)
		
		song_vbox.add_child(hbox)
	
	# Botón volver
	var back_btn = Button.new()
	back_btn.text = "← VOLVER AL MENÚ"
	back_btn.custom_minimum_size = Vector2(300, 50)
	back_btn.pressed.connect(_on_back_pressed)
	
	var back_center = CenterContainer.new()
	back_center.add_child(back_btn)
	main_vbox.add_child(back_center)
	
	var spacer_bottom = Control.new()
	spacer_bottom.custom_minimum_size = Vector2(0, 30)
	main_vbox.add_child(spacer_bottom)

func _on_map_song(song_name: String):
	map_mode_selected.emit(song_name)

func _on_back_pressed():
	back_to_menu.emit()
