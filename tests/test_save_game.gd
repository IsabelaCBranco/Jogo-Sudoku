extends GutTest
## Testes de persistência da partida (Fase 6).


func before_each() -> void:
	GameSession.limpar()
	GameSession.definir_nova_partida(DifficultyManager.Dificuldade.FACIL)
	GameSettings.definir_vidas(true)
	GameSettings.definir_anotacoes(true)
	HintProgression.reset()
	var dir := OS.get_environment("TEMP") + "/gut_partida_" + str(Time.get_ticks_usec()) + "/"
	DirAccess.make_dir_recursive_absolute(dir)
	SaveManager.set_caminho_base(dir)


func after_each() -> void:
	SaveManager.set_caminho_base("user://")


func _instanciar() -> GameController:
	var jogo := GameController.new()
	add_child_autofree(jogo)
	return jogo


func _primeira_celula_editavel_vazia(board: SudokuBoard) -> Vector2i:
	for l in SudokuBoard.TAMANHO:
		for c in SudokuBoard.TAMANHO:
			if not board.esta_bloqueada(l, c) and board.esta_vazia(l, c):
				return Vector2i(l, c)
	return Vector2i(-1, -1)


func _mover_selecao_para(controller: GameController, alvo: Vector2i) -> void:
	var atual: Vector2i = controller.get_celula_selecionada()
	var delta := alvo - atual
	if delta != Vector2i.ZERO:
		controller.mover_selecao(delta)
	assert_eq(controller.get_celula_selecionada(), alvo)


func _valor_errado_para(solucao: int) -> int:
	return 2 if solucao == 1 else 1


# --- Estrutura do salvamento ---

func test_serializar_contem_estrutura() -> void:
	var jogo := _instanciar()
	var dados := jogo.serializar_partida()
	assert_eq(dados["versao"], 1)
	assert_true(dados.has("tabuleiro"))
	assert_true(dados.has("solucao"))
	assert_true(dados.has("originais"))
	assert_true(dados.has("anotacoes"))
	assert_true(dados.has("historico"))
	assert_true(dados.has("score"))
	assert_true(dados.has("vidas"))
	assert_true(dados.has("tempo"))


func test_continuar_sem_save_retorna_falso() -> void:
	var jogo := _instanciar()
	assert_false(jogo.continuar_partida())


func test_continuar_com_save_invalido_descarta_e_retorna_falso() -> void:
	var jogo := _instanciar()
	SaveManager.salvar_partida({"versao": 1, "tabuleiro": "lixo"})
	assert_true(SaveManager.existe_partida_salva())
	assert_false(jogo.continuar_partida())
	assert_false(SaveManager.existe_partida_salva())


func test_continuar_com_versao_incompativel_descarta() -> void:
	var jogo := _instanciar()
	SaveManager.salvar_partida({"versao": 99, "tabuleiro": [], "solucao": [], "originais": []})
	assert_false(jogo.continuar_partida())
	assert_false(SaveManager.existe_partida_salva())


func test_salvar_e_apagar_partida() -> void:
	var jogo := _instanciar()
	jogo.salvar_partida()
	assert_true(SaveManager.existe_partida_salva())
	jogo.apagar_partida_salva()
	assert_false(SaveManager.existe_partida_salva())


# --- Round trip completo ---

