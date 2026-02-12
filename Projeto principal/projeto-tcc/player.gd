# Define que o Script opere com o objeto do tipo CharacterBody2D
extends CharacterBody2D

# @onready significa que essa variável só será atribuída quando o nó já estiver pronto na cena
# var anxiety_controller recebe os dados do nó (genérico) AnxietyController
@onready var anxiety_controller = get_parent().get_node("AnxietyController")

# Atribuição de valores constantes e estáticos para velocidade, gravidade e pulo
const SPEED := 300.0
const JUMP_VELOCITY := -400.0

# Função responsável por processar a física do player
# A função é chamada em um intervalo fixo, sincronizado com o sistema de física da engine
# O parâmetro delta representa o tempo decorrido desde o último frame.
# Essa função é responsável por tudo que envolve movimento físico, colisão ou forças.
func _physics_process(delta: float) -> void:
	
	# ============================================================================================ #
	# 								CONTROLE DA GRAVIDADE
	# ============================================================================================ #

	# Evita perda de contato com o chão, impedindo pequenos saltos ao mudar de inclinação.
	# Sempre que o player estuver em contado com o chão, a velocidade vertical não muda
	if is_on_floor():
		velocity.y = 0
	# Evita que o personagem acumule velocidade vertical indevida.
	else:
		velocity += get_gravity() * delta

	# ============================================================================================ #
	# 								CONTROLE DE PULO
	# ============================================================================================ #
	# Só funciona se o botão de ação for pressionado e se o jogador estiver em contato com o chão
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		# Define a velocidade no eixo Y para efetuar a propulsão do pulo
		velocity.y = JUMP_VELOCITY
	
	# ============================================================================================ #
	# 							CONTROLE DA TAXA DE INSTABILIDADE
	# ============================================================================================ #
	# Recebe o valor de ansiedade
	var ansiedade = anxiety_controller.ansiedade
	# Define a distorção do controle (Representado pela Ansiedade)
	var instabilidade = randf_range(-ansiedade * 10, ansiedade * 10)
	
	# ============================================================================================ #
	# 									MOVIMENTAÇÃO EFETIVA
	# ============================================================================================ #
	# A variável recebe o valor de entrada dos botões de comando (Definidos por padrão)
	# OBS: o operador := significa declaração com tipagem automática (type inference)
	#      Ele cria a variável e já define o tipo dela automaticamente com base no valor atribuído.
	var direction := Input.get_axis("ui_left", "ui_right")
	
	# Caso seja definido uma valor para direction:
	if direction:
		# A velocidade horizontal é aplicada considerando a velocidade definida e a instabilidade
		velocity.x = (direction * SPEED) + instabilidade
	# Caso não seja definido uma valor para direction:
	else:
		# A velocidade horizontal decrescida ao passo da velocidade
		# "Leva o valor atual (velocity.x) até o valor alvo (0) a um passo definido por SPEED"
		velocity.x = move_toward(velocity.x, 0, SPEED)
	
	# Redundância para ativar 'Stop on Slope' e 'Constant Speed' no inspetor.
	# Definem como o personagem se comporta no chão, considerando a inclinação
	# Stop on Slope -> Impede que o personagem escorregue sozinho em rampas quando está parado.
	# Constant Speed -> Mantém a velocidade constante ao andar em rampas.
	set_floor_stop_on_slope_enabled(true)
	set_floor_constant_speed_enabled(true)
	# OBSERVAÇÃO (Inspetor do CharacterBody2D):
	# Max Angle -> Angulo máximo que a engine considera a inclinação como 'chão'
	# Snap Length -> Faz o personagem “grudar” levemente no chão, evitando micro saltos.
	
	# ============================================================================================ #
	# 						CONTROLE DE ROTAÇÃO DO PERSONAGEM COM O CHÃO
	# ============================================================================================ #
	
	if is_on_floor():
		# Pega o valor normal da superfície
		var normal = get_floor_normal()
		# Define a rotação-alvo para o personagem de acordo com a normal da superfície
		var target_rotation = normal.angle() + PI/2
		# Aplica a rotação, de modo interpolada (garante suavidade).
		rotation = lerp_angle(rotation, target_rotation, 10 * delta)
	else:
		# Se o personagem não estiver em contato com o chão, a rotão retorna a 0
		rotation = 0
	
	# Função usada principalmente em CharacterBody2D (ou CharacterBody3D) para
	# mover o personagem aplicando colisão e fazendo ele deslizar nas superfícies automaticamente.
	move_and_slide()
