extends Node

# Permite definir no inspetor o objeto ideal
@export var player_sprite_path: NodePath
# Recebe o nó no caminho especificado previamente
@onready var sprite = get_node(player_sprite_path)

# ============================================================================================ #
# 						FUNÇÃO PARA CONTROLE DE ANIMAÇÕES DO PLAYER
# ============================================================================================ #

func update_state_player(velocity, on_floor, on_wall):
	
	# Caso não esteja em contato com o solo:
	if not on_floor:
		
		# Se estiver em contato com parede, mas não com o solo e a 
		# velocidade em Y for positiva (Estiver em queda)
		# a animação de escorregar é iniciada
		if on_wall and velocity.y !=0:
			sprite.play("Player WallJump")
		
		# Se não estiver em contato com o chão e a velocidade em Y for negativa
		# (Estiver saltando) a animação de pulo é iniciada
		elif velocity.y < 0:
			sprite.play("Player Jump")
			
		# Se não estiver em contato com o chão, nem com a parede 
		# e a velocidade em Y for positiva a animação de queda é iniciada
		else:
			sprite.play("Player Fall")
	
	# Se estiver no chão e a velocidade aboluta em X for positiva 
	# a animação de andar será iniciada
	elif abs(velocity.x) > 5:
		sprite.play("Player Walk")
	
	# Se estiver no chão, a animação de ficar parado é iniciada
	else:
		sprite.play("Player Idle")
	
	# Inverte a orientação da imagem sempre que a velocidade em X for negativa
	# Nos momentos em que o jogador esteja no chão
	# Quando o player para (velocity.x == 0),
	#o sprite pode virar inesperadamente dependendo do último valor.
	if velocity.x != 0:
		sprite.flip_h = velocity.x < 0
