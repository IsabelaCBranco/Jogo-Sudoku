extends Node
## Configurações do jogador, persistidas entre sessões.
##
## Autoload: disponível em toda a árvore do jogo. A UI apenas altera os
## valores; a persistência fica a cargo do SaveManager.

signal configuracoes_alteradas

var vidas_ativadas: bool = true
var som_ativado: bool = true
var musica_ativada: bool = true
var anotacoes_ativadas: bool = true
var exibir_erros: bool = true


func _ready() -> void:
	carregar()


func definir_vidas(ativadas: bool) -> void:
	vidas_ativadas = ativadas
	configuracoes_alteradas.emit()


func definir_som(ativado: bool) -> void:
	som_ativado = ativado
	configuracoes_alteradas.emit()


func definir_musica(ativada: bool) -> void:
	musica_ativada = ativada
	configuracoes_alteradas.emit()


func definir_anotacoes(ativadas: bool) -> void:
	anotacoes_ativadas = ativadas
	configuracoes_alteradas.emit()


func definir_exibir_erros(ativado: bool) -> void:
	exibir_erros = ativado
	configuracoes_alteradas.emit()


func restaurar_padroes() -> void:
	vidas_ativadas = true
	som_ativado = true
	musica_ativada = true
	anotacoes_ativadas = true
	exibir_erros = true
	configuracoes_alteradas.emit()


func salvar() -> void:
	SaveManager.salvar_configuracoes(serializar())


func carregar() -> void:
	var dados := SaveManager.carregar_configuracoes()
	if dados.is_empty():
		return
	vidas_ativadas = bool(dados.get("vidas_ativadas", vidas_ativadas))
	som_ativado = bool(dados.get("som_ativado", som_ativado))
	musica_ativada = bool(dados.get("musica_ativada", musica_ativada))
	anotacoes_ativadas = bool(dados.get("anotacoes_ativadas", anotacoes_ativadas))
	exibir_erros = bool(dados.get("exibir_erros", exibir_erros))


func serializar() -> Dictionary:
	return {
		"vidas_ativadas": vidas_ativadas,
		"som_ativado": som_ativado,
		"musica_ativada": musica_ativada,
		"anotacoes_ativadas": anotacoes_ativadas,
		"exibir_erros": exibir_erros,
	}
