extends MarginContainer

# Estágios de Conscientização
const STAGE_HOSTIL := 0
const STAGE_SINAIS := 1
const STAGE_REDE := 2
const STAGE_FORTE := 3

var conscientizacao: float = 0.0
var stage: int = -1
var walk_speed_multiplier: float = 1.0
var missed_call_time_left: float = 0.0
var anim_time: float = 0.0

# Camadas (Layers)
var sky_layer: Control
var city_layer: Control
var street_layer: Control
var chibi_layer: Control
var vehicle_layer: Control
var ui_layer: Control
var overlay_dark: ColorRect

# Elementos visuais
var sky_bg: ColorRect
var title_label: Label
var status_label: Label
var deam_node: Control
var casa_apoio_node: Control
var banner_node: Control
var posters: Array[Control] = []
var lamps: Array[ColorRect] = []
var chibis: Array[Dictionary] = []

# Ônibus
var bus_node: Control
var bus_x: float = -150.0
var bus_speed: float = 75.0

# Debug / Modo Teste
var debug_auto_demo: bool = false

func _ready() -> void:
	custom_minimum_size = Vector2(500, 128)
	clip_contents = true
	
	resized.connect(_on_resized)
	
	_build_scene()
	_connect_event_bus()
	_apply_stage(0.0, true)
	set_process(true)

func _on_resized() -> void:
	for child in get_children():
		child.queue_free()
	chibis.clear()
	lamps.clear()
	posters.clear()
	_build_scene()
	_apply_stage(conscientizacao, true)

func _process(delta: float) -> void:
	anim_time += delta
	
	# Avanço contínuo no Modo Demo (Ativado pela tecla T)
	if debug_auto_demo:
		var nova_val = fmod(conscientizacao + delta * 15.0, 101.0)
		_apply_stage(nova_val, false)

	if missed_call_time_left > 0.0:
		missed_call_time_left = max(0.0, missed_call_time_left - delta)
		overlay_dark.modulate.a = 0.38
	else:
		overlay_dark.modulate.a = move_toward(overlay_dark.modulate.a, 0.0, delta * 1.8)
		
	_update_lamps()
	_update_chibis(delta)
	_update_bus(delta)

# ==============================================================================
# EVENT BUS & SINAIS
# ==============================================================================

func _connect_event_bus() -> void:
	if not has_node('/root/EventBus'):
		return
	var bus = get_node('/root/EventBus')
	if bus.has_signal('conscientizacao_alterada') and not bus.conscientizacao_alterada.is_connected(_on_conscientizacao_alterada):
		bus.conscientizacao_alterada.connect(_on_conscientizacao_alterada)
	if bus.has_signal('atendimento_classificacao_correta') and not bus.atendimento_classificacao_correta.is_connected(_on_classificacao_correta):
		bus.atendimento_classificacao_correta.connect(_on_classificacao_correta)
	if bus.has_signal('atendimento_classificacao_errada') and not bus.atendimento_classificacao_errada.is_connected(_on_classificacao_errada):
		bus.atendimento_classificacao_errada.connect(_on_classificacao_errada)
	if bus.has_signal('atendimento_ligacao_perdida') and not bus.atendimento_ligacao_perdida.is_connected(_on_ligacao_perdida):
		bus.atendimento_ligacao_perdida.connect(_on_ligacao_perdida)

func _on_conscientizacao_alterada(valor: float) -> void:
	_apply_stage(valor, false)

func _on_classificacao_correta(_tipo: String = '') -> void:
	walk_speed_multiplier = min(walk_speed_multiplier + 0.18, 2.0)
	
	var visiveis: Array[Dictionary] = []
	for chibi in chibis:
		if chibi['root'].visible:
			visiveis.append(chibi)
			
	if not visiveis.is_empty():
		var escolhida = visiveis.pick_random()
		_react_success(escolhida)

func _on_classificacao_errada(tipo: String = '') -> void:
	var emoji := _emoji_para_tipo(tipo)
	for chibi in chibis:
		if chibi['root'].visible:
			_react_error(chibi, emoji)

