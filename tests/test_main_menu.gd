extends GutTest
## Testes do menu principal: dificuldades, navegação e botão continuar.


var _rotas: Array = []


func before_each() -> void:
	GameSession.limpar()
	_rotas.clear()
	var dir := OS.get_environment("TEMP") + "/gut_menu_" + str(Time.get_ticks_usec()) + "/"
	DirAccess.make_dir_recursive_absolute(dir)
	SaveManager.set_caminho_base(dir)
	if SaveManager.existe_partida_salva():
		SaveManager.apagar_partida()


func after_each() -> void:
	SaveManager.set_caminho_base("user://")
	GameSession.limpar()


func _instanciar_menu() -> Node:
	var cena := load("res://scenes/main_menu/main_menu.tscn") as PackedScene
	assert_not_null(cena)
	var instancia: Node = cena.instantiate()
	instancia.navegador = func(rota: String) -> void:
		_rotas.append(rota)
	add_child_autofree(instancia)
	return instancia


func test_dropdown_tem_cinco_dificuldades() -> void:
	var menu := _instanciar_menu()
	await wait_physics_frames(2)
	var dropdown: OptionButton = menu.get_node("Centro/Card/Margin/VBox/OpcaoDificuldade")
	assert_eq(dropdown.get_item_count(), 5)
	assert_eq(dropdown.get_item_text(0), "Muito Fácil")
	assert_eq(dropdown.get_item_text(4), "Especialista")


func test_selecionar_dificuldade_no_dropdown_nao_navega() -> void:
	var menu := _instanciar_menu()
	await wait_physics_frames(2)
	var dropdown: OptionButton = menu.get_node("Centro/Card/Margin/VBox/OpcaoDificuldade")
	dropdown.item_selected.emit(3)

	assert_eq(GameSession.dificuldade_selecionada, 0)
	assert_eq(_rotas, [])


func test_iniciar_jogo_navega_com_dificuldade_selecionada() -> void:
	var menu := _instanciar_menu()
	await wait_physics_frames(2)
	var dropdown: OptionButton = menu.get_node("Centro/Card/Margin/VBox/OpcaoDificuldade")
	dropdown.selected = 3
	menu.iniciar_jogo()

	assert_eq(GameSession.dificuldade_selecionada, DifficultyManager.Dificuldade.DIFICIL)
	assert_false(GameSession.continuar)
	assert_eq(_rotas, ["res://scenes/game/game.tscn"])


func test_escolher_dificuldade_grava_sessao_e_navega() -> void:
	var menu := _instanciar_menu()
	await wait_physics_frames(2)
	var escolhas: Array = []
	menu.dificuldade_escolhida.connect(func(dificuldade: int) -> void: escolhas.append(dificuldade))

	menu.escolher_dificuldade(DifficultyManager.Dificuldade.DIFICIL)

	assert_eq(GameSession.dificuldade_selecionada, DifficultyManager.Dificuldade.DIFICIL)
	assert_false(GameSession.continuar)
	assert_eq(escolhas, [DifficultyManager.Dificuldade.DIFICIL])
	assert_eq(_rotas, ["res://scenes/game/game.tscn"])


func test_continuar_grava_sessao_e_navega() -> void:
	var menu := _instanciar_menu()
	await wait_physics_frames(2)

	menu.continuar_partida()

	assert_true(GameSession.continuar)
	assert_eq(_rotas, ["res://scenes/game/game.tscn"])


func test_abrir_configuracoes_e_estatisticas_navega() -> void:
	var menu := _instanciar_menu()
	await wait_physics_frames(2)

	menu.abrir_configuracoes()
	menu.abrir_estatisticas()

	assert_eq(_rotas, [
		"res://scenes/settings/settings.tscn",
		"res://scenes/statistics/statistics.tscn",
	])


func test_continuar_escondido_sem_partida_salva() -> void:
	var menu := _instanciar_menu()
	await wait_physics_frames(2)
	assert_false(menu.get_node("Centro/Card/Margin/VBox/BtnContinuar").visible)


func test_continuar_visivel_com_partida_salva() -> void:
	var menu := _instanciar_menu()
	await wait_physics_frames(2)
	SaveManager.salvar_partida({"versao": 1})
	menu._ajustar_continuar()
	assert_true(menu.get_node("Centro/Card/Margin/VBox/BtnContinuar").visible)


func test_botao_iniciar_existe_e_visivel() -> void:
	var menu := _instanciar_menu()
	await wait_physics_frames(2)
	var botao: Button = menu.get_node("Centro/Card/Margin/VBox/BtnIniciar")
	assert_not_null(botao)
	assert_true(botao.visible)
	assert_eq(botao.text, "Iniciar Jogo")