func test_round_trip_restaura_estado_completo() -> void:
	var jogo_a := _instanciar()
	var board_a: SudokuBoard = jogo_a.board
	HintProgression.registrar_vitoria(DifficultyManager.Dificuldade.FACIL)

	var alvo := _primeira_celula_editavel_vazia(board_a)
	_mover_selecao_para(jogo_a, alvo)
	jogo_a.inserir_numero(board_a.get_valor_solucao(alvo.x, alvo.y))

	var alvo_erro := _primeira_celula_editavel_vazia(board_a)
	_mover_selecao_para(jogo_a, alvo_erro)
	var valor_errado := _valor_errado_para(board_a.get_valor_solucao(alvo_erro.x, alvo_erro.y))
	jogo_a.inserir_numero(valor_errado)

	var alvo_nota := _primeira_celula_editavel_vazia(board_a)
	_mover_selecao_para(jogo_a, alvo_nota)
	jogo_a.alternar_modo_anotacao()
	jogo_a.inserir_numero(board_a.get_valor_solucao(alvo_nota.x, alvo_nota.y))

	jogo_a.pedir_dica(HintSystem.DICA_CONTAR)

	_mover_selecao_para(jogo_a, alvo)
	jogo_a.inserir_numero(board_a.get_valor_solucao(alvo.x, alvo.y))
	jogo_a.desfazer()

	jogo_a.salvar_partida()
	var tabuleiro_esperado := board_a.get_tabuleiro_atual()
	var notas_esperadas: Array = []
	for l in 9:
		var fileira: Array = []
		for c in 9:
			fileira.append(board_a.get_anotacoes(l, c))
		notas_esperadas.append(fileira)
	var pode_desfazer := jogo_a.pode_desfazer()
	var pode_refazer := jogo_a.pode_refazer()
	var vidas_esperadas := jogo_a.get_vidas()
	var erros_esperados := jogo_a.score.get_erros()
	var dicas_esperadas := jogo_a.score.get_total_dicas()

	jogo_a.queue_free()
	await wait_physics_frames(2)

	GameSession.definir_continuar()
	var jogo_b := _instanciar()
	assert_true(jogo_b.continuar_partida())

	assert_eq(jogo_b.board.get_tabuleiro_atual(), tabuleiro_esperado)
	assert_true(jogo_b.board.tem_erro(alvo_erro.x, alvo_erro.y))
	for l in 9:
		for c in 9:
			assert_eq(jogo_b.board.get_anotacoes(l, c), notas_esperadas[l][c])
	assert_eq(jogo_b.get_vidas(), vidas_esperadas)
	assert_eq(jogo_b.score.get_erros(), erros_esperados)
	assert_eq(jogo_b.score.get_total_dicas(), dicas_esperadas)
	assert_eq(jogo_b.get_modo_anotacao(), true)
	assert_eq(jogo_b.pode_desfazer(), pode_desfazer)
	assert_eq(jogo_b.pode_refazer(), pode_refazer)
	assert_eq(jogo_b.get_celula_selecionada(), alvo)


func test_continuar_preserva_undo_redo() -> void:
	var jogo_a := _instanciar()
	var board_a: SudokuBoard = jogo_a.board

	var alvo := _primeira_celula_editavel_vazia(board_a)
	_mover_selecao_para(jogo_a, alvo)
	var valor := board_a.get_valor_solucao(alvo.x, alvo.y)
	jogo_a.inserir_numero(valor)
	jogo_a.desfazer()

	jogo_a.salvar_partida()
	jogo_a.queue_free()
	await wait_physics_frames(2)

	GameSession.definir_continuar()
	var jogo_b := _instanciar()
	assert_true(jogo_b.continuar_partida())
	assert_true(jogo_b.board.esta_vazia(alvo.x, alvo.y))
	assert_true(jogo_b.pode_refazer())
	assert_true(jogo_b.refazer())
	assert_eq(jogo_b.board.get_valor(alvo.x, alvo.y), valor)


func test_continuar_restaura_pausa_emitindo_sinal() -> void:
	var jogo_a := _instanciar()
	jogo_a.alternar_pausa()
	assert_true(jogo_a.esta_pausado())
	assert_true(SaveManager.existe_partida_salva())
	jogo_a.queue_free()
	await wait_physics_frames(2)

	GameSession.definir_continuar()
	var jogo_b := GameController.new()
	watch_signals(jogo_b)
	add_child_autofree(jogo_b)
	assert_true(jogo_b.esta_pausado())
	assert_false(jogo_b.timer.esta_rodando())
	assert_signal_emitted_with_parameters(jogo_b, "pausa_alterada", [true])


# --- Vitória apaga o save ---

func test_vitoria_apaga_partida_salva() -> void:
	var jogo := _instanciar()
	jogo.salvar_partida()
	assert_true(SaveManager.existe_partida_salva())

	for l in SudokuBoard.TAMANHO:
		for c in SudokuBoard.TAMANHO:
			if not jogo.board.esta_bloqueada(l, c) and jogo.board.esta_vazia(l, c):
				jogo.board.definir_valor(l, c, jogo.board.get_valor_solucao(l, c))

	assert_true(jogo.esta_terminado())
	assert_false(SaveManager.existe_partida_salva())


# --- Serialização dos sistemas ---

