@tool
extends HBoxContainer

@onready var imagem = $Imagem
@onready var lbl_nome = $Nome
@onready var lbl_num = $Num

var dados_requisito: RequisitoResource:
	set(value):
		dados_requisito = value
		if is_node_ready(): 
			_atualizar_visual()

func _ready():
	_atualizar_visual()

func _atualizar_visual():
	if not dados_requisito or not is_node_ready():
		return
		
	var nome_tipo = RequisitoResource.TipoRequisito.keys()[dados_requisito.tipo].capitalize()
	lbl_nome.text = nome_tipo + ":"
	
	imagem.texture = dados_requisito.icone
	
	# CORRIGIDO: de '.actual' para '.atual' nas duas linhas abaixo
	var atual_formatado = formatar_numero(dados_requisito.atual)
	var custo_formatado = formatar_numero(dados_requisito.custo)
	
	lbl_num.text = "%s / %s" % [atual_formatado, custo_formatado]
	lbl_num.modulate = Color.GREEN if dados_requisito.atual >= dados_requisito.custo else Color.RED

# NOVA FUNÇÃO: Transforma números gigantes em formatos compactos (ex: 1.5K, 2.3M)
func formatar_numero(valor: float) -> String:
	if valor >= 1_000_000_000:
		return "%.1fB" % (valor / 1_000_000_000.0)
	elif valor >= 1_000_000:
		return "%.1fM" % (valor / 1_000_000.0)
	elif valor >= 1_000:
		return "%.1fK" % (valor / 1_000.0)
	
	# Se for menor que 1000, mostra o número inteiro normal
	return str(int(valor))
