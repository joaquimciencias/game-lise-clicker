@tool
extends Control

# Sinal para avisar a loja principal quando o botão de compra for clicado
signal compra_solicitada(item_data: ItemLojaResource)

const LINHA_REQUISITO_SCENE = preload("res://Scenes/Paineis/Loja/Linha_Item_Requisito.tscn")

@onready var container_alvo = $VBoxContainer/HBoxContainer/VBoxContainer
@onready var lbl_nome_item = $VBoxContainer/Label # Seu nó de título do item

# Em vez de dicionário, exportamos o Resource do Item!
@export var dados_item: ItemLojaResource:
	set(value):
		dados_item = value
		if is_inside_tree():
			_atualizar_linhas_requisitos()

func _ready():
	_atualizar_linhas_requisitos()

func _atualizar_linhas_requisitos():
	if not container_alvo:
		container_alvo = $VBoxContainer/HBoxContainer/VBoxContainer
	if not lbl_nome_item:
		lbl_nome_item = $VBoxContainer/Label

	if not dados_item:
		return

	lbl_nome_item.text = dados_item.nome_item

	# --- NOVA LÓGICA DE VALIDAÇÃO DA COMPRA ---
	var tudo_cumprido: bool = true

	# 1. Se as linhas já existem no jogo, atualiza os valores e checa os requisitos
	var linhas_existentes = []
	for child in container_alvo.get_children():
		if child.is_in_group("linha_dinamica"):
			linhas_existentes.append(child)
			
	if linhas_existentes.size() == dados_item.requisitos.size() and not Engine.is_editor_hint():
		for i in range(dados_item.requisitos.size()):
			var req = dados_item.requisitos[i]
			if req:
				linhas_existentes[i]._atualizar_visual()
				# Se o atual for menor que o custo, o jogador não pode comprar!
				if req.atual < req.custo:
					tudo_cumprido = false
		
		_organizar_e_bloquear_botao(tudo_cumprido)
		return

	# 2. Se estiver no Editor (ou criando do zero), faz a criação normal
	for child in container_alvo.get_children():
		if child.is_in_group("linha_dinamica") or child.name.begins_with("LinhaRequisito"):
			container_alvo.remove_child(child)
			child.queue_free()
	
	for i in range(dados_item.requisitos.size()):
		var req = dados_item.requisitos[i]
		if not req: continue
		
		var nova_linha = LINHA_REQUISITO_SCENE.instantiate()
		nova_linha.name = "LinhaRequisito_%d" % i
		nova_linha.add_to_group("linha_dinamica")
		container_alvo.add_child(nova_linha)

		if Engine.is_editor_hint():
			nova_linha.owner = get_tree().edited_scene_root

		nova_linha.dados_requisito = req
		
		# Checagem inicial para o editor ou nascimento do nó
		if req.atual < req.custo:
			tudo_cumprido = false

	_organizar_e_bloquear_botao(tudo_cumprido)


# Modificamos sua função antiga para também aplicar o estado do botão
func _organizar_e_bloquear_botao(disponivel: bool):
	if has_node("VBoxContainer/HBoxContainer/VBoxContainer/Button"):
		var botao = $VBoxContainer/HBoxContainer/VBoxContainer/Button
		container_alvo.move_child(botao, -1)
		
		# No editor, deixamos o botão sempre ativo para você testar o visual.
		# No jogo rodando, ele obedece se os requisitos foram cumpridos!
		if Engine.is_editor_hint():
			botao.disabled = false
		else:
			# Se 'disponivel' for true, disabled vira false (botão ativo).
			# Se 'disponivel' for false, disabled vira true (botão bloqueado).
			botao.disabled = not disponivel

# Conecte o sinal 'pressed' do seu Button a esta função no Inspector
func _on_button_pressed() -> void:
	if dados_item:
		print("🔘 [ItemLoja]: Botão clicado! Emitindo sinal de compra...")
		compra_solicitada.emit(dados_item)
