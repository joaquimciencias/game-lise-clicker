extends MarginContainer
# Script conectado à raiz da cena JogoPausado

signal jogo_retomado

# Referências aos nós de UI criados na cena
@onready var slider_musica: HSlider = $CenterContainer/PainelConteudo/MarginContainer/VBoxContainer/ControleMusica/HSliderMusica
@onready var slider_sfx: HSlider = $CenterContainer/PainelConteudo/MarginContainer/VBoxContainer/ControleSfx/HSliderSfx
@onready var btn_mute_musica: Button = $CenterContainer/PainelConteudo/MarginContainer/VBoxContainer/ControleMusica/HBoxCabecalhoMusica/BtnMuteMusica
@onready var btn_mute_sfx: Button = $CenterContainer/PainelConteudo/MarginContainer/VBoxContainer/ControleSfx/HBoxCabecalhoSfx/BtnMuteSfx

# Guarda o último volume antes de mutar para poder restaurar ao desmutar
var volume_anterior_musica: float = 100.0
var volume_anterior_sfx: float = 100.0

func _ready() -> void:
	# Garante via código que a janela de pausa responda mesmo quando o jogo estiver pausado
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group("janelas_pausa")
	hide()
	
	# Sincroniza a interface com o estado real do AudioServer ao iniciar a cena
	_sincronizar_controles_audio()

func abrir() -> void:
	# Atualiza os volumes visualmente caso tenham mudado externamente antes de abrir
	_sincronizar_controles_audio()
	show()

# Botão de continuar que está DENTRO da cena de pausa
func _on_botao_continuar_pressed() -> void:
	hide()
	# Descongela o jogo nativamente na Godot
	get_tree().paused = false
	# Emitimos o sinal para avisar a cena principal se necessário
	jogo_retomado.emit()

# --- CONTROLES DE ÁUDIO (MÚSICA E SFX) ---

func _sincronizar_controles_audio() -> void:
	# Barramento de Música
	var bus_musica_idx = AudioServer.get_bus_index("Musica")
	if bus_musica_idx != -1:
		var vol_db = AudioServer.get_bus_volume_db(bus_musica_idx)
		slider_musica.value = db_to_linear(vol_db)
		var mutado = AudioServer.is_bus_mute(bus_musica_idx)
		btn_mute_musica.button_pressed = mutado
		_atualizar_texto_botao_musica(mutado)

	# Barramento de Efeitos Sonoros (SFX)
	var bus_sfx_idx = AudioServer.get_bus_index("SFX")
	if bus_sfx_idx != -1:
		var vol_db = AudioServer.get_bus_volume_db(bus_sfx_idx)
		slider_sfx.value = db_to_linear(vol_db)
		var mutado = AudioServer.is_bus_mute(bus_sfx_idx)
		btn_mute_sfx.button_pressed = mutado
		_atualizar_texto_botao_sfx(mutado)


func _on_h_slider_musica_value_changed(value: float) -> void:
	var bus_idx = AudioServer.get_bus_index("Musica")
	if bus_idx != -1:
		AudioServer.set_bus_volume_db(bus_idx, linear_to_db(value))
		# Se arrastou para o zero, aciona o mudo automaticamente por comodidade
		if value <= 0.001 and not AudioServer.is_bus_mute(bus_idx):
			btn_mute_musica.button_pressed = true
		elif value > 0.001 and AudioServer.is_bus_mute(bus_idx):
			btn_mute_musica.button_pressed = false


func _on_h_slider_sfx_value_changed(value: float) -> void:
	var bus_idx = AudioServer.get_bus_index("SFX")
	if bus_idx != -1:
		AudioServer.set_bus_volume_db(bus_idx, linear_to_db(value))
		if value <= 0.001 and not AudioServer.is_bus_mute(bus_idx):
			btn_mute_sfx.button_pressed = true
		elif value > 0.001 and AudioServer.is_bus_mute(bus_idx):
			btn_mute_sfx.button_pressed = false


func _on_btn_mute_musica_toggled(toggled_on: bool) -> void:
	var bus_idx = AudioServer.get_bus_index("Musica")
	if bus_idx != -1:
		AudioServer.set_bus_mute(bus_idx, toggled_on)
		_atualizar_texto_botao_musica(toggled_on)
		if toggled_on:
			volume_anterior_musica = slider_musica.value
			slider_musica.value = 0.0
		else:
			slider_musica.value = volume_anterior_musica if volume_anterior_musica > 0 else 0.5


func _on_btn_mute_sfx_toggled(toggled_on: bool) -> void:
	var bus_idx = AudioServer.get_bus_index("SFX")
	if bus_idx != -1:
		AudioServer.set_bus_mute(bus_idx, toggled_on)
		_atualizar_texto_botao_sfx(toggled_on)
		if toggled_on:
			volume_anterior_sfx = slider_sfx.value
			slider_sfx.value = 0.0
		else:
			slider_sfx.value = volume_anterior_sfx if volume_anterior_sfx > 0 else 0.5


func _atualizar_texto_botao_musica(mutado: bool) -> void:
	btn_mute_musica.text = "🔇 Mudo" if mutado else "🔊 Som"


func _atualizar_texto_botao_sfx(mutado: bool) -> void:
	btn_mute_sfx.text = "🔇 Mudo" if mutado else "🔊 Som"