func _on_ligacao_perdida(_tipo: String = '') -> void:
	missed_call_time_left = 2.0
	for chibi in chibis:
		if chibi['root'].visible:
			chibi['running'] = true
			chibi['paused'] = false
			(chibi['emoji'] as Label).text = '!'
			(chibi['emoji'] as Label).modulate.a = 1.0

# ==============================================================================
# CONSTRUÇÃO DO CENÁRIO COMPLETO
# ==============================================================================

func _build_scene() -> void:
	var w = max(size.x, 500.0)
	var h = max(size.y, 128.0)
	
	sky_layer = _create_layer('SkyLayer', w, h)
	city_layer = _create_layer('CityLayer', w, h)
	street_layer = _create_layer('StreetLayer', w, h)
	chibi_layer = _create_layer('ChibiLayer', w, h)
	vehicle_layer = _create_layer('VehicleLayer', w, h)
	ui_layer = _create_layer('UILayer', w, h)

	sky_bg = _rect('SkyBg', Vector2.ZERO, Vector2(w, h), Color('#15151d'))
	sky_layer.add_child(sky_bg)
	
	_build_buildings_and_institutions(w)
	_build_street_and_fixtures(w)
	_build_banners_and_posters(w)
	_spawn_chibis(w)
	_build_bus()
	_build_header(w)
	
	overlay_dark = _rect('LigacaoPerdidaOverlay', Vector2.ZERO, Vector2(w, h), Color(0.08, 0.02, 0.02, 1.0))
	overlay_dark.modulate.a = 0.0
	add_child(overlay_dark)

func _create_layer(layer_name: String, w: float, h: float) -> Control:
	var ctrl = Control.new()
	ctrl.name = layer_name
	ctrl.size = Vector2(w, h)
	ctrl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(ctrl)
	return ctrl

func _build_header(w: float) -> void:
	title_label = _label('Title', 'MINIMAPA', Vector2(10, 6), Vector2(220, 16), 9, Color('#f5e9ff'))
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	ui_layer.add_child(title_label)
	
	status_label = _label('Status', 'Cidade Hostil • 0%', Vector2(w - 210, 6), Vector2(200, 16), 9, Color('#d7c7ff'))
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	ui_layer.add_child(status_label)

func _build_buildings_and_institutions(w: float) -> void:
	for i in range(7):
		var bx = i * (w / 6.0) + 4
		var bw = (w / 6.0) * 0.72
		var bh = randf_range(35, 48)
		var b = _rect('Predio_%d' % i, Vector2(bx, 55 - bh), Vector2(bw, bh), Color('#34323d'))
		city_layer.add_child(b)
		for wx in range(4, int(bw) - 6, 10):
			for wy in range(6, int(bh) - 6, 9):
				city_layer.add_child(_rect('Janela', Vector2(bx + wx, (55 - bh) + wy), Vector2(4, 4), Color('#57525e')))

	# DEAM
	deam_node = Control.new()
	deam_node.name = 'DEAM'
	var deam_x = w * 0.18
	deam_node.add_child(_rect('DEAM_Body', Vector2(deam_x, 15), Vector2(62, 40), Color('#2a283e')))
	deam_node.add_child(_rect('DEAM_Door', Vector2(deam_x + 24, 38), Vector2(14, 17), Color('#191724')))
	deam_node.add_child(_rect('Giroflex', Vector2(deam_x + 26, 11), Vector2(10, 4), Color('#eb6f92')))
	
	var deam_lbl = _label('DEAM_Sign', '🚔 DEAM', Vector2(deam_x, 18), Vector2(62, 14), 8, Color('#eb6f92'))
	deam_node.add_child(deam_lbl)
	deam_node.modulate.a = 0.0
	city_layer.add_child(deam_node)

	# Casa Apoio
	casa_apoio_node = Control.new()
	casa_apoio_node.name = 'CasaApoio'
	var casa_x = w * 0.65
	casa_apoio_node.add_child(_rect('Casa_Body', Vector2(casa_x, 20), Vector2(68, 35), Color('#3e2d47')))
	casa_apoio_node.add_child(_rect('Casa_Door', Vector2(casa_x + 26, 40), Vector2(14, 15), Color('#191724')))
	
	var casa_lbl = _label('Casa_Sign', '🏠 CASA APOIO', Vector2(casa_x, 22), Vector2(68, 14), 7, Color('#ffd8f6'))
	casa_apoio_node.add_child(casa_lbl)
	casa_apoio_node.modulate.a = 0.0
	city_layer.add_child(casa_apoio_node)

