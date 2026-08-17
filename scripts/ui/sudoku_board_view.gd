class_name SudokuBoardView
extends Control
## Apresentação visual do tabuleiro.
##
## Desenha a grade, células dadas, seleção, destaques de linha/coluna/bloco,
## números iguais, erros e anotações. Não contém regras de negócio: apenas
## lê o estado do tabuleiro e emite cliques/toques para o GameController.

signal celula_clicada(linha: int, coluna: int)
signal celula_tocada_toggle(linha: int, coluna: int)

const COR_FUNDO := Color(1, 1, 1, 1)
const COR_LINHA := Color(0.75, 0.75, 0.78, 1)
const COR_LINHA_FORTE := Color(0.15, 0.15, 0.18, 1)
const COR_TEXTO_JOGADOR := Color(0.15, 0.2, 0.5, 1)
const COR_TEXTO_ORIGINAL := Color(0.05, 0.05, 0.08, 1)
const COR_ERRO := Color(0.85, 0.2, 0.2, 1)
const COR_SELECIONADA := Color(0.45, 0.72, 1, 0.45)
const COR_SELECIONADA_MULTI := Color(0.45, 0.72, 1, 0.22)
const COR_RELACIONADA := Color(0.82, 0.9, 1, 0.5)
const COR_IGUAL := Color(0.68, 0.83, 1, 0.4)
const COR_DESTAQUE := Color(1, 0.78, 0.2, 0.65)
const COR_CANDIDATO := Color(0.05, 0.55, 0.9, 1)
const COR_ANOTACAO := Color(0.35, 0.35, 0.45, 1)
const COR_FLASH_ERRO := Color(0.85, 0.2, 0.2, 0.55)
const DURACAO_FLASH_ERRO: float = 0.6

## Tempo em segundos que o destaque de dica permanece na tela.
@export var duracao_destaque: float = 2.5

## Lado máximo do tabuleiro em pixels. O tabuleiro é desenhado quadrado,
## centralizado, e nunca ultrapassa este valor (nem o tamanho do controle).
@export var tamanho_maximo_tabuleiro: float = 500.0

var _board: SudokuBoard
var _selecionada := Vector2i(-1, -1)
var _selecao_multi: Array[Vector2i] = []
var _modo_anotacao: bool = false
var _celula_destaque := Vector2i(-1, -1)
var _celula_candidato := Vector2i(-1, -1)
var _candidato_valor: int = 0
var _timer_dica: Timer
var _flash_erro_pos := Vector2i(-1, -1)
var _flash_erro_tempo: float = 0.0
var _estilo_fundo: StyleBoxFlat


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	resized.connect(queue_redraw)
	_estilo_fundo = StyleBoxFlat.new()
	_estilo_fundo.bg_color = Color(0.97, 0.98, 1, 1)
	_estilo_fundo.set_corner_radius_all(12)
	_estilo_fundo.border_color = Color(0.3, 0.35, 0.48, 1)
	_estilo_fundo.set_border_width_all(2)
	_timer_dica = Timer.new()
	_timer_dica.one_shot = true
	_timer_dica.timeout.connect(_ao_tempo_dica)
	add_child(_timer_dica)


func configurar(board: SudokuBoard) -> void:
	if _board != null and _board != board:
		if _board.celula_errada.is_connected(_ao_celula_errada):
			_board.celula_errada.disconnect(_ao_celula_errada)
	_board = board
	_selecionada = Vector2i(-1, -1)
	_selecao_multi.clear()
	_flash_erro_pos = Vector2i(-1, -1)
	_flash_erro_tempo = 0.0
	limpar_dicas_visuais()
	if not board.celula_errada.is_connected(_ao_celula_errada):
		board.celula_errada.connect(_ao_celula_errada)
	queue_redraw()


func definir_selecao(pos: Vector2i) -> void:
	if pos == _selecionada:
		return
	_selecionada = pos
	queue_redraw()


## Define o conjunto completo de células selecionadas (inclui a primária).
## Usado pela seleção múltipla por toque; a primária é destacada com mais
## intensidade pelo `definir_selecao`.
func definir_selecoes(celulas: Array) -> void:
	_selecao_multi.clear()
	for celula in celulas:
		_selecao_multi.append(celula as Vector2i)
	queue_redraw()


func definir_modo_anotacao(ativo: bool) -> void:
	_modo_anotacao = ativo
	queue_redraw()


func destacar_celula(pos: Vector2i) -> void:
	_celula_destaque = pos
	_agendar_limpeza_dica()
	queue_redraw()


