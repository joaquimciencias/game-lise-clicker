extends CanvasLayer

signal tutorial_concluido


var step: int = 0

@onready var dimmer: ColorRect = $Overlay/Dimmer
@onready var dialogue_panel: PanelContainer = $Overlay/DialoguePanel
@onready var foto_mentora: TextureRect = $Overlay/DialoguePanel/MarginContainer/HBoxMain/FotoMentora
@onready var texto_bia: Label = $Overlay/DialoguePanel/MarginContainer/HBoxMain/VBoxContent/TextoBia
@onready var botao_avancar: Button = $Overlay/DialoguePanel/MarginContainer/HBoxMain/VBoxContent/HBoxButtons/BotaoAvancar
@onready var highlight_box: ReferenceRect = $Overlay/HighlightBox

var shader_material: ShaderMaterial

func _ready() -> void:
# 1. Se o tutorial já foi concluído anteriormente, destrói o nó imediatamente sem exibir nada
	if UpgradesManager and UpgradesManager.tutorial_concluido:
		queue_free()
		return

	preparar_shader_dimmer()
	
	if botao_avancar:
		botao_avancar.pressed.connect(_on_botao_avancar_pressed)
		
	atualizar_tutorial()

func preparar_shader_dimmer() -> void:
	var shader = Shader.new()
	shader.code = """
	shader_type canvas_item;

	uniform vec4 rect_target;
	uniform vec4 overlay_color : source_color = vec4(0.0, 0.0, 0.0, 0.7);

	void fragment() {
		vec2 pixel_pos = SCREEN_UV / SCREEN_PIXEL_SIZE;
		bool inside_x = pixel_pos.x >= rect_target.x && pixel_pos.x <= (rect_target.x + rect_target.z);
		bool inside_y = pixel_pos.y >= rect_target.y && pixel_pos.y <= (rect_target.y + rect_target.w);
		
		if (inside_x && inside_y && rect_target.z > 0.0 && rect_target.w > 0.0) {
			COLOR = vec4(0.0, 0.0, 0.0, 0.0);
		} else {
			COLOR = overlay_color;
		}
	}
	"""
	shader_material = ShaderMaterial.new()
	shader_material.shader = shader
	dimmer.material = shader_material

#func _input(event: InputEvent) -> void:
	#if event.is_action_just_pressed("ui_accept"):
		#avancar_tutorial()

func _on_botao_avancar_pressed() -> void:
	avancar_tutorial()

func avancar_tutorial() -> void:
	step += 1
	atualizar_tutorial()

func mudar_posicao_dialogo(no_topo: bool) -> void:
	if no_topo:
		dialogue_panel.anchor_top = 0.0
		dialogue_panel.anchor_bottom = 0.0
		dialogue_panel.offset_top = 20.0
		dialogue_panel.offset_bottom = 210.0
	else:
		dialogue_panel.anchor_top = 1.0
		dialogue_panel.anchor_bottom = 1.0
		dialogue_panel.offset_top = -210.0
		dialogue_panel.offset_bottom = -20.0

func destacar_no(target_node_path: NodePath, forcar_visibilidade: bool = false) -> void:
	var target: Node = get_node_or_null(target_node_path)
	
	if not target and get_parent():
		target = get_parent().get_node_or_null(target_node_path)
		
	var control_target = target as Control
	if not control_target:
		remover_destaque()
		return

	if forcar_visibilidade and not control_target.visible:
		control_target.show()

	var global_rect: Rect2 = control_target.get_global_rect()
	var rect_vec4 = Vector4(global_rect.position.x, global_rect.position.y, global_rect.size.x, global_rect.size.y)
	
	if shader_material:
		shader_material.set_shader_parameter("rect_target", rect_vec4)
		
	highlight_box.show()
	highlight_box.position = global_rect.position
	highlight_box.size = global_rect.size

func remover_destaque() -> void:
	if shader_material:
		shader_material.set_shader_parameter("rect_target", Vector4(0, 0, 0, 0))
	highlight_box.hide()

func atualizar_tutorial() -> void:
	match step:
		0:
			mudar_posicao_dialogo(false)
			remover_destaque()
			texto_bia.text = "(SUPERVISORA BIA)\nOlá, Lise! Seja bem-vinda ao seu primeiro dia. Vou te apresentar todos os setores da nossa central."
		1:
			mudar_posicao_dialogo(false)
			destacar_no("Painel_Topo_Inicial")
			texto_bia.text = "Aqui no topo você acompanha o status geral do dia e o andamento do seu turno de trabalho."
		2:
			mudar_posicao_dialogo(false)
			destacar_no("Painel_Barra_Conscientizacao")
			texto_bia.text = "Esta barra mede o nível geral de conscientização na cidade. Mantê-la em um bom patamar é o nosso objetivo principal!"
		3:
			mudar_posicao_dialogo(false)
			destacar_no("Painel_Tipos_Conscientizados")
			texto_bia.text = "Neste painel listamos as modalidades de violência reconhecidas. Identificar e categorizar corretamente cada relato ajuda no combate direto."
		4:
			mudar_posicao_dialogo(false)
			destacar_no("Painel_Atendimento")
			texto_bia.text = "Esta é a sua mesa de Atendimento. É por aqui que você receberá chamadas e interagirá diretamente com os relatos das vítimas."
		5:
			mudar_posicao_dialogo(false)
			destacar_no("Painel_Fila_Mulheres")
			texto_bia.text = "Aqui fica a Fila de Atendimento. Fique de olho no tempo de espera e no fluxo de mulheres aguardando suporte."
		6:
			mudar_posicao_dialogo(true)
			destacar_no("Painel_MiniMapa")
			texto_bia.text = "No Minimapa acompanhamos os focos da cidade e identificamos a disseminação de Fake News e desinformação."
		7:
			mudar_posicao_dialogo(true)
			destacar_no("Painel_ResultadoAcoes")
			texto_bia.text = "Neste quadro acompanhamos os Resultados das Ações adotadas, avaliando a eficácia e o impacto do nosso trabalho."
		8:
			mudar_posicao_dialogo(false)
			destacar_no("PainelMainLoja", true)
			texto_bia.text = "Este é o menu de Upgrades. Com os relatórios concluídos, podemos investir em melhorias para ampliar o alcance e a infraestrutura da central."
		9:
			mudar_posicao_dialogo(false)
			var loja = get_parent().get_node_or_null("PainelMainLoja") if get_parent() else null
			if loja and loja is Control:
				loja.hide()
				
			remover_destaque()
			texto_bia.text = "Fique atenta: durante o expediente, emergências e eventos imprevisíveis podem surgir e alterar a dinâmica de atendimento!"
		10:
			mudar_posicao_dialogo(false)
			remover_destaque()
			texto_bia.text = "Agora você conhece toda a interface! Boa sorte no seu primeiro turno, Lise. Estamos contando com você!"
		11:
			# 2. Marca no UpgradesManager que o tutorial já acabou
			if UpgradesManager:
				UpgradesManager.tutorial_concluido = true

			emit_signal("tutorial_concluido")
			queue_free()
