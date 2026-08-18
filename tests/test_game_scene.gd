extends GutTest
## Teste de fumaça: a cena principal carrega e o controller funciona.


func before_each() -> void:
	GameSession.limpar()
	GameSession.definir_nova_partida(DifficultyManager.Dificuldade.FACIL)
	GameSettings.definir_vidas(true)
	GameSettings.definir_anotacoes(true)
	GameSettings.definir_som(true)
	AudioManager.ultimo_efeito = AudioManager.Tipo.NENHUM
	HintProgression.reset()
	var dir := OS.get_environment("TEMP") + "/gut_cena_" + str(Time.get_ticks_usec()) + "/"
	DirAccess.make_dir_recursive_absolute(dir)
	SaveManager.set_caminho_base(dir)


func after_each() -> void:
	SaveManager.set_caminho_base("user://")


func _instanciar() -> Node:
	var cena := load("res://scenes/game/game.tscn") as PackedScene
	assert_not_null(cena)
	var instancia: Node = cena.instantiate()
	add_child_autofree(instancia)
	return instancia


func _primeira_celula_editavel_vazia(board: SudokuBoard) -> Vector2i:
	for l in SudokuBoard.TAMANHO:
		for c in SudokuBoard.TAMANHO:
			if not board.esta_bloqueada(l, c) and board.esta_vazia(l, c):
				return Vector2i(l, c)
	return Vector2i(-1, -1)


func test_cena_gera_tabuleiro() -> void:
	var jogo := _instanciar()
	await wait_physics_frames(2)
	var controller := jogo as GameController
	assert_not_null(controller.board)
	assert_false(controller.board.esta_completa())
	assert_eq(controller.board.get_mascara_originais().size(), 9)
	assert_eq(controller.get_vidas(), 3)


func test_inserir_desfazer_refazer() -> void:
	var jogo := _instanciar()
	await wait_physics_frames(2)
	var controller := jogo as GameController
	var alvo := _primeira_celula_editavel_vazia(controller.board)
	assert_ne(alvo, Vector2i(-1, -1))

	for i in alvo.x:
		controller.mover_selecao(Vector2i(1, 0))
	for i in alvo.y:
		controller.mover_selecao(Vector2i(0, 1))
	assert_eq(controller.get_celula_selecionada(), alvo)

	var valor := controller.board.get_valor_solucao(alvo.x, alvo.y)
	assert_true(controller.inserir_numero(valor))
	assert_eq(controller.board.get_valor(alvo.x, alvo.y), valor)

	assert_true(controller.desfazer())
	assert_true(controller.board.esta_vazia(alvo.x, alvo.y))

	assert_true(controller.refazer())
	assert_eq(controller.board.get_valor(alvo.x, alvo.y), valor)


func test_inserir_valor_correto_toca_efeito() -> void:
	var jogo := _instanciar()
	await wait_physics_frames(2)
	var controller := jogo as GameController
	var alvo := _primeira_celula_editavel_vazia(controller.board)
	controller.mover_selecao(alvo - controller.get_celula_selecionada())
	controller.inserir_numero(controller.board.get_valor_solucao(alvo.x, alvo.y))
	assert_eq(AudioManager.ultimo_efeito, AudioManager.Tipo.INSERIR)


func test_inserir_valor_errado_toca_efeito_de_erro() -> void:
	var jogo := _instanciar()
	await wait_physics_frames(2)
	var controller := jogo as GameController
	var alvo := _primeira_celula_editavel_vazia(controller.board)
	controller.mover_selecao(alvo - controller.get_celula_selecionada())
	var solucao: int = controller.board.get_valor_solucao(alvo.x, alvo.y)
	controller.inserir_numero(2 if solucao == 1 else 1)
	assert_eq(AudioManager.ultimo_efeito, AudioManager.Tipo.ERRO)


func test_tecla_numpad_insere_valor() -> void:
	var jogo := _instanciar()
	await wait_physics_frames(2)
	var controller := jogo as GameController
	var alvo := _primeira_celula_editavel_vazia(controller.board)
	controller.mover_selecao(alvo - controller.get_celula_selecionada())

	var valor: int = controller.board.get_valor_solucao(alvo.x, alvo.y)
	var evento := InputEventKey.new()
	evento.keycode = KEY_KP_1 + (valor - 1)
	evento.pressed = true
	evento.echo = false
	controller._unhandled_input(evento)

	assert_eq(controller.board.get_valor(alvo.x, alvo.y), valor)


