extends MarginContainer

signal jogo_pausado

@onready var lbl_dias = $HBoxConteudo/VBoxDiasRestantes/BotaoDiasRestantes/CenterContainer/VBoxContainer/Num
@onready var lbl_ligacoes = $HBoxConteudo/HBoxLigacoesTotais/BotaoLigacoesTotais/CenterContainer/VBoxContainer/Num
@onready var lbl_precisao = $HBoxConteudo/HBoxPrecisao/BotaoPrecisao/CenterContainer/VBoxContainer/Num
@onready var container_dias = $HBoxConteudo/VBoxDiasRestantes/BotaoDiasRestantes

var cor_original_dias: Color

func _ready() -> void:
	if lbl_dias:
		cor_original_dias = lbl_dias.modulate
		
	# Valores iniciais de exibição padrão
	atualizar_dias(30, 30)
	atualizar_ligacoes(0)
	atualizar_precisao(100.0)

	# --- NOVO: Ouve as atualizações do EventBus para recalcular o total ---
	if typeof(EventBus) != TYPE_NIL and EventBus.has_signal("pontos_atualizados"):
		EventBus.pontos_atualizados.connect(_on_event_bus_pontos_atualizados)
	
	# Faz a primeira leitura de pontos caso o jogo já tenha começado com valores acumulados
	_recalcular_e_atualizar_total()

## Atualiza o texto dos dias no formato "atuais/totais" (ex: 30/30)
func atualizar_dias(dias_restantes: int, dias_totais: int, animar: bool = true) -> void:
	if lbl_dias:
		lbl_dias.text = str(dias_restantes) + "/" + str(dias_totais)
		if animar:
			piscar_label_rapido()

## Atualiza as ligações totais exibidas
func atualizar_ligacoes(total: int) -> void:
	if lbl_ligacoes:
		lbl_ligacoes.text = str(total)

## Atualiza a precisão calculada em porcentagem formatada
func atualizar_precisao(porcentagem: float) -> void:
	if lbl_precisao:
		lbl_precisao.text = "%.0f%%" % porcentagem

# --- NOVO: Chamado automaticamente sempre que o EventBus sinalizar mudança nos pontos ---
func _on_event_bus_pontos_atualizados() -> void:
	_recalcular_e_atualizar_total()

func _recalcular_e_atualizar_total() -> void:
	var total_ligacoes: int = 0

	# 1. Verifica no EventBus primeiro
	if typeof(EventBus) != TYPE_NIL and "registros_por_tipo" in EventBus:
		# Se o dicionário do EventBus existir (mesmo se estiver zerado), usamos ele!
		for qtd in EventBus.registros_por_tipo.values():
			total_ligacoes += int(qtd)
	else:
		# 2. Só recorre ao grupo se o EventBus não possuir a variável "registros_por_tipo"
		var nos_painel = get_tree().get_nodes_in_group("painel_pontos")
		if nos_painel.size() > 0:
			var painel = nos_painel[0]
			if painel.has_method("obter_pontos_por_chave_string"):
				var pontos: Dictionary = painel.obter_pontos_por_chave_string()
				for qtd in pontos.values():
					total_ligacoes += int(qtd)

	# Atualiza o label diretamente com o total calculado
	atualizar_ligacoes(total_ligacoes)

# Função de efeito visual de impacto nos dias
func piscar_label_rapido() -> void:
	if not lbl_dias: return

	var cor_impacto = Color.RED

	var tween = create_tween().set_parallel(true)

	tween.tween_property(lbl_dias, "modulate", cor_impacto, 0.05)
	
	tween.tween_property(lbl_dias, "modulate", cor_original_dias, 0.3)\
		.set_delay(0.05)\
		.set_trans(Tween.TRANS_CUBIC)\
		.set_ease(Tween.EASE_OUT)

	tween.tween_property(lbl_dias, "scale", Vector2(1.35, 1.35), 0.08)\
		.set_trans(Tween.TRANS_BACK)\
		.set_ease(Tween.EASE_OUT)
		
	tween.tween_property(lbl_dias, "scale", Vector2.ONE, 0.25)\
		.set_trans(Tween.TRANS_SPRING)\
		.set_ease(Tween.EASE_OUT)\
		.set_delay(0.08)

	tween.tween_property(lbl_dias, "rotation_degrees", -10.0, 0.04)
	tween.tween_property(lbl_dias, "rotation_degrees", 10.0, 0.04).set_delay(0.04)
	tween.tween_property(lbl_dias, "rotation_degrees", -5.0, 0.04).set_delay(0.08)
	tween.tween_property(lbl_dias, "rotation_degrees", 0.0, 0.04).set_delay(0.12)

func _on_botao_pausa_pressed() -> void:
	emit_signal("jogo_pausado")
