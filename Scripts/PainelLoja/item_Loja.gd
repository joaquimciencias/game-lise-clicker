extends PanelContainer

var item_id: String = ""

@onready var lbl_nome = $Margin/VBox/HBoxHeader/LblNome
@onready var lbl_nivel = $Margin/VBox/HBoxHeader/LblNivel
@onready var lbl_desc = $Margin/VBox/LblDesc
@onready var lbl_efeito = $Margin/VBox/LblEfeito
@onready var progress_bar = $Margin/VBox/HBoxBottom/VBoxProgresso/ProgressBar
@onready var lbl_progresso_txt = $Margin/VBox/HBoxBottom/VBoxProgresso/LblProgressoTxt
@onready var btn_ativar = $Margin/VBox/HBoxBottom/BtnAtivar

signal item_atualizado

func configurar_card(id: String):
	item_id = id
	atualizar_ui()

func atualizar_ui():
	var dados = LojaData.banco_itens[item_id]
	var nivel_atual = LojaData.niveis_itens[item_id]
	
	lbl_nome.text = dados["nome"]
	lbl_desc.text = dados["desc"]
	lbl_nivel.text = "Nível " + str(nivel_atual) + "/3"
	
	if nivel_atual >= 3:
		lbl_efeito.text = "✨ Benefício Máximo: " + dados["nv3"]["efeito"]
		lbl_progresso_txt.text = "Concluído!"
		progress_bar.value = 100
		btn_ativar.disabled = true
		btn_ativar.text = "✓ ATIVO"
		return

	var proximo_nv = nivel_atual + 1
	var dados_nv = dados["nv" + str(proximo_nv)]
	
	lbl_efeito.text = "💡 O que muda: " + dados_nv["efeito"]
	
	# Verificação de requisitos
	var total_atual = LojaData.get_total_registros()
	var req_total_ok = total_atual >= dados_nv["req_total"]
	
	var req_especifico_ok = true
	var txt_esp = ""
	
	if dados_nv["req_tipo"] != "":
		var val_esp = LojaData.get(dados_nv["req_tipo"])
		req_especifico_ok = val_esp >= dados_nv["val_tipo"]
		txt_esp = " + " + str(dados_nv["val_tipo"]) + " " + dados_nv["req_tipo"].replace("reg_", "").capitalize()

	# Cálculo simples da porcentagem de progresso para a barra
	var pct = clamp((float(total_atual) / float(dados_nv["req_total"])) * 100.0, 0.0, 100.0)
	progress_bar.value = pct
	
	lbl_progresso_txt.text = "Meta: " + str(dados_nv["req_total"]) + " Acolhimentos" + txt_esp
	
	if req_total_ok and req_especifico_ok:
		btn_ativar.disabled = false
		btn_ativar.text = "🌟 APLICAR AÇÃO"
	else:
		btn_ativar.disabled = true
		btn_ativar.text = "🔒 EM EM ANDAMENTO"

func _on_btn_ativar_pressed():
	if LojaData.niveis_itens[item_id] < 3:
		LojaData.niveis_itens[item_id] += 1
		atualizar_ui()
		emit_signal("item_atualizado")
