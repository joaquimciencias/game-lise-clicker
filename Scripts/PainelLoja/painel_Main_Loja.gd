extends Control

signal loja_fechada
signal compra_finalizada_com_sucesso(mensagem_texto: String)

const CARD_ITEM_SCENE = preload("res://Scenes/Paineis/Loja/CardItemLoja.tscn")

@export var dia_atual: int = 1
@export var total_dias: int = 30

@onready var container_itens: VBoxContainer = get_node_or_null("MainPanelContainer/Margin/VBoxMain/ScrollContainer/ContainerItens") as VBoxContainer

@onready var btn_expansao: Button = get_node_or_null("MainPanelContainer/Margin/VBoxMain/HBoxAbas/BtnExpansao") as Button
@onready var btn_conscientizacao: Button = get_node_or_null("MainPanelContainer/Margin/VBoxMain/HBoxAbas/BtnConscientizacao") as Button
@onready var btn_formacao: Button = get_node_or_null("MainPanelContainer/Margin/VBoxMain/HBoxAbas/BtnFormacao") as Button
@onready var btn_proximo_plantao: Button = get_node_or_null("MainPanelContainer/Margin/VBoxMain/BtnFinalizarTurno") as Button

@onready var lbl_fisica: Label = get_node_or_null("MainPanelContainer/Margin/VBoxMain/HeaderTotais/Margin/VBoxHeader/HBoxBadges/BadgeFisica/Lbl") as Label
@onready var lbl_psico: Label = get_node_or_null("MainPanelContainer/Margin/VBoxMain/HeaderTotais/Margin/VBoxHeader/HBoxBadges/BadgePsico/Lbl") as Label
@onready var lbl_moral: Label = get_node_or_null("MainPanelContainer/Margin/VBoxMain/HeaderTotais/Margin/VBoxHeader/HBoxBadges/BadgeMoral/Lbl") as Label
@onready var lbl_patrimonial: Label = get_node_or_null("MainPanelContainer/Margin/VBoxMain/HeaderTotais/Margin/VBoxHeader/HBoxBadges/BadgePatrimonial/Lbl") as Label

var tab_active_style: StyleBoxFlat
var tab_inactive_style: StyleBoxFlat

var aba_atual: String = "expansao"
@onready var lbl_status_regras: Label = get_node_or_null("MainPanelContainer/Margin/VBoxMain/LblStatusRegras") as Label

func _ready() -> void:
	add_to_group("loja_principal")
	_criar_estilos_abas()
	_conectar_sinais()
	
	if typeof(EventBus) != TYPE_NIL and EventBus.has_signal("pontos_atualizados"):
		if not EventBus.pontos_atualizados.is_connected(_atualizar_header_e_footer):
			EventBus.pontos_atualizados.connect(_atualizar_header_e_footer)
	
	# Ouve mudanças de limite de compra
	if UpgradesManager and UpgradesManager.has_signal("limite_compras_mudou"):
		UpgradesManager.limite_compras_mudou.connect(_on_limite_compras_mudou)
		
	_atualizar_header_e_footer()
	call_deferred("carregar_aba", aba_atual)

func _criar_estilos_abas() -> void:
	tab_active_style = StyleBoxFlat.new()
	tab_active_style.bg_color = Color("#8B5CF6")
	tab_active_style.set_corner_radius_all(8)
	
	tab_inactive_style = StyleBoxFlat.new()
	tab_inactive_style.bg_color = Color("#2E293D")
	tab_inactive_style.set_corner_radius_all(8)

func _conectar_sinais() -> void:
	if btn_expansao and not btn_expansao.pressed.is_connected(_on_expansao_pressed):
		btn_expansao.pressed.connect(_on_expansao_pressed)
	if btn_conscientizacao and not btn_conscientizacao.pressed.is_connected(_on_conscientizacao_pressed):
		btn_conscientizacao.pressed.connect(_on_conscientizacao_pressed)
	if btn_formacao and not btn_formacao.pressed.is_connected(_on_formacao_pressed):
		btn_formacao.pressed.connect(_on_formacao_pressed)
	if btn_proximo_plantao and not btn_proximo_plantao.pressed.is_connected(_on_proximo_plantao_pressed):
		btn_proximo_plantao.pressed.connect(_on_proximo_plantao_pressed)

func _on_expansao_pressed() -> void: carregar_aba("expansao")
func _on_conscientizacao_pressed() -> void: carregar_aba("conscientizacao")
func _on_formacao_pressed() -> void: carregar_aba("formacao")