func mostrar_candidato(pos: Vector2i, valor: int) -> void:
	_celula_candidato = pos
	_candidato_valor = valor
	_agendar_limpeza_dica()
	queue_redraw()


func limpar_dicas_visuais() -> void:
	_celula_destaque = Vector2i(-1, -1)
	_celula_candidato = Vector2i(-1, -1)
	_candidato_valor = 0
	queue_redraw()


## Agenda a remoção automática do destaque de dica após `duracao_destaque`.
## Como o timer é único e reiniciado, um novo destaque sempre anula o anterior.
func _agendar_limpeza_dica() -> void:
	if _timer_dica == null:
		return
	_timer_dica.wait_time = duracao_destaque
	_timer_dica.start()


func _ao_tempo_dica() -> void:
	limpar_dicas_visuais()


func _ao_celula_errada(_linha: int, _coluna: int, _valor: int) -> void:
	if not GameSettings.exibir_erros:
		return
	_flash_erro_pos = Vector2i(_linha, _coluna)
	_flash_erro_tempo = DURACAO_FLASH_ERRO
	queue_redraw()


func _process(delta: float) -> void:
	if _flash_erro_tempo <= 0.0:
		return
	_flash_erro_tempo -= delta
	if _flash_erro_tempo <= 0.0:
		_flash_erro_tempo = 0.0
		_flash_erro_pos = Vector2i(-1, -1)
	queue_redraw()


# --- Entrada ---

