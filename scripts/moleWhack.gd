extends Area2D

signal mole_whacked(mole)
signal mole_expired(mole)

@export var lifetime: float = 1.0
var cell_index: int = -1

# Referencias internas
@onready var sprite: Sprite2D = $Sprite2D
@onready var collision: CollisionShape2D = $CollisionShape2D
@onready var lifetime_timer: Timer = $LifetimeTimer


# Ruta de la textura golpeada
@export var whacked_texture: Texture2D

func _ready():
	lifetime_timer.wait_time = lifetime
	lifetime_timer.one_shot = true
	lifetime_timer.start()
	lifetime_timer.timeout.connect(_on_lifetime_timeout)

func _input_event(_viewport, event, _shape_idx):
	if event is InputEventMouseButton and event.pressed:
		_whack()

func _on_lifetime_timeout():
	emit_signal("mole_expired", self)
	queue_free()

func _whack():
	# Evitar doble golpe
	if not collision.disabled:
		# Señal al main
		emit_signal("mole_whacked", self)

		# Cambiar sprite al frame golpeado
		if whacked_texture:
			sprite.texture = whacked_texture

		# Desactivar colisión para que no reciba más clicks
		collision.disabled = true

		# Detener timer para que no borre antes de tiempo
		lifetime_timer.stop()

		# Esperar 0.3s antes de eliminar
		_delayed_remove()

func _delayed_remove():
	var t = Timer.new()
	t.wait_time = 0.3
	t.one_shot = true
	add_child(t)
	t.start()
	t.timeout.connect(func():
		if is_instance_valid(self):
			queue_free()
	)