func test_score_serializar_restaurar() -> void:
	var score_a := ScoreSystem.new()
	score_a.iniciar(DifficultyManager.Dificuldade.DIFICIL)
	score_a.registrar_erro()
	score_a.registrar_dica(HintSystem.DICA_CANDIDATO)
	score_a.atualizar_tempo(30)
	var dados := score_a.serializar()

	var score_b := ScoreSystem.new()
	score_b.carregar_estado(dados)
	assert_eq(score_b.dificuldade, DifficultyManager.Dificuldade.DIFICIL)
	assert_eq(score_b.get_erros(), 1)
	assert_eq(score_b.get_total_dicas(), 1)
	assert_eq(score_b.get_pontuacao(), score_a.get_pontuacao())


func test_lives_serializar_restaurar() -> void:
	var lives_a := LivesSystem.new()
	lives_a.iniciar()
	lives_a.perder_vida()
	var dados := lives_a.serializar()

	var lives_b := LivesSystem.new()
	lives_b.carregar_estado(dados)
	assert_eq(lives_b.get_vidas(), 2)
	assert_true(lives_b.vidas_ativadas)


func test_lives_desativado_serializar() -> void:
	var lives_a := LivesSystem.new()
	lives_a.iniciar(false)
	var dados := lives_a.serializar()

	var lives_b := LivesSystem.new()
	lives_b.carregar_estado(dados)
	assert_false(lives_b.vidas_ativadas)
	assert_eq(lives_b.get_vidas(), 3)


func test_timer_definir_segundos() -> void:
	var timer := TimerSystem.new()
	timer.iniciar()
	timer.pausar()
	watch_signals(timer)
	timer.definir_segundos(42)
	assert_eq(timer.get_segundos(), 42)
	assert_signal_emitted_with_parameters(timer, "tempo_alterado", [42])


func test_move_history_serializar_restaurar() -> void:
	var board := SudokuBoard.new(
		[[0, 0, 0, 0, 0, 0, 0, 0, 0],
		[0, 0, 0, 0, 0, 0, 0, 0, 0],
		[0, 0, 0, 0, 0, 0, 0, 0, 0],
		[0, 0, 0, 0, 0, 0, 0, 0, 0],
		[0, 0, 0, 0, 0, 0, 0, 0, 0],
		[0, 0, 0, 0, 0, 0, 0, 0, 0],
		[0, 0, 0, 0, 0, 0, 0, 0, 0],
		[0, 0, 0, 0, 0, 0, 0, 0, 0],
		[0, 0, 0, 0, 0, 0, 0, 0, 0]],
		[[1, 2, 3, 4, 5, 6, 7, 8, 9],
		[4, 5, 6, 7, 8, 9, 1, 2, 3],
		[7, 8, 9, 1, 2, 3, 4, 5, 6],
		[2, 3, 4, 5, 6, 7, 8, 9, 1],
		[5, 6, 7, 8, 9, 1, 2, 3, 4],
		[8, 9, 1, 2, 3, 4, 5, 6, 7],
		[3, 4, 5, 6, 7, 8, 9, 1, 2],
		[6, 7, 8, 9, 1, 2, 3, 4, 5],
		[9, 1, 2, 3, 4, 5, 6, 7, 8]],
		[[0, 0, 0, 0, 0, 0, 0, 0, 0],
		[0, 0, 0, 0, 0, 0, 0, 0, 0],
		[0, 0, 0, 0, 0, 0, 0, 0, 0],
		[0, 0, 0, 0, 0, 0, 0, 0, 0],
		[0, 0, 0, 0, 0, 0, 0, 0, 0],
		[0, 0, 0, 0, 0, 0, 0, 0, 0],
		[0, 0, 0, 0, 0, 0, 0, 0, 0],
		[0, 0, 0, 0, 0, 0, 0, 0, 0],
		[0, 0, 0, 0, 0, 0, 0, 0, 0]]
	)
	var history_a := MoveHistory.new(board)
	var antes := history_a.snapshot()
	board.definir_valor(0, 0, 1)
	history_a.registrar(antes)
	var dados := history_a.serializar()

	var history_b := MoveHistory.new(board)
	history_b.carregar_estado(dados)
	assert_true(history_b.pode_desfazer())
	assert_true(history_b.desfazer())
	assert_true(board.esta_vazia(0, 0))
