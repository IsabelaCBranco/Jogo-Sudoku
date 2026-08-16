class_name MoveHistory
extends RefCounted
## Histórico de movimentos para desfazer/refazer.
##
## Guarda snapshots completos do tabuleiro (valor + anotações de cada célula)
## antes de cada alteração. Desfazer restaura o estado anterior; refazer
## reaplica o estado posterior. O tamanho do histórico é limitado.

signal historico_alterado

const LIMITE: int = 200

var _board: SudokuBoard
var _desfazer: Array = []
var _refazer: Array = []
var _gravando: bool = false


func _init(board: SudokuBoard) -> void:
	_board = board


func limpar() -> void:
	_desfazer.clear()
	_refazer.clear()
	historico_alterado.emit()


func serializar() -> Dictionary:
	return {
		"desfazer": _desfazer,
		"refazer": _refazer,
	}


func carregar_estado(dados: Dictionary) -> void:
	_desfazer = _normalizar_pilha(dados.get("desfazer", []))
	_refazer = _normalizar_pilha(dados.get("refazer", []))
	historico_alterado.emit()


func _normalizar_pilha(pilha: Array) -> Array:
	var resultado: Array = []
	for estado in pilha:
		var novo: Array = []
		for celula in estado:
			var anotacoes: Array = []
			for valor in celula["anotacoes"]:
				anotacoes.append(int(valor))
			novo.append({
				"valor": int(celula["valor"]),
				"anotacoes": anotacoes,
			})
		resultado.append(novo)
	return resultado


func pode_desfazer() -> bool:
	return _desfazer.size() > 0


func pode_refazer() -> bool:
	return _refazer.size() > 0


func tamanho_historico() -> int:
	return _desfazer.size()


func snapshot() -> Array:
	var resultado: Array = []
	for i in SudokuBoard.TAMANHO * SudokuBoard.TAMANHO:
		var celula := _board.get_celula(i / SudokuBoard.TAMANHO, i % SudokuBoard.TAMANHO)
		resultado.append({
			"valor": celula.valor_atual,
			"anotacoes": celula.get_anotacoes(),
		})
	return resultado


func registrar(estado_anterior: Array) -> void:
	if _gravando:
		return
	_desfazer.append(estado_anterior)
	if _desfazer.size() > LIMITE:
		_desfazer.pop_front()
	_refazer.clear()
	historico_alterado.emit()


func desfazer() -> bool:
	if not pode_desfazer():
		return false
	var estado: Array = _desfazer.pop_back()
	_refazer.append(snapshot())
	_restaurar(estado)
	historico_alterado.emit()
	return true


func refazer() -> bool:
	if not pode_refazer():
		return false
	var estado: Array = _refazer.pop_back()
	_desfazer.append(snapshot())
	if _desfazer.size() > LIMITE:
		_desfazer.pop_front()
	_restaurar(estado)
	historico_alterado.emit()
	return true


func _restaurar(estado: Array) -> void:
	_gravando = true
	for i in estado.size():
		var celula := _board.get_celula(i / SudokuBoard.TAMANHO, i % SudokuBoard.TAMANHO)
		celula.definir_valor(int(estado[i]["valor"]))
		celula.limpar_anotacoes()
		for valor in estado[i]["anotacoes"]:
			celula.adicionar_anotacao(int(valor))
	_gravando = false
