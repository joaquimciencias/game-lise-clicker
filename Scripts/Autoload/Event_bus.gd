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

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

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
