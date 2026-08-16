class_name LivesSystem
extends RefCounted
## Sistema de vidas da partida.
##
## O modo de vidas pode ser desativado; nesse caso nenhuma vida é removida.
## A UI não controla a quantidade de vidas diretamente.

signal vidas_alteradas(vidas: int)
signal vidas_zeradas()

const VIDA_INICIAL: int = 3

var _vidas: int = VIDA_INICIAL
var vidas_ativadas: bool = true


func iniciar(ativadas: bool = true) -> void:
	vidas_ativadas = ativadas
	_vidas = VIDA_INICIAL
	vidas_alteradas.emit(_vidas)


func reiniciar() -> void:
	_vidas = VIDA_INICIAL
	vidas_alteradas.emit(_vidas)


func get_vidas() -> int:
	return _vidas


func serializar() -> Dictionary:
	return {
		"ativadas": vidas_ativadas,
		"vidas": _vidas,
	}


func carregar_estado(dados: Dictionary) -> void:
	if dados.is_empty():
		return
	vidas_ativadas = bool(dados.get("ativadas", true))
	_vidas = int(dados.get("vidas", VIDA_INICIAL))
	vidas_alteradas.emit(_vidas)


func perder_vida() -> bool:
	if not vidas_ativadas:
		return false
	if _vidas <= 0:
		return false

	_vidas -= 1
	vidas_alteradas.emit(_vidas)
	if _vidas == 0:
		vidas_zeradas.emit()
	return true
