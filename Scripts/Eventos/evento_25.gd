extends Control

## Evento Extra de Interceptação Emergencial — Violência Sexual
## Mantém integração com EventBus e Game Manager.
## Inclui efeitos de Glitch, Sirene, Typewriter e Tensão.

const BONUS_CONSCIENTIZACAO: float = 5.0
const PENALIDADE_CONSCIENTIZACAO: float = 3.0
const TEMPO_LIMITE_SEGUNDOS: float = 35.0

const COR_EMERGENCIA := Color("ff0033")
const COR_AZUL_POLICIA := Color("0066ff")
const COR_SUCESSO := Color("2ec4b6")
const COR_FALHA := Color("e63946")

enum Estado { LENDO, LIGANDO, RESULTADO, FINALIZADO }

var limiar_evento: float = 25.0
var estado: Estado = Estado.LENDO
var progresso_atual: float = 0.0
var minigame_sucesso: bool = false
var ja_finalizado: bool = false

# Referências Seguras de Nós da Cena
@onready var timer: Timer = $TimerProgresso if has_node("TimerProgresso") else null
@onready var label_timer: Label = $PanelTimer/LabelTimer if has_node("PanelTimer/LabelTimer") else null
@onready var panel_sirene_red: ColorRect = $OverlaySirene/SirenRed if has_node("OverlaySirene/SirenRed") else null
@onready var panel_sirene_blue: ColorRect = $OverlaySirene/SirenBlue if has_node("OverlaySirene/SirenBlue") else null
@onready var vinheta_panico: TextureRect = $VinhetaPanico if has_node("VinhetaPanico") else null
@onready var progress_bar: ProgressBar = $MarginContainerAcao/VBoxContainer/ProgressBarAtendimento if has_node("MarginContainerAcao/VBoxContainer/ProgressBarAtendimento") else null
@onready var botao_acionar: Button = $MarginContainerAcao/VBoxContainer/BotaoAcionar if has_node("MarginContainerAcao/VBoxContainer/BotaoAcionar") else null
@onready var area_acao: MarginContainer = $MarginContainerAcao if has_node("MarginContainerAcao") else null
@onready var area_relato: VBoxContainer = $MarginContainerRelato if has_node("MarginContainerRelato") else null
@onready var label_aviso: Label = $MarginContainerRelato/Panel/Aviso if has_node("MarginContainerRelato/Panel/Aviso") else null
@onready var label_titulo: Label = $LabelTitulo if has_node("LabelTitulo") else null
@onready var label_prioridade: Label = $LabelPrioridade if has_node("LabelPrioridade") else null

# Elementos visuais para efeito Glitch
@onready var panel_principal: Panel = $PanelPrincipal if has_node("PanelPrincipal") else null
@onready var color_glitch_overlay: ColorRect = $OverlayGlitch if has_node("OverlayGlitch") else null

# Áudios Integrados
@onready var audio_sirene: AudioStreamPlayer = $Audios/AudioSirene if has_node("Audios/AudioSirene") else null
@onready var audio_heartbeat: AudioStreamPlayer = $Audios/AudioHeartbeat if has_node("Audios/AudioHeartbeat") else null
@onready var audio_click: AudioStreamPlayer = $Audios/AudioClick if has_node("Audios/AudioClick") else null
@onready var audio_glitch: AudioStreamPlayer = $Audios/AudioGlitch if has_node("Audios/AudioGlitch") else null

var tween_sirene: Tween
var tween_vinheta: Tween
var tween_glitch: Tween
var timer_glitch_aleatorio: Timer

var botao_entendi: Button
var painel_resultado: Control
var label_titulo_resultado: Label
var label_mensagem_resultado: Label
var label_delta: Label
var botao_continuar: Button

# Texto impactante com interferências simuladas
var texto_relato_completo: String = """\"Alô?! Me ajuda... por favor...
Ele me trancou aqui... [SINAL FRAGIL] ele fez de novo!
Disse que ninguém vai me ouvir...
Meu corpo dói... Espera... acho que ele voltou!
Eu preciso deslig—...\"

(INTERCEPTAÇÃO CRÍTICA — SINAL INTERROMPIDO)"""

var caracteres_glitch: String = "@#$&%*!~?/><01XY"


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().paused = true

	_configurar_ui_inicial()
	_criar_botao_entendi()
	_criar_painel_resultado()
	_animar_entrada()
	_iniciar_efeito_vinheta_panico()
	_iniciar_loop_glitch()

	await get_tree().process_frame
	pivot_offset = size / 2.0

	if has_node("/root/EventBus"):
		get_node("/root/EventBus").minigame_iniciado.emit(limiar_evento)
	_efeito_typewriter(texto_relato_completo)


