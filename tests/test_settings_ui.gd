extends GutTest
## Testes da tela de configurações (apresentação + persistência).


func before_each() -> void:
	GameSettings.restaurar_padroes()
	var dir := OS.get_environment("TEMP") + "/gut_settings_" + str(Time.get_ticks_usec()) + "/"
	DirAccess.make_dir_recursive_absolute(dir)
	SaveManager.set_caminho_base(dir)
	GameSettings.salvar()


func after_each() -> void:
	SaveManager.set_caminho_base("user://")
	GameSettings.restaurar_padroes()


func _instanciar_tela() -> Node:
	var cena := load("res://scenes/settings/settings.tscn") as PackedScene
	assert_not_null(cena)
	var instancia: Node = cena.instantiate()
	add_child_autofree(instancia)
	return instancia


func test_valores_iniciais_refletem_configuracoes() -> void:
	var tela := _instanciar_tela()
	await wait_physics_frames(2)
	assert_true(tela.get_node("Centro/Card/Margin/VBox/BtnVidas").button_pressed)
	assert_true(tela.get_node("Centro/Card/Margin/VBox/BtnSom").button_pressed)
	assert_true(tela.get_node("Centro/Card/Margin/VBox/BtnMusica").button_pressed)
	assert_true(tela.get_node("Centro/Card/Margin/VBox/BtnAnotacoes").button_pressed)
	assert_true(tela.get_node("Centro/Card/Margin/VBox/BtnErros").button_pressed)


func test_alternar_vidas_altera_e_persiste() -> void:
	var tela := _instanciar_tela()
	await wait_physics_frames(2)
	tela.get_node("Centro/Card/Margin/VBox/BtnVidas").button_pressed = false

	assert_false(GameSettings.vidas_ativadas)
	assert_false(bool(SaveManager.carregar_configuracoes().get("vidas_ativadas", true)))


func test_alternar_anotacoes_altera_e_persiste() -> void:
	var tela := _instanciar_tela()
	await wait_physics_frames(2)
	tela.get_node("Centro/Card/Margin/VBox/BtnAnotacoes").button_pressed = false

	assert_false(GameSettings.anotacoes_ativadas)
	assert_false(bool(SaveManager.carregar_configuracoes().get("anotacoes_ativadas", true)))


func test_restaurar_padroes_volta_valores() -> void:
	var tela := _instanciar_tela()
	await wait_physics_frames(2)
	tela.get_node("Centro/Card/Margin/VBox/BtnVidas").button_pressed = false
	tela.get_node("Centro/Card/Margin/VBox/BtnErros").button_pressed = false

	tela._ao_padroes()

	assert_true(GameSettings.vidas_ativadas)
	assert_true(GameSettings.exibir_erros)
	assert_true(tela.get_node("Centro/Card/Margin/VBox/BtnVidas").button_pressed)
	assert_true(tela.get_node("Centro/Card/Margin/VBox/BtnErros").button_pressed)
	assert_true(bool(SaveManager.carregar_configuracoes().get("vidas_ativadas", false)))


func test_voltar_navega_para_o_menu() -> void:
	var tela := _instanciar_tela()
	await wait_physics_frames(2)
	var rotas: Array = []
	tela.navegador = func(rota: String) -> void:
		rotas.append(rota)

	tela._ao_voltar()

	assert_eq(rotas, ["res://scenes/main_menu/main_menu.tscn"])