func test_botao_numpad_insere_valor() -> void:
	var jogo := _instanciar()
	await wait_physics_frames(2)
	var controller := jogo as GameController
	var hud := jogo.get_node("HUD")
	var alvo := _primeira_celula_editavel_vazia(controller.board)
	controller.mover_selecao(alvo - controller.get_celula_selecionada())

	var valor: int = controller.board.get_valor_solucao(alvo.x, alvo.y)
	var botao := hud.get_node("Layout/Principal/Controls/Margin/VBox/Numpad/BtnNum" + str(valor)) as Button
	botao.emit_signal("pressed")

	assert_eq(controller.board.get_valor(alvo.x, alvo.y), valor)


func test_hud_expoe_informacoes() -> void:
	var jogo := _instanciar()
	await wait_physics_frames(2)
	var controller := jogo as GameController
	var hud := jogo.get_node("HUD")

	assert_eq(controller.get_erros(), 0)
	assert_eq(controller.get_progresso(), controller.board.contar_preenchidas())
	assert_eq(hud.get_node("Layout/Principal/Controls/Margin/VBox/Numpad").get_child_count(), 9)
	assert_eq(
		hud.get_node("Layout/Principal/Header/Margin/HBox/LabelPontos").text,
		str(controller.get_pontuacao())
	)


func test_botoes_do_hud_nao_recebem_foco() -> void:
	var jogo := _instanciar()
	await wait_physics_frames(2)
	var hud := jogo.get_node("HUD")

	for botao_no in hud.find_children("*", "Button", true, false):
		var botao := botao_no as Button
		assert_eq(botao.focus_mode, Control.FOCUS_NONE, "Botão %s não pode receber foco." % botao.name)


func test_pedir_dica_de_resolver_preenche_celula() -> void:
	HintProgression.registrar_vitoria(DifficultyManager.Dificuldade.ESPECIALISTA)
	var jogo := _instanciar()
	await wait_physics_frames(2)
	var controller := jogo as GameController
	assert_true(controller.pedir_dica(HintSystem.DICA_RESOLVER))


func test_pedir_dica_sem_estoque_bloqueada() -> void:
	var jogo := _instanciar()
	await wait_physics_frames(2)
	var controller := jogo as GameController
	assert_false(controller.pedir_dica(HintSystem.DICA_CONTAR))
	assert_false(controller.pedir_dica(HintSystem.DICA_CANDIDATO))
	assert_false(controller.pedir_dica(HintSystem.DICA_RESOLVER))


func test_pedir_dica_esgota_estoque() -> void:
	HintProgression.registrar_vitoria(DifficultyManager.Dificuldade.DIFICIL)
	var jogo := _instanciar()
	await wait_physics_frames(2)
	var controller := jogo as GameController
	assert_eq(controller.get_dicas_restantes(HintSystem.DICA_RESOLVER), 1)
	assert_true(controller.pedir_dica(HintSystem.DICA_RESOLVER))
	assert_eq(controller.get_dicas_restantes(HintSystem.DICA_RESOLVER), 0)
	assert_false(controller.pedir_dica(HintSystem.DICA_RESOLVER))


func _preencher_solucao(controller: GameController) -> void:
	for l in SudokuBoard.TAMANHO:
		for c in SudokuBoard.TAMANHO:
			if not controller.board.esta_bloqueada(l, c) and controller.board.esta_vazia(l, c):
				controller.board.definir_valor(l, c, controller.board.get_valor_solucao(l, c))


func test_pausa_alterna_overlay() -> void:
	var jogo := _instanciar()
	await wait_physics_frames(2)
	var controller := jogo as GameController
	var overlay := jogo.get_node("PauseOverlay")
	assert_false(overlay.visible)

	controller.alternar_pausa()
	assert_true(controller.esta_pausado())
	assert_true(overlay.visible)

	controller.alternar_pausa()
	assert_false(controller.esta_pausado())
	assert_false(overlay.visible)


func test_tecla_esc_pausa() -> void:
	var jogo := _instanciar()
	await wait_physics_frames(2)
	var controller := jogo as GameController
	var evento := InputEventKey.new()
	evento.keycode = KEY_ESCAPE
	evento.pressed = true
	evento.echo = false

	controller._unhandled_input(evento)

	assert_true(controller.esta_pausado())
	assert_true(jogo.get_node("PauseOverlay").visible)


