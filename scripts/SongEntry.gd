extends Button

# ==========================
# Variables
# ==========================
@export var song_name: String # Nombre de la canción
@export var duration: String # Duración en formato mm:ss
@export var high_score: int # Puntuación más alta
@export var illustration: Texture # Ilustración/fondo de la canción

# Señal personalizada para avisar cuando se selecciona una canción
signal song_selected(data: Dictionary)

func _ready():
	# Configura los labels internos con la info de la canción
	$VBoxContainer/NameLabel.text = song_name
	$VBoxContainer/DurationLabel.text = duration
	$VBoxContainer/ScoreLabel.text = "High Score: %s" % high_score

func _pressed():
	# Cuando se hace click, emite la señal con todos los datos de la canción
	emit_signal("song_selected", {
		"name": song_name,
		"duration": duration,
		"high_score": high_score,
		"illustration": illustration
	})
