# ==============================================================================
# SCRIPT DESENVOLVIDO PARA LIDAR APENAS COM MOVIMENTOS E ESTADOS DO JOGADOR
# ==============================================================================

# Define que o Script opere com o objeto do tipo CharacterBody2D
extends CharacterBody2D

# ------------------------------------------------------------------------------
# Referências externas
@export var animation_controller_path : NodePath
@onready var animation_controller = get_node(animation_controller_path)

@export var attack_controller_path : NodePath
@onready var attack_controller = get_node(attack_controller_path)

# ------------------------------------------------------------------------------
# var sprite recebe os dados do nó AnimatedSprite2D referente ao sprite animado.
# O operador $ é um atalho conveniente para a função get_node(...),
# ele permite acessar um nó filho sem a necessidade de usar métodos como.
@onready var visuals = $"Player Visuals"
@onready var spr_rotator = $"Player Visuals/Main Sprites"
@onready var sprite = $"Player Visuals/Main Sprites/AnimatedSprite2D (player)"

# ------------------------------------------------------------------------------
# Lista de estados possíveis voltados para a implementação do FSM,
# Facilitando o desenvolvimento futuro
enum PlayerState {
	IDLE,
	WALK,
	JUMP,
	FALL,
	WALL_SLIDE,
	ATTACK
}
# Definição dos estados padrão para inicialização 
var current_state : PlayerState = PlayerState.IDLE
var previous_state : PlayerState = PlayerState.IDLE

# ------------------------------------------------------------------------------
# Variáveiis responsaveis pela movimentação física
# O operador := significa declaração com tipagem automática (type inference)

const SPEED := 100.0 # Velocidade de movimento
const JUMP_VELOCITY := -300.0 # Força de pulo
const ACCELERATION := 200.0 # Força de aceleração
const FRICTION := 800.0 # Força de arrasto

# ------------------------------------------------------------------------------
# Variáveiis responsaveis pela mecânica de WallJump
const WALL_SLIDE_SPEED := 40.0 # Velocidade de deslizar na parede
const WALL_JUMP_FORCE_X := 150.0 # Força de pulo no eixo X
const WALL_JUMP_FORCE_Y := -260.0 # Força de pulo no eixo Y
const WALL_JUMP_LOCK_TIME := 0.2 # Tempo que o personagem fica 'colado'

# ------------------------------------------------------------------------------
# Controle de ataque
var attacking := false

# ==============================================================================
# FUNÇÃO READY (INICIALIZADOR)
# ==============================================================================
func _ready():
	
	# Redundância para ativar 'Stop on Slope' e 'Constant Speed' no inspetor.
	# Definem como o personagem se comporta no chão, considerando a inclinação
	set_floor_stop_on_slope_enabled(true)
	set_floor_constant_speed_enabled(true)
	# OBSERVAÇÃO (Inspetor do CharacterBody2D):
	# Max Angle -> Angulo máximo que a engine considera a inclinação como 'chão'
	# Snap Length -> Evitando micro saltos.
	
	# Conecta sinal enviado pelo AttackController
	# Caso o attack_controller tenha um sinal denominado "attack_finished", 
	# esse sinal é conectado à função local _on_attack_finished no momento
	# em que ele for emitido pelo nó definido por "attack_controller"
	if attack_controller.has_signal("attack_finished"):
		attack_controller.attack_finished.connect(_on_attack_finished)

# ==============================================================================
# FUNÇÃO PHYSICS (EXECUTA EM LOOP DE ACORDO COM O FPS)
# ==============================================================================
func _physics_process(delta):
	# Função principal do script responsável por processar a física do player
	# Flags abaixo indicam se o personagem está em contato com o chão ou parede
	var on_floor = is_on_floor()
	var on_wall = is_on_wall()
	
	# Chamada de funções para lidar com físicas e mecânicas
	_handle_gravity(delta, on_floor)
	_handle_movement(delta)
	_handle_jump(on_floor, on_wall)
	_handle_rotation(on_floor, spr_rotator, delta)
	_handle_attack_input(on_wall)
	
	# método responsável por mover corpos de personagem (CharacterBody2D/3D) 
	# que precisam de detecção de colisão, deslizamento em paredes e rampas.
	move_and_slide()
	
	# Decide o estado atual estado do player
	_update_state(on_floor, on_wall, previous_state)                 
	# Atualiza a animação a ser executada
	_update_animation(current_state)

# ==============================================================================
# FUNÇÃO QUE CONTROLA O FSM
# ==============================================================================
func _update_state(on_floor, on_wall, param_previous_state):
	# Função responsável apenas por decidir o estado atual do personagem.
	# Essa função define prioridade, de modo que apenas 1 estado é ativo por vez
	
	# Sai da função ser o jogador está atacando, mantendo-o em ataque
	if attacking:
		current_state = PlayerState.ATTACK
		return
	
	# Conjunto de estados caso o jogador não esteja em contato com o chão
	# Aqui são definidos os controles de pulo, walljump e queda
	if not on_floor:
		if on_wall and velocity.y > 0:
			current_state = PlayerState.WALL_SLIDE
		elif velocity.y < 0:
			current_state = PlayerState.JUMP
		else:
			current_state = PlayerState.FALL
	
	# Estado do player caso esteja em contato com o chão e tenha
	# uma velocidade horizontal absoluta superior a 5 
	elif abs(velocity.x) > 5:
		current_state = PlayerState.WALK
	# Estado do player caso esteja parado
	else:
		current_state = PlayerState.IDLE
	
	# Evita de atualizar um estado para um mesmo estado anterior
	if current_state != param_previous_state:
		previous_state = current_state

