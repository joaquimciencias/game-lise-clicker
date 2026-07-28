extends Control

## Evento 50% — Combate às Fake News (Rede Lilás)
## Minigame Dinâmico: Movimento Indefinido Orgânico (Ruído Perlin/Mudança de Direção),
## Fuga Ativa e Agressiva do Mouse, Sem Repetição de Frases, Painéis de Contexto e Feedback.

const COR_GLOW_AZUL := Color("#3B82F6")
const COR_BALAO_NEUTRO := Color(0.12, 0.16, 0.24, 0.92)
const COR_FAKE_EVIDENCIADA := Color(0.9, 0.2, 0.2, 0.9)
const COR_FATO_EVIDENCIADO := Color(0.2, 0.8, 0.4, 0.9)

enum Estado { ANTES, DURANTE, DEPOIS, FINALIZADO }

var limiar_evento: float = 50.0
var estado: Estado = Estado.ANTES
var acertos: int = 0
var erros: int = 0
var total_fake_news_necessarias: int = 3

@onready var container_baloes: Control = $ContainerBaloes if has_node("ContainerBaloes") else null
@onready var margin_relato: MarginContainer = $MarginContainerRelato if has_node("MarginContainerRelato") else null
@onready var label_aviso: Label = $MarginContainerRelato/Panel/Aviso if has_node("MarginContainerRelato/Panel/Aviso") else null
@onready var timer: Timer = $TimerProgresso if has_node("TimerProgresso") else null
@onready var label_prioridade: Label = $LabelPrioridade if has_node("LabelPrioridade") else null
@onready var label_timer_hud: Label = $LabelTimerHUD if has_node("LabelTimerHUD") else null
@onready var label_placar_hud: Label = $LabelPlacarHUD if has_node("LabelPlacarHUD") else null

var botao_iniciar: Button
var painel_resultado: Control
var label_titulo_resultado: Label
var label_mensagem_resultado: Label
var label_delta: Label
var botao_continuar: Button

# Pool de posts de redes sociais (Garantido sem repetição)
# Pool de posts de redes sociais (Fake x Fato)
var pool_fake: Array = [
	"💬 \"Violência psicológica não dá cadeia, é só briga de casal\"",
	"💬 \"Medidas protetivas só são concedidas com laudo de lesão corporal\"",
	"💬 \"A vítima é obrigada a manter convivência com o agressor por guarda\"",
	"💬 \"Ligue 180 serve apenas para denúncias com provas físicas\"",
	"💬 \"Denunciar agressão verbal não gera nenhum processo criminal\""
]

var pool_fatos: Array = [
	"💬 \"Violência psicológica É CRIME previsto na Lei Maria da Penha\"",
	"💬 \"Medidas protetivas podem ser concedidas emergencialmente sem agressão física\"",
	"💬 \"O Ligue 180 é gratuito, anônimo e funciona 24 horas por dia\"",
	"💬 \"Afastamento do lar pode ser determinado de imediato para proteção\"",
	"💬 \"Violência patrimonial e moral também são formas de abuso puníveis\""
]

# Dicionários de estado dinâmico dos balões
var baloes_info: Array = []
var timer_multiplicacao: Timer

var texto_antes: String = """🚨 ALERTA DE VITALIZAÇÃO DE DESINFORMAÇÃO!

Um surto de postagens com notícias falsas (Fake News) sobre a Lei Maria da Penha e direitos das mulheres está se espalhando livremente pelas redes sociais.

⚠️ COMO JOGAR:
1. Os posts flutuam livremente em direções imprevisíveis e contínuas pela tela!
2. Quando você aproxima o cursor, eles tentam fugir do seu clique.
3. Leia com atenção: todos iniciam com aparência neutra. Derrube apenas as FAKE NEWS!

Elimine 3 Fake News antes que o tempo acabe!"""


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
		_atualizar_movimentacao_indefinida_e_fuga(delta)


