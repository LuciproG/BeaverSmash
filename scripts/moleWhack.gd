extends Area2D

signal mole_whacked(mole)
signal mole_expired(mole)
var whacked: bool = false


# ==========================
# Variables exportadas
# ==========================
@export var lifetime: float = 1.0
@export var hit_texture: Texture2D  # Arrastra aquí el sprite de “golpeado”

# ==========================
# Variables internas
# ==========================
var cell_index: int = -1

# Referencias
@onready var sprite: Sprite2D = $Sprite2D
@onready var collision: CollisionShape2D = $CollisionShape2D
@onready var lifetime_timer: Timer = $LifetimeTimer

# ==========================
# Ready
# ==========================
func _ready():
	lifetime_timer.wait_time = lifetime
	lifetime_timer.one_shot = true
	lifetime_timer.start()
	lifetime_timer.timeout.connect(_on_lifetime_timeout)

# ==========================
# Input
# ==========================
func _input_event(_viewport, event, _shape_idx):
	if event is InputEventMouseButton and event.pressed:
		_whack()

# ==========================
# Lifetime terminado
# ==========================
func _on_lifetime_timeout():
	emit_signal("mole_expired", self)
	queue_free()

# ==========================
# Golpeada
# ==========================
func _whack():
	if collision.disabled:
		return
	whacked = true
	
	# Cambiar el sprite a golpeado
	if hit_texture:
		sprite.texture = hit_texture

	collision.disabled = true
	lifetime_timer.stop()
	_delayed_remove()

# ==========================
# Espera antes de desaparecer
# ==========================
func _delayed_remove():
	var t = Timer.new()
	t.wait_time = 0.3
	t.one_shot = true
	add_child(t)
	t.start()
	t.timeout.connect(func():
		if is_instance_valid(self):
			if whacked:
				emit_signal("mole_whacked", self)
			else:
				emit_signal("mole_expired", self)
			queue_free()
	)
