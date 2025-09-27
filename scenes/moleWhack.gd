extends Area2D

# ==========================
# Señales
# ==========================
signal mole_whacked   # Se emite cuando el jugador hace clic en la mole

# ==========================
# Variables
# ==========================
var cell_index: int   # Cada mole sabe en qué celda está (lo asigna el main.gd)


# ==========================
# Input sobre la mole
# ==========================
func _input_event(_viewport, event, _shape_idx):
	# Detecta si el evento es un click con el mouse
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		emit_signal("mole_whacked", self)  # Avisamos al main.gd que esta mole fue golpeada