func _build_street_and_fixtures(w: float) -> void:
	street_layer.add_child(_rect('Calcada', Vector2(0, 55), Vector2(w, 20), Color('#4a4650')))
	street_layer.add_child(_rect('Guia', Vector2(0, 73), Vector2(w, 2), Color('#635e6c')))
	street_layer.add_child(_rect('Rua', Vector2(0, 75), Vector2(w, 53), Color('#24242a')))
	
	for x in range(10, int(w), 40):
		street_layer.add_child(_rect('FaixaRua', Vector2(x, 98), Vector2(20, 2), Color('#7c7883')))
	
	lamps.clear()
	var step = w / 4.0
	for i in range(4):
		var lx = i * step + 35
		street_layer.add_child(_rect('Poste_%d' % i, Vector2(lx, 20), Vector2(3, 35), Color('#595361')))
		var lamp = _rect('Luz_%d' % i, Vector2(lx - 6, 17), Vector2(15, 4), Color('#4c4555'))
		street_layer.add_child(lamp)
		lamps.append(lamp)

func _build_banners_and_posters(w: float) -> void:
	posters.clear()
	
	# Quadro 1
	var q1 = Control.new()
	q1.name = 'Quadro1'
	q1.position = Vector2(w * 0.10, 30)
	q1.size = Vector2(36, 20)
	q1.add_child(_rect('Bg', Vector2.ZERO, Vector2(36, 20), Color('#ebbcba')))
	var q1_lbl = _label('Q1_Txt', 'LIGUE\n180', Vector2.ZERO, Vector2(36, 20), 6, Color('#191724'))
	q1.add_child(q1_lbl)
	q1.modulate.a = 0.0
	city_layer.add_child(q1)
	posters.append(q1)

	# Quadro 2
	var q2 = Control.new()
	q2.name = 'Quadro2'
	q2.position = Vector2(w * 0.52, 30)
	q2.size = Vector2(48, 20)
	q2.add_child(_rect('Bg', Vector2.ZERO, Vector2(48, 20), Color('#9ccfd8')))
	var q2_lbl = _label('Q2_Txt', 'DIREITOS\nDA MULHER', Vector2.ZERO, Vector2(48, 20), 6, Color('#191724'))
	q2.add_child(q2_lbl)
	q2.modulate.a = 0.0
	city_layer.add_child(q2)
	posters.append(q2)

	# Faixa Motivacional Superior
	banner_node = Control.new()
	banner_node.name = 'BannerNode'
	banner_node.position = Vector2(w * 0.35, 18)
	banner_node.size = Vector2(145, 18)
	banner_node.add_child(_rect('FaixaBg', Vector2.ZERO, Vector2(145, 18), Color('#c4a7e7')))
	
	var txt = _label('FaixaTxt', '💜 VOCÊ NÃO ESTÁ SOZINHA!', Vector2.ZERO, Vector2(145, 18), 7, Color('#191724'))
	banner_node.add_child(txt)
	banner_node.modulate.a = 0.0
	city_layer.add_child(banner_node)

func _build_bus() -> void:
	bus_node = Control.new()
	bus_node.name = 'BusNode'
	bus_node.position = Vector2(bus_x, 78)
	bus_node.size = Vector2(140, 32)
	
	bus_node.add_child(_rect('BusBody', Vector2.ZERO, Vector2(130, 24), Color('#907aa9')))
	bus_node.add_child(_rect('BusRoof', Vector2(2, -2), Vector2(126, 3), Color('#e0def4')))
	
	for i in range(5):
		bus_node.add_child(_rect('BusWin_%d' % i, Vector2(8 + (i * 24), 3), Vector2(18, 8), Color('#ebbcba')))
	
	# Faixa central do Ônibus
	bus_node.add_child(_rect('BusBannerBg', Vector2(4, 13), Vector2(122, 10), Color('#eb6f92')))
	
	var bus_txt = _label('BusCamp', '🚌 CAMPANHA: DENUNCIE! LIGUE 180', Vector2(4, 6.5), Vector2(122, 10), 5, Color('#ffffff'))
	bus_node.add_child(bus_txt)

	# Rodas
	bus_node.add_child(_rect('Roda1', Vector2(18, 23), Vector2(12, 6), Color('#191724')))
	bus_node.add_child(_rect('Roda2', Vector2(95, 23), Vector2(12, 6), Color('#191724')))

	bus_node.modulate.a = 0.0
	vehicle_layer.add_child(bus_node)

