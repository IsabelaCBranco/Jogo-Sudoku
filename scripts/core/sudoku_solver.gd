class_name SudokuSolver
extends RefCounted
## Resolvedor de Sudoku 9x9.
##
## Trabalha com matrizes `Array` de inteiros (0 = célula vazia), sem depender
## da classe de tabuleiro nem da UI, o que permite testes determinísticos.

const TAMANHO: int = 9
const TAMANHO_BLOCO: int = 3
const VALOR_VAZIO: int = 0


## Retorna a solução do tabuleiro ou uma `Array` vazia quando não há solução.
## Não modifica o tabuleiro recebido.
static func resolver(tabuleiro: Array) -> Array:
	var copia := _copiar(tabuleiro)
	if _resolver_recursivo(copia):
		return copia
	return []


static func tem_solucao(tabuleiro: Array) -> bool:
	return resolver(tabuleiro).size() > 0


## Conta soluções até o limite informado (padrão: 2), parando cedo.
static func contar_solucoes(tabuleiro: Array, maximo: int = 2) -> int:
	if not _e_tabuleiro_valido(tabuleiro):
		return 0
	var copia := _copiar(tabuleiro)
	return _contar_recursivo(copia, maximo)


static func tem_solucao_unica(tabuleiro: Array) -> bool:
	return contar_solucoes(tabuleiro, 2) == 1


## Conta quantos preenchimentos o solver precisa tentar até encontrar a
## solução — medida aproximada de complexidade do puzzle (0 para tabuleiro
## completo). Não modifica o tabuleiro recebido.
static func contar_decisoes(tabuleiro: Array) -> int:
	var copia := _copiar(tabuleiro)
	var contador: Array[int] = [0]
	_contar_decisoes_recursivo(copia, contador)
	return contador[0]


static func _contar_decisoes_recursivo(tabuleiro: Array, contador: Array[int]) -> bool:
	var posicao := _melhor_proxima_vazia(tabuleiro)
	if posicao == -1:
		return true
	var linha: int = posicao / TAMANHO
	var coluna: int = posicao % TAMANHO
	for valor in range(1, 10):
		if pode_inserir(tabuleiro, linha, coluna, valor):
			contador[0] += 1
			tabuleiro[linha][coluna] = valor
			if _contar_decisoes_recursivo(tabuleiro, contador):
				return true
			tabuleiro[linha][coluna] = VALOR_VAZIO
	return false


static func _resolver_recursivo(tabuleiro: Array) -> bool:
	var posicao := _melhor_proxima_vazia(tabuleiro)
	if posicao == -1:
		return true
	var linha: int = posicao / TAMANHO
	var coluna: int = posicao % TAMANHO
	for valor in range(1, 10):
		if pode_inserir(tabuleiro, linha, coluna, valor):
			tabuleiro[linha][coluna] = valor
			if _resolver_recursivo(tabuleiro):
				return true
			tabuleiro[linha][coluna] = VALOR_VAZIO
	return false


static func _contar_recursivo(tabuleiro: Array, maximo: int) -> int:
	var posicao := _melhor_proxima_vazia(tabuleiro)
	if posicao == -1:
		return 1
	var linha: int = posicao / TAMANHO
	var coluna: int = posicao % TAMANHO
	var total: int = 0
	for valor in range(1, 10):
		if pode_inserir(tabuleiro, linha, coluna, valor):
			tabuleiro[linha][coluna] = valor
			total += _contar_recursivo(tabuleiro, maximo)
			tabuleiro[linha][coluna] = VALOR_VAZIO
			if total >= maximo:
				return maximo
	return total


## Escolhe a célula vazia com menos candidatos (heurística MRV),
## reduzindo drasticamente o espaço de busca em tabuleiros esparsos.
static func _melhor_proxima_vazia(tabuleiro: Array) -> int:
	var melhor_posicao: int = -1
	var menos_candidatos: int = TAMANHO + 1
	for linha in TAMANHO:
		for coluna in TAMANHO:
			if tabuleiro[linha][coluna] != VALOR_VAZIO:
				continue
			var candidatos := _contar_candidatos(tabuleiro, linha, coluna)
			if candidatos < menos_candidatos:
				menos_candidatos = candidatos
				melhor_posicao = linha * TAMANHO + coluna
				if candidatos == 1:
					return melhor_posicao
	return melhor_posicao


static func _contar_candidatos(tabuleiro: Array, linha: int, coluna: int) -> int:
	var contador: int = 0
	for valor in range(1, 10):
		if pode_inserir(tabuleiro, linha, coluna, valor):
			contador += 1
	return contador


static func pode_inserir(tabuleiro: Array, linha: int, coluna: int, valor: int) -> bool:
	for i in TAMANHO:
		if tabuleiro[linha][i] == valor:
			return false
		if tabuleiro[i][coluna] == valor:
			return false
	var inicio_linha: int = (linha / TAMANHO_BLOCO) * TAMANHO_BLOCO
	var inicio_coluna: int = (coluna / TAMANHO_BLOCO) * TAMANHO_BLOCO
	for l in TAMANHO_BLOCO:
		for c in TAMANHO_BLOCO:
			if tabuleiro[inicio_linha + l][inicio_coluna + c] == valor:
				return false
	return true


## Verifica se o tabuleiro não possui valores repetidos em linha, coluna ou bloco.
static func _e_tabuleiro_valido(tabuleiro: Array) -> bool:
	for linha in TAMANHO:
		var vistos: Array[int] = []
		for coluna in TAMANHO:
			var valor: int = tabuleiro[linha][coluna]
			if valor != VALOR_VAZIO:
				if vistos.has(valor):
					return false
				vistos.append(valor)

	for coluna in TAMANHO:
		var vistos: Array[int] = []
		for linha in TAMANHO:
			var valor: int = tabuleiro[linha][coluna]
			if valor != VALOR_VAZIO:
				if vistos.has(valor):
					return false
				vistos.append(valor)

	for inicio_linha in range(0, TAMANHO, TAMANHO_BLOCO):
		for inicio_coluna in range(0, TAMANHO, TAMANHO_BLOCO):
			var vistos: Array[int] = []
			for l in TAMANHO_BLOCO:
				for c in TAMANHO_BLOCO:
					var valor: int = tabuleiro[inicio_linha + l][inicio_coluna + c]
					if valor != VALOR_VAZIO:
						if vistos.has(valor):
							return false
						vistos.append(valor)

	return true


static func _copiar(tabuleiro: Array) -> Array:
	var copia: Array = []
	for linha in tabuleiro:
		copia.append(linha.duplicate())
	return copia