func test_vitoria_mostra_overlay_de_resultado() -> void:
	var jogo := _instanciar()
	await wait_physics_frames(2)
	var controller := jogo as GameController
	var overlay := jogo.get_node("ResultOverlay")
	assert_false(overlay.visible)

	_preencher_solucao(controller)
	await wait_physics_frames(1)

	assert_true(controller.esta_terminado())
	assert_true(overlay.visible)
	assert_eq(overlay.get_node("Centro/Painel/Margin/VBox/LabelTituloResultado").text, "Vitória!")
	assert_eq(GameSession.resultado, GameSession.Resultado.VITORIA)
	var vbox := overlay.get_node("Centro/Painel/Margin/VBox")
	assert_eq(vbox.get_node("Stats/LabelPontosResultado").text, str(GameSession.resultado_pontos))
	assert_eq(vbox.get_node("Stats/LabelErrosResultado").text, str(GameSession.resultado_erros))


func test_derrota_mostra_overlay_de_resultado() -> void:
	var jogo := _instanciar()
	await wait_physics_frames(2)
	var controller := jogo as GameController
	var overlay := jogo.get_node("ResultOverlay")

	controller.lives.perder_vida()
	controller.lives.perder_vida()
	assert_eq(controller.get_vidas(), 1)

	var alvo := _primeira_celula_editavel_vazia(controller.board)
	assert_ne(alvo, Vector2i(-1, -1))
	var atual: Vector2i = controller.get_celula_selecionada()
	if alvo != atual:
		controller.mover_selecao(alvo - atual)
	var valor := controller.board.get_valor_solucao(alvo.x, alvo.y)
	var errado := 2 if valor == 1 else 1
	controller.inserir_numero(errado)
	await wait_physics_frames(1)

	assert_true(controller.esta_terminado())
	assert_true(overlay.visible)
	assert_eq(overlay.get_node("Centro/Painel/Margin/VBox/LabelTituloResultado").text, "Derrota")
	assert_eq(GameSession.resultado, GameSession.Resultado.DERROTA)
	var vbox := overlay.get_node("Centro/Painel/Margin/VBox")
	assert_false(vbox.get_node("Stats/LabelPontosResultado").visible)
	assert_false(vbox.get_node("Stats/LabelVidasResultado").visible)


func test_solicitar_reinicio_pausa_e_abre_overlay() -> void:
	var jogo := _instanciar()
	await wait_physics_frames(2)
	var controller := jogo as GameController
	var overlay := jogo.get_node("RestartOverlay")
	assert_false(overlay.visible)

	controller.solicitar_reinicio()

	assert_true(overlay.visible)
	assert_true(controller.esta_pausado())


func test_cancelar_reinicio_retoma_partida() -> void:
	var jogo := _instanciar()
	await wait_physics_frames(2)
	var controller := jogo as GameController
	var overlay := jogo.get_node("RestartOverlay")

	controller.solicitar_reinicio()
	controller.cancelar_reinicio()

	assert_false(overlay.visible)
	assert_false(controller.esta_pausado())


func test_cancelar_reinicio_aberto_em_pausa_continua_pausado() -> void:
	var jogo := _instanciar()
	await wait_physics_frames(2)
	var controller := jogo as GameController
	var overlay := jogo.get_node("RestartOverlay")

	controller.alternar_pausa()
	controller.solicitar_reinicio()
	assert_true(overlay.visible)

	controller.cancelar_reinicio()

	assert_false(overlay.visible)
	assert_true(controller.esta_pausado())
	assert_true(jogo.get_node("PauseOverlay").visible)


func test_tecla_r_abre_dialogo_de_reinicio() -> void:
	var jogo := _instanciar()
	await wait_physics_frames(2)
	var controller := jogo as GameController
	var evento := InputEventKey.new()
	evento.keycode = KEY_R
	evento.pressed = true
	evento.echo = false

	controller._unhandled_input(evento)

	assert_true(jogo.get_node("RestartOverlay").visible)
	assert_true(controller.esta_pausado())


func test_esc_fecha_dialogo_de_reinicio() -> void:
	var jogo := _instanciar()
	await wait_physics_frames(2)
	var controller := jogo as GameController
	controller.solicitar_reinicio()
	assert_true(controller.esta_pausado())

	var evento := InputEventKey.new()
	evento.keycode = KEY_ESCAPE
	evento.pressed = true
	evento.echo = false
	controller._unhandled_input(evento)

	assert_false(jogo.get_node("RestartOverlay").visible)
	assert_false(controller.esta_pausado())


