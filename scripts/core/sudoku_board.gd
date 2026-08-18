class_name SudokuBoard
extends RefCounted
## Modelo do tabuleiro de Sudoku 9x9, independente da UI.
##
## Responsável pela representação, regras de validação, inserção de valores,
## anotações e verificação de vitória. Não depende de nós visuais.

signal celula_alterada(linha: int, coluna: int, valor: int)
signal celula_errada(linha: int, coluna: int, valor: int)
signal vitoria()

const TAMANHO: int = 9
const TAMANHO_BLOCO: int = 3
const VALOR_VAZIO: int = 0

var _celulas: Array[SudokuCell] = []


func _init(tabuleiro: Array, solucao: Array, originais: Array) -> void:
	_criar_celulas(tabuleiro, solucao, originais)


func _criar_celulas(tabuleiro: Array, solucao: Array, originais: Array) -> void:
	_celulas.clear()
	for i in TAMANHO * TAMANHO:
		var linha: int = i / TAMANHO
		var coluna: int = i % TAMANHO
		var valor_original: int = int(solucao[linha][coluna])
		var dado: bool = bool(originais[linha][coluna])
		_celulas.append(SudokuCell.new(valor_original, dado))
		# O tabuleiro fornecido não deve conter valores que contradizem a solução.
		# O valor atual vem da solução quando a célula é original, senão do estado inicial.
		if not dado and int(tabuleiro[linha][coluna]) != 0:
			_celulas[i].definir_valor(int(tabuleiro[linha][coluna]))


func get_celula(linha: int, coluna: int) -> SudokuCell:
	_verificar_posicao(linha, coluna)
	return _celulas[_indice(linha, coluna)]


func get_valor(linha: int, coluna: int) -> int:
	return get_celula(linha, coluna).valor_atual


func get_valor_solucao(linha: int, coluna: int) -> int:
	return get_celula(linha, coluna).valor_solucao


func esta_bloqueada(linha: int, coluna: int) -> bool:
	return get_celula(linha, coluna).original


func esta_vazia(linha: int, coluna: int) -> bool:
	return get_celula(linha, coluna).esta_vazia()


func tem_erro(linha: int, coluna: int) -> bool:
	return get_celula(linha, coluna).tem_erro


## Verifica se inserir `valor` em (linha, coluna) não viola as regras do
## Sudoku considerando o estado atual do tabuleiro.
func movimento_valido(linha: int, coluna: int, valor: int) -> bool:
	if valor < 1 or valor > 9:
		return false
	return not get_valores_linha(linha).has(valor) \
		and not get_valores_coluna(coluna).has(valor) \
		and not get_valores_bloco(linha, coluna).has(valor)


## Insere um valor na célula. Retorna false quando a célula está bloqueada.
func definir_valor(linha: int, coluna: int, valor: int) -> bool:
	var celula := get_celula(linha, coluna)
	if celula.original or valor == VALOR_VAZIO:
		return false
	if valor < 1 or valor > 9:
		return false

	celula.definir_valor(valor)
	_atualizar_anotacoes_relacionadas(linha, coluna, valor)
	celula_alterada.emit(linha, coluna, valor)

	if celula.tem_erro:
		celula_errada.emit(linha, coluna, valor)
	elif esta_completa():
		verificar_vitoria()

	return true


## Remove o valor de uma célula editável. Retorna false quando bloqueada.
func remover_valor(linha: int, coluna: int) -> bool:
	var celula := get_celula(linha, coluna)
	if celula.original:
		return false
	if not celula.limpar():
		return false
	celula_alterada.emit(linha, coluna, VALOR_VAZIO)
	return true


func get_valores_linha(linha: int) -> Array[int]:
	_verificar_linha(linha)
	var valores: Array[int] = []
	for coluna in TAMANHO:
		var valor := get_valor(linha, coluna)
		if valor != VALOR_VAZIO:
			valores.append(valor)
	return valores


func get_valores_coluna(coluna: int) -> Array[int]:
	_verificar_coluna(coluna)
	var valores: Array[int] = []
	for linha in TAMANHO:
		var valor := get_valor(linha, coluna)
		if valor != VALOR_VAZIO:
			valores.append(valor)
	return valores


func get_valores_bloco(linha: int, coluna: int) -> Array[int]:
	_verificar_posicao(linha, coluna)
	var valores: Array[int] = []
	var inicio_linha: int = (linha / TAMANHO_BLOCO) * TAMANHO_BLOCO
	var inicio_coluna: int = (coluna / TAMANHO_BLOCO) * TAMANHO_BLOCO
	for l in TAMANHO_BLOCO:
		for c in TAMANHO_BLOCO:
			var valor := get_valor(inicio_linha + l, inicio_coluna + c)
			if valor != VALOR_VAZIO:
				valores.append(valor)
	return valores