# ==============================================================================
# CHIBIS (PERSONAGENS)
# ==============================================================================

func _spawn_chibis(w: float) -> void:
	chibis.clear()
	
	for i in range(16):
		var req_stage := STAGE_HOSTIL
		
		if i < 2:
			req_stage = STAGE_HOSTIL
		elif i < 4:
			req_stage = STAGE_SINAIS
		elif i < 8:
			req_stage = STAGE_REDE
		else:
			req_stage = STAGE_FORTE
			
		var is_group_member := (i >= 5 and i <= 7)
		var sign_text := ''
		if i == 5: sign_text = 'LIGUE'
		elif i == 7: sign_text = '180'
		
		var spawn_x := fmod(float(i) * (w / 7.0) + 10.0, w)
		
		var chibi = _create_chibi(i, Vector2(spawn_x, 48.0), req_stage, is_group_member, sign_text)
		chibi_layer.add_child(chibi['root'])
		chibis.append(chibi)

func _create_chibi(index: int, pos: Vector2, req_stage: int, is_group: bool, sign_text: String) -> Dictionary:
	var root = Control.new()
	root.name = 'Chibi_%d' % index
	root.position = pos
	root.size = Vector2(22, 28)
	
	var bubble = _label('Balao', '', Vector2(-15, -16), Vector2(52, 14), 7, Color('#ffffff'))
	bubble.modulate.a = 0.0
	root.add_child(bubble)

	var emoji = _label('EmojiErro', '', Vector2(-2, -20), Vector2(25, 14), 9, Color('#ffffff'))
	emoji.modulate.a = 0.0
	root.add_child(emoji)

	# Cartaz centralizado perfeitamente
	if sign_text != '':
		var sign_bg = Control.new()
		sign_bg.name = 'CartazBg'
		sign_bg.position = Vector2(-7, -22)
		sign_bg.size = Vector2(36, 18)
		
		sign_bg.add_child(_rect('PlacaFundo', Vector2.ZERO, Vector2(36, 18), Color('#f2e9e1')))
		sign_bg.add_child(_rect('Haste', Vector2(17, 18), Vector2(2, 8), Color('#896851')))
		
		var sign_lbl = _label('CartazTxt', sign_text, Vector2.ZERO, Vector2(36, 18), 5, Color('#191724'))
		sign_bg.add_child(sign_lbl)
		root.add_child(sign_bg)

	root.add_child(_rect('Cabeca', Vector2(5, 0), Vector2(11, 9), Color('#f6c177')))
	root.add_child(_rect('Cabelo', Vector2(4, -2), Vector2(13, 5), Color(['#56321d', '#40214f', '#242424', '#7c4a24', '#6d2e2e'][index % 5])))
	root.add_child(_rect('Corpo', Vector2(4, 9), Vector2(13, 10), Color(['#a855f7', '#ec4899', '#60a5fa', '#34d399', '#f59e0b'][index % 5])))
	
	var pernas = _label('Pernas', '| |', Vector2(4, 18), Vector2(13, 10), 8, Color('#1b1b24'))
	root.add_child(pernas)

	return {
		'root': root,
		'bubble': bubble,
		'emoji': emoji,
		'speed': 20.0 if is_group else (14.0 + float(index % 5) * 3.5),
		'direction': 1.0 if (is_group or index % 2 == 0) else -1.0,
		'base_y': pos.y,
		'req_stage': req_stage,
		'is_group': is_group,
		'group_offset': (index - 5) * 26.0 if is_group else 0.0,
		'running': false,
		'paused': false
	}

# ==============================================================================
# LÓGICA DE ESTÁGIOS E EVOLUÇÃO
# ==============================================================================

