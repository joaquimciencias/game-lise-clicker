extends Control

## Evento 75% — Ataque Político (Fact-Checking & Rebatimento)
## Mecânica de triagem de publicações (Fake News x Provocações Irrelevantes)
## com botões de decisão e feedback em tempo real.

const COR_GLOW_AMARELO := Color("#F59E0B")
const COR_BG_CARD := Color(0.08, 0.12, 0.18, 0.98)
const COR_TEXTO_PADRAO := Color(0.9, 0.95, 1.0)

enum Estado { ANTES, DURANTE, DEPOIS, FINALIZADO }

var limiar_evento: float = 75.0
var estado: Estado = Estado.ANTES

var credibilidade: float = 100.0
var taxa_decaimento_credibilidade: float = 4.0 # Decaimento constante por segundo

@onready var container_jogo: Control = $ContainerJogo if has_node("ContainerJogo") else null
@onready var container_feed: Control = $ContainerJogo/ContainerFeed if has_node("ContainerJogo/ContainerFeed") else null
@onready var progress_credibilidade: ProgressBar = $ContainerJogo/ProgressBarCredibilidade if has_node("ContainerJogo/ProgressBarCredibilidade") else null
@onready var label_credibilidade: Label = $ContainerJogo/LabelCredibilidade if has_node("ContainerJogo/LabelCredibilidade") else null
@onready var label_timer_hud: Label = $ContainerJogo/LabelTimerHUD if has_node("ContainerJogo/LabelTimerHUD") else null

@onready var margin_relato: MarginContainer = $MarginContainerRelato if has_node("MarginContainerRelato") else null
@onready var label_aviso: Label = $MarginContainerRelato/Panel/Aviso if has_node("MarginContainerRelato/Panel/Aviso") else null
@onready var timer: Timer = $TimerProgresso if has_node("TimerProgresso") else null

# --- REFERÊNCIA DO ÁUDIO NA CENA ---
# Substitua "SomClique" pelo nome exato do seu nó AudioStreamPlayer na árvore da cena
@onready var som_clique: AudioStreamPlayer = $Falas

var botao_iniciar: Button
var painel_card_atual: PanelContainer
var label_autor_card: Label
var label_texto_card: Label
var botao_desmentir: Button
var botao_ignorar: Button

var painel_resultado: Control
var label_titulo_resultado: Label
var label_mensagem_resultado: Label
var label_delta: Label
var botao_continuar: Button

# Pool de postagens para verificação
var deck_postagens: Array = [
	{
		"autor": "🔴 @NoticiasPoliticasDF",
		"texto": "🚨 URGENTE: Projeto Lise usa verba pública para fins eleitorais e não atende nenhuma mulher!",
		"e_fake_news": true,
		"prova": "📊 Relatório Oficial: 1.200 mulheres atendidas no semestre."
	},
	{
		"autor": "👤 @Anonimo9921",
		"texto": "Acho essa iniciativa muito ruim, o design do aplicativo é feio.",
		"e_fake_news": false, # Apenas troll/opinião fútil
		"prova": "Opinião pessoal sem impacto institucional."
	},
	{
		"autor": "📰 @PortalMidiaLivre",
		"texto": "BOMBA: Abrigos de apoio às vítimas estão completamente vazios e abandonados!",
		"e_fake_news": true,
		"prova": "📑 Auditoria: 98% de ocupação e acolhimento ativo."
	},
	{
		"autor": "💬 @ComentaristaRaivoso",
		"texto": "Ninguém pediu por esse tipo de serviço na cidade. Perda de tempo!",
		"e_fake_news": false,
		"prova": "Provocação irrelevante sem dado falso específico."
	},
	{
		"autor": "🌐 @FatoOuFarsaBlog",
		"texto": "Denúncia: Atendimentos do Ligue 180 são simulados por inteligência artificial!",
		"e_fake_news": true,
		"prova": "🗣️ Depoimentos: Equipe técnica 100% humanizada e certificada."
	},
	{
		"autor": "🤖 @BotDaVerdade12",
		"texto": "Vocês trabalham demais, deviam fechar no fim de semana.",
		"e_fake_news": false,
		"prova": "Comentário irrelevante de bot."
	},
	{
		"autor": "📢 @RadarDaCapital",
		"texto": "EXCLUSIVO: Medidas protetivas concedidas pelo programa não possuem validade jurídica!",
		"e_fake_news": true,
		"prova": "⚖️ Parceria Oficial com o Tribunal de Justiça."
	}
]

var carta_atual_index: int = 0
var total_acertos: int = 0

