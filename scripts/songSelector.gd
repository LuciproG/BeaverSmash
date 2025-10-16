extends Control
## =========================================================
## Selector estilo osu!:
## - Izquierda: lista (VBox dentro de un ScrollContainer)
## - Derecha: panel grande (TextureRect) con el fondo de la canción
## Descubre nodos por TIPO y crea lo que falte.
## =========================================================


# ---------------------------------------------------------
# (A) Utilidades: búsqueda recursiva por tipo y creación segura
# ---------------------------------------------------------

# Busca el PRIMER descendiente del tipo dado (p.ej. "ScrollContainer", "VBoxContainer", "TextureRect")
func _find_first_by_type(root: Node, type_name: String) -> Node:
	if root == null:
		return null
	if root.get_class() == type_name:
		return root
	for child in root.get_children():
		var hit := _find_first_by_type(child, type_name)
		if hit:
			return hit
	return null

# Crea (si hace falta) un ScrollContainer + VBoxContainer mínimos, anclados y visibles.
func _ensure_left_list(hbox: HBoxContainer) -> VBoxContainer:
	var scroll := _find_first_by_type(hbox, "ScrollContainer") as ScrollContainer
	if scroll == null:
		scroll = ScrollContainer.new()
		hbox.add_child(scroll)
		# Layout: que ocupe su columna
		scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL   # Fill + Expand
		scroll.size_flags_vertical   = Control.SIZE_EXPAND_FILL   # Fill + Expand
		scroll.custom_minimum_size   = Vector2(420, 0)            # ancho mínimo para que se vea
		scroll.size_flags_stretch_ratio = 0.0                     # que no “robe” el ancho de la derecha

	var vbox := _find_first_by_type(scroll, "VBoxContainer") as VBoxContainer
	if vbox == null:
		vbox = VBoxContainer.new()
		scroll.add_child(vbox)
		# Layout: columna que crece verticalmente
		vbox.size_flags_vertical = Control.SIZE_FILL
		vbox.set("theme_override_constants/separation", 8)

	return vbox

# Crea (si hace falta) un TextureRect de preview a la derecha.
func _ensure_right_preview(hbox: HBoxContainer) -> TextureRect:
	# Busca un TextureRect directo (la “columna” derecha)
	for child in hbox.get_children():
		if child is TextureRect:
			return child as TextureRect

	# Si no hay, crea uno nuevo
	var preview := TextureRect.new()
	hbox.add_child(preview)
	# Layout: que ocupe la segunda columna
	preview.size_flags_horizontal = Control.SIZE_EXPAND_FILL     # Fill + Expand
	preview.size_flags_vertical   = Control.SIZE_EXPAND_FILL
	preview.custom_minimum_size   = Vector2(640, 360)
	preview.stretch_mode          = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	preview.size_flags_stretch_ratio = 1.0                      # esta columna se queda con el resto
	return preview


# ---------------------------------------------------------
# (B) Referencias resueltas en _ready
# ---------------------------------------------------------
var song_list: VBoxContainer      # VBox con las filas (hijos Button)
var right_preview: TextureRect    # Panel derecho (TextureRect grande)

# Plantilla de fila
var entry_scene: PackedScene = preload("res://scenes/SongEntry.tscn")

# Datos de canciones (archivos EXACTOS que indicaste)
var songs := [
	{
		"name": "Acceleration",
		"duration": "2:34",
		"high_score": 50750,
		"thumb": preload("res://assets/sprites/Song_preview_1.png"),
		"bg":    preload("res://assets/sprites/song_1.png")
	},
	{
		"name": "After Dark (TV Size)",
		"duration": "1:30",
		"high_score": 30500,
		"thumb": preload("res://assets/sprites/Song_preview_2.png"),
		"bg":    preload("res://assets/sprites/song_2.png")
	}
]

var current_selected: Button = null


