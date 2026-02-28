# Define que o Script opere com o objeto do tipo CharacterBody2D
extends CharacterBody2D

# --------------------------------------------------------------------------------------------------

# @onready significa que essa variável só será atribuída quando o nó já estiver pronto na cena
# @export var anxiety_controller_path -> Permite definir a referência no Inspetor

# var anxiety_controller recebe os dados do nó Player Events Controller
@export var anxiety_controller_path : NodePath
@onready var anxiety_controller = get_node(anxiety_controller_path)

# var animation_controller recebe os dados do nó Player Animations
@export var animation_controller_path : NodePath
@onready var animation_controller = get_node(animation_controller_path)
# --------------------------------------------------------------------------------------------------

# var sprite recebe os dados do nó AnimatedSprite2D referente ao sprite animado.
# O operador $ é um atalho conveniente para a função get_node(...),
# ele permite acessar um nó filho sem a necessidade de usar métodos como.
@onready var visuals = $"Player Visuals"
@onready var rotator = $"Player Visuals/Main Sprites"
@onready var sprite = $"Player Visuals/Main Sprites/AnimatedSprite2D"

# @onready significa que essa variável só será atribuída quando o nó já estiver pronto na cena
# A variável recebe o nó que contém o controle das animações do player, de modo a enviar 
# status para o controlador.

# --------------------------------------------------------------------------------------------------
# Variáveiis responsaveis pela movimentação física

const SPEED := 100.0 # Velocidade de movimento
const JUMP_VELOCITY := -300.0 # Força de pulo
const ACCELERATION := 200.0 # Força de aceleração
const FRICTION := 800.0 # Força de arrasto

# --------------------------------------------------------------------------------------------------
# Variáveiis responsaveis pela mecânica de WallJump

const WALL_SLIDE_SPEED := 40.0 # Velocidade na qual o personagem desliza na parede
const WALL_JUMP_FORCE_X := 150.0 # Força de pulo no eixo X
const WALL_JUMP_FORCE_Y := -260.0 # Força de pulo no eixo Y
const WALL_JUMP_LOCK_TIME := 0.2 # Tempo que o personagem fica 'colado'

# --------------------------------------------------------------------------------------------------
# Funções do script

# Função executada apenas ao instanciar o objeto
func _ready():
	# Redundância para ativar 'Stop on Slope' e 'Constant Speed' no inspetor.
	# Definem como o personagem se comporta no chão, considerando a inclinação
	# Stop on Slope -> Impede que o personagem escorregue sozinho em rampas quando está parado.
	# Constant Speed -> Mantém a velocidade constante ao andar em rampas.
	set_floor_stop_on_slope_enabled(true)
	set_floor_constant_speed_enabled(true)
	# OBSERVAÇÃO (Inspetor do CharacterBody2D):
	# Max Angle -> Angulo máximo que a engine considera a inclinação como 'chão'
	# Snap Length -> Faz o personagem “grudar” levemente no chão, evitando micro saltos.

# Função responsável por processar a física do player
# A função é chamada em um intervalo fixo, sincronizado com o sistema de física da engine
# O parâmetro delta representa o tempo decorrido desde o último frame.
# Essa função é responsável por tudo que envolve movimento físico, colisão ou forças.
func _physics_process(delta: float) -> void:
	
	# ============================================================================================ #
	# 							CONTROLE DA TAXA DE INSTABILIDADE
	# ============================================================================================ #
	# Recebe o valor de ansiedade
	# var ansiedade = anxiety_controller.ansiedade
	# Define a distorção do controle (Representado pela Ansiedade)
	#var instabilidade = randf_range(-ansiedade * 10, ansiedade * 10)
	
	# Mantém sem instabilidade de gameplay (Para fins de teste)
	# RETIRAR ESTE TRECHO FUTURAMENTE
	var instabilidade = 0
	
	# ============================================================================================ #
	# 								CONTROLE DA GRAVIDADE
	# ============================================================================================ #
	
	# Flags para indicar se o personagem está em contato com o chão ou parede
	var on_floor = is_on_floor()
	var on_wall = is_on_wall()
	
	# Evita perda de contato com o chão, impedindo pequenos saltos ao mudar de inclinação.
	# Sempre que o player estiver em contado com o chão, a velocidade vertical não muda
	if on_floor:
		velocity.y = 0
	# Evita que o personagem acumule velocidade vertical indevida.
	else:
		velocity.y += get_gravity().y * delta
		
	# Controle de WallSlide (Apenas se o jogador em contato com a parede mas não o chão)
	if on_wall and not on_floor and velocity.y > 0:
		velocity.y = min(velocity.y, WALL_SLIDE_SPEED)
	
	# ============================================================================================ #
	# 								MOVIMENTAÇÃO EFETIVA
	# ============================================================================================ #
	# A variável recebe o valor de entrada dos botões de comando (Definidos por padrão)
	# OBS: o operador := significa declaração com tipagem automática (type inference)
	# Ele cria a variável e já define o tipo dela automaticamente com base no valor atribuído.
	
	var direction := Input.get_axis("ui_left", "ui_right")
	# A velocidade horizontal máxima é indicada por target_speed
	var target_speed = direction * SPEED + instabilidade
	
	# A velocidade no eixo X vai de seu valor original até a velocidade máxima definida
	# a um passo positivo ou negativo de acordo com a direção do comando
	velocity.x = move_toward(velocity.x, target_speed, 
		(ACCELERATION if direction != 0 else FRICTION) * delta)
	
	# ============================================================================================ #
	# 							CONTROLE DE PULO e WALLJUMP
	# ============================================================================================ #
	
	if Input.is_action_just_pressed("ui_accept"):

		if is_on_floor():
			velocity.y = JUMP_VELOCITY

		elif is_on_wall():
			# Caso esteja em contato com parede, é pego o valor da normal da parede
			# e aplica uma força tanto horizontal quanto vertical para executar um
			# pulo para cima e no sentido contrário
			var normal = get_wall_normal()
			velocity = Vector2(
				normal.x * WALL_JUMP_FORCE_X,
				WALL_JUMP_FORCE_Y
				)
				
	
	# ============================================================================================ #
	# 					CONTROLE DE ROTAÇÃO DO PERSONAGEM COM O CHÃO
	# ============================================================================================ #
	
	if on_floor:
		# Pega o valor normal da superfície
		var normal = get_floor_normal()
		# Define a rotação-alvo para o personagem de acordo com a normal da superfície
		var target_rotation = normal.angle() + PI/2
		
		# Aplica a rotação, de modo interpolada (garante suavidade).
		# Aplica a rotação no nó que não carrega o sprite. 
		# Pixel perfect horizontal é incompatível com rotação contínua do sprite.
		rotator.rotation = lerp_angle(rotator.rotation, target_rotation, 10 * delta)
		
	else:
		# Se o personagem não estiver em contato com o chão, a rotão retorna a 0
		rotator.rotation = 0
	
	# Função usada principalmente em CharacterBody2D (ou CharacterBody3D) para
	# mover o personagem aplicando colisão e fazendo ele deslizar nas superfícies automaticamente.
	move_and_slide()
	
	# ============================================================================================ #
	# 					ENVIO DE SINAIS AO CONTROLADOR DE ANIMAÇÕES DO PLAYER
	# ============================================================================================ #
	
	# A variável que se conecta ao controlador de animações executa a função Update_state
	# responsável por pegar o estado atual do personagem e aplicar animações
	animation_controller.update_state_player(velocity, is_on_floor(), is_on_wall())
	
