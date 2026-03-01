extends Node

# Permite definir no inspetor o objeto ideal
@export var hitbox_path: NodePath
# Recebe o nó no caminho especificado previamente
@onready var hitbox = get_node(hitbox_path)

var attacking := false # Flag para o status do ataque
var attack_timer := 0.0 # Tempo de ativação da hitbox (ataque)
const ATTACK_DURATION := 0.25 # Tempo máximo de ativação da hitbox 

# Função para inicializar o ataque
func start_attack():
	
	# Caso a flag já indique um ataque em andamento, a função é encerrada
	if attacking:
		return
	
	# Ativa a flag da função
	attacking = true
	# Define o tempo de ataque com a duração máxima pré-definida
	attack_timer = ATTACK_DURATION
	# Ativa o parâmetro de monitoramento da hitbox de ataque
	hitbox.monitoring = true

# Função para atualizar o tempo de ataque
func update(delta):
	
	# Caso a flag indique que não há um ataque em andamento, a função é encerrada
	if not attacking:
		return
	
	# O tempo de ataque é reduzido de acordo com o tempo
	attack_timer -= delta
	# Caso o tempo acabe, a flag é atualizada e o parâmetro de 
	# monitoramento da hitbox de ataque é desativado
	if attack_timer <= 0:
		attacking = false
		hitbox.monitoring = false
		
		# CONTINUAR DO ITEM 5 GPT
		
