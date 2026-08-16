class_name TimerSystem
extends RefCounted
## Cronômetro da partida.
##
## Não conta o tempo durante pausas. O controle de ticks é feito por quem
## possui a referência (GameController), chamando `atualizar(delta)`.

signal tempo_alterado(segundos: int)

var _segundos: float = 0.0
var _rodando: bool = false
var _ultimo_segundo_emitido: int = -1


func iniciar() -> void:
	_segundos = 0.0
	_ultimo_segundo_emitido = -1
	_rodando = true
	tempo_alterado.emit(0)


func pausar() -> void:
	_rodando = false


func retomar() -> void:
	_rodando = true


func parar() -> void:
	_rodando = false


func definir_segundos(segundos: int) -> void:
	_segundos = float(maxi(0, segundos))
	_ultimo_segundo_emitido = int(_segundos)
	tempo_alterado.emit(int(_segundos))


func atualizar(delta: float) -> void:
	if not _rodando:
		return
	_segundos += delta
	var segundo_atual := int(_segundos)
	if segundo_atual != _ultimo_segundo_emitido:
		_ultimo_segundo_emitido = segundo_atual
		tempo_alterado.emit(segundo_atual)


func get_segundos() -> int:
	return int(_segundos)


func esta_rodando() -> bool:
	return _rodando
