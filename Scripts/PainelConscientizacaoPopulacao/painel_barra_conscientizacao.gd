extends MarginContainer

@onready var progress_bar: ProgressBar = $VBoxContainer/HBoxContainer/MarginContainer/ProgressBar
@onready var particulas: GPUParticles2D = $VBoxContainer/HBoxContainer/MarginContainer/ProgressBar/GPUParticles2D
@onready var progress_bar_damage: ProgressBar = $VBoxContainer/HBoxContainer/MarginContainer/ProgressBarDamage

var tween_dano: Tween

func _ready() -> void:
	add_to_group("barra_conscientizacao") # <--- ADICIONE ESTA LINHA
	# Configura ambas as barras para 0-100%
	progress_bar.max_value = 100.0
	progress_bar.min_value = 0.0
	progress_bar.step = 0.0
	
	if progress_bar_damage:
		progress_bar_damage.max_value = 100.0
		progress_bar_damage.min_value = 0.0
		progress_bar_damage.step = 0.0

	definir_conscientizacao(0.0) # Começa zerada
	
	# Ajusta a posição inicial do nó de partículas para a base da barra
	_atualizar_area_particulas()

## Função exposta para a Main atualizar o valor da barra
func definir_conscientizacao(valor_alvo: float) -> void:
	if not progress_bar:
		return

	var novo_valor = clamp(valor_alvo, 0.0, 100.0)
	var valor_atual = progress_bar.value

	# Interrompe animações de dano anteriores se houver uma nova ação
	if tween_dano:
		tween_dano.kill()

	# --- CASO 1: PERDA DE CONSCIENTIZAÇÃO (DANO SOFRIDO) ---
	if novo_valor < valor_atual:
		# 1. A barra principal desce INSTANTANEAMENTE para revelar o trecho vermelho por baixo
		progress_bar.value = novo_valor

		# 2. A barra vermelha aguarda um instante e depois desliza até alcançar a principal
		tween_dano = create_tween()
		tween_dano.tween_property(progress_bar_damage, "value", novo_valor, 5)\
			.set_delay(0.3)\
			.set_trans(Tween.TRANS_SINE)\
			.set_ease(Tween.EASE_OUT)

	# --- CASO 2: GANHO DE CONSCIENTIZAÇÃO (ACERTO) ---
	else:
		# 1. A barra vermelha sobe junto ou vai direto para o novo valor
		progress_bar_damage.value = novo_valor

		# 2. A barra principal sobe suavemente até o novo valor
		tween_dano = create_tween()
		tween_dano.tween_property(progress_bar, "value", novo_valor, 5)\
			.set_trans(Tween.TRANS_SINE)\
			.set_ease(Tween.EASE_OUT)
	_atualizar_area_particulas()

func _process(_delta: float) -> void:
	# Atualiza dinamicamente enquanto a barra anima suavemente com o Tween
	_atualizar_area_particulas()



func _atualizar_area_particulas() -> void:
	if not particulas or not progress_bar:
		return
		
	var pct = progress_bar.value / progress_bar.max_value
	var largura_preenchida = progress_bar.size.x * pct
	var altura_barra = progress_bar.size.y
	
	# Se a barra estiver zerada, desativa as partículas
	if largura_preenchida <= 0.0:
		particulas.emitting = false
		return
		
	particulas.emitting = true
	
	# 1. Posiciona o emissor EXATAMENTE NO CENTRO da região preenchida
	# (Tanto no eixo X quanto no eixo Y)
	particulas.position = Vector2(largura_preenchida / 2.0, altura_barra / 2.0)
	
	# 2. Configura a caixa de emissão para cobrir toda a largura e altura preenchida
	if particulas.process_material is ParticleProcessMaterial:
		var mat = particulas.process_material as ParticleProcessMaterial
		
		# Define o formato de emissão como Caixa (Box)
		mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
		
		# Como o Extents mede do centro até a borda (raio), dividimos por 2:
		# X = Metade da largura preenchida
		# Y = Metade da altura da barra
		# Z = 0 (jogo 2D)
		mat.emission_box_extents = Vector3(largura_preenchida / 2.0, altura_barra / 2.0, 0.0)

## Retorna a porcentagem atual da barra (0.0 a 100.0)
func obter_porcentagem_atual() -> float:
	if not progress_bar:
		return 0.0
	return progress_bar.value
