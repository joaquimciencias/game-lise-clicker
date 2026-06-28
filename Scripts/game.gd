extends CanvasLayer

@onready var pnl_atendimento: Control = $Painel_Atendimento
@onready var pnl_ligacoes_atendidas: Control = $Painel_Ligacoes_Atendidas
@onready var pnl_conscientizacao: Control = $Painel_Tipos_Conscientizados

func _ready() -> void:
	# Conectamos o sinal da cena de atendimento à nossa função gerente
	pnl_atendimento.atendimento_concluido.connect(_on_atendimento_concluido)

# Como o sinal agora envia um dado (o tipo), a função que recebe precisa de um parâmetro (tipo_violencia)
func _on_atendimento_concluido(tipo_violencia: int) -> void:
	# 1. Manda atualizar o placar geral (da sua dúvida anterior)
	pnl_ligacoes_atendidas.adicionar_atendimento()
	
	# 2. Manda atualizar o placar específico, repassando a informação de qual tipo foi
	pnl_conscientizacao.registrar_novo_caso(tipo_violencia)
