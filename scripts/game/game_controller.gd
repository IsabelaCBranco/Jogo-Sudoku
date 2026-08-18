class_name GameController
extends Node
## Orquestra uma partida de Sudoku.
##
## Gera o puzzle, cria o tabuleiro e os sistemas, processa a entrada do
## jogador e coordena vitória/derrota. A UI apenas observa os sinais e
## apresenta o estado; nenhuma regra de negócio vive na interface.

signal estado_alterado
signal selecao_alterada(pos: Vector2i)
signal vitoria(pontos: int)
signal derrota
signal vida_alterada(vidas: int)
signal tempo_alterado(segundos: int)
signal pontuacao_alterada(pontos: int)
signal historico_alterado(pode_desfazer: bool, pode_refazer: bool)
signal modo_anotacao_alterado(ativo: bool)
signal pausa_alterada(ativo: bool)
signal dica_contagem(pos: Vector2i, quantidade: int)
signal dica_candidato(pos: Vector2i, valor: int)
signal dicas_alteradas
signal reinicio_solicitado
signal reinicio_cancelado

@export var dificuldade_inicial: int = DifficultyManager.Dificuldade.FACIL
@export var seed_partida: int = -1

const VERSAO_SALVAMENTO: int = 1
const INTERVALO_AUTOSAVE: float = 15.0

var board: SudokuBoard
var lives: LivesSystem
var timer: TimerSystem
var score: ScoreSystem
var history: MoveHistory

var dificuldade: int = DifficultyManager.Dificuldade.FACIL

var _celula_selecionada := Vector2i(0, 0)
var _modo_anotacao: bool = false
var _pausado: bool = false
var _terminado: bool = false
var _segundos_ate_salvar: float = 0.0
var _dialogo_reinicio_aberto: bool = false
var _reinicio_abriu_pausa: bool = false


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	HintProgression.dicas_alteradas.connect(_ao_dicas_alteradas)
	if GameSession.continuar:
		GameSession.continuar = false
		if continuar_partida():
			return
	iniciar_partida(GameSession.dificuldade_selecionada, seed_partida)


func _process(delta: float) -> void:
	if timer != null:
		timer.atualizar(delta)
		if timer.esta_rodando() and not _terminado:
			_segundos_ate_salvar += delta
			if _segundos_ate_salvar >= INTERVALO_AUTOSAVE:
				_segundos_ate_salvar = 0.0
				salvar_partida()


func _notification(o_que: int) -> void:
	if o_que == NOTIFICATION_WM_CLOSE_REQUEST and board != null and not _terminado:
		salvar_partida()


# --- Início de partida ---

func iniciar_partida(dificuldade: int, seed: int = -1) -> void:
	self.dificuldade = dificuldade
	_terminado = false
	_pausado = false
	_modo_anotacao = false
	_dialogo_reinicio_aberto = false
	_reinicio_abriu_pausa = false
	apagar_partida_salva()
	pausa_alterada.emit(false)
	modo_anotacao_alterado.emit(false)

	var resultado := SudokuGenerator.gerar(dificuldade, seed)
	board = SudokuBoard.new(resultado["tabuleiro"], resultado["solucao"], resultado["originais"])

	lives = LivesSystem.new()
	timer = TimerSystem.new()
	score = ScoreSystem.new()
	history = MoveHistory.new(board)

	lives.iniciar(GameSettings.vidas_ativadas)
	score.iniciar(dificuldade)

	_conectar_sistemas()
	timer.iniciar()
	_selecionar(Vector2i(0, 0))
	StatisticsSystem.registrar_partida_iniciada()

	_conectar_view()
	estado_alterado.emit()
	historico_alterado.emit(history.pode_desfazer(), history.pode_refazer())


func _conectar_sistemas() -> void:
	board.celula_errada.connect(_ao_celula_errada)
	board.vitoria.connect(_ao_vitoria)
	lives.vidas_alteradas.connect(_ao_vidas_alteradas)
	lives.vidas_zeradas.connect(_ao_vidas_zeradas)
	timer.tempo_alterado.connect(_ao_tempo_alterado)
	score.pontuacao_alterada.connect(_ao_pontuacao_alterada)
	history.historico_alterado.connect(_ao_historico_alterado)


