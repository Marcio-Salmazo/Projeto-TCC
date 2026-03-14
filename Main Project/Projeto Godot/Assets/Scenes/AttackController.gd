# ==============================================================================
# SCRIPT DESENVOLVIDO PARA LIDAR APENAS COM A EXECUÇÃO DO ATAQUE DO PLAYER
# ENVOLVENDO SINAIS E DETECÇÃO/CONTROLE DE HITBOX
# ==============================================================================
extends Node

# ------------------------------------------------------------------------------
# Sinais a serem enviados para os demais scripts associados

signal attack_started
# Quando o sinal de finalização do ataque for emitido, a função 
# "_on_attack_finished" do Script PlayerController.gd é chamada
signal attack_finished

# ------------------------------------------------------------------------------
# Referência externa para o HitBox
@export var hitbox_path : NodePath
@onready var attack_hitbox : Area2D = get_node(hitbox_path)
# Referência externa para o Animator Controller
@export var animator_controller_path : NodePath
@onready var animator_controller = get_node(animator_controller_path)

# ------------------------------------------------------------------------------
# Estado inicial interno (Entende-se que o jogador não começa em ataque)
var attacking := false

# ==============================================================================
# FUNÇÃO READY PARA INICIALIZAÇÃO
# ==============================================================================
func _ready():

	# Garante que a hitbox começa desligada
	if attack_hitbox:
		attack_hitbox.monitoring = false

	# conecta o sinal de fim da animação, proveniente do AnimatorController.gd
	# à função local 'end_attack' responsável por gerenciar as modificações
	# associadas ao fim do Ataque
	if animator_controller:
		if animator_controller.has_signal("attack_animation_finished"):
			animator_controller.attack_animation_finished.connect(end_attack)

# ==============================================================================
# FUNÇÃO QUE INICIALIZA O ATAQUE
# ==============================================================================
func start_attack():
	
	# Caso o jogador já esteja atacando, a função é ignorada
	if attacking:
		return
		
	# Inicializa o fluxo de ataque, indicado pela flag attacking
	attacking = true
	# Emite um sinal que o fluxo foi iniciado (O qual servirá como referência
	# para os demais Scripts que lidam com a mecânica de ataque)
	emit_signal("attack_started")

	# ativa hitbox
	if attack_hitbox:
		attack_hitbox.monitoring = true

	# Solicita ao AnimatorController para tocar animação
	if animator_controller:
		animator_controller.play_attack_animation()

# ==============================================================================
# FINALIZAR ATAQUE
# ==============================================================================
func end_attack():
	
	# Caso o jogador não esteja atacando, a função é ignorada
	if not attacking:
		return
		
	# Encerra o fluxo de ataque, indicado pela flag attacking
	attacking = false

	# Desativa hitbox
	if attack_hitbox:
		attack_hitbox.monitoring = false
	
	# Emite um sinal que o fluxo foi encerrado (O qual servirá como referência
	# para o Script PlayerController.gd)
	emit_signal("attack_finished")
