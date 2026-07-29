# UpgradesData.gd
class_name UpgradesData

static func get_todos_os_upgrades() -> Dictionary:
	return {
		"expansao": [
			{
				"id": "bot_panico",
				"nome": "Botão de Pânico Urbano & Ilhas de Segurança",
				"icone": "🚨",
				"niveis": {
					1: {
						"req_totais": 1, "req_especifico": {},
						"passivo": {"fisica": 1},
						"txt_passivo": "+1 Física/s",
						"txt_gameplay": "Adiciona +1,5s no tempo limite de resposta das chamadas (11,5s).",
						"txt_visual": "Pequenos totens com luz lilás piscando aparecem no minimapa."
					},
					2: {
						"req_totais": 70, "req_especifico": {},
						"passivo": {"fisica": 3, "patrimonial": 2},
						"txt_passivo": "+3 Físicas/s e +2 Patrimoniais/s",
						"txt_gameplay": "Adiciona mais +1,5s no tempo das ligações ( total 13s ).",
						"txt_visual": "Postes e totens acendem luzes amarelas/lilases no minimapa."
					},
					3: {
						"req_totais": 200, "req_especifico": {"fisica": 50},
						"passivo": {"fisica": 8, "patrimonial": 6},
						"txt_passivo": "+8 Físicas/s e +6 Patrimoniais/s",
						"txt_gameplay": "Respostas expiradas não reduzem a Consciência da População.",
						"txt_visual": "Ruas do minimapa ganham faixas reflexivas lilases e brilho."
					}
				}
			},
			{
				"id": "casa_mulher",
				"nome": "Casa da Mulher Brasileira (Centro Integrado)",
				"icone": "🏛️",
				"niveis": {
					1: {
						"req_totais": 1, "req_especifico": {},
						"passivo": {"todos": 2},
						"txt_passivo": "+2 em Todos os 4 Tipos/s",
						"txt_gameplay": "Acelera em 25% a revelação dos detalhes visuais da vítima.",
						"txt_visual": "Edifício grande com a fachada da Casa da Mulher no minimapa."
					},
					2: {
						"req_totais": 150, "req_especifico": {},
						"passivo": {"todos": 5},
						"txt_passivo": "+5 em Todos os 4 Tipos/s",
						"txt_gameplay": "Consciência da População sobe passivamente +0,5% a cada 5s.",
						"txt_visual": "Silhueta no painel revela cores e feições mais rápido."
					},
					3: {
						"req_totais": 380, "req_especifico": {"moral": 60},
						"passivo": {"todos": 12},
						"txt_passivo": "+12 em Todos os 4 Tipos/s",
						"txt_gameplay": "A ilutração da mulher acolhida fica visível permanentemente.",
						"txt_visual": "Bandeira lilás hasteada e brilho de holofotes na Casa da Mulher."
					}
				}
			},
			{
				"id": "ronda_maria",
				"nome": "Ronda Maria da Penha (Patrulha Comunitária)",
				"icone": "🚔",
				"niveis": {
					1: {
						"req_totais": 1, "req_especifico": {},
						"passivo": {"fisica": 2, "psicologica": 2},
						"txt_passivo": "+2 Física/s e +2 Psicológica/s",
						"txt_gameplay": "Reduz em 50% a perda de multiplicadores em erros.",
						"txt_visual": "Viatura da Patrulha estacionada ao lado da central."
					},
					2: {
						"req_totais": 240, "req_especifico": {},
						"passivo": {"fisica": 6, "psicologica": 5},
						"txt_passivo": "+6 Físicas/s e +5 Psicológicas/s",
						"txt_gameplay": "Erros de resposta não reduzem mais a barra de Consciência.",
						"txt_visual": "Viatura ronda as ruas do minimapa com giroflex aceso."
					},
					3: {
						"req_totais": 480, "req_especifico": {"patrimonial": 60},
						"passivo": {"fisica": 15, "patrimonial": 10},
						"txt_passivo": "+15 Físicas/s e +10 Patrimoniais/s",
						"txt_gameplay": "25% de chance de acionar Ronda Protetiva (+2 atendimentos).",
						"txt_visual": "Viatura ganha rastro luminoso e selo 'Ronda Ativa'."
					}
				}
			},
			{
				"id": "centros_autonomia",
				"nome": "Centros de Autonomia Econômica & Acolhimento",
				"icone": "🏠",
				"niveis": {
					1: {
						"req_totais": 120, "req_especifico": {},
						"passivo": {"patrimonial": 3},
						"txt_passivo": "+3 Patrimonial/s",
						"txt_gameplay": "Classificação correta de Violência Patrimonial concede +1% extra.",
						"txt_visual": "Ícone de engrenagem/chave no painel Patrimonial."
					},
					2: {
						"req_totais": 280, "req_especifico": {},
						"passivo": {"patrimonial": 8, "moral": 4},
						"txt_passivo": "+8 Patrimoniais/s e +4 Morais/s",
						"txt_gameplay": "Cada bloco de 50 registros concede +2% de Consciência.",
						"txt_visual": "Quadro de registro Patrimonial ganha contorno dourado."
					},
					3: {
						"req_totais": 520, "req_especifico": {"patrimonial": 70},
						"passivo": {"patrimonial": 18, "moral": 12},
						"txt_passivo": "+18 Patrimoniais/s e +12 Morais/s",
						"txt_gameplay": "Multiplica por 2x a geração passiva Patrimonial e Moral.",
						"txt_visual": "Minimapa exibe galpões acesos com pessoas caminhando."
					}
				}
			}
		],
		"conscientizacao": [
			{
				"id": "campanha_tv",
				"nome": "Campanhas de TV & Rádio em Horário Nobre",
				"icone": "📺",
				"niveis": {
					1: {
						"req_totais": 25, "req_especifico": {},
						"passivo": {"psicologica": 1},
						"txt_passivo": "+1 Psicológica/s",
						"txt_gameplay": "+0,5% extra de Consciência a cada ligação correta.",
						"txt_visual": "Pequenas TVs no minimapa piscam com símbolo lilás."
					},
					2: {
						"req_totais": 85, "req_especifico": {},
						"passivo": {"psicologica": 3, "moral": 3},
						"txt_passivo": "+3 Psicológicas/s e +3 Morais/s",
						"txt_gameplay": "+1% extra de Consciência e ativa COMBO x2.",
						"txt_visual": "Indicador 'CAMPANHA NO AR' no topo da tela."
					},
					3: {
						"req_totais": 220, "req_especifico": {"psicologica": 50},
						"passivo": {"psicologica": 8, "moral": 8},
						"txt_passivo": "+8 Psicológicas/s e +8 Morais/s",
						"txt_gameplay": "Consciência sobe passivamente +1% a cada 10s.",
						"txt_visual": "Outdoors iluminados no minimapa com propagandas."
					}
				}
			},
			{
				"id": "redes_sociais",
				"nome": "Redes Sociais & Mobilização Digital",
				"icone": "📲",
				"niveis": {
					1: {
						"req_totais": 40, "req_especifico": {},
						"passivo": {"moral": 2},
						"txt_passivo": "+2 Moral/s",
						"txt_gameplay": "Acertos em < 3s dobram os pontos nos 3s seguintes.",
						"txt_visual": "Ícones flutuantes sobem no painel esquerdo."
					},
					2: {
						"req_totais": 130, "req_especifico": {},
						"passivo": {"moral": 5, "psicologica": 4},
						"txt_passivo": "+5 Morais/s e +4 Psicológicas/s",
						"txt_gameplay": "Errar não zera o combo (apenas cai 1 nível).",
						"txt_visual": "Quadro Moral ganha contorno degradê roxo/rosa."
					},
					3: {
						"req_totais": 320, "req_especifico": {"moral": 60},
						"passivo": {"moral": 12, "psicologica": 10},
						"txt_passivo": "+12 Morais/s e +10 Psicológicas/s",
						"txt_gameplay": "Multiplica por 2x a geração passiva Moral e Psicológica.",
						"txt_visual": "Notificações de likes sobem dos prédios no minimapa."
					}
				}
			},
			{
				"id": "cartilhas_escolas",
				"nome": "Cartilhas Educativas nas Escolas e Comércios",
				"icone": "📚",
				"niveis": {
					1: {
						"req_totais": 60, "req_especifico": {},
						"passivo": {"todos": 1},
						"txt_passivo": "+1 em Todos os 4 Tipos/s",
						"txt_gameplay": "Aumenta o rendimento dos geradores em +25%.",
						"txt_visual": "Ícones de cartilhas nos 4 botões de classificação."
					},
					2: {
						"req_totais": 180, "req_especifico": {},
						"passivo": {"todos": 4},
						"txt_passivo": "+4 em Todos os 4 Tipos/s",
						"txt_gameplay": "Rendimento +50% e reduz tempo de leitura.",
						"txt_visual": "Ícones de cartilhas ganham brilho dourado."
					},
					3: {
						"req_totais": 400, "req_especifico": {"patrimonial": 50},
						"passivo": {"todos": 10},
						"txt_passivo": "+10 em Todos os 4 Tipos/s",
						"txt_gameplay": "Habilidade 'Leitura Guiada' destaca a prova principal.",
						"txt_visual": "Parágrafo decisivo ganha caixa de destaque lilás."
					}
				}
			},
			{
				"id": "rodas_conversa",
				"nome": "Rodas de Conversa & Mídia Comunitária",
				"icone": "🗣️",
				"niveis": {
					1: {
						"req_totais": 100, "req_especifico": {},
						"passivo": {"patrimonial": 3, "moral": 2},
						"txt_passivo": "+3 Patrimonial/s e +2 Moral/s",
						"txt_gameplay": "Segunda chance de 2s para corrigir erros.",
						"txt_visual": "Ícone de duas mãos seguradas ao lado do timer."
					},
					2: {
						"req_totais": 260, "req_especifico": {},
						"passivo": {"patrimonial": 7, "moral": 6},
						"txt_passivo": "+7 Patrimoniais/s e +6 Morais/s",
						"txt_gameplay": "10 chamadas 100% precisas concedem +3% de Consciência.",
						"txt_visual": "Fundo com padrão suave de rede de apoio."
					},
					3: {
						"req_totais": 500, "req_especifico": {"psicologica": 70},
						"passivo": {"todos": 15},
						"txt_passivo": "+15 em Todos os 4 Tipos/s",
						"txt_gameplay": "Com apenas 90% atinge a Vitória total.",
						"txt_visual": "Minimapa muda para 'Cidade Conscientizada'."
					}
				}
			}
		],
		"formacao": [
			{
				"id": "escuta_humanizada",
				"nome": "Capacitação em Escuta Humanizada & Não-Violenta",
				"icone": "🎧",
				"niveis": {
					1: {
						"req_totais": 30, "req_especifico": {},
						"passivo": {"psicologica": 1, "moral": 1},
						"txt_passivo": "+1 Psicológica/s e +1 Moral/s",
						"txt_gameplay": "Temporizador ganha +1,5s extra de tolerância.",
						"txt_visual": "Certificado emoldurado na parede da central."
					},
					2: {
						"req_totais": 110, "req_especifico": {},
						"passivo": {"psicologica": 4, "moral": 3},
						"txt_passivo": "+4 Psicológicas/s e +3 Morais/s",
						"txt_gameplay": "+1,5s extra no temporizador (total 3s adicionais).",
						"txt_visual": "Atendente com postura mais calma na animação."
					},
					3: {
						"req_totais": 290, "req_especifico": {"psicologica": 50},
						"passivo": {"psicologica": 10, "moral": 8},
						"txt_passivo": "+10 Psicológicas/s e +8 Morais/s",
						"txt_gameplay": "Trava de Calma: Respostas nos 2s finais dão pontuação cheia.",
						"txt_visual": "Borda lilás no temporizador 'Escuta Qualificada'."
					}
				}
			},
			{
				"id": "suporte_psicologico",
				"nome": "Suporte Psicológico & Cuidado da Atendente",
				"icone": "☕",
				"niveis": {
					1: {
						"req_totais": 50, "req_especifico": {},
						"passivo": {"todos": 2},
						"txt_passivo": "+2 em Todos os 4 Tipos/s",
						"txt_gameplay": "Erros reduzem apenas 1 nível de combo (não zera).",
						"txt_visual": "Xícara de chá/café fumegante na mesa."
					},
					2: {
						"req_totais": 160, "req_especifico": {},
						"passivo": {"todos": 5},
						"txt_passivo": "+5 em Todos os 4 Tipos/s",
						"txt_gameplay": "Reduz em 50% a perda de Consciência ao errar.",
						"txt_visual": "Vaso de flores e iluminação aconchegante."
					},
					3: {
						"req_totais": 350, "req_especifico": {"moral": 60},
						"passivo": {"todos": 12},
						"txt_passivo": "+12 em Todos os 4 Tipos/s",
						"txt_gameplay": "Imunidade ao Estresse: Apaga 1 erro a cada 20 chamadas.",
						"txt_visual": "Headset profissional e selo 'Bem-Estar em Operação'."
					}
				}
			},
			{
				"id": "lei_maria_penha",
				"nome": "Especialização na Lei Maria da Penha",
				"icone": "⚖️",
				"niveis": {
					1: {
						"req_totais": 80, "req_especifico": {},
						"passivo": {"patrimonial": 2, "fisica": 2},
						"txt_passivo": "+2 Patrimonial/s e +2 Física/s",
						"txt_gameplay": "Destaca em negrito expressões jurídicas do relato.",
						"txt_visual": "Vade Mecum aberto surge na mesa."
					},
					2: {
						"req_totais": 200, "req_especifico": {},
						"passivo": {"patrimonial": 6, "fisica": 6},
						"txt_passivo": "+6 Patrimoniais/s e +6 Físicas/s",
						"txt_gameplay": "Palavras-chave com destaque em amarelo neon.",
						"txt_visual": "Livro com páginas marcadas em neon."
					},
					3: {
						"req_totais": 420, "req_especifico": {"patrimonial": 60},
						"passivo": {"todos": 14},
						"txt_passivo": "+14 em Todos os 4 Tipos/s",
						"txt_gameplay": "Sugestão Assistida: Botão correto pisca suavemente.",
						"txt_visual": "Segundo monitor com jurisprudência em tempo real."
					}
				}
			},
			{
				"id": "gestao_crise",
				"nome": "Gestão de Crise & Atendimento Sob Pressão",
				"icone": "⚡",
				"niveis": {
					1: {
						"req_totais": 140, "req_especifico": {},
						"passivo": {"fisica": 3, "patrimonial": 3},
						"txt_passivo": "+3 Física/s e +3 Patrimonial/s",
						"txt_gameplay": "Acertos em < 3s dão +2% de Consciência instantânea.",
						"txt_visual": "Timer digital no painel de chamadas."
					},
					2: {
						"req_totais": 310, "req_especifico": {},
						"passivo": {"fisica": 8, "patrimonial": 8},
						"txt_passivo": "+8 Físicas/s e +8 Patrimoniais/s",
						"txt_gameplay": "Combo de Agilidade: 3 acertos rápidos dobram pontos.",
						"txt_visual": "Tag 'AGILIDADE DE ATENDIMENTO!' acionada."
					},
					3: {
						"req_totais": 550, "req_especifico": {"fisica": 80},
						"passivo": {"todos_multiplicador": 3.0},
						"txt_passivo": "Triplica (3x) toda a geração automática de registros",
						"txt_gameplay": "30% de chance de encerrar o dia atual imediatamente.",
						"txt_visual": "Status 'Central de Excelência' com luzes LED."
					}
				}
			}
		]
	}
