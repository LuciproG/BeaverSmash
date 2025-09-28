extends Area2D

# ==========================
# Señales
# ==========================
signal mole_whacked(mole)
signal mole_expired(mole)

# ==========================
# Variables
# ==========================
var cell_index: int = -1
@export var lifetime: float = 2.0

@onready var lifetime_timer: Timer = $LifetimeTimer

# ==========================
# Ready
# ==========================
func _ready():
	# Configurar el timer de vida
	lifetime_timer.wait_time = lifetime
	lifetime_timer.one_shot = true
	lifetime_timer.timeout.connect(_on_lifetime_timeout)
	lifetime_timer.start()
	
	# Conectar input_event solo si no estaba conectado
	var input_callable = Callable(self, "_on_input_event")
	if not input_event.is_connected(input_callable):
		input_event.connect(input_callable)

# ==========================
# Cuando la mole es golpeada
# ==========================
func whack():
	mole_whacked.emit(self)
	queue_free()

# ==========================
# Cuando expira el tiempo de vida
# ==========================
func _on_lifetime_timeout():
	mole_expired.emit(self)
	queue_free()

# ==========================
# Detectar clic del jugador
# ==========================
func _on_input_event(_viewport, event, _shape_idx):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		whack()