func _conectar_view() -> void:
	var no_view := get_node_or_null("SudokuBoard")
	if not no_view is SudokuBoardView:
		return
	var view := no_view as SudokuBoardView
	view.configurar(board)
	if not view.celula_clicada.is_connected(_selecionar_pela_view):
		view.celula_clicada.connect(_selecionar_pela_view)
	if not selecao_alterada.is_connected(view.definir_selecao):
		selecao_alterada.connect(view.definir_selecao)
	if not modo_anotacao_alterado.is_connected(view.definir_modo_anotacao):
		modo_anotacao_alterado.connect(view.definir_modo_anotacao)
	if not dica_contagem.is_connected(view.mostrar_contagem):
		dica_contagem.connect(view.mostrar_contagem)
	if not dica_candidato.is_connected(view.mostrar_candidato):
		dica_candidato.connect(view.mostrar_candidato)
	if not estado_alterado.is_connected(view.queue_redraw):
		estado_alterado.connect(view.queue_redraw)
	view.definir_selecao(_celula_selecionada)


func _selecionar_pela_view(linha: int, coluna: int) -> void:
	_selecionar(Vector2i(linha, coluna))


# --- Persistência da partida ---

func serializar_partida() -> Dictionary:
	return {
		"versao": VERSAO_SALVAMENTO,
		"dificuldade": dificuldade,
		"seed": seed_partida,
		"tabuleiro": board.get_tabuleiro_atual(),
		"solucao": board.get_solucao(),
		"originais": board.get_mascara_originais(),
		"anotacoes": _serializar_anotacoes(),
		"celula_selecionada": [_celula_selecionada.x, _celula_selecionada.y],
		"modo_anotacao": _modo_anotacao,
		"pausado": _pausado,
		"terminado": _terminado,
		"vidas": lives.serializar(),
		"tempo": timer.get_segundos(),
		"score": score.serializar(),
		"historico": history.serializar(),
	}


func salvar_partida() -> void:
	if board == null or _terminado:
		return
	SaveManager.salvar_partida(serializar_partida())


func apagar_partida_salva() -> void:
	SaveManager.apagar_partida()


func continuar_partida() -> bool:
	var dados := SaveManager.carregar_partida()
	if dados.is_empty():
		return false
	if not _validar_dados_partida(dados):
		push_warning("Partida salva inválida ou em versão incompatível; descartada.")
		apagar_partida_salva()
		return false

	dificuldade = int(dados.get("dificuldade", DifficultyManager.Dificuldade.FACIL))
	seed_partida = int(dados.get("seed", -1))
	board = SudokuBoard.new(dados["tabuleiro"], dados["solucao"], dados["originais"])

	lives = LivesSystem.new()
	timer = TimerSystem.new()
	score = ScoreSystem.new()
	history = MoveHistory.new(board)

	lives.carregar_estado(dados.get("vidas", {}))
	timer.definir_segundos(int(dados.get("tempo", 0)))
	score.carregar_estado(dados.get("score", {}))
	history.carregar_estado(dados.get("historico", {}))

	_restaurar_anotacoes(dados.get("anotacoes", []))
	var selecao: Variant = dados.get("celula_selecionada", [0, 0])
	if selecao is Array and (selecao as Array).size() >= 2:
		_celula_selecionada = Vector2i(int(selecao[0]), int(selecao[1]))
	else:
		_celula_selecionada = Vector2i.ZERO
	_modo_anotacao = bool(dados.get("modo_anotacao", false))
	_pausado = bool(dados.get("pausado", false))
	_terminado = bool(dados.get("terminado", false))
	_dialogo_reinicio_aberto = false
	_reinicio_abriu_pausa = false
	modo_anotacao_alterado.emit(_modo_anotacao)
	pausa_alterada.emit(_pausado)

	_conectar_sistemas()
	if _pausado:
		timer.pausar()
	else:
		timer.retomar()
	_segundos_ate_salvar = 0.0

	_conectar_view()
	estado_alterado.emit()
	historico_alterado.emit(history.pode_desfazer(), history.pode_refazer())
	return true


