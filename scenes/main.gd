extends Node2D

# ==========================
# Variables y escenas
# ==========================
@onready var music = $Music   # Nodo AudioStreamPlayer que reproduce la canción
@onready var play_button = $CanvasLayer/playButton   # Botón del menú
@onready var game_layer = $GameLayer   # Capa donde se instancian las moles
@onready var beat_timer = $BeatTimer   # Timer sincronizado con el BPM de la música
@onready var mole_scene = preload("res://scenes/mole.tscn")   # Escena de la mole

# Configuración de la grilla
const GRID_SIZE = 3
const SPACING = 120   # distancia entre celdas
var grid_positions: Array[Vector2] = []   # posiciones absolutas de cada celda
var occupied_cells: Array[bool] = []      # si una celda está ocupada o no


# ==========================
# Ready
# ==========================
func _ready():
	# Conectar botón Play
	play_button.pressed.connect(_on_play_button_pressed)

	# Conectar el Timer de beats
	beat_timer.timeout.connect(_on_beat)

	# Calcular posiciones de la grilla centrada
	_generate_grid()

	# Inicializar celdas como libres
	occupied_cells.resize(grid_positions.size())
	occupied_cells.fill(false)

	# Configurar el Timer con el BPM de Toby Fox - "It's TV Time!"
	# BPM = 148 → cada beat ≈ 0.405 segundos
	var bpm = 74.0
	beat_timer.wait_time = 60.0 / bpm
	beat_timer.autostart = false
	beat_timer.one_shot = false


# ==========================
# Generar grilla centrada
# ==========================
func _generate_grid():
	grid_positions.clear()

	var screen_size = get_viewport_rect().size
	var grid_width = (GRID_SIZE - 1) * SPACING
	var grid_height = (GRID_SIZE - 1) * SPACING

	# Centramos la grilla en pantalla y la bajamos un poco (+120)
	var start_x = screen_size.x / 2.0 - grid_width / 2.0
	var start_y = screen_size.y / 2.0 - grid_height / 2.0 + 120.0

	for row in range(GRID_SIZE):
		for col in range(GRID_SIZE):
			var pos = Vector2(start_x + col * SPACING, start_y + row * SPACING)
			grid_positions.append(pos)


# ==========================
# Callback en cada beat
# ==========================
func _on_beat():
	# En cada beat de la música intentamos spawnear una mole
	_spawn_mole()


# ==========================
# Spawn de moles
# ==========================
func _spawn_mole():
	# Buscar celdas libres
	var free_cells = []
	for i in range(occupied_cells.size()):
		if not occupied_cells[i]:
			free_cells.append(i)

	if free_cells.size() == 0:
		return  # todas ocupadas

	# Elegir celda aleatoria libre
	var cell_index = free_cells[randi() % free_cells.size()]
	var mole = mole_scene.instantiate()

	mole.position = grid_positions[cell_index]
	mole.cell_index = cell_index   # cada mole sabe en qué celda está
	mole.mole_whacked.connect(_on_mole_whacked)

	occupied_cells[cell_index] = true
	game_layer.add_child(mole)   # ahora las moles se agregan dentro del GameLayer


# ==========================
# Callback cuando mole es whacked
# ==========================
func _on_mole_whacked(mole):
	# Liberamos la celda y borramos la mole
	occupied_cells[mole.cell_index] = false
	mole.queue_free()


# ==========================
# Botón Play
# ==========================
func _on_play_button_pressed():
	play_button.visible = false   # Ocultar botón
	music.play()                  # Reproducir música
	beat_timer.start()            # Iniciar spawn de moles en tiempo con el BPM