func _obter_dados_conscientizacao_atuais() -> Dictionary:
	var nos_painel = get_tree().get_nodes_in_group("painel_pontos")
	if nos_painel.size() > 0:
		var painel = nos_painel[0]
		if painel.has_method("obter_pontos_por_chave_string"):
			return painel.obter_pontos_por_chave_string()
	
	if typeof(EventBus) != TYPE_NIL and "registros_por_tipo" in EventBus:
		return EventBus.registros_por_tipo
		
	return {"fisica": 0, "psicologica": 0, "moral": 0, "patrimonial": 0}

# --- AQUI ESTÁ A ATUALIZAÇÃO DO HEADER DA LOJA COM ANIMAÇÃO ---
func _atualizar_header_e_footer() -> void:
	var pontos = _obter_dados_conscientizacao_atuais()
	
	var fis = int(pontos.get("fisica", 0))
	var psi = int(pontos.get("psicologica", 0))
	var mor = int(pontos.get("moral", 0))
	var pat = int(pontos.get("patrimonial", 0))
	
	animar_label_numero(lbl_fisica, fis, "🥊 Físicos: ")
	animar_label_numero(lbl_psico, psi, "🧠 Psicológicos: ")
	animar_label_numero(lbl_moral, mor, "🗣️ Morais: ")
	animar_label_numero(lbl_patrimonial, pat, "💔 Patrimoniais: ")

	if btn_proximo_plantao:
		btn_proximo_plantao.text = "🌙 ENCERRAR EXPEDIENTE E AVANÇAR DIA"# (%02d/%d) ➔" % [dia_atual, total_dias]

	_atualizar_banner_feedback()

func carregar_aba(nome_aba: String) -> void:
	aba_atual = nome_aba
	_atualizar_estilo_botoes_aba()
	
	if not container_itens:
		return

	for child in container_itens.get_children():
		child.queue_free()
		
	var todos_upgrades = UpgradesData.get_todos_os_upgrades()
	var lista_itens_aba = todos_upgrades.get(aba_atual, [])
	
	var niveis_comprados: Dictionary = {}
	if get_node_or_null("/root/UpgradesManager"):
		niveis_comprados = UpgradesManager.niveis_upgrades
	
	var reg_tipos = _obter_dados_conscientizacao_atuais()
	var reg_totais = 0
	for qtd in reg_tipos.values():
		reg_totais += int(qtd)
	
	for dados_item in lista_itens_aba:
		var id = dados_item.get("id", "")
		var nivel = niveis_comprados.get(id, 0)
		
		if CARD_ITEM_SCENE:
			var card_instancia = CARD_ITEM_SCENE.instantiate()
			container_itens.add_child(card_instancia)
			
			if card_instancia.has_method("configurar_card"):
				card_instancia.configurar_card(dados_item, nivel, reg_totais, reg_tipos)
			
			if card_instancia.has_signal("item_comprado"):
				card_instancia.item_comprado.connect(_on_item_comprado)

func _atualizar_estilo_botoes_aba() -> void:
	if btn_expansao:
		btn_expansao.add_theme_stylebox_override("normal", tab_active_style if aba_atual == "expansao" else tab_inactive_style)
	if btn_conscientizacao:
		btn_conscientizacao.add_theme_stylebox_override("normal", tab_active_style if aba_atual == "conscientizacao" else tab_inactive_style)
	if btn_formacao:
		btn_formacao.add_theme_stylebox_override("normal", tab_active_style if aba_atual == "formacao" else tab_inactive_style)

func _obter_dados_upgrade_por_id(id_procurado: String) -> Dictionary:
	var todos = UpgradesData.get_todos_os_upgrades()
	for categoria in todos.values():
		for item in categoria:
			if item.get("id", "") == id_procurado:
				return item
	return {}

func _on_item_comprado(id_item: String) -> void:
	var mgr = get_node_or_null("/root/UpgradesManager")
	
	# CHECK 1: Verifica a regra de limite de compra por rodada
	if mgr and not mgr.pode_comprar():
		compra_finalizada_com_sucesso.emit("❌ Limite de ações atingido para este dia!")
		return
		
	var nivel_atual = 0
	if mgr and "niveis_upgrades" in mgr:
		nivel_atual = mgr.niveis_upgrades.get(id_item, 0)
	
	if nivel_atual < 3:
		var novo_nivel = nivel_atual + 1
		
		if mgr and mgr.has_method("registrar_compra"):
			mgr.registrar_compra(id_item, novo_nivel)
		
		var dados = _obter_dados_upgrade_por_id(id_item)
		var nome_item = dados.get("nome", "Melhoria")
		
		compra_finalizada_com_sucesso.emit("✅ Melhoria Adquirida:\n%s (Nível %d)!" % [nome_item, novo_nivel])
		
		_atualizar_todos_os_itens()

