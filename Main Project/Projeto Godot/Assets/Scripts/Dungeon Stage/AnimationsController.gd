# ==============================================================================
# SCRIPT DESENVOLVIDO PARA LIDAR ESPECIFICAMENTE COM ANIMAÇÕES DO PLAYER
# ==============================================================================
extends Node

# ------------------------------------------------------------------------------
# Referências externas para os Sprites do jogador e do ataque
@export var player_sprite_path: NodePath
@onready var player_sprite = get_node(player_sprite_path)

@export var blade_effects_sprite_path: NodePath
@onready var blade_sprite = get_node(blade_effects_sprite_path)

# ------------------------------------------------------------------------------
# Sinais a serem enviados para os demais scripts associados
signal attack_animation_finished

# ------------------------------------------------------------------------------
# Lista de estados possíveis voltados para a implementação do FSM
enum PlayerState {
	IDLE,
	WALK,
	JUMP,
	FALL,
	WALL_SLIDE,
	ATTACK
}

# ==============================================================================
# FUNÇÃO READY PARA INICIALIZAÇÃO
# ==============================================================================
func _ready():

	# Os nós 'AnimatedSprite2D' possuem um sinal referente ao término de sua
	# animação, aqui, os sinais emitidos ao fim da animação são conectados à
	# função local _on_animation_finished
	if player_sprite:
		player_sprite.animation_finished.connect(_on_animation_finished)
	elif blade_sprite:
		blade_sprite.animation_finished.connect(_on_animation_finished)

# ==============================================================================
# FUNÇÃO AUXILIAR PARA EVITAR QUE UMA MESMA ANIMAÇÃO SEJA REINICIADA
# ==============================================================================
func _play(anim_name: String):
	
	if player_sprite.animation != anim_name:
		player_sprite.play(anim_name)

# ==============================================================================
# FUNÇÃO QUE GERENCIA AS ANIMAÇÕES ESPECÍFICAS DO SPRITE DO JOGADOR
# ==============================================================================
func update_player_animation(state):

	match state:

		PlayerState.WALL_SLIDE:
			_play("Player WallJump")
		PlayerState.JUMP:
			_play("Player Jump")
		PlayerState.FALL:
			_play("Player Fall")
		PlayerState.WALK:
			_play("Player Walk")
		PlayerState.IDLE:
			_play("Player Idle")

# ==============================================================================
# ANIMAÇÃO DE ATAQUE
# ==============================================================================
func play_attack_animation():
	blade_sprite.play("Blade Animation")
	player_sprite.play("Player Attack")
	
# ==============================================================================
# CALLBACK DE ANIMAÇÃO
# ==============================================================================
func _on_animation_finished():
	
	# Emite um sinal de término da animação referente aos ataques
	# tanto do player, quanto dos efeitos da lâmina. Estes sinais
	# serão processados pelo Attack Controller
	if player_sprite.animation == "Player Attack": 
		if blade_sprite.animation == "Blade Animation":
			emit_signal("attack_animation_finished")