var texto_antes: String = """🏛️ ALERTA DE CRISE INSTITUCIONAL!

Uma campanha orquestrada de desinformação está espalhando ataques contra a Gestão Lise.

⚠️ COMO JOGAR (FACT-CHECKING):
1. Cartões de publicações surgirão na tela.
2. Analise o conteúdo rápido:
   • 🛡️ DESMENTIR (FAKENEWS): Use para fake news graves e acusações falsas (Recupera Credibilidade).
   • 🗑️ IGNORAR (TROLL/OPINIÃO): Use para provocações irrelevantes ou opiniões fúteis sem dados falsos.
3. Cuidado: Se você gastar recursos desmentindo um troll, perderá tempo e credibilidade! Se ignorar uma Fake News real, a credibilidade despenca!"""


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().paused = true

	_criar_botao_iniciar()
	_criar_painel_resultado()
	_efeito_typewriter(texto_antes)

	if has_node("/root/EventBus"):
		get_node("/root/EventBus").minigame_iniciado.emit(limiar_evento)


func _process(delta: float) -> void:
	if estado == Estado.DURANTE:
		if is_instance_valid(timer) and not timer.is_stopped() and is_instance_valid(label_timer_hud):
			label_timer_hud.text = "⏱️ Tempo: %.1fs" % timer.time_left

		# Decaimento contínuo de credibilidade
		credibilidade -= taxa_decaimento_credibilidade * delta
		credibilidade = clamp(credibilidade, 0.0, 100.0)
		_atualizar_hud_credibilidade()

		if credibilidade <= 0.0:
			_ir_para_depois(false)


func _criar_botao_iniciar() -> void:
	if not is_instance_valid(margin_relato):
		return
	
	botao_iniciar = Button.new()
	botao_iniciar.text = "🔍 INICIAR FACT-CHECKING"
	botao_iniciar.custom_minimum_size = Vector2(340, 48)
	botao_iniciar.add_theme_font_size_override("font_size", 14)
	botao_iniciar.add_theme_color_override("font_color", Color.WHITE)
	
	var style := StyleBoxFlat.new()
	style.bg_color = COR_GLOW_AMARELO
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_right = 10
	style.corner_radius_bottom_left = 10
	
	botao_iniciar.add_theme_stylebox_override("normal", style)
	
	var panel := margin_relato.get_node("Panel") if margin_relato.has_node("Panel") else margin_relato
	panel.add_child(botao_iniciar)
	
	botao_iniciar.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	botao_iniciar.grow_horizontal = Control.GROW_DIRECTION_BOTH
	botao_iniciar.offset_left = -170
	botao_iniciar.offset_right = 170
	botao_iniciar.offset_top = -55
	botao_iniciar.offset_bottom = -10
	
	botao_iniciar.pressed.connect(_on_botao_iniciar_pressed)


func _efeito_typewriter(texto: String) -> void:
	if not is_instance_valid(label_aviso):
		return
	label_aviso.text = ""
	for i in range(texto.length()):
		if estado != Estado.ANTES:
			break
		label_aviso.text += texto[i]
		await get_tree().create_timer(0.012, true, false, true).timeout


func _on_botao_iniciar_pressed() -> void:
	if estado != Estado.ANTES:
		return
	
	estado = Estado.DURANTE
	
	if is_instance_valid(margin_relato): margin_relato.visible = false
	if is_instance_valid(container_jogo): container_jogo.visible = true

	deck_postagens.shuffle()
	_montar_interface_card()
	_carregar_proxima_carta()

	if timer:
		timer.timeout.connect(_on_timer_timeout)
		timer.start()


