extends PanelContainer

signal item_comprado(id_item: String)

@onready var lbl_icone: Label = $Margin/HBoxMain/IconeBox/LblIcone
@onready var lbl_nome: Label = $Margin/HBoxMain/VBoxDetalhes/HBoxTitulo/LblNome
@onready var lbl_nivel: Label = $Margin/HBoxMain/VBoxDetalhes/HBoxTitulo/LblNivel
@onready var lbl_requisito: Label = $Margin/HBoxMain/VBoxDetalhes/LblRequisito
@onready var lbl_passivo: Label = $Margin/HBoxMain/VBoxDetalhes/BoxEfeitos/Margin/VBox/LblPassivo
@onready var lbl_gameplay: Label = $Margin/HBoxMain/VBoxDetalhes/BoxEfeitos/Margin/VBox/LblGameplay
@onready var lbl_visual: Label = $Margin/HBoxMain/VBoxDetalhes/BoxVisual/Margin/LblVisual
@onready var btn_comprar: Button = $Margin/HBoxMain/BtnComprar

var id_item: String = ""

func _ready() -> void:
	if btn_comprar and not btn_comprar.pressed.is_connected(_on_btn_comprar_pressed):
		btn_comprar.pressed.connect(_on_btn_comprar_pressed)

func configurar_card(dados_item: Dictionary, nivel_atual: int, registros_totais: int, registros_por_tipo: Dictionary) -> void:
	id_item = dados_item.get("id", "")
	if lbl_icone: lbl_icone.text = dados_item.get("icone", "❓")
	if lbl_nome: lbl_nome.text = dados_item.get("nome", "Item Desconhecido")
	
	var proximo_nivel = nivel_atual + 1
	var niveis: Dictionary = dados_item.get("niveis", {})
	
	# Se já estiver no nível máximo (Nível 3)
	if proximo_nivel > 3:
		if lbl_nivel: lbl_nivel.text = "[ Nível 3 / 3 - MÁXIMO ]"
		var dados_max = niveis.get(3, {})
		if lbl_requisito: lbl_requisito.text = "✅ Totalmente Implementado"
		if lbl_passivo: lbl_passivo.text = "⚡ Clicker Passivo: " + dados_max.get("txt_passivo", "")
		if lbl_gameplay: lbl_gameplay.text = "🎮 Efeito: " + dados_max.get("txt_gameplay", "")
		if lbl_visual: lbl_visual.text = "👁️ Efeito Urbano: " + dados_max.get("txt_visual", "")
		if btn_comprar:
			btn_comprar.disabled = true
			btn_comprar.text = "Nível\nMáximo"
		return

	# Dados do próximo nível a ser comprado
	var dados_prox = niveis.get(proximo_nivel, {})
	if lbl_nivel: lbl_nivel.text = "[ Nível %d / 3 ]" % [nivel_atual]
	
	# Exibição dos efeitos do próximo nível
	if lbl_passivo: lbl_passivo.text = "⚡ Próximo Nível: " + dados_prox.get("txt_passivo", "")
	if lbl_gameplay: lbl_gameplay.text = "🎮 Efeito: " + dados_prox.get("txt_gameplay", "")
	if lbl_visual: lbl_visual.text = "👁️ Efeito Urbano: " + dados_prox.get("txt_visual", "")
	
	# Validação de Requisitos
	var req_totais = dados_prox.get("req_totais", 0)
	var req_esp = dados_prox.get("req_especifico", {})
	
	var atende_req_totais = registros_totais >= req_totais
	var atende_req_esp = true
	var txt_req_esp = ""
	
	for tipo in req_esp.keys():
		var qtd_necessaria = req_esp[tipo]
		var qtd_atual = registros_por_tipo.get(tipo, 0)
		if qtd_atual < qtd_necessaria:
			atende_req_esp = false
		txt_req_esp += " + %d Registros %s" % [qtd_necessaria, tipo.capitalize()]

	# Atualiza o texto visual de requisitos
	if lbl_requisito:
		lbl_requisito.text = "🔒 Requisito: %d Registros Totais%s" % [req_totais, txt_req_esp]
	
	# Liberação / Bloqueio do botão de compra
	if btn_comprar:
		if atende_req_totais and atende_req_esp:
			btn_comprar.disabled = false
			btn_comprar.text = "Implementar\nNível %d" % proximo_nivel
		else:
			btn_comprar.disabled = true
			btn_comprar.text = "Bloqueado"

func _on_btn_comprar_pressed() -> void:
	item_comprado.emit(id_item)