func get_anotacoes(linha: int, coluna: int) -> Array[int]:
	return get_celula(linha, coluna).get_anotacoes()


func tem_anotacao(linha: int, coluna: int, valor: int) -> bool:
	return get_celula(linha, coluna).tem_anotacao(valor)


func adicionar_anotacao(linha: int, coluna: int, valor: int) -> bool:
	return get_celula(linha, coluna).adicionar_anotacao(valor)


func remover_anotacao(linha: int, coluna: int, valor: int) -> bool:
	return get_celula(linha, coluna).remover_anotacao(valor)


func limpar_anotacoes(linha: int, coluna: int) -> void:
	get_celula(linha, coluna).limpar_anotacoes()


## Todas as células estão preenchidas (independente de estarem corretas).
func esta_completa() -> bool:
	for celula in _celulas:
		if celula.esta_vazia():
			return false
	return true


## Quantidade de ocorrências de um dígito (1-9) no tabuleiro atual.
func contar_valor(valor: int) -> int:
	var total := 0
	for celula in _celulas:
		if celula.valor_atual == valor:
			total += 1
	return total


## Quantidade de células preenchidas (valores e anotações não contam).
func contar_preenchidas() -> int:
	var total := 0
	for celula in _celulas:
		if not celula.esta_vazia():
			total += 1
	return total


## O estado atual é idêntico à solução.
func verificar_vitoria() -> bool:
	for linha in TAMANHO:
		for coluna in TAMANHO:
			if get_valor(linha, coluna) != get_valor_solucao(linha, coluna):
				return false
	if not _vitoria_emitida:
		_vitoria_emitida = true
		vitoria.emit()
	return true


## Restaura o tabuleiro ao estado original (apenas células fornecidas).
func reiniciar() -> void:
	for i in _celulas.size():
		var celula := _celulas[i]
		if celula.original:
			celula.definir_valor(celula.valor_solucao)
		else:
			celula.limpar()
	celula_reiniciada.emit()


func get_tabuleiro_atual() -> Array:
	return _grade_valores(func(celula: SudokuCell) -> int: return celula.valor_atual)


func get_solucao() -> Array:
	return _grade_valores(func(celula: SudokuCell) -> int: return celula.valor_solucao)


func get_mascara_originais() -> Array:
	return _grade_valores(func(celula: SudokuCell) -> int: return 1 if celula.original else 0)


signal celula_reiniciada()

var _vitoria_emitida: bool = false


func _atualizar_anotacoes_relacionadas(linha: int, coluna: int, valor: int) -> void:
	_remover_anotacao_da_linha(linha, valor)
	_remover_anotacao_da_coluna(coluna, valor)
	_remover_anotacao_do_bloco(linha, coluna, valor)


func _remover_anotacao_da_linha(linha: int, valor: int) -> void:
	for coluna in TAMANHO:
		get_celula(linha, coluna).remover_anotacao(valor)


func _remover_anotacao_da_coluna(coluna: int, valor: int) -> void:
	for linha in TAMANHO:
		get_celula(linha, coluna).remover_anotacao(valor)


func _remover_anotacao_do_bloco(linha: int, coluna: int, valor: int) -> void:
	var inicio_linha: int = (linha / TAMANHO_BLOCO) * TAMANHO_BLOCO
	var inicio_coluna: int = (coluna / TAMANHO_BLOCO) * TAMANHO_BLOCO
	for l in TAMANHO_BLOCO:
		for c in TAMANHO_BLOCO:
			get_celula(inicio_linha + l, inicio_coluna + c).remover_anotacao(valor)


func _grade_valores(extrair: Callable) -> Array:
	var grade: Array = []
	for linha in TAMANHO:
		var fileira: Array = []
		for coluna in TAMANHO:
			fileira.append(extrair.call(get_celula(linha, coluna)))
		grade.append(fileira)
	return grade


func _indice(linha: int, coluna: int) -> int:
	return linha * TAMANHO + coluna


func _verificar_posicao(linha: int, coluna: int) -> void:
	_verificar_linha(linha)
	_verificar_coluna(coluna)


func _verificar_linha(linha: int) -> void:
	assert(linha >= 0 and linha < TAMANHO, "Linha fora do tabuleiro: %d" % linha)


func _verificar_coluna(coluna: int) -> void:
	assert(coluna >= 0 and coluna < TAMANHO, "Coluna fora do tabuleiro: %d" % coluna)