func _serializar_anotacoes() -> Array:
	var notas: Array = []
	for l in SudokuBoard.TAMANHO:
		var fileira: Array = []
		for c in SudokuBoard.TAMANHO:
			fileira.append(board.get_anotacoes(l, c))
		notas.append(fileira)
	return notas


func _restaurar_anotacoes(notas: Variant) -> void:
	if not notas is Array:
		return
	for l in notas.size():
		if not notas[l] is Array:
			continue
		for c in notas[l].size():
			var celula := board.get_celula(l, c)
			if celula.esta_vazia():
				for valor in notas[l][c]:
					celula.adicionar_anotacao(int(valor))


func _validar_dados_partida(dados: Dictionary) -> bool:
	if int(dados.get("versao", -1)) != VERSAO_SALVAMENTO:
		return false
	return _matriz_valida(dados.get("tabuleiro")) and _matriz_valida(dados.get("solucao")) \
		and _matriz_valida(dados.get("originais"))


func _matriz_valida(matriz: Variant) -> bool:
	if not matriz is Array:
		return false
	var linhas := matriz as Array
	if linhas.size() != SudokuBoard.TAMANHO:
		return false
	for linha in linhas:
		if not linha is Array or (linha as Array).size() != SudokuBoard.TAMANHO:
			return false
	return true


# --- Ações do jogador ---

func inserir_numero(valor: int) -> bool:
	if _terminado or _pausado or board == null:
		return false
	if valor < 1 or valor > 9:
		return false

	var pos := _celula_selecionada
	if _modo_anotacao and GameSettings.anotacoes_ativadas:
		return _alternar_anotacao(pos, valor)

	if board.esta_bloqueada(pos.x, pos.y):
		return false

	var antes := history.snapshot()
	if board.get_valor(pos.x, pos.y) == valor:
		if not board.remover_valor(pos.x, pos.y):
			return false
		AudioManager.tocar_efeito(AudioManager.Tipo.APAGAR)
	else:
		if not board.definir_valor(pos.x, pos.y, valor):
			return false
		if not board.get_celula(pos.x, pos.y).tem_erro:
			AudioManager.tocar_efeito(AudioManager.Tipo.INSERIR)
	history.registrar(antes)
	estado_alterado.emit()
	return true


func apagar_celula() -> bool:
	if _terminado or _pausado or board == null:
		return false
	var pos := _celula_selecionada
	if board.esta_bloqueada(pos.x, pos.y):
		return false
	if board.esta_vazia(pos.x, pos.y):
		return false

	var antes := history.snapshot()
	if not board.remover_valor(pos.x, pos.y):
		return false
	AudioManager.tocar_efeito(AudioManager.Tipo.APAGAR)
	history.registrar(antes)
	estado_alterado.emit()
	return true


func desfazer() -> bool:
	if _terminado or _pausado or history == null:
		return false
	if not history.desfazer():
		return false
	AudioManager.tocar_efeito(AudioManager.Tipo.DESFAZER)
	estado_alterado.emit()
	return true


func refazer() -> bool:
	if _terminado or _pausado or history == null:
		return false
	if not history.refazer():
		return false
	AudioManager.tocar_efeito(AudioManager.Tipo.REFAZER)
	estado_alterado.emit()
	return true