# ==============================================================================
# FUNÇÃO DE ATUALIZAÇÃO DAS ANIMAÇÕES
# ==============================================================================
func _update_animation(param_current_state):
	
	# Atualiza qual animação deve ser tocada, considerando o estado atual
	# do personagem do jogo, DESCONSIDERANDO a animação de ataque. 
	# A escolha se baseia por meio da cláusula 'match'
	# que busca correspondências de maneira análoga à um switch-case
	if animation_controller and param_current_state != PlayerState.ATTACK:
		animation_controller.update_player_animation(param_current_state)

	if velocity.x != 0:
		sprite.flip_h = velocity.x < 0

# ==============================================================================
# FUNÇÃO DE CONTROLE DA GRAVIDADE
# ==============================================================================
func _handle_gravity(delta, on_floor):
	
	# Evita perda de contato com o chão, impedindo pequenos saltos 
	# ao mudar de inclinação. Sempre que o player estiver em contado com o chão, 
	# a velocidade vertical não muda.
	if not on_floor:
		velocity.y += get_gravity().y * delta

# ==============================================================================
# FUNÇÃO DE CONTROLE DE MOVIMENTO
# ==============================================================================
func _handle_movement(delta):

	# Recebe inputs para o movimento horizontal
	var direction := Input.get_axis("ui_left", "ui_right")
	# Target speed indica velocidade horizontal máxima
	var target_speed = direction * SPEED
	
	# A velocidade no eixo X vai de seu valor original até a velocidade 
	# máxima definida a um passo positivo ou negativo de acordo com a 
	# direção do comando
	velocity.x = move_toward(velocity.x, target_speed, 
		(ACCELERATION if direction != 0 else FRICTION) * delta)

# ==============================================================================
# FUNÇÃO PARA CONTROLE DE PULO E WALLJUMP
# ==============================================================================
func _handle_jump(on_floor, on_wall):
	
	# Controle de WallSlide (Apenas se o jogador em contato com a parede)
	if on_wall and not on_floor and velocity.y > 0:
		velocity.y = WALL_SLIDE_SPEED
		
	if Input.is_action_just_pressed("ui_accept"):
		if is_on_floor():
			velocity.y = JUMP_VELOCITY

		elif is_on_wall():
			# Caso esteja em contato com parede, é pego o valor da normal 
			# da parede e aplica uma força tanto horizontal quanto vertical 
			# para executar um pulo para cima e no sentido contrário
			var normal = get_wall_normal()
			velocity = Vector2(normal.x * WALL_JUMP_FORCE_X, WALL_JUMP_FORCE_Y)

# ==============================================================================
# FUNÇÃO QUE LIDA COM ROTAÇÃO DO PLAYER EM DIFERENTES SUPERFÍCIES
# ==============================================================================
func _handle_rotation(on_floor, param_spr_rotator, delta):
	
	if on_floor:
		# Pega o valor normal da superfície
		var normal = get_floor_normal()
		# Define a rotação-alvo para o personagem de acordo com a normal do chão
		var target_rotation = normal.angle() + PI/2
		
		# Aplica a rotação, de modo interpolada (garante suavidade)
		# Aplica a rotação no nó que não carrega o sprite.
		# Pixel perfect horizontal é incompatível com rotação contínua do sprite
		spr_rotator.rotation = lerp_angle(param_spr_rotator.rotation, 
		target_rotation, 10 * delta)
		
	else:
		# Se o personagem não estiver em contato com o chão, a rotão retorna a 0
		spr_rotator.rotation = 0

# ==============================================================================
# INPUT DE ATAQUE
# ==============================================================================
func _handle_attack_input(on_wall):
	
	# Sai da função caso o jogador já esteja no estado de ataque
	if attacking:
		return
	
	# Entra no fluxo de ataque caso o botão seja pressionado e o jogados
	# não esteja em contato com alguma parede
	if Input.is_action_just_pressed("attack") and not on_wall:
		
		# Atualiza a flag de ataque e 
		# Inicia o método que controla o Ataque no Script associado
		# ao nó Attack Controller
		attacking = true
		if attack_controller:
			attack_controller.start_attack()
			
# ==============================================================================
# CALLBACK OARA O ATAQUE
# ==============================================================================

func _on_attack_finished():
	
	# Quando o nó attack_controller emitir o sinal denominado "attack_finished", 
	# a flag de ataque é atualizada e definida como 'False'
	attacking = false