func test_botao_reiniciar_do_hud_abre_dialogo() -> void:
	var jogo := _instanciar()
	await wait_physics_frames(2)
	var controller := jogo as GameController
	var hud := jogo.get_node("HUD")
	var botao := hud.get_node("Layout/Principal/Controls/Margin/VBox/LinhaD/BtnReiniciar") as Button

	botao.emit_signal("pressed")

	assert_true(jogo.get_node("RestartOverlay").visible)
	assert_true(controller.esta_pausado())


func test_botao_reiniciar_da_pausa_abre_dialogo() -> void:
	var jogo := _instanciar()
	await wait_physics_frames(2)
	var controller := jogo as GameController
	controller.alternar_pausa()
	var pause := jogo.get_node("PauseOverlay")
	var botao := pause.get_node("Centro/Painel/Margin/VBox/BtnReiniciarPausa") as Button

	botao.emit_signal("pressed")

	assert_true(jogo.get_node("RestartOverlay").visible)
	assert_true(controller.esta_pausado())


func test_reiniciar_mesmo_puzzle_restaura_tabuleiro() -> void:
	var jogo := _instanciar()
	await wait_physics_frames(2)
	var controller := jogo as GameController
	var alvo := _primeira_celula_editavel_vazia(controller.board)
	assert_ne(alvo, Vector2i(-1, -1))
	controller.mover_selecao(alvo - controller.get_celula_selecionada())
	controller.inserir_numero(controller.board.get_valor_solucao(alvo.x, alvo.y))
	assert_false(controller.board.esta_vazia(alvo.x, alvo.y))

	controller.reiniciar_partida()

	assert_true(controller.board.esta_vazia(alvo.x, alvo.y))
	assert_false(controller.esta_pausado())
	assert_false(controller.esta_terminado())
	assert_eq(controller.get_vidas(), 3)


func test_reiniciar_novo_puzzle_gera_novo_tabuleiro() -> void:
	var jogo := _instanciar()
	await wait_physics_frames(2)
	var controller := jogo as GameController

	controller.reiniciar_com_novo_puzzle()

	assert_not_null(controller.board)
	assert_false(controller.board.esta_completa())
	assert_false(controller.esta_pausado())
	assert_false(controller.esta_terminado())
	assert_eq(controller.get_vidas(), 3)
	assert_eq(controller.get_progresso(), controller.board.contar_preenchidas())


func test_cancelar_ignorado_sem_dialogo() -> void:
	var jogo := _instanciar()
	await wait_physics_frames(2)
	var controller := jogo as GameController

	controller.cancelar_reinicio()

	assert_false(controller.esta_pausado())
	assert_false(jogo.get_node("RestartOverlay").visible)


func test_novo_puzzle_fecha_pausa_do_dialogo() -> void:
	var jogo := _instanciar()
	await wait_physics_frames(2)
	var controller := jogo as GameController

	controller.solicitar_reinicio()
	assert_true(controller.esta_pausado())
	assert_true(jogo.get_node("PauseOverlay").visible)

	controller.reiniciar_com_novo_puzzle()

	assert_false(controller.esta_pausado())
	assert_false(jogo.get_node("PauseOverlay").visible)


func test_botao_novo_puzzle_fecha_pause_e_dialogo() -> void:
	var jogo := _instanciar()
	await wait_physics_frames(2)
	var controller := jogo as GameController
	var overlay := jogo.get_node("RestartOverlay")

	controller.solicitar_reinicio()
	var botao := overlay.get_node("Centro/Painel/Margin/VBox/BtnReiniciarNovo") as Button
	botao.emit_signal("pressed")

	assert_false(overlay.visible)
	assert_false(controller.esta_pausado())
	assert_false(jogo.get_node("PauseOverlay").visible)


func test_botao_reiniciar_mesmo_fecha_pause_e_dialogo() -> void:
	var jogo := _instanciar()
	await wait_physics_frames(2)
	var controller := jogo as GameController
	var overlay := jogo.get_node("RestartOverlay")

	controller.solicitar_reinicio()
	var botao := overlay.get_node("Centro/Painel/Margin/VBox/BtnReiniciarMesmo") as Button
	botao.emit_signal("pressed")

	assert_false(overlay.visible)
	assert_false(controller.esta_pausado())
	assert_false(jogo.get_node("PauseOverlay").visible)


# --- Seleção múltipla (toque) ---

func _celulas_vazias_editaveis(controller: GameController) -> Array[Vector2i]:
	var resultado: Array[Vector2i] = []
	for l in SudokuBoard.TAMANHO:
		for c in SudokuBoard.TAMANHO:
			if not controller.board.esta_bloqueada(l, c) and controller.board.esta_vazia(l, c):
				resultado.append(Vector2i(l, c))
	return resultado