func pedir_dica(nivel: int) -> bool:
	if _terminado or _pausado or board == null:
		return false
	if not HintProgression.pode_usar(nivel):
		return false
	var alvo := _celula_selecionada

	match nivel:
		HintSystem.DICA_CONTAR:
			var info := HintSystem.get_contagem_candidatos(board, alvo)
			if info.is_empty():
				return false
			var celula: Vector2i = info["celula"]
			var quantidade: int = info["quantidade"]
			dica_contagem.emit(celula, quantidade)
		HintSystem.DICA_CANDIDATO:
			var info := HintSystem.get_candidato(board, alvo)
			if info.is_empty():
				return false
			var celula: Vector2i = info["celula"]
			dica_candidato.emit(celula, int(info["valor"]))
		HintSystem.DICA_RESOLVER:
			var celula := HintSystem.get_celula_resolvivel(board, alvo)
			if celula == HintSystem.CELULA_INVALIDA:
				return false
			var antes := history.snapshot()
			board.definir_valor(celula.x, celula.y, board.get_valor_solucao(celula.x, celula.y))
			history.registrar(antes)
			estado_alterado.emit()
		_:
			return false

	HintProgression.consumir(nivel)
	score.registrar_dica(nivel)
	AudioManager.tocar_efeito(AudioManager.Tipo.DICA)
	return true


func solicitar_reinicio() -> void:
	if board == null or _terminado or _dialogo_reinicio_aberto:
		return
	_dialogo_reinicio_aberto = true
	_reinicio_abriu_pausa = _pausado
	if not _pausado:
		alternar_pausa()
	reinicio_solicitado.emit()


func cancelar_reinicio() -> void:
	if not _dialogo_reinicio_aberto:
		return
	_dialogo_reinicio_aberto = false
	if not _reinicio_abriu_pausa and _pausado:
		alternar_pausa()
	reinicio_cancelado.emit()


func reiniciar_partida() -> void:
	if board == null:
		return
	_dialogo_reinicio_aberto = false
	_reinicio_abriu_pausa = false
	_terminado = false
	_pausado = false
	_modo_anotacao = false
	board.reiniciar()
	history.limpar()
	lives.reiniciar()
	score.reiniciar()
	timer.iniciar()
	_segundos_ate_salvar = 0.0
	pausa_alterada.emit(false)
	modo_anotacao_alterado.emit(false)
	estado_alterado.emit()
	historico_alterado.emit(history.pode_desfazer(), history.pode_refazer())
	salvar_partida()


func reiniciar_com_novo_puzzle() -> void:
	if board == null:
		return
	iniciar_partida(dificuldade)


func alternar_pausa() -> void:
	if _terminado:
		return
	_pausado = not _pausado
	if _pausado:
		timer.pausar()
		salvar_partida()
	else:
		timer.retomar()
	pausa_alterada.emit(_pausado)


func alternar_modo_anotacao() -> void:
	_modo_anotacao = not _modo_anotacao
	modo_anotacao_alterado.emit(_modo_anotacao)


func mover_selecao(direcao: Vector2i) -> void:
	_selecionar(_celula_selecionada + direcao)


# --- Acessores para a UI ---

func get_celula_selecionada() -> Vector2i:
	return _celula_selecionada


func get_modo_anotacao() -> bool:
	return _modo_anotacao


func esta_terminado() -> bool:
	return _terminado


func esta_pausado() -> bool:
	return _pausado


func get_vidas() -> int:
	return lives.get_vidas()


func get_tempo() -> int:
	return timer.get_segundos()


func get_pontuacao() -> int:
	return score.get_pontuacao()


func get_erros() -> int:
	return score.get_erros()


func get_progresso() -> int:
	return board.contar_preenchidas()


func pode_desfazer() -> bool:
	return history.pode_desfazer()


func pode_refazer() -> bool:
	return history.pode_refazer()


func get_dicas_restantes(nivel: int) -> int:
	return HintProgression.get_disponiveis(nivel)


# --- Sinais do tabuleiro/sistemas ---

func _ao_celula_errada(_linha: int, _coluna: int, _valor: int) -> void:
	if _terminado:
		return
	AudioManager.tocar_efeito(AudioManager.Tipo.ERRO)
	score.registrar_erro()
	if lives.perder_vida():
		vida_alterada.emit(lives.get_vidas())


