extends MarginContainer

signal pontos_atualizados(total_pontos: int)

# Pegando a referência dos 4 labels de texto "Num" baseados na hierarquia da sua imagem
@onready var lbl_fisica = $VBoxContainer/VBoxContainer/Fisicas/VBoxContainer/Num
@onready var lbl_psicologica = $VBoxContainer/VBoxContainer/Psicologicas/VBoxContainer/Num
@onready var lbl_moral = $VBoxContainer/VBoxContainer/Morais/VBoxContainer/Num
@onready var lbl_patrimonial = $VBoxContainer/VBoxContainer/Patrimoniais/VBoxContainer2/Num

# Contadores individuais
var cont_fisica: int = 0
var cont_psicologica: int = 0
var cont_moral: int = 0
var cont_patrimonial: int = 0

func _ready() -> void:
# Adiciona este painel ao grupo para a loja encontrá-lo facilmente
	add_to_group("painel_pontos")
	
	# Zera os textos no início do jogo (seu código original)
	lbl_fisica.text = "0"
	lbl_psicologica.text = "0"
	lbl_moral.text = "0"
	lbl_patrimonial.text = "0"
	
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

# Esta função será chamada pela cena Game. 
# O "match" funciona como vários "ifs", checando qual número chegou.
func registrar_novo_caso(tipo_recebido: int) -> void:
	match tipo_recebido:
		0:
			cont_fisica += 1
			lbl_fisica.text = str(cont_fisica)
		1:
			cont_psicologica += 1
			lbl_psicologica.text = str(cont_psicologica)
		2:
			cont_moral += 1
			lbl_moral.text = str(cont_moral)
		3:
			cont_patrimonial += 1
			lbl_patrimonial.text = str(cont_patrimonial)

	# --- NOVO: Calcula o total e avisa a Main que os pontos mudaram ---
	var total_ligacoes_atendidas = cont_fisica + cont_psicologica + cont_moral + cont_patrimonial
	pontos_atualizados.emit(total_ligacoes_atendidas)

	# Seu código original que notifica a loja continua aqui embaixo:
	_notificar_mudanca_loja()

func _notificar_mudanca_loja():
	var main_loja = get_tree().get_first_node_in_group("loja_principal")
	if main_loja.has_method("_atualizar_todos_os_itens"):
		main_loja._atualizar_todos_os_itens()

# Retorna os pontos reais acumulados no jogo mapeados para o Enum dos requisitos
func obter_pontos_atuais() -> Dictionary:
	return {
		RequisitoResource.TipoRequisito.FISICAS: cont_fisica,
		RequisitoResource.TipoRequisito.PSICOLOGICAS: cont_psicologica,
		RequisitoResource.TipoRequisito.MORAIS: cont_moral,
		RequisitoResource.TipoRequisito.PATRIMONIAIS: cont_patrimonial
	}
