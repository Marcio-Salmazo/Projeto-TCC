extends Node

# Permite definir no inspetor o objeto ideal
@export var player_sprite_path: NodePath
# Recebe o nó no caminho especificado previamente
@onready var sprite = get_node(player_sprite_path)

# Lista de estados possíveis voltados para a implementação do FSM,
# Deve seguir o mesmo enum definido em Play_Controller.gd
enum PlayerState {
	IDLE,
	WALK,
	JUMP,
	FALL,
	WALL_SLIDE,
	ATTACK
}

# Armazena o estado padrão de ataque
var attacking := false
# ============================================================================================ #
# 						FUNÇÃO PARA CONTROLE DE ANIMAÇÕES DO PLAYER
# ============================================================================================ #

# Se a animação atual for diferente deve-se tocar animação nova. Senão, não fazer nada
# Ela evita de ficar reiniciando o loop de animação, caso a mesma condicional seja atendida.
func play(anim_name: String):
	if sprite.animation != anim_name:
		sprite.play(anim_name)

# Essa função apenas atualiza o estado de ataque, não toca animação diretamente.
func update_event_attack(is_attacking):
	attacking = is_attacking

func update_player_animation(state):

	match state:

		PlayerState.ATTACK:
			play("Player Attack")
		PlayerState.WALL_SLIDE:
			play("Player WallJump")
		PlayerState.JUMP:
			play("Player Jump")
		PlayerState.FALL:
			play("Player Fall")
		PlayerState.WALK:
			play("Player Walk")
		PlayerState.IDLE:
			play("Player Idle")