func _montar_interface_card() -> void:
	if not is_instance_valid(container_feed):
		return

	# Card central de postagem
	painel_card_atual = PanelContainer.new()
	painel_card_atual.custom_minimum_size = Vector2(500, 180)
	
	var style_card := StyleBoxFlat.new()
	style_card.bg_color = COR_BG_CARD
	style_card.border_width_left = 2
	style_card.border_width_top = 2
	style_card.border_width_right = 2
	style_card.border_width_bottom = 2
	style_card.border_color = COR_GLOW_AMARELO
	style_card.corner_radius_top_left = 14
	style_card.corner_radius_top_right = 14
	style_card.corner_radius_bottom_right = 14
	style_card.corner_radius_bottom_left = 14
	style_card.content_margin_left = 20
	style_card.content_margin_top = 15
	style_card.content_margin_right = 20
	style_card.content_margin_bottom = 15

	painel_card_atual.add_theme_stylebox_override("panel", style_card)
	container_feed.add_child(painel_card_atual)
	
	painel_card_atual.set_anchors_preset(Control.PRESET_CENTER)
	painel_card_atual.grow_horizontal = Control.GROW_DIRECTION_BOTH
	painel_card_atual.grow_vertical = Control.GROW_DIRECTION_BOTH
	painel_card_atual.offset_left = -250
	painel_card_atual.offset_right = 250
	painel_card_atual.offset_top = -110
	painel_card_atual.offset_bottom = 70

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	painel_card_atual.add_child(vbox)

	label_autor_card = Label.new()
	label_autor_card.add_theme_font_size_override("font_size", 13)
	label_autor_card.add_theme_color_override("font_color", COR_GLOW_AMARELO)
	vbox.add_child(label_autor_card)

	label_texto_card = Label.new()
	label_texto_card.add_theme_font_size_override("font_size", 15)
	label_texto_card.add_theme_color_override("font_color", COR_TEXTO_PADRAO)
	label_texto_card.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(label_texto_card)

	# Botoes de Acao
	var hbox_botoes := HBoxContainer.new()
	hbox_botoes.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox_botoes.add_theme_constant_override("separation", 40)
	container_feed.add_child(hbox_botoes)

	hbox_botoes.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	hbox_botoes.grow_horizontal = Control.GROW_DIRECTION_BOTH
	hbox_botoes.offset_left = -250
	hbox_botoes.offset_right = 250
	hbox_botoes.offset_top = -45
	hbox_botoes.offset_bottom = -5

	botao_desmentir = Button.new()
	botao_desmentir.text = "🛡️ DESMENTIR (FAKE NEWS)"
	botao_desmentir.custom_minimum_size = Vector2(220, 44)
	botao_desmentir.add_theme_font_size_override("font_size", 12)
	
	var style_desmentir := StyleBoxFlat.new()
	style_desmentir.bg_color = Color(0.1, 0.6, 0.3)
	style_desmentir.corner_radius_top_left = 8
	style_desmentir.corner_radius_top_right = 8
	style_desmentir.corner_radius_bottom_right = 8
	style_desmentir.corner_radius_bottom_left = 8
	botao_desmentir.add_theme_stylebox_override("normal", style_desmentir)
	botao_desmentir.pressed.connect(func(): _processar_resposta(true))
	hbox_botoes.add_child(botao_desmentir)

	botao_ignorar = Button.new()
	botao_ignorar.text = "🗑️ IGNORAR (TROLL/OPINIÃO)"
	botao_ignorar.custom_minimum_size = Vector2(220, 44)
	botao_ignorar.add_theme_font_size_override("font_size", 12)
	
	var style_ignorar := StyleBoxFlat.new()
	style_ignorar.bg_color = Color(0.5, 0.2, 0.2)
	style_ignorar.corner_radius_top_left = 8
	style_ignorar.corner_radius_top_right = 8
	style_ignorar.corner_radius_bottom_right = 8
	style_ignorar.corner_radius_bottom_left = 8
	botao_ignorar.add_theme_stylebox_override("normal", style_ignorar)
	botao_ignorar.pressed.connect(func(): _processar_resposta(false))
	hbox_botoes.add_child(botao_ignorar)


func _carregar_proxima_carta() -> void:
	if carta_atual_index >= deck_postagens.size():
		# Reinicia o deck embaralhado se o tempo ainda não acabou
		deck_postagens.shuffle()
		carta_atual_index = 0

	var dados_card: Dictionary = deck_postagens[carta_atual_index]
	label_autor_card.text = dados_card["autor"]
	label_texto_card.text = dados_card["texto"]

	# Efeito visual de entrada da carta
	painel_card_atual.scale = Vector2(0.8, 0.8)
	var tween := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(painel_card_atual, "scale", Vector2.ONE, 0.15).set_trans(Tween.TRANS_BACK)


func _processar_resposta(jogador_escolheu_desmentir: bool) -> void:
	if estado != Estado.DURANTE:
		return

	# Toca o som usando o nó já existente na cena
	if is_instance_valid(som_clique):
		som_clique.stop() # Reseta caso seja clicado rápido
		som_clique.play()

	var dados_card: Dictionary = deck_postagens[carta_atual_index]
	var e_fake: bool = dados_card["e_fake_news"]

	if jogador_escolheu_desmentir == e_fake:
		# Acerto!
		total_acertos += 1
		if e_fake:
			credibilidade = clamp(credibilidade + 15.0, 0.0, 100.0)
		else:
			credibilidade = clamp(credibilidade + 5.0, 0.0, 100.0) # Não perdeu tempo com troll
	else:
		# Erro!
		if e_fake:
			# Deixou uma Fake News passar
			credibilidade = clamp(credibilidade - 20.0, 0.0, 100.0)
		else:
			# Alimentou o troll
			credibilidade = clamp(credibilidade - 10.0, 0.0, 100.0)

	_atualizar_hud_credibilidade()
	carta_atual_index += 1
	_carregar_proxima_carta()


