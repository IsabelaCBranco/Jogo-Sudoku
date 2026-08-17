extends Control
## Interface da partida (apresentação apenas).
##
## Observa os sinais do GameController e atualiza rótulos e botões; os botões
## apenas acionam métodos do controller. Nenhuma regra de negócio aqui.
## A inicialização é deferida até o primeiro sinal de estado, garantindo que
## os sistemas do controller já existam (o _ready do HUD roda antes do pai).

@export_node_path var controller_path: NodePath

var _controller: GameController


func _ready() -> void:
	_controller = get_node(controller_path)
	_controller.estado_alterado.connect(_ao_estado_alterado)
	_controller.vitoria.connect(_ao_vitoria)
	_controller.derrota.connect(_ao_derrota)
	_controller.vida_alterada.connect(_ao_vida_alterada)
	_controller.tempo_alterado.connect(_ao_tempo_alterado)
	_controller.pontuacao_alterada.connect(_ao_pontuacao_alterada)
	_controller.modo_anotacao_alterado.connect(_ao_modo_anotacao_alterado)
	_controller.historico_alterado.connect(_ao_historico_alterado)
	_controller.dicas_alteradas.connect(_ao_dicas_alteradas)

	%BtnNotas.pressed.connect(_controller.alternar_modo_anotacao)
	%BtnApagar.pressed.connect(_controller.apagar_celula)
	%BtnDesfazer.pressed.connect(_controller.desfazer)
	%BtnRefazer.pressed.connect(_controller.refazer)
	%BtnDica1.pressed.connect(_controller.pedir_dica.bind(HintSystem.DICA_DESTACAR))
	%BtnDica2.pressed.connect(_controller.pedir_dica.bind(HintSystem.DICA_CANDIDATO))
	%BtnDica3.pressed.connect(_controller.pedir_dica.bind(HintSystem.DICA_RESOLVER))
	%BtnPausar.pressed.connect(_controller.alternar_pausa)
	%BtnReiniciar.pressed.connect(_controller.solicitar_reinicio)
	for botao_no in %Numpad.get_children():
		var botao := botao_no as Button
		botao.pressed.connect(_controller.inserir_numero.bind(int(botao.get_meta("valor"))))
	_sem_foco_nos_botoes()
	%LabelAjuda.visible = not OS.has_feature("mobile")


## Os botões do HUD não devem capturar o foco do teclado: ao clicar em um
## botão, as setas deixariam de mover a seleção do tabuleiro e passariam a
## navegar entre os botões. Toda ação já possui atalho de teclado.
func _sem_foco_nos_botoes() -> void:
	for botao_no in find_children("*", "Button", true, false):
		(botao_no as Button).focus_mode = Control.FOCUS_NONE


func _ao_estado_alterado() -> void:
	%LabelDificuldade.text = DifficultyManager.get_nome(_controller.dificuldade)
	_ao_vida_alterada(_controller.get_vidas())
	_ao_tempo_alterado(_controller.get_tempo())
	_ao_pontuacao_alterada(_controller.get_pontuacao())
	_ao_modo_anotacao_alterado(_controller.get_modo_anotacao())
	_ao_historico_alterado(_controller.pode_desfazer(), _controller.pode_refazer())
	%LabelRecorde.text = _formatar_recorde()
	%LabelStatus.text = ""
	_ao_dicas_alteradas()


func _formatar_recorde() -> String:
	var recorde := StatisticsSystem.get_melhor_pontuacao(_controller.dificuldade)
	if recorde <= 0:
		return "—"
	return str(recorde)


func _ao_vitoria(pontos: int) -> void:
	%LabelStatus.text = "Vitória!"
	%LabelPontos.text = str(pontos)
	%LabelRecorde.text = _formatar_recorde()


func _ao_derrota() -> void:
	%LabelStatus.text = "Fim de jogo!"


func _ao_vida_alterada(vidas: int) -> void:
	if GameSettings.vidas_ativadas:
		%LabelVidas.text = "♥".repeat(vidas)
	else:
		%LabelVidas.text = "OFF"


func _ao_tempo_alterado(segundos: int) -> void:
	%LabelTempo.text = "%02d:%02d" % [segundos / 60, segundos % 60]


func _ao_pontuacao_alterada(pontos: int) -> void:
	%LabelPontos.text = str(pontos)


func _ao_modo_anotacao_alterado(ativo: bool) -> void:
	%LabelModo.text = "ON" if ativo else "OFF"


func _ao_historico_alterado(pode_desfazer: bool, pode_refazer: bool) -> void:
	%BtnDesfazer.disabled = not pode_desfazer
	%BtnRefazer.disabled = not pode_refazer


func _ao_dicas_alteradas() -> void:
	_atualizar_botao_dica(%BtnDica1, HintSystem.DICA_DESTACAR)
	_atualizar_botao_dica(%BtnDica2, HintSystem.DICA_CANDIDATO)
	_atualizar_botao_dica(%BtnDica3, HintSystem.DICA_RESOLVER)


func _atualizar_botao_dica(botao: Button, nivel: int) -> void:
	var restantes := _controller.get_dicas_restantes(nivel)
	botao.text = "%s (%d)" % [HintSystem.get_nome_dica(nivel), restantes]
	botao.disabled = restantes <= 0
