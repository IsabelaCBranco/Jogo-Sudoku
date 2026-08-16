class_name SudokuGenerator
extends RefCounted
## Gera puzzles de Sudoku válidos e com solução única.
##
## O processo: gerar uma solução completa aleatória, remover células
## progressivamente e verificar a unicidade da solução a cada remoção.
## A aleatoriedade é controlada por seed para permitir testes determinísticos.

const TAMANHO: int = 9
const VALOR_VAZIO: int = 0

const MAX_TENTATIVAS: int = 8
const FATOR_SUB_SEED: int = 7919


## Gera um puzzle completo. Com `seed >= 0` a geração é reproduzível.
## Re-tenta com sub-seeds determinísticas quando a complexidade do puzzle
## gerado fica fora da faixa esperada para a dificuldade.
static func gerar(dificuldade: int, seed: int = -1) -> Dictionary:
	var deterministica := seed >= 0
	var tentativa := 0
	while true:
		var rng := RandomNumberGenerator.new()
		if deterministica:
			rng.seed = seed + tentativa * FATOR_SUB_SEED
		else:
			rng.randomize()
		var resultado := _gerar_uma_vez(dificuldade, rng)
		if tentativa >= MAX_TENTATIVAS - 1 \
				or DifficultyManager.complexidade_na_faixa(dificuldade, resultado["complexidade"]):
			return resultado
		tentativa += 1
	return {}


## Gera um puzzle em uma única tentativa e devolve sua complexidade (em
## decisões do solver), sem a lógica de aceitação — útil para calibração
## das faixas e para testes.
static func complexidade_de_uma_geracao(dificuldade: int, seed: int) -> int:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	return _gerar_uma_vez(dificuldade, rng)["complexidade"]


static func _gerar_uma_vez(dificuldade: int, rng: RandomNumberGenerator) -> Dictionary:
	var solucao := _gerar_solucao(rng)
	var alvo: int = DifficultyManager.selecionar_preenchidas(dificuldade, rng)
	var puzzle := _copiar(solucao)
	_remover_valores(puzzle, alvo, rng)

	return {
		"tabuleiro": puzzle,
		"solucao": solucao,
		"originais": _gerar_mascara(puzzle),
		"dificuldade": dificuldade,
		"preenchidas": _contar_preenchidas(puzzle),
		"complexidade": SudokuSolver.contar_decisoes(puzzle),
	}


static func _gerar_solucao(rng: RandomNumberGenerator) -> Array:
	var grade := _grade_vazia()
	_preencher_solucao(grade, 0, rng)
	return grade


static func _preencher_solucao(grade: Array, indice: int, rng: RandomNumberGenerator) -> bool:
	if indice >= TAMANHO * TAMANHO:
		return true
	var linha: int = indice / TAMANHO
	var coluna: int = indice % TAMANHO
	var candidatos := [1, 2, 3, 4, 5, 6, 7, 8, 9]
	_embaralhar(candidatos, rng)
	for valor in candidatos:
		if SudokuSolver.pode_inserir(grade, linha, coluna, valor):
			grade[linha][coluna] = valor
			if _preencher_solucao(grade, indice + 1, rng):
				return true
			grade[linha][coluna] = VALOR_VAZIO
	return false


static func _remover_valores(grade: Array, alvo: int, rng: RandomNumberGenerator) -> void:
	var posicoes: Array[int] = []
	for i in TAMANHO * TAMANHO:
		posicoes.append(i)
	_embaralhar(posicoes, rng)
	for posicao in posicoes:
		if _contar_preenchidas(grade) <= alvo:
			break
		var linha: int = posicao / TAMANHO
		var coluna: int = posicao % TAMANHO
		var valor_atual: int = grade[linha][coluna]
		if valor_atual == VALOR_VAZIO:
			continue
		grade[linha][coluna] = VALOR_VAZIO
		if not SudokuSolver.tem_solucao_unica(grade):
			grade[linha][coluna] = valor_atual


static func _embaralhar(lista: Array, rng: RandomNumberGenerator) -> void:
	for i in range(lista.size() - 1, 0, -1):
		var j: int = rng.randi_range(0, i)
		var temporario: Variant = lista[i]
		lista[i] = lista[j]
		lista[j] = temporario


static func _gerar_mascara(grade: Array) -> Array:
	var mascara: Array = []
	for linha in grade:
		var fileira: Array = []
		for valor in linha:
			fileira.append(1 if valor != VALOR_VAZIO else 0)
		mascara.append(fileira)
	return mascara


static func _contar_preenchidas(grade: Array) -> int:
	var total: int = 0
	for linha in grade:
		for valor in linha:
			if valor != VALOR_VAZIO:
				total += 1
	return total


static func _grade_vazia() -> Array:
	var grade: Array = []
	for i in TAMANHO:
		var fileira: Array = []
		for j in TAMANHO:
			fileira.append(VALOR_VAZIO)
		grade.append(fileira)
	return grade


static func _copiar(grade: Array) -> Array:
	var copia: Array = []
	for linha in grade:
		copia.append(linha.duplicate())
	return copia