func _atualizar_hud_credibilidade() -> void:
	if is_instance_valid(progress_credibilidade):
		progress_credibilidade.value = credibilidade
	if is_instance_valid(label_credibilidade):
		label_credibilidade.text = "CREDIBILIDADE INSTITUCIONAL: %.0f%%" % credibilidade


func _on_timer_timeout() -> void:
	if estado == Estado.DURANTE:
		_ir_para_depois(credibilidade > 25.0)


func _criar_painel_resultado() -> void:
	painel_resultado = Control.new()
	painel_resultado.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	painel_resultado.visible = false
	painel_resultado.modulate.a = 0.0
	add_child(painel_resultado)

	var fundo := Panel.new()
	fundo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var style_fundo := StyleBoxFlat.new()
	style_fundo.bg_color = Color(0.04, 0.06, 0.1, 0.97)
	style_fundo.border_width_left = 3
	style_fundo.border_width_top = 3
	style_fundo.border_width_right = 3
	style_fundo.border_width_bottom = 3
	style_fundo.border_color = COR_GLOW_AMARELO
	fundo.add_theme_stylebox_override("panel", style_fundo)
	painel_resultado.add_child(fundo)

	var centro := CenterContainer.new()
	centro.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	painel_resultado.add_child(centro)

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 14)
	vbox.custom_minimum_size = Vector2(520, 0)
	centro.add_child(vbox)

	label_titulo_resultado = Label.new()
	label_titulo_resultado.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label_titulo_resultado.add_theme_font_size_override("font_size", 24)
	vbox.add_child(label_titulo_resultado)

	label_mensagem_resultado = Label.new()
	label_mensagem_resultado.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label_mensagem_resultado.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label_mensagem_resultado.add_theme_font_size_override("font_size", 14)
	vbox.add_child(label_mensagem_resultado)

	label_delta = Label.new()
	label_delta.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label_delta.add_theme_font_size_override("font_size", 22)
	vbox.add_child(label_delta)

	botao_continuar = Button.new()
	botao_continuar.text = "RETORNAR AO JOGO"
	botao_continuar.custom_minimum_size = Vector2(240, 46)
	botao_continuar.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	
	var btn_style := StyleBoxFlat.new()
	btn_style.bg_color = COR_GLOW_AMARELO
	btn_style.corner_radius_top_left = 10
	btn_style.corner_radius_top_right = 10
	btn_style.corner_radius_bottom_right = 10
	btn_style.corner_radius_bottom_left = 10
	botao_continuar.add_theme_stylebox_override("normal", btn_style)
	
	botao_continuar.pressed.connect(_on_botao_continuar_pressed)
	vbox.add_child(botao_continuar)


func _ir_para_depois(sucesso: bool) -> void:
	estado = Estado.DEPOIS
	
	if timer: timer.stop()
	if is_instance_valid(container_jogo): container_jogo.visible = false

	if sucesso:
		label_titulo_resultado.text = "🛡️ VERIFICAÇÃO CONCLUÍDA COM SUCESSO!"
		label_titulo_resultado.add_theme_color_override("font_color", Color(0.2, 0.85, 0.45))
		label_mensagem_resultado.text = "Você conseguiu neutralizar as acusações falsas sem perder tempo com provocações vazias!\n\n💡 APRENDIZADO:\nCampanhas de desinformação dependem do pânico e da falta de checagem. Apresentar dados e fatos concretos é a única forma de blindar os serviços sociais contra ataques políticos.\n\n• Triagens Corretas: %d\n• Credibilidade Final: %.0f%%" % [total_acertos, credibilidade]
		label_delta.text = "+15% Conscientização Social"
		label_delta.add_theme_color_override("font_color", Color(0.2, 0.85, 0.45))
	else:
		label_titulo_resultado.text = "⚠️ A DESINFORMAÇÃO VENCEU..."
		label_titulo_resultado.add_theme_color_override("font_color", Color(0.95, 0.3, 0.3))
		label_mensagem_resultado.text = "As fake news não foram desmentidas a tempo e a imagem da instituição foi severamente prejudicada.\n\n⚠️ O RISCO:\nQuando fakenews atacam a credibilidade de programas de apoio, as vítimas perdem a confiança e deixam de buscar ajuda."
		label_delta.text = "-10% Conscientização Social"
		label_delta.add_theme_color_override("font_color", Color(0.95, 0.3, 0.3))

	if painel_resultado:
		painel_resultado.visible = true
		var tween := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		tween.tween_property(painel_resultado, "modulate:a", 1.0, 0.35)


func _on_botao_continuar_pressed() -> void:
	if estado != Estado.DEPOIS:
		return
		
	estado = Estado.FINALIZADO
	
	if has_node("/root/EventBus"):
		get_node("/root/EventBus").minigame_finalizado.emit(credibilidade > 25.0, limiar_evento)
		
	get_tree().paused = false
	queue_free()