# =============================================================================
# ETAPA 1: ANTES (INTRODUÇÃO)
# =============================================================================

func _criar_botao_iniciar() -> void:
	if not is_instance_valid(margin_relato):
		return
	
	botao_iniciar = Button.new()
	botao_iniciar.text = "🔍 INICIAR CONTENÇÃO DE DESINFORMAÇÃO"
	botao_iniciar.custom_minimum_size = Vector2(340, 48)
	botao_iniciar.add_theme_font_size_override("font_size", 14)
	botao_iniciar.add_theme_color_override("font_color", Color.WHITE)
	
	var style := StyleBoxFlat.new()
	style.bg_color = COR_GLOW_AZUL
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


# =============================================================================
# ETAPA 2: DURANTE (MOVIMENTAÇÃO INDEFINIDA, FUGA DO MOUSE, SEM REPETIÇÃO)
# =============================================================================

func _on_botao_iniciar_pressed() -> void:
	if estado != Estado.ANTES:
		return
	
	estado = Estado.DURANTE
	
	if is_instance_valid(margin_relato):
		margin_relato.visible = false
		
	if is_instance_valid(container_baloes):
		container_baloes.visible = true
		
	if is_instance_valid(label_prioridade):
		label_prioridade.text = "ATENÇÃO: LEIA E DERRUBE APENAS AS FAKE NEWS!"

	if label_timer_hud: label_timer_hud.visible = true
	if label_placar_hud: label_placar_hud.visible = true

	_iniciar_posts_iniciais()
	_iniciar_timer_multiplicacao()

	if timer:
		timer.timeout.connect(_on_timer_timeout)
		timer.start()


func _iniciar_posts_iniciais() -> void:
	pool_fake.shuffle()
	pool_fatos.shuffle()

	# Spawn inicial sem repetições (usando pop_back)
	for i in range(3):
		if pool_fake.size() > 0:
			_spawnar_balao(pool_fake.pop_back(), true)
		if pool_fatos.size() > 0:
			_spawnar_balao(pool_fatos.pop_back(), false)


func _spawnar_balao(texto: String, is_fake: bool) -> void:
	if not is_instance_valid(container_baloes) or baloes_info.size() >= 8:
		return

	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = COR_BALAO_NEUTRO
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.3, 0.45, 0.7, 0.8)
	style.corner_radius_top_left = 14
	style.corner_radius_top_right = 14
	style.corner_radius_bottom_right = 14
	style.corner_radius_bottom_left = 14
	style.content_margin_left = 12
	style.content_margin_top = 8
	style.content_margin_right = 12
	style.content_margin_bottom = 8

	panel.add_theme_stylebox_override("panel", style)
	
	var pos_x := randf_range(30.0, 400.0)
	var pos_y := randf_range(30.0, 220.0)
	panel.position = Vector2(pos_x, pos_y)
	panel.custom_minimum_size = Vector2(300, 50)

	var button := Button.new()
	button.text = texto
	button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	button.flat = true
	button.add_theme_color_override("font_color", Color(0.9, 0.95, 1.0))
	button.add_theme_font_size_override("font_size", 12)

	button.pressed.connect(func(): _on_balao_clicado(panel, button, is_fake))

	panel.add_child(button)
	container_baloes.add_child(panel)

	# Ângulo inicial e parâmetro para flutuação contínua de trajetória curva
	var angulo := randf_range(0.0, TAU)
	var vel_base := randf_range(50.0, 90.0)
	var dir := Vector2(cos(angulo), sin(angulo))

	var info := {
		"node": panel,
		"dir": dir,
		"speed": vel_base,
		"change_timer": randf_range(1.0, 2.5), # Tempo para curva orgânica
		"is_fake": is_fake
	}
	baloes_info.append(info)

	panel.scale = Vector2.ZERO
	var tween := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(panel, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK)