func _ready() -> void:
	# 1) Root a pantalla completa
	set_anchors_preset(Control.PRESET_FULL_RECT)

	# 2) Conseguir (o crear) el HBoxContainer principal
	var hbox := _find_first_by_type(self, "HBoxContainer") as HBoxContainer
	if hbox == null:
		hbox = HBoxContainer.new()
		add_child(hbox)
		hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hbox.size_flags_vertical   = Control.SIZE_EXPAND_FILL
		hbox.set("theme_override_constants/separation", 12)

	# 3) Asegurar columna izquierda (Scroll + VBox) y derecha (TextureRect)
	song_list     = _ensure_left_list(hbox)
	right_preview = _ensure_right_preview(hbox)

	# 4) Ajustar layout AHORA que existen los nodos
	_layout_guard()

	# 5) Poblar la lista (sin seleccionar nada por defecto)
	_build_list()
	# (Opcional) dejar el panel derecho vacío al iniciar
	if right_preview:
		right_preview.texture = null


# Ajustes de layout (anchors / size flags / mínimos)
func _layout_guard() -> void:
	# Root a pantalla completa
	if self is Control:
		set_anchors_preset(Control.PRESET_FULL_RECT)

	# Reaplicar flags al HBox (por si fue creado en _ready)
	var hbox := _find_first_by_type(self, "HBoxContainer") as HBoxContainer
	if hbox:
		hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hbox.size_flags_vertical   = Control.SIZE_EXPAND_FILL
		hbox.set("theme_override_constants/separation", 12)

	# Columna izquierda: asegurar ancho mínimo y que no estire
	var scroll := _find_first_by_type(hbox, "ScrollContainer") as ScrollContainer
	if scroll:
		scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		scroll.size_flags_vertical   = Control.SIZE_EXPAND_FILL
		scroll.custom_minimum_size   = Vector2(420, 0)
		scroll.size_flags_stretch_ratio = 0.0

	# Columna derecha: quedarse con el resto
	if right_preview:
		right_preview.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		right_preview.size_flags_vertical   = Control.SIZE_EXPAND_FILL
		right_preview.custom_minimum_size   = Vector2(640, 360)
		right_preview.stretch_mode          = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		right_preview.size_flags_stretch_ratio = 1.0


# ---------------------------------------------------------
# (C) Construcción de filas (SongEntry)
# ---------------------------------------------------------
func _build_list() -> void:
	# Limpiar filas previas
	for c in song_list.get_children():
		c.queue_free()

	# Crear fila por canción
	for s in songs:
		var row: Button = entry_scene.instantiate()
		row.custom_minimum_size = Vector2(0, 84)  # altura visible
		# Pasar datos a la fila (coinciden con SongEntry.gd)
		row.song_name     = s["name"]
		row.duration      = s["duration"]
		row.high_score    = s["high_score"]
		row.thumbnail     = s["thumb"]   # miniatura que se ve en la fila
		row.right_preview = s["bg"]      # imagen grande del panel derecho
		# Conectar selección y agregar
		row.song_selected.connect(_on_song_selected)
		song_list.add_child(row)

	print("[SongSelector] Entradas creadas: ", songs.size())


# ---------------------------------------------------------
# (D) Responder a la selección: resaltar + cambiar preview
# ---------------------------------------------------------
func _on_song_selected(data: Dictionary) -> void:
	var who := get_viewport().gui_get_focus_owner()
	if who is Button:
		_highlight_row(who)
	_apply_preview(data)

func _highlight_row(btn: Button) -> void:
	if current_selected and is_instance_valid(current_selected):
		current_selected.modulate = Color.WHITE
	current_selected = btn
	current_selected.modulate = Color(0.90, 0.96, 1.0)  # tinte suave de selección

func _apply_preview(data: Dictionary) -> void:
	if right_preview and data.has("preview"):
		right_preview.texture = data["preview"]


# ---------------------------------------------------------
# (E) ESC robusto — sale aunque un Control “se coma” la tecla
# ---------------------------------------------------------
func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == Key.KEY_ESCAPE:
		get_tree().quit()
