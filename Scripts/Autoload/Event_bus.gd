extends Node

# --- ESTATÍSTICAS E RECURSOS DO JOGADOR ---
var registros_totais: int = 0
var registros_por_tipo: Dictionary = {
	"fisica": 0,
	"psicologica": 0,
	"moral": 0,
	"patrimonial": 0
}

# --- SINAIS DA LOJA E PONTOS ---
@warning_ignore("unused_signal")
signal pontos_atualizados
@warning_ignore("unused_signal")
signal item_comprado(item)

# --- SINAIS DE EVENTOS DE PROGRESSO ---
@warning_ignore("unused_signal")
signal evento_gatilhado(porcentagem: int)
@warning_ignore("unused_signal")
signal evento_concluido(porcentagem: int)

@warning_ignore("unused_signal")
signal minigame_iniciado(limiar: float)
@warning_ignore("unused_signal")
signal minigame_finalizado(sucesso: bool, limiar: float)

# --- SINAIS DO MINIMAPA DINÂMICO ---
@warning_ignore("unused_signal")
signal conscientizacao_alterada(valor: float)
@warning_ignore("unused_signal")
signal atendimento_classificacao_correta(tipo: String)
@warning_ignore("unused_signal")
signal atendimento_classificacao_errada(tipo: String)
@warning_ignore("unused_signal")
signal atendimento_ligacao_perdida(tipo: String)

# --- SINAIS DE CONTROLE DO JOGO ---
signal jogo_pausado
signal jogo_retomado

# --- ESTADO DO FIM DE JOGO ---
var fim_de_jogo_vitoria: bool = false
var fim_de_jogo_stats: Dictionary = {}

# --- CONFIGURAÇÃO DO SOM DE CLIQUE ---
const CLICK_SFX = preload("res://Assets/Audio/click.ogg")

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

# --- DETECÇÃO GLOBAL DE CLIQUE ---
func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			_tocar_som_clique()

func _tocar_som_clique() -> void:
	var sfx_player = AudioStreamPlayer.new()
	sfx_player.stream = CLICK_SFX
	# Garante que o som toque mesmo se o jogo estiver pausado
	sfx_player.process_mode = Node.PROCESS_MODE_ALWAYS 
	
	get_tree().root.add_child(sfx_player)
	sfx_player.play()
	sfx_player.finished.connect(sfx_player.queue_free)

func adicionar_registro(tipo: String, quantidade: int = 1) -> void:
	var tipo_normalizado = tipo.to_lower()
	if registros_por_tipo.has(tipo_normalizado):
		registros_por_tipo[tipo_normalizado] += quantidade
		registros_totais += quantidade
		pontos_atualizados.emit()

func resetar_registros() -> void:
	registros_totais = 0
	registros_por_tipo = {
		"fisica": 0,
		"psicologica": 0,
		"moral": 0,
		"patrimonial": 0
	}

func pausar_jogo() -> void:
	get_tree().paused = true
	jogo_pausado.emit()

func retomar_jogo() -> void:
	get_tree().paused = false
	jogo_retomado.emit()