func _atualizar_movimentacao_indefinida_e_fuga(delta: float) -> void:
	var mouse_pos := container_baloes.get_local_mouse_position()
	var bounds_max := container_baloes.size
	if bounds_max.x < 100: bounds_max.x = 760
	if bounds_max.y < 100: bounds_max.y = 320

	for i in range(baloes_info.size()):
		var info: Dictionary = baloes_info[i]
		var panel: PanelContainer = info["node"]
		if not is_instance_valid(panel) or not panel.visible:
			continue

		var pos := panel.position
		var sz := panel.size
		var centro := pos + (sz / 2.0)

		# 1. Mudança contínua e aleatória da direção (Caminhada orgânica indefinida pela tela)
		info["change_timer"] -= delta
		if info["change_timer"] <= 0.0:
			info["change_timer"] = randf_range(1.2, 3.0)
			# Aplica uma rotação suave na direção atual (-45° a +45°)
			var angulo_variacao := randf_range(-PI / 4.0, PI / 4.0)
			info["dir"] = info["dir"].rotated(angulo_variacao).normalized()

		var dir_movimento: Vector2 = info["dir"]
		var velocidade_atual: float = info["speed"]

		# 2. FUGA REATIVA E AGRESSIVA DO MOUSE
		var dist_mouse := mouse_pos.distance_to(centro)
		var raio_fuga := 140.0
		
		if dist_mouse < raio_fuga and dist_mouse > 0.001:
			var dir_fuga := (centro - mouse_pos).normalized()
			# Quanto mais perto o mouse chega, mais rápido o balão foge
			var fator_urgencia := 1.0 - (dist_mouse / raio_fuga)
			dir_movimento = (dir_movimento + dir_fuga * 3.5 * fator_urgencia).normalized()
			velocidade_atual += 180.0 * fator_urgencia

		# 3. Atualização da Posição
		pos += dir_movimento * velocidade_atual * delta

		# 4. Enquadramento Suave (Mantém circulando indefinidamente sem travar nas bordas)
		if pos.x < 10.0:
			pos.x = 10.0
			dir_movimento.x = abs(dir_movimento.x)
		elif pos.x + sz.x > bounds_max.x - 10.0:
			pos.x = bounds_max.x - 10.0 - sz.x
			dir_movimento.x = -abs(dir_movimento.x)

		if pos.y < 10.0:
			pos.y = 10.0
			dir_movimento.y = abs(dir_movimento.y)
		elif pos.y + sz.y > bounds_max.y - 10.0:
			pos.y = bounds_max.y - 10.0 - sz.y
			dir_movimento.y = -abs(dir_movimento.y)

		info["dir"] = dir_movimento
		panel.position = pos


func _iniciar_timer_multiplicacao() -> void:
	timer_multiplicacao = Timer.new()
	timer_multiplicacao.wait_time = 4.0
	timer_multiplicacao.one_shot = false
	timer_multiplicacao.timeout.connect(_on_multiplicar_baloes)
	add_child(timer_multiplicacao)
	timer_multiplicacao.start()


func _on_multiplicar_baloes() -> void:
	if estado != Estado.DURANTE:
		return
		
	# Garante que novas frases geradas NUNCA se repitam (usando pop_back)
	if pool_fake.size() > 0:
		var texto_novo: String = pool_fake.pop_back()
		_spawnar_balao(texto_novo, true)