func _ao_vitoria() -> void:
	if _terminado:
		return
	_terminado = true
	timer.parar()
	AudioManager.tocar_efeito(AudioManager.Tipo.VITORIA)
	var pontos := score.calcular_final(lives.get_vidas())
	HintProgression.registrar_vitoria(dificuldade)
	GameSession.registrar_vitoria(pontos, timer.get_segundos(), lives.get_vidas(), dificuldade, score.get_erros(), score.get_total_dicas())
	StatisticsSystem.registrar_vitoria(dificuldade, timer.get_segundos(), pontos, score.get_erros(), score.get_total_dicas())
	apagar_partida_salva()
	vitoria.emit(pontos)


func _ao_vidas_zeradas() -> void:
	if _terminado:
		return
	_terminado = true
	timer.parar()
	AudioManager.tocar_efeito(AudioManager.Tipo.DERROTA)
	GameSession.registrar_derrota(timer.get_segundos(), dificuldade, score.get_erros(), score.get_total_dicas())
	StatisticsSystem.registrar_derrota(dificuldade, score.get_erros(), score.get_total_dicas())
	apagar_partida_salva()
	derrota.emit()


func _ao_tempo_alterado(segundos: int) -> void:
	score.atualizar_tempo(segundos)
	tempo_alterado.emit(segundos)


func _ao_pontuacao_alterada(pontos: int) -> void:
	pontuacao_alterada.emit(pontos)


func _ao_vidas_alteradas(vidas: int) -> void:
	vida_alterada.emit(vidas)


func _ao_historico_alterado() -> void:
	historico_alterado.emit(history.pode_desfazer(), history.pode_refazer())


func _ao_dicas_alteradas() -> void:
	dicas_alteradas.emit()


# --- Internos ---

func _alternar_anotacao(pos: Vector2i, valor: int) -> bool:
	var celula := board.get_celula(pos.x, pos.y)
	if celula.original or not celula.esta_vazia():
		return false

	var antes := history.snapshot()
	if board.tem_anotacao(pos.x, pos.y, valor):
		board.remover_anotacao(pos.x, pos.y, valor)
	else:
		board.adicionar_anotacao(pos.x, pos.y, valor)
	history.registrar(antes)
	estado_alterado.emit()
	return true


func _selecionar(pos: Vector2i) -> void:
	if pos.x < 0 or pos.x >= SudokuBoard.TAMANHO or pos.y < 0 or pos.y >= SudokuBoard.TAMANHO:
		return
	_celula_selecionada = pos
	AudioManager.tocar_efeito(AudioManager.Tipo.SELECIONAR)
	selecao_alterada.emit(pos)


func _unhandled_input(evento: InputEvent) -> void:
	if not (evento is InputEventKey and evento.pressed and not evento.echo):
		return

	var tecla := (evento as InputEventKey).keycode
	if _dialogo_reinicio_aberto:
		if tecla == KEY_ESCAPE:
			cancelar_reinicio()
		return
	match tecla:
		KEY_UP, KEY_W:
			mover_selecao(Vector2i(-1, 0))
		KEY_DOWN, KEY_S:
			mover_selecao(Vector2i(1, 0))
		KEY_LEFT, KEY_A:
			mover_selecao(Vector2i(0, -1))
		KEY_RIGHT, KEY_D:
			mover_selecao(Vector2i(0, 1))
		KEY_BACKSPACE, KEY_DELETE:
			apagar_celula()
		KEY_Z:
			if (evento as InputEventKey).ctrl_pressed:
				if (evento as InputEventKey).shift_pressed:
					refazer()
				else:
					desfazer()
		KEY_Y:
			if (evento as InputEventKey).ctrl_pressed:
				refazer()
		KEY_N:
			alternar_modo_anotacao()
		KEY_H:
			pedir_dica(HintSystem.DICA_RESOLVER)
		KEY_P, KEY_ESCAPE:
			alternar_pausa()
		KEY_R:
			solicitar_reinicio()
		_:
			if tecla >= KEY_1 and tecla <= KEY_9:
				inserir_numero(tecla - KEY_0)
			elif tecla >= KEY_KP_1 and tecla <= KEY_KP_9:
				inserir_numero(tecla - KEY_KP_1 + 1)
