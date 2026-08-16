extends Control
## Sobreposição de confirmação de reinício (apresentação apenas).
##
## Observa os sinais de solicitação/cancelamento do controller e oferece:
## continuar jogando (cancelar), reiniciar o mesmo puzzle ou gerar um novo.
## Nenhuma regra de negócio vive aqui.

@export_node_path var controller_path: NodePath

var _controller: GameController


func _ready() -> void:
	_controller = get_node(controller_path)
	_controller.reinicio_solicitado.connect(_ao_reinicio_solicitado)
	_controller.reinicio_cancelado.connect(_ao_reinicio_cancelado)
	%BtnCancelarReinicio.pressed.connect(_controller.cancelar_reinicio)
	%BtnReiniciarMesmo.pressed.connect(_ao_reiniciar_mesmo)
	%BtnReiniciarNovo.pressed.connect(_ao_reiniciar_novo)
	visible = false


func _ao_reinicio_solicitado() -> void:
	%LabelProgressoReinicio.text = "%d/%d preenchidos" % [
		_controller.get_progresso(),
		SudokuBoard.TAMANHO * SudokuBoard.TAMANHO,
	]
	visible = true
	%BtnCancelarReinicio.grab_focus()


func _fechar() -> void:
	visible = false
	get_viewport().gui_release_focus()


func _ao_reinicio_cancelado() -> void:
	_fechar()


func _ao_reiniciar_mesmo() -> void:
	_controller.reiniciar_partida()
	_fechar()


func _ao_reiniciar_novo() -> void:
	_controller.reiniciar_com_novo_puzzle()
	_fechar()