func _process(_delta: float) -> void:
	if estado != Estado.LIGANDO:
		return
	if is_instance_valid(timer) and not timer.is_stopped() and is_instance_valid(label_timer):
		label_timer.text = "%.1fs" % timer.time_left


func _tween() -> Tween:
	var tween := create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	return tween


# =============================================================================
# EFEITOS VISUAIS: GLITCH & INTERCEPTAÇÃO DE SINAL
# =============================================================================

func _iniciar_loop_glitch() -> void:
	timer_glitch_aleatorio = Timer.new()
	timer_glitch_aleatorio.one_shot = true
	timer_glitch_aleatorio.wait_time = randf_range(1.5, 3.5)
	timer_glitch_aleatorio.timeout.connect(_on_glitch_timer_timeout)
	add_child(timer_glitch_aleatorio)
	timer_glitch_aleatorio.start()


func _on_glitch_timer_timeout() -> void:
	if estado != Estado.FINALIZADO:
		_disparar_efeito_glitch()
		if is_instance_valid(timer_glitch_aleatorio):
			timer_glitch_aleatorio.wait_time = randf_range(1.2, 4.0)
			timer_glitch_aleatorio.start()


func _disparar_efeito_glitch() -> void:
	if audio_glitch and randf() > 0.3:
		audio_glitch.pitch_scale = randf_range(0.8, 1.4)
		audio_glitch.play()

	var pos_orig := position
	var scale_orig := scale
	
	if color_glitch_overlay:
		color_glitch_overlay.visible = true
		color_glitch_overlay.modulate.a = randf_range(0.15, 0.4)

	var tween_g := _tween()
	for i in range(3):
		var offset_x := randf_range(-12.0, 12.0)
		var offset_y := randf_range(-6.0, 6.0)
		var scale_x := randf_range(0.98, 1.02)
		tween_g.tween_property(self, "position", pos_orig + Vector2(offset_x, offset_y), 0.02)
		tween_g.tween_property(self, "scale", Vector2(scale_x, 1.0), 0.02)
		if panel_principal:
			panel_principal.modulate = Color(randf_range(0.7, 1.0), randf_range(0.2, 0.5), randf_range(0.2, 0.9))

	tween_g.tween_property(self, "position", pos_orig, 0.03)
	tween_g.tween_property(self, "scale", scale_orig, 0.03)
	
	await tween_g.finished
	if color_glitch_overlay:
		color_glitch_overlay.visible = false
	if panel_principal:
		panel_principal.modulate = Color.WHITE


# =============================================================================
# EFEITOS DE TENSÃO E IMERSÃO
# =============================================================================

func _iniciar_efeito_vinheta_panico() -> void:
	if not is_instance_valid(vinheta_panico):
		return
	tween_vinheta = _tween().set_loops()
	tween_vinheta.tween_property(vinheta_panico, "modulate:a", 0.7, 0.6).set_trans(Tween.TRANS_SINE)
	tween_vinheta.tween_property(vinheta_panico, "modulate:a", 0.2, 0.6).set_trans(Tween.TRANS_SINE)


func _iniciar_sirene_policia() -> void:
	if not is_instance_valid(panel_sirene_red) or not is_instance_valid(panel_sirene_blue):
		return
	
	if audio_sirene:
		audio_sirene.play()

	tween_sirene = _tween().set_loops()
	tween_sirene.tween_property(panel_sirene_red, "modulate:a", 0.35, 0.15)
	tween_sirene.tween_property(panel_sirene_red, "modulate:a", 0.0, 0.15)
	tween_sirene.tween_property(panel_sirene_blue, "modulate:a", 0.35, 0.15)
	tween_sirene.tween_property(panel_sirene_blue, "modulate:a", 0.0, 0.15)


func _parar_sirene() -> void:
	if tween_sirene:
		tween_sirene.kill()
	if panel_sirene_red:
		panel_sirene_red.modulate.a = 0.0
	if panel_sirene_blue:
		panel_sirene_blue.modulate.a = 0.0
	if audio_sirene:
		audio_sirene.stop()


func _shake_screen(intensidade: float = 6.0) -> void:
	var pos_original := position
	var tween := _tween()
	for i in range(4):
		var offset := Vector2(randf_range(-intensidade, intensidade), randf_range(-intensidade, intensidade))
		tween.tween_property(self, "position", pos_original + offset, 0.03)
	tween.tween_property(self, "position", pos_original, 0.03)


