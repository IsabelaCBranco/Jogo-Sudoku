class_name SudokuCell
extends RefCounted
## Célula do tabuleiro de Sudoku.
##
## Guarda o valor atual, o valor da solução, se é uma célula fornecida
## originalmente (bloqueada) e as anotações/candidatos.
## É um simples contêiner de dados, sem lógica de tabuleiro.

var valor_solucao: int = 0
var valor_atual: int = 0
var original: bool = false
var tem_erro: bool = false

var _anotacoes: Array[int] = []


func _init(valor_solucao: int, original: bool) -> void:
	self.valor_solucao = valor_solucao
	self.original = original
	if original:
		valor_atual = valor_solucao


func esta_vazia() -> bool:
	return valor_atual == 0


func esta_correta() -> bool:
	return valor_atual != 0 and valor_atual == valor_solucao


func get_anotacoes() -> Array[int]:
	return _anotacoes.duplicate()


func tem_anotacao(valor: int) -> bool:
	return _anotacoes.has(valor)


func adicionar_anotacao(valor: int) -> bool:
	if valor <= 0 or valor > 9:
		return false
	if esta_vazia() and not tem_anotacao(valor):
		_anotacoes.append(valor)
		return true
	return false


func remover_anotacao(valor: int) -> bool:
	if _anotacoes.has(valor):
		_anotacoes.erase(valor)
		return true
	return false


func limpar_anotacoes() -> void:
	_anotacoes.clear()


func definir_valor(valor: int) -> bool:
	if original:
		return false
	if valor < 0 or valor > 9:
		return false

	valor_atual = valor
	tem_erro = valor != 0 and valor != valor_solucao
	if valor != 0:
		limpar_anotacoes()
	return true


func limpar() -> bool:
	if original:
		return false
	valor_atual = 0
	tem_erro = false
	return true
