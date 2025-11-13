extends Area2D

signal mole_whacked(mole)
signal mole_expired(mole)

# ==========================
# Variables
# ==========================
@export var lifetime: float = 2.0
@export var hit_texture: Texture2D

var cell_index: int = -1
var is_hit: bool = false

# ==========================
# Referencias
# ==========================
@onready var sprite: Sprite2D = $Sprite2D
@onready var collision: CollisionShape2D = $CollisionShape2D
@onready var lifetime_timer: Timer = $LifetimeTimer

# ==========================
# Inicialización
# ==========================
func _ready():
	lifetime_timer.wait_time = lifetime
	lifetime_timer.one_shot = true
	lifetime_timer.timeout.connect(_on_lifetime_timeout)
	lifetime_timer.start()

# ==========================
# Input
# ==========================
func _input_event(_viewport, event, _shape_idx):
	if event is InputEventMouseButton and event.pressed and not is_hit:
		_whack()

# ==========================
# Golpear
# ==========================
func _whack():
	is_hit = true
	collision.disabled = true
	lifetime_timer.stop()
	
	# Cambiar sprite
	if hit_texture:
		sprite.texture = hit_texture
	
	# Emitir señal y eliminar después de 0.3s
	mole_whacked.emit(self)
	await get_tree().create_timer(0.3).timeout
	queue_free()

# ==========================
# Expirar
# ==========================
func _on_lifetime_timeout():
	if not is_hit:
		mole_expired.emit(self)