func _efeito_typewriter(texto: String) -> void:
	if not is_instance_valid(label_aviso):
		return
	label_aviso.text = ""
	for i in range(texto.length()):
		if estado != Estado.LENDO:
			break
		
		if randf() < 0.04 and texto[i] != " " and texto[i] != "\n":
			var char_glitch = caracteres_glitch[randi() % caracteres_glitch.length()]
			label_aviso.text += char_glitch
			await get_tree().create_timer(0.02, true, false, true).timeout
			label_aviso.text = label_aviso.text.left(label_aviso.text.length() - 1)
		
		label_aviso.text += texto[i]
		if texto[i] != " " and texto[i] != "\n":
			if audio_click and randf() > 0.5:
				audio_click.pitch_scale = randf_range(0.85, 1.15)
				audio_click.play()
		await get_tree().create_timer(0.025, true, false, true).timeout


# =============================================================================
# CONFIGURAÇÃO DA INTERFACE
# =============================================================================

func _configurar_ui_inicial() -> void:
	progresso_atual = 0.0
	if progress_bar:
		progress_bar.max_value = 100.0
		progress_bar.value = 0.0
	if botao_acionar:
		botao_acionar.pressed.connect(_on_botao_acionar_pressed)
		botao_acionar.disabled = true
	if area_acao:
		area_acao.visible = false
		area_acao.modulate.a = 0.0
	if timer:
		timer.wait_time = TEMPO_LIMITE_SEGUNDOS
		timer.timeout.connect(_on_timer_progresso_timeout)


func _criar_botao_entendi() -> void:
	if not is_instance_valid(area_relato):
		return
	botao_entendi = Button.new()
	botao_entendi.name = "BotaoEntendi"
	botao_entendi.text = "🚨 TENTAR REESTABELECER CONEXÃO (190)"
	botao_entendi.custom_minimum_size = Vector2(340, 52)
	botao_entendi.add_theme_font_size_override("font_size", 16)
	botao_entendi.add_theme_color_override("font_color", Color.WHITE)
	botao_entendi.add_theme_stylebox_override("normal", _style_botao(COR_EMERGENCIA))
	
	botao_entendi.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	botao_entendi.grow_horizontal = Control.GROW_DIRECTION_BOTH
	botao_entendi.offset_left = -170
	botao_entendi.offset_right = 170
	botao_entendi.offset_top = -60
	botao_entendi.offset_bottom = -8

	area_relato.add_child(botao_entendi)
	botao_entendi.pressed.connect(_on_botao_entendi_pressed)


func _criar_painel_resultado() -> void:
	painel_resultado = Control.new()
	painel_resultado.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	painel_resultado.visible = false
	painel_resultado.modulate.a = 0.0
	add_child(painel_resultado)

	var fundo := Panel.new()
	fundo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fundo.add_theme_stylebox_override("panel", _style_painel_resultado())
	painel_resultado.add_child(fundo)

	var centro := CenterContainer.new()
	centro.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	painel_resultado.add_child(centro)

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 16)
	vbox.custom_minimum_size = Vector2(460, 0)
	centro.add_child(vbox)

	label_titulo_resultado = Label.new()
	label_titulo_resultado.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label_titulo_resultado.add_theme_font_size_override("font_size", 28)
	vbox.add_child(label_titulo_resultado)

	label_mensagem_resultado = Label.new()
	label_mensagem_resultado.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label_mensagem_resultado.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label_mensagem_resultado.add_theme_font_size_override("font_size", 16)
	vbox.add_child(label_mensagem_resultado)

	label_delta = Label.new()
	label_delta.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label_delta.add_theme_font_size_override("font_size", 28)
	vbox.add_child(label_delta)

	botao_continuar = Button.new()
	botao_continuar.text = "CONTINUAR O JOGO"
	botao_continuar.custom_minimum_size = Vector2(240, 50)
	botao_continuar.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	botao_continuar.add_theme_stylebox_override("normal", _style_botao(COR_EMERGENCIA))
	botao_continuar.pressed.connect(_on_botao_continuar_pressed)
	vbox.add_child(botao_continuar)


func _style_botao(cor: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = cor
	style.corner_radius_top_left = 12
	style.corner_radius_top_right = 12
	style.corner_radius_bottom_right = 12
	style.corner_radius_bottom_left = 12
	return style


func _style_painel_resultado() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.03, 0.08, 0.96)
	style.border_width_left = 3
	style.border_width_top = 3
	style.border_width_right = 3
	style.border_width_bottom = 3
	style.border_color = COR_EMERGENCIA
	return style