func _gui_input(evento: InputEvent) -> void:
	if _board == null:
		return
	if evento is InputEventScreenTouch and (evento as InputEventScreenTouch).pressed:
		var posicao := _celula_na_posicao((evento as InputEventScreenTouch).position)
		if posicao != Vector2i(-1, -1):
			celula_tocada_toggle.emit(posicao.x, posicao.y)
		return
	if evento is InputEventMouseButton and (evento as InputEventMouseButton).pressed \
			and (evento as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
		var posicao := _celula_na_posicao((evento as InputEventMouseButton).position)
		if posicao != Vector2i(-1, -1):
			celula_clicada.emit(posicao.x, posicao.y)


func _celula_na_posicao(posicao: Vector2) -> Vector2i:
	var lado := _lado_celula()
	if lado <= 0.0:
		return Vector2i(-1, -1)
	var local := posicao - _origem_tabuleiro()
	var linha := int(local.y / lado)
	var coluna := int(local.x / lado)
	if linha < 0 or linha >= SudokuBoard.TAMANHO or coluna < 0 or coluna >= SudokuBoard.TAMANHO:
		return Vector2i(-1, -1)
	return Vector2i(linha, coluna)


# --- Desenho ---

func _draw() -> void:
	if _board == null:
		return
	var lado := _lado_celula()
	var origem := _origem_tabuleiro()

	draw_style_box(_estilo_fundo, Rect2(origem, Vector2(lado * SudokuBoard.TAMANHO, lado * SudokuBoard.TAMANHO)))
	_desenhar_destaques(origem, lado)
	_desenhar_grade(origem, lado)
	_desenhar_conteudo(origem, lado)


func _desenhar_destaques(origem: Vector2, lado: float) -> void:
	for l in SudokuBoard.TAMANHO:
		for c in SudokuBoard.TAMANHO:
			var pos := Vector2i(l, c)
			var rect := _retangulo(pos, origem, lado)
			if _selecionada == pos:
				draw_rect(rect, COR_SELECIONADA)
			elif _selecao_multi.has(pos):
				draw_rect(rect, COR_SELECIONADA_MULTI)
			elif _celula_relacionada(pos):
				draw_rect(rect, COR_RELACIONADA)
			elif _tem_mesmo_valor(pos):
				draw_rect(rect, COR_IGUAL)
	if _celula_destaque != Vector2i(-1, -1):
		draw_rect(_retangulo(_celula_destaque, origem, lado), COR_DESTAQUE)
	if _flash_erro_tempo > 0.0 and _flash_erro_pos != Vector2i(-1, -1):
		var cor := COR_FLASH_ERRO
		cor.a *= clampf(_flash_erro_tempo / DURACAO_FLASH_ERRO, 0.0, 1.0)
		draw_rect(_retangulo(_flash_erro_pos, origem, lado), cor)


func _desenhar_grade(origem: Vector2, lado: float) -> void:
	for i in SudokuBoard.TAMANHO + 1:
		var forte: bool = i % SudokuBoard.TAMANHO_BLOCO == 0
		var cor := COR_LINHA_FORTE if forte else COR_LINHA
		var grossura: float = 3.0 if forte else 1.0
		var deslocamento := i * lado
		draw_line(origem + Vector2(deslocamento, 0), origem + Vector2(deslocamento, lado * SudokuBoard.TAMANHO), cor, grossura)
		draw_line(origem + Vector2(0, deslocamento), origem + Vector2(lado * SudokuBoard.TAMANHO, deslocamento), cor, grossura)


func _desenhar_conteudo(origem: Vector2, lado: float) -> void:
	for l in SudokuBoard.TAMANHO:
		for c in SudokuBoard.TAMANHO:
			var celula := _board.get_celula(l, c)
			var rect := _retangulo(Vector2i(l, c), origem, lado)
			if celula.esta_vazia():
				_desenhar_anotacoes(celula, rect, lado)
			else:
				var cor := COR_TEXTO_ORIGINAL if celula.original else COR_TEXTO_JOGADOR
				if celula.tem_erro and GameSettings.exibir_erros:
					cor = COR_ERRO
				_desenhar_numero(str(celula.valor_atual), rect, lado, cor, celula.original)

	if _celula_candidato != Vector2i(-1, -1):
		var rect := _retangulo(_celula_candidato, origem, lado)
		_desenhar_numero(str(_candidato_valor), rect, lado, COR_CANDIDATO, true)


func _desenhar_numero(texto: String, rect: Rect2, lado: float, cor: Color, negrito: bool) -> void:
	var fonte := get_theme_default_font()
	var tamanho: int = int(lado * (0.68 if negrito else 0.6))
	var ascenso := fonte.get_ascent(tamanho)
	var descenso := fonte.get_descent(tamanho)
	var pos := Vector2(
		rect.position.x,
		rect.position.y + rect.size.y / 2.0 + (ascenso - descenso) / 2.0
	)
	if negrito:
		draw_string(fonte, pos + Vector2(1, 0), texto, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x, tamanho, cor)
	draw_string(fonte, pos, texto, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x, tamanho, cor)


func _desenhar_anotacoes(celula: SudokuCell, rect: Rect2, lado: float) -> void:
	var anotacoes := celula.get_anotacoes()
	if anotacoes.is_empty():
		return
	var fonte := get_theme_default_font()
	var tamanho: int = maxi(8, int(lado * 0.24))
	var celula_mini := Vector2(lado / 3.0, lado / 3.0)
	for valor in anotacoes:
		var indice := valor - 1
		var mini_linha := indice / 3
		var mini_coluna := indice % 3
		var centro := rect.position + Vector2(
			(mini_coluna + 0.5) * celula_mini.x,
			(mini_linha + 0.5) * celula_mini.y
		)
		var ascenso := fonte.get_ascent(tamanho)
		var descenso := fonte.get_descent(tamanho)
		var pos := Vector2(
			centro.x - celula_mini.x / 2.0,
			centro.y + (ascenso - descenso) / 2.0
		)
		draw_string(fonte, pos, str(valor), HORIZONTAL_ALIGNMENT_CENTER, celula_mini.x, tamanho, COR_ANOTACAO)


# --- Utilidades de geometria ---

func _retangulo(pos: Vector2i, origem: Vector2, lado: float) -> Rect2:
	return Rect2(origem + Vector2(pos.y, pos.x) * lado, Vector2(lado, lado))


func _lado_celula() -> float:
	return floor(min(size.x, size.y, tamanho_maximo_tabuleiro) / SudokuBoard.TAMANHO)


func _origem_tabuleiro() -> Vector2:
	var lado := _lado_celula()
	var total := lado * SudokuBoard.TAMANHO
	return Vector2((size.x - total) / 2.0, (size.y - total) / 2.0)


func _celula_relacionada(pos: Vector2i) -> bool:
	if _selecionada.x < 0:
		return false
	if pos == _selecionada:
		return false
	if pos.x == _selecionada.x or pos.y == _selecionada.y:
		return true
	var bloco_linha: int = (_selecionada.x / SudokuBoard.TAMANHO_BLOCO) * SudokuBoard.TAMANHO_BLOCO
	var bloco_coluna: int = (_selecionada.y / SudokuBoard.TAMANHO_BLOCO) * SudokuBoard.TAMANHO_BLOCO
	return pos.x >= bloco_linha and pos.x < bloco_linha + SudokuBoard.TAMANHO_BLOCO \
		and pos.y >= bloco_coluna and pos.y < bloco_coluna + SudokuBoard.TAMANHO_BLOCO


func _tem_mesmo_valor(pos: Vector2i) -> bool:
	if _selecionada.x < 0 or _board == null:
		return false
	var valor := _board.get_valor(_selecionada.x, _selecionada.y)
	return valor != 0 and _board.get_valor(pos.x, pos.y) == valor