func _on_balao_clicado(panel: PanelContainer, button: Button, is_fake: bool) -> void:
	if estado != Estado.DURANTE or not is_instance_valid(panel):
		return

	button.disabled = true
	var style := panel.get_theme_stylebox("panel").duplicate() as StyleBoxFlat

	if is_fake:
		acertos += 1
		style.bg_color = COR_FAKE_EVIDENCIADA
		panel.add_theme_stylebox_override("panel", style)
		
		if label_placar_hud:
			label_placar_hud.text = "🎯 Fake News Derrubadas: %d/%d" % [acertos, total_fake_news_necessarias]

		var tween := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		tween.tween_property(panel, "scale", Vector2(1.15, 1.15), 0.1)
		tween.tween_property(panel, "scale", Vector2.ZERO, 0.2).set_trans(Tween.TRANS_BACK)
		await tween.finished
		
		_remover_balao_info(panel)
		panel.queue_free()
	else:
		erros += 1
		style.bg_color = COR_FATO_EVIDENCIADO
		panel.add_theme_stylebox_override("panel", style)

		var pos_orig := panel.position
		var tween := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		for i in range(4):
			tween.tween_property(panel, "position:x", pos_orig.x + 8, 0.03)
			tween.tween_property(panel, "position:x", pos_orig.x - 8, 0.03)
		tween.tween_property(panel, "position:x", pos_orig.x, 0.03)
		
		await get_tree().create_timer(1.2, true, false, true).timeout
		if is_instance_valid(button):
			button.disabled = false
			style.bg_color = COR_BALAO_NEUTRO
			panel.add_theme_stylebox_override("panel", style)

	_verificar_fim_de_jogo()


func _remover_balao_info(panel: PanelContainer) -> void:
	for i in range(baloes_info.size() - 1, -1, -1):
		if baloes_info[i]["node"] == panel:
			baloes_info.remove_at(i)
			break


func _verificar_fim_de_jogo() -> void:
	if acertos >= total_fake_news_necessarias:
		_ir_para_depois(true)


func _on_timer_timeout() -> void:
	if estado == Estado.DURANTE:
		_ir_para_depois(acertos >= total_fake_news_necessarias)


# =============================================================================
# ETAPA 3: DEPOIS (FEEDBACK DETALHADO E CONSCIENTIZAÇÃO)
# =============================================================================

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
	style_fundo.border_color = COR_GLOW_AZUL
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
	btn_style.bg_color = COR_GLOW_AZUL
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
	if is_instance_valid(timer_multiplicacao): timer_multiplicacao.stop()

	if is_instance_valid(container_baloes): container_baloes.visible = false
	if label_timer_hud: label_timer_hud.visible = false
	if label_placar_hud: label_placar_hud.visible = false

	if sucesso:
		label_titulo_resultado.text = "🛡️ REDE HIGIENIZADA COM SUCESSO!"
		label_titulo_resultado.add_theme_color_override("font_color", Color(0.2, 0.85, 0.45))
		label_mensagem_resultado.text = "Você conteve o surto de desinformação a tempo!

💡 IMPACTO REAL:
Notícias falsas afastam vítimas da proteção policial e dos serviços de acolhimento. Checar a fonte antes de compartilhar e combater mitos garante que a Lei Maria da Penha continue salvando vidas.

• Fake News Derrubadas: %d
• Equívocos em Fatos Reais: %d" % [acertos, erros]
		label_delta.text = "+10% Conscientização Social"
		label_delta.add_theme_color_override("font_color", Color(0.2, 0.85, 0.45))
	else:
		label_titulo_resultado.text = "⚠️ A DESINFORMAÇÃO SE ESPALHOU..."
		label_titulo_resultado.add_theme_color_override("font_color", Color(0.95, 0.3, 0.3))
		label_mensagem_resultado.text = "A desinformação viralizou mais rápido do que a checagem dos fatos.

⚠️ O PERIGO DA FAKE NEWS:
Quando mentiras sobre a rede de apoio se espalham, mulheres em situação de risco deixam de ligar para o 180 por acreditarem que não serão protegidas.

Sempre verifique os canais oficiais do Governo e do Judiciário!"
		label_delta.text = "-5% Conscientização Social"
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
		get_node("/root/EventBus").minigame_finalizado.emit(acertos >= total_fake_news_necessarias, limiar_evento)
		
	get_tree().paused = false
	queue_free()
