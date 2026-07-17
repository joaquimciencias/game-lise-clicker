extends MarginContainer

signal compra_finalizada_com_sucesso(mensagem_texto: String)

@export var item_loja_cena: PackedScene # Ajuste o caminho se necessário

# Listas de Resources para cada aba, configuráveis pelo Inspector da cena principal!
@export var itens_expansao: Array[ItemLojaResource] = []
@export var itens_conscientizacao: Array[ItemLojaResource] = []
@export var itens_formacao: Array[ItemLojaResource] = []

@export var painel_conscientizacao: Node

@onready var btn_expansao = $PainelAnimLoja/VBoxContainer/HBoxBotoes/Expansao
@onready var btn_conscientizacao = $PainelAnimLoja/VBoxContainer/HBoxBotoes/Conscientizacao
@onready var btn_formacao = $PainelAnimLoja/VBoxContainer/HBoxBotoes/Formacao

@onready var conteudo_expansao = $PainelAnimLoja/VBoxContainer/ScrollContainer/ConteudoExpansao
@onready var conteudo_conscientizacao = $PainelAnimLoja/VBoxContainer/ScrollContainer/ConteudoConscientizacao
@onready var conteudo_formacao = $PainelAnimLoja/VBoxContainer/ScrollContainer/ConteudoFormacao

func _ready():
	# Conectar sinais dos botões de abas
	btn_expansao.pressed.connect(_on_expansao_pressed)
	btn_conscientizacao.pressed.connect(_on_conscientizacao_pressed)
	btn_formacao.pressed.connect(_on_formacao_pressed)
	
	# Carrega e popula todas as abas dinamicamente ao iniciar o jogo
	_gerar_itens_na_aba(conteudo_expansao, itens_expansao)
	_gerar_itens_na_aba(conteudo_conscientizacao, itens_conscientizacao)
	_gerar_itens_na_aba(conteudo_formacao, itens_formacao)
	
	_atualizar_todos_os_itens()
	mostrar_aba("expansao") # Inicia na primeira aba

func _gerar_itens_na_aba(container_aba: Node, lista_resources: Array[ItemLojaResource]):
	for child in container_aba.get_children():
		child.queue_free()
		
	for item_resource in lista_resources:
		if not item_resource: continue
		
		var novo_item = item_loja_cena.instantiate()
		container_aba.add_child(novo_item)
		
		# --- NOVO: Duplica o resource para que as mudanças de custo ocorram apenas nesta partida ---
		var copia_idempotente = item_resource.duplicate(true)
		novo_item.dados_item = copia_idempotente
		
		novo_item.compra_solicitada.connect(_on_item_compra_solicitada)

func _on_expansao_pressed(): mostrar_aba("expansao")
func _on_conscientizacao_pressed(): mostrar_aba("conscientizacao")
func _on_formacao_pressed(): mostrar_aba("formacao")

func mostrar_aba(aba: String):
	conteudo_expansao.visible = (aba == "expansao")
	conteudo_conscientizacao.visible = (aba == "conscientizacao")
	conteudo_formacao.visible = (aba == "formacao")

func _on_item_compra_solicitada(item_clicado_data: ItemLojaResource):
	print("🛒 [Loja]: Tentando evoluir o item: ", item_clicado_data.nome_item)
	
	var pode_comprar = true
	var pontos_jogador = _obter_pontos_reais_jogador()

	for req in item_clicado_data.requisitos:
		if not req: continue
		if pontos_jogador.get(req.tipo, 0) < req.custo:
			pode_comprar = false
			break

	if pode_comprar:
		print("🎉 ITEM EVOLUÍDO COM SUCESSO: ", item_clicado_data.nome_item)

		# --- PROGRESSÃO DO CLICKER ---
		for req in item_clicado_data.requisitos:
			if not req: continue
			var novo_custo = ceil(req.custo * 1.5)
			if novo_custo == req.custo:
				novo_custo += 1
			req.custo = int(novo_custo)

		# --- MODIFICADO: Em vez de criar o popup aqui, avisa a MainGame ---
		var texto_notificacao = "Melhoria Adquirida:\n%s!" % item_clicado_data.nome_item
		compra_finalizada_com_sucesso.emit(texto_notificacao)

		# Força a loja a se atualizar na tela
		_atualizar_todos_os_itens()
		
	else:
		print("❌ Erro: Requisitos insuficientes para o próximo nível.")

func _atualizar_todos_os_itens():
	var pontos_jogador = _obter_pontos_reais_jogador()
	
	for aba in [conteudo_expansao, conteudo_conscientizacao, conteudo_formacao]:
		if not aba: continue
		for item in aba.get_children():
			if "dados_item" in item and item.dados_item:
				for req in item.dados_item.requisitos:
					if req:
						# CORRIGIDO: de 'req.actual' para 'req.atual'
						req.atual = pontos_jogador.get(req.tipo, 0)
				
				if item.has_method("_atualizar_linhas_requisitos"):
					item._atualizar_linhas_requisitos()

# Puxa os dados direto do seu PnlConscientizacao real via grupo
func _obter_pontos_reais_jogador() -> Dictionary:
	var painel = get_tree().get_first_node_in_group("painel_pontos")
	
	if painel and painel.has_method("obter_pontos_atuais"):
		return painel.obter_pontos_atuais()
		
	# Caso o painel não seja encontrado por segurança retorna tudo zero
	return { 
		RequisitoResource.TipoRequisito.FISICAS: 0, 
		RequisitoResource.TipoRequisito.PSICOLOGICAS: 0, 
		RequisitoResource.TipoRequisito.MORAIS: 0, 
		RequisitoResource.TipoRequisito.PATRIMONIAIS: 0 
	}