func _apply_stage(valor: float, force: bool) -> void:
	conscientizacao = clamp(valor, 0.0, 100.0)
	var new_stage := STAGE_HOSTIL
	
	if conscientizacao >= 75.0:
		new_stage = STAGE_FORTE
	elif conscientizacao >= 50.0:
		new_stage = STAGE_REDE
	elif conscientizacao >= 25.0:
		new_stage = STAGE_SINAIS
		
	if new_stage == stage and not force:
		status_label.text = '%s • %d%%' % [_stage_name(stage), int(conscientizacao)]
		_update_chibi_visibility()
		return
		
	stage = new_stage
	status_label.text = '%s • %d%%' % [_stage_name(stage), int(conscientizacao)]
	
	match stage:
		STAGE_HOSTIL: sky_bg.color = Color('#15151d')
		STAGE_SINAIS: sky_bg.color = Color('#202030')
		STAGE_REDE: sky_bg.color = Color('#2f2445')
		STAGE_FORTE: sky_bg.color = Color('#382052')
			
	for p in posters:
		p.modulate.a = 1.0 if stage >= STAGE_SINAIS else 0.0
		
	if deam_node:
		deam_node.modulate.a = 1.0 if stage >= STAGE_REDE else 0.0
		
	if bus_node:
		bus_node.modulate.a = 1.0 if stage >= STAGE_REDE else 0.0
		
	if casa_apoio_node:
		casa_apoio_node.modulate.a = 1.0 if stage >= STAGE_FORTE else 0.0
		
	if banner_node:
		banner_node.modulate.a = 1.0 if stage >= STAGE_FORTE else 0.0
		
	_update_chibi_visibility()
	if conscientizacao >= 80.0:
		_exibir_baloes_encorajamento()

func _update_chibi_visibility() -> void:
	for chibi in chibis:
		chibi['root'].visible = stage >= int(chibi['req_stage'])

# ==============================================================================
# ATUALIZAÇÕES EM TEMPO REAL (PROCESS)
# ==============================================================================

func _update_chibis(delta: float) -> void:
	var celebracao_ativa := (conscientizacao >= 80.0)
	var max_w := size.x if size.x > 0 else 500.0
	
	for chibi in chibis:
		var root: Control = chibi['root']
		if not root.visible or chibi['paused']:
			continue
			
		var speed: float = chibi['speed'] * walk_speed_multiplier
		if chibi['running']:
			speed *= 4.5
			
		root.position.x += speed * float(chibi['direction']) * delta
		
		# Pulo de celebração aleatório (>= 80%) vs Pulo padrão
		if celebracao_ativa:
			var jump_offset = abs(sin(Time.get_ticks_msec() * 0.012 + float(chibis.find(chibi)) * 3.7)) * 14.0
			root.position.y = float(chibi['base_y']) - jump_offset
		else:
			root.position.y = float(chibi['base_y']) + sin(Time.get_ticks_msec() / 150.0 + float(chibis.find(chibi))) * 1.5
			
		# Limites de borda ajustados usando max_w (size.x)
		if root.position.x > max_w + 48:
			root.position.x = -46
			chibi['running'] = false
			(chibi['emoji'] as Label).modulate.a = 0.0
		elif root.position.x < -52:
			root.position.x = max_w + 42
			chibi['running'] = false
			(chibi['emoji'] as Label).modulate.a = 0.0
			
	walk_speed_multiplier = move_toward(walk_speed_multiplier, 1.0, delta * 0.08)

func _update_bus(delta: float) -> void:
	if stage < STAGE_REDE:
		return
		
	var w = max(size.x, 500.0)
	bus_x += bus_speed * delta
	if bus_x > w + 40:
		bus_x = -130.0
	bus_node.position.x = bus_x

func _update_lamps() -> void:
	for i in range(lamps.size()):
		var lamp = lamps[i]
		if stage == STAGE_HOSTIL:
			lamp.color = Color('#8b7b51') if sin(anim_time * 9.0 + float(i)) > 0.45 else Color('#403a44')
		elif stage == STAGE_SINAIS:
			lamp.color = Color('#bda96b')
		else:
			lamp.color = Color('#ffe49a')

# ==============================================================================
# REAÇÕES E FEEDBACKS VISUAIS
# ==============================================================================

