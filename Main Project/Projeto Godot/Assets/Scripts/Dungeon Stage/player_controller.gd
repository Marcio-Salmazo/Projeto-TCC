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

# var attack_controller recebe os dados do nó Attack Controller
@export var attack_controller_path : NodePath
@onready var attack_controller = get_node(attack_controller_path)

# --------------------------------------------------------------------------------------------------

# var sprite recebe os dados do nó AnimatedSprite2D referente ao sprite animado.
# O operador $ é um atalho conveniente para a função get_node(...),
# ele permite acessar um nó filho sem a necessidade de usar métodos como.
@onready var visuals = $"Player Visuals"
@onready var spr_rotator = $"Player Visuals/Main Sprites"
@onready var sprite = $"Player Visuals/Main Sprites/AnimatedSprite2D"

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
# Definição do estado atual 
var current_state = PlayerState.IDLE
# Definição do estado anterior para permitir a detecção de transições de estado
var previous_state = PlayerState.IDLE

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

# ==================================================================================================
# 									FUNÇÕES DO SCRIPT
# ==================================================================================================

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

# ..................................................................................................

# Função principal do script responsável por processar a física do player
# A função é chamada em um intervalo fixo, sincronizado com o sistema de física da engine
# O parâmetro delta representa o tempo decorrido desde o último frame.
# Essa função é responsável por tudo que envolve movimento físico, colisão ou forças.
func _physics_process(delta):
	
	# Flags para indicar se o personagem está em contato com o chão ou parede
	var on_floor = is_on_floor()
	var on_wall = is_on_wall()
	
	handle_gravity(delta, on_floor)
	handle_movement(delta)
	handle_jump(on_floor, on_wall)
	handle_rotation(on_floor, spr_rotator, delta)
	
	move_and_slide()
	
	# Decide qual estado o player está
	update_state(on_floor, on_wall, previous_state)          
	# Executa comportamento do estado
	handle_state()          
	# Atualiza a animação a ser executada
	update_animation(current_state)

# ..................................................................................................

# Função responsável apenas por decidir o estado atual do personagem.
# Essa função define prioridade, de modo que apenas 1 estado é ativo por vez
# Importante destacar que agora, os estados também apresentam noção de prioridade
func update_state(on_floor, on_wall, param_previous_state):
	
	# Verfica se o jogador está atacando e altera o estado
	if attack_controller.attacking:
		current_state = PlayerState.ATTACK
		return
	
	# Conjunto de eventos caso o jogador não esteja em contato com o chão
	if not on_floor:
		if on_wall and velocity.y > 0:
			current_state = PlayerState.WALL_SLIDE
		elif velocity.y < 0:
			current_state = PlayerState.JUMP
		else:
			current_state = PlayerState.FALL
	
	# Conjunto de eventos caso o jogador esteja em contato com o 
	# chão e não esteja atacando
	elif abs(velocity.x) > 5:
		current_state = PlayerState.WALK

	else:
		current_state = PlayerState.IDLE
		
	if current_state != param_previous_state:
		previous_state = current_state

# ..................................................................................................

# Função responsável por executar comportamentos dependendo do estado atual.
# Neste caso inicial, alguns estados não precisam fazer nada ainda, 
# mas essa função abre espaço para expansão futura.
# Exemplo:
# 		ATTACK → bloquear movimento
# 		HURT → knockback
# 		PANIC → controles instáveis
func handle_state():
	
	# 'match' é usada para controlar o fluxo comparando uma variável com vários padrões.
	# semelhante a `switch` em outras linguagens
	match current_state:

		PlayerState.ATTACK:
			pass 
		PlayerState.WALL_SLIDE:
			pass
		PlayerState.JUMP:
			pass
		PlayerState.FALL:
			pass
		PlayerState.WALK:
			pass
		PlayerState.IDLE:
			pass

# ..................................................................................................

# Função responsável pelo gerenciamento físico da Gravidade
func handle_gravity(delta, on_floor):
	
	# Evita perda de contato com o chão, impedindo pequenos saltos ao mudar de inclinação.
	# Sempre que o player estiver em contado com o chão, a velocidade vertical não muda
	if not on_floor:
		velocity.y += get_gravity().y * delta

# ..................................................................................................

func handle_movement(delta):
	
	# A variável recebe o valor de entrada dos botões de comando (Definidos por padrão)
	# OBS: o operador := significa declaração com tipagem automática (type inference)
	# Ele cria a variável e já define o tipo dela automaticamente com base no valor atribuído.
	
	var direction := Input.get_axis("ui_left", "ui_right")
	# A velocidade horizontal máxima é indicada por target_speed
	var target_speed = direction * SPEED
	
	# A velocidade no eixo X vai de seu valor original até a velocidade máxima definida
	# a um passo positivo ou negativo de acordo com a direção do comando
	velocity.x = move_toward(velocity.x, target_speed, 
		(ACCELERATION if direction != 0 else FRICTION) * delta)

# ..................................................................................................

func handle_jump(on_floor, on_wall):
	
	# Controle de WallSlide (Apenas se o jogador em contato com a parede mas não o chão)
	if on_wall and not on_floor and velocity.y > 0:
		velocity.y = WALL_SLIDE_SPEED
		
	if Input.is_action_just_pressed("ui_accept"):

		if is_on_floor():
			velocity.y = JUMP_VELOCITY

		elif is_on_wall():
			# Caso esteja em contato com parede, é pego o valor da normal da parede
			# e aplica uma força tanto horizontal quanto vertical para executar um
			# pulo para cima e no sentido contrário
			var normal = get_wall_normal()
			velocity = Vector2(normal.x * WALL_JUMP_FORCE_X, WALL_JUMP_FORCE_Y)

# ..................................................................................................

func handle_rotation(on_floor, param_spr_rotator, delta):
	
	if on_floor:
		# Pega o valor normal da superfície
		var normal = get_floor_normal()
		# Define a rotação-alvo para o personagem de acordo com a normal da superfície
		var target_rotation = normal.angle() + PI/2
		
		# Aplica a rotação, de modo interpolada (garante suavidade).
		# Aplica a rotação no nó que não carrega o sprite. 
		# Pixel perfect horizontal é incompatível com rotação contínua do sprite.
		spr_rotator.rotation = lerp_angle(param_spr_rotator.rotation, target_rotation, 10 * delta)
		
	else:
		# Se o personagem não estiver em contato com o chão, a rotão retorna a 0
		spr_rotator.rotation = 0

# ..................................................................................................

# Atualiza qual animação deve ser tocada, considerando o estado atual
# do personagem do jogo. A escolha se baseia por meio da cláusula 'match'
# que busca correspondências de maneira análoga à um switch-case
func update_animation(param_current_state):
	
	animation_controller.update_player_animation(param_current_state)
	
	# Controle de direção do sprite
	if velocity.x != 0:
		sprite.flip_h = velocity.x < 0

# ..................................................................................................
