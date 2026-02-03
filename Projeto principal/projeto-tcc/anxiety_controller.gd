extends Node
@onready var heartbeat = get_parent().get_node("Heartbeat")

@export var ansiedade := 0.0
@export var taxa_crescimento := 0.2
@export var ansiedade_max := 10.0

func _process(delta):
	ansiedade += taxa_crescimento * delta
	ansiedade = min(ansiedade, ansiedade_max)
	
	# O som acelera progressivamente de acordo com o grau de ansiedade
	heartbeat.pitch_scale = 1.0 + (ansiedade * 0.1)