func _atualizar_todos_os_itens() -> void:
	_atualizar_header_e_footer()
	carregar_aba(aba_atual)

func _on_proximo_plantao_pressed() -> void:
	parar_animacao_botao_encerrar() # Reseta o botão para o tamanho padrão
	
	if UpgradesManager:
		UpgradesManager.iniciar_nova_rodada()
		
	loja_fechada.emit()
	hide()

func _on_fechar_pressed() -> void:
	loja_fechada.emit()
	hide()

# --- FUNÇÃO RESPONSÁVEL POR ANIMAR OS NÚMEROS (LOJA) ---
func animar_label_numero(label: Label, valor_destino: int, prefixo: String = "") -> void:
	if not label:
		return

	var texto_atual: String = label.text
	var valor_inicial: int = 0
	
	var regex = RegEx.new()
	regex.compile("\\d+")
	var resultado = regex.search(texto_atual)
	if resultado:
		valor_inicial = resultado.get_string().to_int()

	if valor_inicial == valor_destino:
		label.text = prefixo + str(valor_destino)
		return

	# Verifica se 'tween_numero' existe antes de ler para evitar o erro no console
	if label.has_meta("tween_numero"):
		var tween_existente: Tween = label.get_meta("tween_numero")
		if tween_existente and tween_existente.is_running():
			tween_existente.kill()

	var diferenca: int = abs(valor_destino - valor_inicial)
	var tempo_duracao: float = clamp(diferenca * 0.08, 0.2, 1.2)

	var tween = create_tween()
	label.set_meta("tween_numero", tween)
	
	tween.tween_method(
		func(val: int):
			label.text = prefixo + str(val),
		valor_inicial,
		valor_destino,
		tempo_duracao
	).set_trans(Tween.TRANS_LINEAR)

func _atualizar_banner_feedback() -> void:
	if not UpgradesManager:
		return
		
	var pct = UpgradesManager.obter_porcentagem_consciencia()
	var restantes = UpgradesManager.obter_compras_restantes()
	var max_compras = UpgradesManager.limite_compras_rodada
	
	if lbl_status_regras:
		if pct < 50.0:
			lbl_status_regras.text = "📢 Conscientização em %.0f%% (<50%%):\n- Limite: %d/%d compra por dia.\n- Seus itens comprados sobem +1 nível automaticamente a cada rodada!" % [pct, (max_compras - restantes), max_compras]
		else:
			lbl_status_regras.text = "🔥 Conscientização Alta em %.0f%% (≥50%%):\n- BÔNUS DE POPULARIDADE: Você pode comprar ou evoluir 2 itens neste dia! (%d restantes)" % [pct, restantes]

	# CHECAGEM: Se as compras acabaram, ativa a animação no botão de encerrar!
	if restantes == 0:
		chamar_atencao_botao_encerrar()
	else:
		parar_animacao_botao_encerrar()
		
		
func _on_limite_compras_mudou(_restantes: int, _maximo: int) -> void:
	_atualizar_banner_feedback()
	carregar_aba(aba_atual) # Recarrega para desabilitar/habilitar os cards


# --- ANIMAR E CHAMAR ATENÇÃO PARA O BOTÃO DE ENCERRAR ---
func chamar_atencao_botao_encerrar() -> void:
	if not btn_proximo_plantao:
		return

	# Garante a origem no centro para o botão crescer por igual
	btn_proximo_plantao.pivot_offset = btn_proximo_plantao.size / 2.0

	# Cancela animação anterior se já existir
	parar_animacao_botao_encerrar()

	# Cria um Tween em loop infinito (pulsando)
	var tween = create_tween().set_loops()
	btn_proximo_plantao.set_meta("tween_destaque", tween)

	# Frequência e intensidade do pulso
	tween.tween_property(btn_proximo_plantao, "scale", Vector2(1.08, 1.08), 0.5)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(btn_proximo_plantao, "scale", Vector2(1.0, 1.0), 0.5)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func parar_animacao_botao_encerrar() -> void:
	if btn_proximo_plantao and btn_proximo_plantao.has_meta("tween_destaque"):
		var tween_existente: Tween = btn_proximo_plantao.get_meta("tween_destaque")
		if tween_existente and tween_existente.is_running():
			tween_existente.kill()
		btn_proximo_plantao.scale = Vector2(1.0, 1.0)
