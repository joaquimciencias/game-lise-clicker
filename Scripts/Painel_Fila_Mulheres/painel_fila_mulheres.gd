extends MarginContainer

const SILHUETA_CENA = preload("res://Scenes/Paineis/Fila_Mulheres/silhueta_mulher.tscn")

@onready var container_fila: Panel = $ContainerFila

var espacamento_x: float = 60.0 
var limite_maximo: int = 2
var fila_de_mulheres: Array = []

var texturas_diferentes: Array[Texture2D] = [
	preload("res://Assets/IMG/silhueta.png"),
	#preload("res://assets/silhueta_2.png"),
	#preload("res://assets/silhueta_3.png"),
	#preload("res://assets/silhueta_4.png"),
	#preload("res://assets/silhueta_5.png")
]

func _ready() -> void:
	for i in range(limite_maximo):
		adicionar_mulher_na_fila(true)
	# Aplica o tom de cinza inicial para todas
	atualizar_tons_de_cinza()

func adicionar_mulher_na_fila(instantaneo: bool = false) -> void:
	if fila_de_mulheres.size() >= limite_maximo:
		return
		
	var nova_mulher: TextureRect = SILHUETA_CENA.instantiate()
	container_fila.add_child(nova_mulher)
	fila_de_mulheres.append(nova_mulher)
	
	container_fila.move_child(nova_mulher, 0)
	
	if not texturas_diferentes.is_empty():
		var textura_aleatoria = texturas_diferentes[randi() % texturas_diferentes.size()]
		nova_mulher.texture = textura_aleatoria

	var indice = fila_de_mulheres.size() - 1
	var posicao_alvo = Vector2(indice * espacamento_x, 0) 
	
	if instantaneo:
		nova_mulher.position = posicao_alvo
	else:
		# Nasce na extrema direita, com opacidade total (sem transparência)
		nova_mulher.position = Vector2(limite_maximo * espacamento_x, 0)
		# Define como branco puro temporariamente antes do Tween atualizar os tons de forma síncrona
		nova_mulher.modulate = Color(1, 1, 1, 1)
		
		var tween = create_tween().set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
		tween.tween_property(nova_mulher, "position", posicao_alvo, 0.5)

func avancar_fila() -> void:
	if fila_de_mulheres.is_empty():
		return
		
	var mulher_da_vez = fila_de_mulheres.pop_front()
	
	var tween_sumir = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween_sumir.tween_property(mulher_da_vez, "position:x", -100.0, 0.3)
	# Apenas a primeira mulher desvanece a opacidade ao sair de cena para o painel de atendimento
	tween_sumir.parallel().tween_property(mulher_da_vez, "modulate:a", 0.0, 0.3)
	tween_sumir.tween_callback(mulher_da_vez.queue_free)
	
	for i in range(fila_de_mulheres.size()):
		var mulher = fila_de_mulheres[i]
		var nova_posicao_x = i * espacamento_x
		
		var tween_andar = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tween_andar.tween_property(mulher, "position:x", nova_posicao_x, 0.4)
		
	for i in range(fila_de_mulheres.size()):
		container_fila.move_child(fila_de_mulheres[i], container_fila.get_child_count() - 1 - i)
		
	adicionar_mulher_na_fila(false)
	
	# Recalcula e anima a transição de cor de todas as silhuetas que mudaram de lugar na fila
	atualizar_tons_de_cinza()

# Função responsável por aplicar o degradê opaco baseado na posição atual da fila
func atualizar_tons_de_cinza() -> void:
	for i in range(fila_de_mulheres.size()):
		var mulher = fila_de_mulheres[i]
		
		# Calcula o valor do canal RGB (0.0 = Preto, 1.0 = Branco)
		# Usamos o float(limite_maximo - 1) para mapear o topo da fila em 0 e a última em 1
		var fator_cinza: float = float(i) / float(limite_maximo - 1)
		
		# Garante que o valor fique estritamente entre 0 e 1 (segurança)
		fator_cinza = clampf(fator_cinza, 0.0, 1.0)
		
		# Cria a cor sólida (Alpha = 1.0 garante que não há transparência entre os rastros)
		var cor_alvo = Color(fator_cinza, fator_cinza, fator_cinza, 1.0)
		
		# Transiciona suavemente a cor antiga para a nova cor correspondente ao novo lugar na fila
		var tween_cor = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tween_cor.tween_property(mulher, "modulate", cor_alvo, 0.4)

# Retorna verdadeiro se não houver nenhuma mulher na fila
func esta_vazia() -> bool:
	return fila_de_mulheres.is_empty()
