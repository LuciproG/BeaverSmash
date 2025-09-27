extends Area2D

# ==========================
# Señales
# ==========================
signal mole_whacked(mole)   # Emitida cuando el jugador golpea la mole
signal mole_expired(mole)   # Emitida cuando la mole desaparece sola

# ==========================
# Variables
# ==========================
var cell_index: int = -1    # La celda en la que aparece la mole
@export var lifetime: float = 2.0   # Tiempo de vida en segundos

@onready var lifetime_timer: Timer = $LifetimeTimer   # Timer que controla cuánto vive la mole


# ==========================
# Ready
# ==========================
func _ready():
	# Configurar el timer de vida
	lifetime_timer.wait_time = lifetime
	lifetime_timer.one_shot = true
	lifetime_timer.timeout.connect(_on_lifetime_timeout)
	lifetime_timer.start()
	
	# Escuchar clics en la mole
	input_event.connect(_on_input_event)


# ==========================
# Cuando la mole es golpeada
# ==========================
func whack():
	mole_whacked.emit(self)   # Avisamos al Main que fue golpeada
	queue_free()              # Desaparece inmediatamente


# ==========================
# Cuando expira el tiempo de vida
# ==========================
func _on_lifetime_timeout():
	mole_expired.emit(self)   # Avisamos al Main que desapareció
	queue_free()              # Desaparece sola


# ==========================
# Detectar clic del jugador
# ==========================
func _on_input_event(viewport, event, shape_idx):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		whack()