func _duas_celulas_com_mesma_solucao(controller: GameController) -> Array[Vector2i]:
	for a in _celulas_vazias_editaveis(controller):
		for b in _celulas_vazias_editaveis(controller):
			if a == b:
				continue
			if controller.board.get_valor_solucao(a.x, a.y) == controller.board.get_valor_solucao(b.x, b.y):
				return [a, b]
	return []


func _selecionar_exatamente(controller: GameController, alvos: Array[Vector2i]) -> void:
	for pos in controller.get_celulas_selecionadas().duplicate():
		if not alvos.has(pos):
			controller.alternar_selecao(pos)
	for pos in alvos:
		if not controller.get_celulas_selecionadas().has(pos):
			controller.alternar_selecao(pos)
	assert_eq(controller.get_celulas_selecionadas(), alvos)


func test_tocar_alterna_celulas_na_selecao_multi() -> void:
	var jogo := _instanciar()
	await wait_physics_frames(2)
	var controller := jogo as GameController

	assert_eq(controller.get_celulas_selecionadas(), [Vector2i(0, 0)])

	controller.alternar_selecao(Vector2i(2, 4))
	assert_eq(controller.get_celulas_selecionadas(), [Vector2i(0, 0), Vector2i(2, 4)])
	assert_eq(controller.get_celula_selecionada(), Vector2i(2, 4))

	controller.alternar_selecao(Vector2i(0, 0))
	assert_eq(controller.get_celulas_selecionadas(), [Vector2i(2, 4)])

	controller.alternar_selecao(Vector2i(2, 4))
	assert_true(controller.get_celulas_selecionadas().is_empty())
	assert_eq(controller.get_celula_selecionada(), Vector2i(-1, -1))


func test_mover_selecao_limpa_selecao_multi() -> void:
	var jogo := _instanciar()
	await wait_physics_frames(2)
	var controller := jogo as GameController

	controller.alternar_selecao(Vector2i(3, 3))
	controller.mover_selecao(Vector2i(1, 0))

	assert_eq(controller.get_celulas_selecionadas(), [Vector2i(4, 3)])


func test_inserir_numero_aplica_a_todas_selecionadas() -> void:
	var jogo := _instanciar()
	await wait_physics_frames(2)
	var controller := jogo as GameController

	var alvos := _duas_celulas_com_mesma_solucao(controller)
	assert_false(alvos.is_empty(), "Puzzle deve ter duas células vazias com a mesma solução.")
	var valor: int = controller.board.get_valor_solucao(alvos[0].x, alvos[0].y)

	_selecionar_exatamente(controller, alvos)
	assert_true(controller.inserir_numero(valor))

	for pos in alvos:
		assert_eq(controller.board.get_valor(pos.x, pos.y), valor)
		assert_false(controller.board.get_celula(pos.x, pos.y).tem_erro)

	assert_true(controller.desfazer())
	for pos in alvos:
		assert_true(controller.board.esta_vazia(pos.x, pos.y))


func test_apagar_aplica_a_todas_selecionadas() -> void:
	var jogo := _instanciar()
	await wait_physics_frames(2)
	var controller := jogo as GameController

	var alvos := _duas_celulas_com_mesma_solucao(controller)
	assert_false(alvos.is_empty())
	var valor: int = controller.board.get_valor_solucao(alvos[0].x, alvos[0].y)
	_selecionar_exatamente(controller, alvos)
	assert_true(controller.inserir_numero(valor))

	assert_true(controller.apagar_celula())
	for pos in alvos:
		assert_true(controller.board.esta_vazia(pos.x, pos.y))


func test_inserir_numero_sem_selecao_nao_faz_nada() -> void:
	var jogo := _instanciar()
	await wait_physics_frames(2)
	var controller := jogo as GameController

	controller.alternar_selecao(Vector2i(0, 0))
	controller.alternar_selecao(Vector2i(0, 0))

	assert_false(controller.inserir_numero(1))
	assert_eq(controller.get_progresso(), controller.board.contar_preenchidas())


func test_serializar_partida_guarda_selecao_multi() -> void:
	var jogo := _instanciar()
	await wait_physics_frames(2)
	var controller := jogo as GameController

	controller.alternar_selecao(Vector2i(5, 6))

	var dados := controller.serializar_partida()
	assert_eq(dados["celulas_selecionadas"], [[0, 0], [5, 6]])
