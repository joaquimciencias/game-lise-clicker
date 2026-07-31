extends MarginContainer

signal pontos_atualizados(total_pontos: int)

# Referências dos 4 labels de texto "Num"
@onready var lbl_fisica = $VBoxContainer/VBoxContainer/Fisicas/HBoxContainer/Num
@onready var lbl_psicologica = $VBoxContainer/VBoxContainer/Psicologicas/HBoxContainer/Num
@onready var lbl_moral = $VBoxContainer/VBoxContainer/Morais/HBoxContainer/Num
@onready var lbl_patrimonial = $VBoxContainer/VBoxContainer/Patrimoniais/HBoxContainer/Num

# Contadores individuais
var cont_fisica: int = 0
var cont_psicologica: int = 0
var cont_moral: int = 0
var cont_patrimonial: int = 0

func _ready() -> void:
	add_to_group("painel_pontos")
	
	# Zera os textos no início do jogo
	lbl_fisica.text = "0"
	lbl_psicologica.text = "0"
	lbl_moral.text = "0"
	lbl_patrimonial.text = "0"
	
	# Ouve o EventBus para se atualizar sozinho se o UpgradesManager gerar pontos passivos
	if typeof(EventBus) != TYPE_NIL and EventBus.has_signal("pontos_atualizados"):
		EventBus.pontos_atualizados.connect(_on_event_bus_pontos_atualizados)

func atualizar_contador(tipo_violencia: String) -> void:
	match tipo_violencia:
		"Física":
			registrar_novo_caso(0)
		"Psicológica":
			registrar_novo_caso(1)
		"Moral":
			registrar_novo_caso(2)
		"Patrimonial":
			registrar_novo_caso(3)

func registrar_novo_caso(tipo_recebido: int) -> void:
	match tipo_recebido:
		0:
			cont_fisica += 1
			animar_label_numero(lbl_fisica, cont_fisica)
		1:
			cont_psicologica += 1
			animar_label_numero(lbl_psicologica, cont_psicologica)
		2:
			cont_moral += 1
			animar_label_numero(lbl_moral, cont_moral)
		3:
			cont_patrimonial += 1
			animar_label_numero(lbl_patrimonial, cont_patrimonial)

	# 1. Mantém o sinal local original
	var total_ligacoes_atendidas = cont_fisica + cont_psicologica + cont_moral + cont_patrimonial
	pontos_atualizados.emit(total_ligacoes_atendidas)

	# 2. Avisa o EventBus global que os pontos mudaram
	if typeof(EventBus) != TYPE_NIL and EventBus.has_signal("pontos_atualizados"):
		# Evita loop infinito desconectando temporariamente durante o emit local
		if EventBus.pontos_atualizados.is_connected(_on_event_bus_pontos_atualizados):
			EventBus.pontos_atualizados.disconnect(_on_event_bus_pontos_atualizados)
			EventBus.pontos_atualizados.emit()
			EventBus.pontos_atualizados.connect(_on_event_bus_pontos_atualizados)

# Atualiza os contadores caso os pontos venham do EventBus (ex: passivos da loja)
func _on_event_bus_pontos_atualizados() -> void:
	if typeof(EventBus) != TYPE_NIL and "registros_por_tipo" in EventBus:
		var dados = EventBus.registros_por_tipo
		
		cont_fisica = int(dados.get("fisica", cont_fisica))
		cont_psicologica = int(dados.get("psicologica", cont_psicologica))
		cont_moral = int(dados.get("moral", cont_moral))
		cont_patrimonial = int(dados.get("patrimonial", cont_patrimonial))
		
		animar_label_numero(lbl_fisica, cont_fisica)
		animar_label_numero(lbl_psicologica, cont_psicologica)
		animar_label_numero(lbl_moral, cont_moral)
		animar_label_numero(lbl_patrimonial, cont_patrimonial)

# Retorna os pontos reais acumulados no jogo mapeados para o Enum dos requisitos
func obter_pontos_atuais() -> Dictionary:
	return {
		RequisitoResource.TipoRequisito.FISICAS: cont_fisica,
		RequisitoResource.TipoRequisito.PSICOLOGICAS: cont_psicologica,
		RequisitoResource.TipoRequisito.MORAIS: cont_moral,
		RequisitoResource.TipoRequisito.PATRIMONIAIS: cont_patrimonial
	}

# Retorna pontos formatados por chave string (usado pela loja)
func obter_pontos_por_chave_string() -> Dictionary:
	return {
		"fisica": cont_fisica,
		"psicologica": cont_psicologica,
		"moral": cont_moral,
		"patrimonial": cont_patrimonial
	}

# --- FUNÇÃO RESPONSÁVEL POR ANIMAR OS NÚMEROS DE FORMA FLUIDA E CONTÍNUA ---
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

	# Checa com 'has_meta' antes de pegar o valor para não dar erro de 'meta' inexistente no console
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
