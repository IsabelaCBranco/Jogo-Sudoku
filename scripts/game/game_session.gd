extends Node
## Dados transitórios da sessão entre telas (autoload).
##
## Carrega apenas informações de navegação (dificuldade escolhida, pedido
## de continuar) e o resultado da partida encerrada, para que a sobreposição
## de conclusão possa apresentá-lo. Não contém regras de negócio.

enum Resultado { NENHUM = 0, VITORIA = 1, DERROTA = 2 }

var dificuldade_selecionada: int = DifficultyManager.Dificuldade.FACIL
var continuar: bool = false
var resultado: int = Resultado.NENHUM
var resultado_pontos: int = 0
var resultado_tempo_segundos: int = 0
var resultado_vidas: int = 0
var resultado_dificuldade: int = DifficultyManager.Dificuldade.FACIL
var resultado_erros: int = 0
var resultado_dicas: int = 0


func definir_nova_partida(dificuldade: int) -> void:
	dificuldade_selecionada = dificuldade
	continuar = false


func definir_continuar() -> void:
	continuar = true


func registrar_vitoria(pontos: int, tempo_segundos: int, vidas: int, dificuldade: int, erros: int, dicas: int) -> void:
	resultado = Resultado.VITORIA
	resultado_pontos = pontos
	resultado_tempo_segundos = tempo_segundos
	resultado_vidas = vidas
	resultado_dificuldade = dificuldade
	resultado_erros = erros
	resultado_dicas = dicas


func registrar_derrota(tempo_segundos: int, dificuldade: int, erros: int, dicas: int) -> void:
	resultado = Resultado.DERROTA
	resultado_pontos = 0
	resultado_tempo_segundos = tempo_segundos
	resultado_vidas = 0
	resultado_dificuldade = dificuldade
	resultado_erros = erros
	resultado_dicas = dicas


func limpar() -> void:
	continuar = false
	resultado = Resultado.NENHUM
	resultado_pontos = 0
	resultado_tempo_segundos = 0
	resultado_vidas = 0
	resultado_dificuldade = DifficultyManager.Dificuldade.FACIL
	resultado_erros = 0
	resultado_dicas = 0
