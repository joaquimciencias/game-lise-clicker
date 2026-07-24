extends Node

# --- SINAIS DA LOJA E PONTOS ---
@warning_ignore("unused_signal")
signal pontos_atualizados
@warning_ignore("unused_signal")
signal item_comprado(item)

# --- SINAIS DE EVENTOS DE PROGRESSO ---
# Emitidos quando o progresso atinge 25%, 50% ou 75%
@warning_ignore("unused_signal")
signal evento_gatilhado(porcentagem: int)
@warning_ignore("unused_signal")
signal evento_concluido(porcentagem: int)

@warning_ignore("unused_signal")
signal minigame_iniciado(limiar: float)
@warning_ignore("unused_signal")
signal minigame_finalizado(sucesso: bool, limiar: float)

# --- SINAIS DE CONTROLE DO JOGO ---
signal jogo_pausado
signal jogo_retomado

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

# Função utilitária para pausar o jogo de forma segura
func pausar_jogo() -> void:
	get_tree().paused = true
	jogo_pausado.emit()

# Função utilitária para retomar o jogo
func retomar_jogo() -> void:
	get_tree().paused = false
	jogo_retomado.emit()
