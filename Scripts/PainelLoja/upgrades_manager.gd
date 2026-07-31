extends Node

signal nivel_upgrade_alterado(id_item: String, novo_nivel: int)
signal ponto_passivo_gerado(tipo: String, quantidade: int)
signal atributos_atualizados
signal limite_compras_mudou(compras_restantes: int, limite_maximo: int)

@export var meta_consciencia_vitoria: int = 100
var tempo_tolerancia_extra: float = 0.0

# Dicionário dinâmico de níveis { "bot_panico": 0, "casa_mulher": 0, ... }
var niveis_upgrades: Dictionary = {}

# --- CONTROLE DE COMPRAS POR RODADA ---
var compras_feitas_na_rodada: int = 0
var limite_compras_rodada: int = 1

var timer_passivo: Timer
# Controla se o tutorial já foi visto nesta sessão
var tutorial_concluido: bool = false

func _ready() -> void:
	_inicializar_niveis()
	_inicializar_timer()
	_recalcular_efeitos()

func _inicializar_niveis() -> void:
	var categorias = UpgradesData.get_todos_os_upgrades()
	for lista_itens in categorias.values():
		for item in lista_itens:
			var id_item: String = item.get("id", "")
			if not id_item.is_empty():
				niveis_upgrades[id_item] = 0

func _inicializar_timer() -> void:
	timer_passivo = Timer.new()
	timer_passivo.one_shot = false
	timer_passivo.wait_time = 1.0
	timer_passivo.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(timer_passivo)
	timer_passivo.timeout.connect(_on_timer_passivo_timeout)
	timer_passivo.start()

# --- REGRAS DE CONSCIENTIZAÇÃO E COMPRAS ---

# Busca a porcentagem real exibida na barra de conscientização
func obter_porcentagem_consciencia() -> float:
	var nos_barra = get_tree().get_nodes_in_group("barra_conscientizacao")
	if nos_barra.size() > 0:
		var barra = nos_barra[0]
		if barra.has_method("obter_porcentagem_atual"):
			return barra.obter_porcentagem_atual()

	return 0.0

# Reseta o limite no início de cada nova rodada/dia
func iniciar_nova_rodada() -> void:
	var pct: float = obter_porcentagem_consciencia()
	compras_feitas_na_rodada = 0
	
	if pct >= 50.0:
		limite_compras_rodada = 2
	else:
		limite_compras_rodada = 1
		_evoluir_itens_automaticamente_por_rodada()
		
	limite_compras_mudou.emit(obter_compras_restantes(), limite_compras_rodada)

func pode_comprar() -> bool:
	return compras_feitas_na_rodada < limite_compras_rodada

func obter_compras_restantes() -> int:
	return max(0, limite_compras_rodada - compras_feitas_na_rodada)

# Quando a consciência está < 50%, itens comprados evoluem +1 nível por rodada até o nível máx (3)
func _evoluir_itens_automaticamente_por_rodada() -> void:
	for id_item in niveis_upgrades.keys():
		var lvl_atual: int = niveis_upgrades[id_item]
		# Se já foi comprado (nível > 0) e ainda não atingiu o nível máximo (3)
		if lvl_atual > 0 and lvl_atual < 3:
			niveis_upgrades[id_item] = lvl_atual + 1
			nivel_upgrade_alterado.emit(id_item, lvl_atual + 1)
	
	_recalcular_efeitos()
	atributos_atualizados.emit()

func registrar_compra(id_item: String, novo_nivel: int) -> void:
	if not pode_comprar():
		push_warning("Tentativa de compra bloqueada: limite da rodada atingido!")
		return

	compras_feitas_na_rodada += 1
	niveis_upgrades[id_item] = novo_nivel
	_recalcular_efeitos()
	atributos_atualizados.emit()
	nivel_upgrade_alterado.emit(id_item, novo_nivel)
	limite_compras_mudou.emit(obter_compras_restantes(), limite_compras_rodada)

# --- SISTEMA PASSIVO SEGUNDO A SEGUNDO ---

func _on_timer_passivo_timeout() -> void:
	var categorias = UpgradesData.get_todos_os_upgrades()
	var multiplicador_geral: float = 1.0

	for lista_itens in categorias.values():
		for item in lista_itens:
			var id = item.get("id", "")
			var lvl = niveis_upgrades.get(id, 0)
			if lvl > 0 and item.get("niveis", {}).has(lvl):
				var passivo = item["niveis"][lvl].get("passivo", {})
				if passivo.has("todos_multiplicador"):
					multiplicador_geral *= passivo["todos_multiplicador"]

	for lista_itens in categorias.values():
		for item in lista_itens:
			var id = item.get("id", "")
			var lvl = niveis_upgrades.get(id, 0)
			if lvl > 0 and item.get("niveis", {}).has(lvl):
				var passivo = item["niveis"][lvl].get("passivo", {})
				_aplicar_passivo(passivo, multiplicador_geral)

func _aplicar_passivo(passivo: Dictionary, multiplicador: float) -> void:
	var tipos_validos = ["fisica", "psicologica", "moral", "patrimonial"]
	
	if passivo.has("todos"):
		var qtd = int(passivo["todos"] * multiplicador)
		for tipo in tipos_validos:
			if qtd > 0 and typeof(EventBus) != TYPE_NIL and EventBus.has_method("adicionar_registro"):
				EventBus.adicionar_registro(tipo, qtd)
				ponto_passivo_gerado.emit(tipo, qtd)
	else:
		for tipo in tipos_validos:
			if passivo.has(tipo):
				var qtd = int(passivo[tipo] * multiplicador)
				if qtd > 0 and typeof(EventBus) != TYPE_NIL and EventBus.has_method("adicionar_registro"):
					EventBus.adicionar_registro(tipo, qtd)
					ponto_passivo_gerado.emit(tipo, qtd)

func _recalcular_efeitos() -> void:
	var lvl_panico = niveis_upgrades.get("bot_panico", 0)
	var lvl_escuta = niveis_upgrades.get("escuta_humanizada", 0)
	
	var extra_panico = lvl_panico * 1.5
	var extra_escuta = lvl_escuta * 1.5
	
	tempo_tolerancia_extra = extra_panico + extra_escuta


# --- ZERA TODAS AS COMPRAS E CONFIGURAÇÕES PARA UM NOVO JOGO ---
func resetar_upgrades() -> void:
	# 1. Zera os registros do EventBus para as Ligações Totais zerarem no painel
	if typeof(EventBus) != TYPE_NIL and "registros_por_tipo" in EventBus:
		EventBus.registros_por_tipo = {
			"fisica": 0,
			"psicologica": 0,
			"moral": 0,
			"patrimonial": 0
		}
		if EventBus.has_signal("pontos_atualizados"):
			EventBus.pontos_atualizados.emit()

	# 2. Zera o nível de todos os itens cadastrados na loja
	for id_item in niveis_upgrades.keys():
		niveis_upgrades[id_item] = 0
		nivel_upgrade_alterado.emit(id_item, 0)

	# 3. Reseta as variáveis de controle da rodada
	compras_feitas_na_rodada = 0
	limite_compras_rodada = 1
	tempo_tolerancia_extra = 0.0

	# 4. Notifica a interface e recalcula os efeitos zerados
	_recalcular_efeitos()
	atributos_atualizados.emit()
	limite_compras_mudou.emit(obter_compras_restantes(), limite_compras_rodada)

	# --- ADICIONE ESTA LINHA AQUI ---
	# Reinicia o timer passivo para a nova partida
	if timer_passivo:
		timer_passivo.start()