func _react_success(chibi: Dictionary) -> void:
	chibi['paused'] = true
	var root: Control = chibi['root']
	var bubble: Label = chibi['bubble']
	bubble.text = ['Obrigada!', 'Juntas!', '💜 REDE LILÁS', 'RESPEITO!'].pick_random()
	bubble.modulate.a = 1.0
	
	var original_pos := root.position
	var tween := create_tween()
	tween.tween_property(root, 'position:y', original_pos.y - 12.0, 0.14).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(root, 'position:y', original_pos.y, 0.18).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	tween.tween_interval(0.75)
	tween.tween_property(bubble, 'modulate:a', 0.0, 0.25)
	await tween.finished
	chibi['paused'] = false

func _react_error(chibi: Dictionary, emoji: String) -> void:
	chibi['paused'] = true
	var root: Control = chibi['root']
	var emoji_label: Label = chibi['emoji']
	emoji_label.text = emoji
	emoji_label.modulate.a = 1.0
	
	var tween := create_tween()
	tween.tween_property(root, 'rotation', deg_to_rad(-8.0), 0.12)
	tween.tween_property(root, 'rotation', deg_to_rad(8.0), 0.12)
	tween.tween_property(root, 'rotation', 0.0, 0.12)
	tween.tween_interval(0.85)
	tween.tween_property(emoji_label, 'modulate:a', 0.0, 0.25)
	await tween.finished
	chibi['paused'] = false

func _emoji_para_tipo(tipo: String) -> String:
	var t := tipo.to_lower()
	if 'fisica' in t or 'física' in t: return '🩸'
	if 'psicol' in t: return '🌩️'
	if 'moral' in t: return '🤐'
	if 'patrimonial' in t: return '🔓'
	return '⚠️'

func _stage_name(value: int) -> String:
	match value:
		STAGE_SINAIS: return 'Primeiros Sinais'
		STAGE_REDE: return 'Rede em Expansão'
		STAGE_FORTE: return 'Comunidade Fortalecida'
		_: return 'Cidade Hostil'

# ==============================================================================
# HELPERS DE UI (ALINHAMENTO RIGOROSO DE TEXTO)
# ==============================================================================

func _rect(node_name: String, pos: Vector2, rect_size: Vector2, color: Color) -> ColorRect:
	var r := ColorRect.new()
	r.name = node_name
	r.position = pos
	r.size = rect_size
	r.color = color
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return r

func _label(node_name: String, text_value: String, pos: Vector2, rect_size: Vector2, font_size: int, color: Color) -> Label:
	var l := Label.new()
	l.name = node_name
	l.position = pos
	l.size = rect_size
	l.text = text_value
	l.add_theme_font_size_override('font_size', font_size)
	l.add_theme_color_override('font_color', color)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.autowrap_mode = TextServer.AUTOWRAP_OFF
	l.clip_text = false
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l

# ==============================================================================
# RECURSOS DE DEBUG E TESTE
# ==============================================================================

func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.is_echo()):
		return

	match event.keycode:
		KEY_0:
			_apply_stage(0.0, true)
		KEY_1:
			_apply_stage(25.0, true)
		KEY_2:
			_apply_stage(50.0, true)
		KEY_3:
			_apply_stage(75.0, true)
		KEY_4:
			_apply_stage(100.0, true)

		KEY_UP:
			_apply_stage(conscientizacao + 5.0, false)
		KEY_DOWN:
			_apply_stage(conscientizacao - 5.0, false)

		KEY_E:
			_on_classificacao_correta("fisica")
		KEY_R:
			_on_classificacao_errada("psicologica")
		KEY_P:
			_on_ligacao_perdida()

		KEY_T:
			debug_auto_demo = !debug_auto_demo


func _exibir_baloes_encorajamento() -> void:
	var frases := ["Você consegue!", "Juntas!", "Vamos lá!", "Força!", "Não pare!", "💜"]
	for chibi in chibis:
		if chibi['root'].visible and not chibi['paused']:
			var bubble: Label = chibi['bubble']
			if bubble.modulate.a <= 0.1:
				bubble.text = frases.pick_random()
				var tween := create_tween()
				tween.tween_property(bubble, "modulate:a", 1.0, 0.2)
				tween.tween_interval(1.2)
				tween.tween_property(bubble, "modulate:a", 0.0, 0.4)