func _animar_entrada() -> void:
	modulate.a = 0.0
	scale = Vector2(0.95, 0.95)
	var tween := _tween().set_parallel(true)
	tween.tween_property(self, "modulate:a", 1.0, 0.3)
	tween.tween_property(self, "scale", Vector2.ONE, 0.3)


# =============================================================================
# TRANSIÇÃO DE FASE
# =============================================================================

func _on_botao_entendi_pressed() -> void:
	if estado != Estado.LENDO:
		return
	
	if botao_entendi:
		botao_entendi.disabled = true
	_iniciar_sirene_policia()
	_disparar_efeito_glitch()
	
	if area_relato:
		var tween := _tween().set_parallel(true)
		tween.tween_property(area_relato, "modulate:a", 0.0, 0.25)
		await tween.finished
		area_relato.visible = false
	
	if label_titulo:
		label_titulo.text = "LIGAÇÃO INTERCEPTADA — EMBARALHAMENTO DE SINAL"
	if label_prioridade:
		label_prioridade.text = "PRESSIONE RAPIDAMENTE PARA CONECTAR Á DELEGACIA!"
	
	if area_acao:
		area_acao.visible = true
		var tween_in := _tween()
		tween_in.tween_property(area_acao, "modulate:a", 1.0, 0.25)
	
	estado = Estado.LIGANDO
	if botao_acionar:
		botao_acionar.disabled = false
	if timer:
		timer.start()


func _on_botao_acionar_pressed() -> void:
	if estado != Estado.LIGANDO or ja_finalizado:
		return

	var ganho := calcular_resistencia(progresso_atual)
	progresso_atual = minf(100.0, progresso_atual + ganho)
	
	_shake_screen(5.0)
	if randf() < 0.25:
		_disparar_efeito_glitch()

	if progress_bar:
		var t := _tween()
		t.tween_property(progress_bar, "value", progresso_atual, 0.08)

	if progresso_atual >= 100.0:
		_ir_para_resultado(true)


func calcular_resistencia(progresso: float) -> float:
	var t := clampf(progresso / 100.0, 0.0, 1.0)
	return 12.0 * pow(1.0 - t, 1.1) + 1.8


func _on_timer_progresso_timeout() -> void:
	if estado == Estado.LIGANDO and not ja_finalizado:
		_ir_para_resultado(false)


# =============================================================================
# TELA FINAL E CONSCIENTIZAÇÃO
# =============================================================================

func _ir_para_resultado(sucesso: bool) -> void:
	ja_finalizado = true
	estado = Estado.RESULTADO
	minigame_sucesso = sucesso

	if timer:
		timer.stop()
	_parar_sirene()
	_disparar_efeito_glitch()
	if botao_acionar:
		botao_acionar.disabled = true

	if sucesso:
		label_titulo_resultado.text = "🚨 SOCORRO A CAMINHO!"
		label_titulo_resultado.add_theme_color_override("font_color", COR_SUCESSO)
		label_mensagem_resultado.text = "A polícia foi acionada a tempo e a localização da vítima foi enviada às autoridades.\n\nLembre-se: Em casos reais de violência contra a mulher, denuncie!\n• Ligue 180 (Central de Atendimento à Mulher)\n• Ligue 190 (Polícia Militar para emergências)"
		label_delta.text = "+%.0f%% Conscientização" % BONUS_CONSCIENTIZACAO
		label_delta.add_theme_color_override("font_color", COR_SUCESSO)
	else:
		label_titulo_resultado.text = "⚠️ SINAL PERDIDO — LIGAÇÃO CAIU"
		label_titulo_resultado.add_theme_color_override("font_color", COR_FALHA)
		label_mensagem_resultado.text = "A ligação foi cortada antes de obter a localização exata. Em situações extremas, agir rápido salva vidas.\n\nNunca hesite em acionar o 180 ou 190 ao suspeitar de agressão ou cárcere."
		label_delta.text = "-%.0f%% Conscientização" % PENALIDADE_CONSCIENTIZACAO
		label_delta.add_theme_color_override("font_color", COR_FALHA)

	if painel_resultado:
		painel_resultado.visible = true
		var tween := _tween()
		tween.tween_property(painel_resultado, "modulate:a", 1.0, 0.35)


func _on_botao_continuar_pressed() -> void:
	if estado != Estado.RESULTADO:
		return
	
	estado = Estado.FINALIZADO
	if has_node("/root/EventBus"):
		get_node("/root/EventBus").minigame_finalizado.emit(minigame_sucesso, limiar_evento)
	get_tree().paused = false
	queue_free()
