extends Node

# --- SALDO DE REGISTROS (NUNCA SUBTRAI) ---
var reg_fisicas: int = 0
var reg_psicologicas: int = 0
var reg_morais: int = 0
var reg_patrimoniais: int = 0

# --- ESTADO DE NÍVEL DOS ITENS (0 = Bloqueado, 1 = Nv1 Ativo, 2 = Nv2 Ativo, 3 = Nv3 Ativo) ---
var niveis_itens: Dictionary = {
	# ABA 1: EXPANSÃO
	"botao_panico": 0,
	"casa_mulher": 0,
	"ronda_maria": 0,
	"centros_autonomia": 0,
	# ABA 2: CONSCIENTIZAÇÃO
	"campanhas_tv": 0,
	"mobilizacao_digital": 0,
	"cartilhas_educativas": 0,
	"rodas_conversa": 0,
	# ABA 3: FORMAÇÃO
	"escuta_humanizada": 0,
	"suporte_psicologico": 0,
	"especializacao_lei": 0,
	"gestao_crise": 0
}

# --- BANCO DE DADOS DOS ITENS E REQUISITOS ---
var banco_itens: Dictionary = {
	"botao_panico": {
		"nome": "Botão de Pânico Urbano",
		"aba": "Expansão",
		"desc": "Totens de emergência com luzes lilases nas ruas.",
		"nv1": {"req_total": 20, "req_tipo": "", "val_tipo": 0, "efeito": "+1,5s no temporizador"},
		"nv2": {"req_total": 70, "req_tipo": "", "val_tipo": 0, "efeito": "+3,0s no temporizador"},
		"nv3": {"req_total": 200, "req_tipo": "reg_fisicas", "val_tipo": 50, "efeito": "Erros por tempo não reduzem Consciência"}
	},
	"casa_mulher": {
		"nome": "Casa da Mulher Brasileira",
		"aba": "Expansão",
		"desc": "Centro integrado de acolhimento e proteção.",
		"nv1": {"req_total": 50, "req_tipo": "", "val_tipo": 0, "efeito": "Revela imagem da vítima 25% mais rápido"},
		"nv2": {"req_total": 150, "req_tipo": "", "val_tipo": 0, "efeito": "+0,5% Consciência a cada 5s (Passivo)"},
		"nv3": {"req_total": 380, "req_tipo": "reg_morais", "val_tipo": 60, "efeito": "Vítima acolhida permanentemente na tela"}
	},
	"campanhas_tv": {
		"nome": "Campanhas de TV & Rádio",
		"aba": "Conscientização",
		"desc": "Anúncios educativos em horário nobre.",
		"nv1": {"req_total": 25, "req_tipo": "", "val_tipo": 0, "efeito": "+0,5% extra de Consciência por acerto"},
		"nv2": {"req_total": 85, "req_tipo": "", "val_tipo": 0, "efeito": "Ativa Multiplicador COMBO x2"},
		"nv3": {"req_total": 220, "req_tipo": "reg_psicologicas", "val_tipo": 50, "efeito": "+1% Consciência a cada 10s"}
	},
	"escuta_humanizada": {
		"nome": "Escuta Humanizada",
		"aba": "Formação",
		"desc": "Capacitação em atendimento empático da atendente.",
		"nv1": {"req_total": 30, "req_tipo": "", "val_tipo": 0, "efeito": "+1,5s no temporizador da ligação"},
		"nv2": {"req_total": 110, "req_tipo": "", "val_tipo": 0, "efeito": "+3,0s no temporizador total"},
		"nv3": {"req_total": 290, "req_tipo": "reg_psicologicas", "val_tipo": 50, "efeito": "Trava de Calma no final do timer"}
	}
}

func get_total_registros() -> int:
	return reg_fisicas + reg_psicologicas + reg_morais + reg_patrimoniais

# Método auxiliar para simular acolhimento nos testes
func adicionar_registro_teste(tipo: String, qtd: int = 10):
	if tipo == "fisica": reg_fisicas += qtd
	elif tipo == "psicologica": reg_psicologicas += qtd
	elif tipo == "moral": reg_morais += qtd
	elif tipo == "patrimonial": reg_patrimoniais += qtd
