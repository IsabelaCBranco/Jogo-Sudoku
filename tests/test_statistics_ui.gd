extends GutTest
## Testes da tela de estatísticas (apresentação + reset).


func before_each() -> void:
	StatisticsSystem.reset()
	var dir := OS.get_environment("TEMP") + "/gut_stats_" + str(Time.get_ticks_usec()) + "/"
	DirAccess.make_dir_recursive_absolute(dir)
	SaveManager.set_caminho_base(dir)


func after_each() -> void:
	SaveManager.set_caminho_base("user://")
	StatisticsSystem.reset()


func _instanciar_tela() -> Node:
	var cena := load("res://scenes/statistics/statistics.tscn") as PackedScene
	assert_not_null(cena)
	var instancia: Node = cena.instantiate()
	add_child_autofree(instancia)
	return instancia


func test_apresenta_contadores() -> void:
	StatisticsSystem.registrar_partida_iniciada()
	StatisticsSystem.registrar_partida_iniciada()
	StatisticsSystem.registrar_partida_iniciada()
	StatisticsSystem.registrar_vitoria(DifficultyManager.Dificuldade.FACIL, 60, 3500, 1, 2)

	var tela := _instanciar_tela()
	await wait_physics_frames(2)

	assert_eq(tela.get_node("Centro/Card/Margin/VBoxExterno/Scroll/VBox/LabelIniciadas").text, "Partidas iniciadas: 3")
	assert_eq(tela.get_node("Centro/Card/Margin/VBoxExterno/Scroll/VBox/LabelConcluidas").text, "Partidas concluídas: 1")
	assert_eq(tela.get_node("Centro/Card/Margin/VBoxExterno/Scroll/VBox/LabelVencidas").text, "Partidas vencidas: 1")
	assert_eq(tela.get_node("Centro/Card/Margin/VBoxExterno/Scroll/VBox/LabelTempoMedio").text, "Tempo médio: 01:00")
	assert_eq(tela.get_node("Centro/Card/Margin/VBoxExterno/Scroll/VBox/LabelMediaErros").text, "Média de erros: 1.0")
	assert_eq(tela.get_node("Centro/Card/Margin/VBoxExterno/Scroll/VBox/LabelDicas").text, "Dicas utilizadas: 2")


func test_apresenta_melhores_por_dificuldade() -> void:
	StatisticsSystem.registrar_partida_iniciada()
	StatisticsSystem.registrar_vitoria(DifficultyManager.Dificuldade.MUITO_FACIL, 30, 4000, 0, 0)
	StatisticsSystem.registrar_vitoria(DifficultyManager.Dificuldade.ESPECIALISTA, 600, 9000, 3, 4)

	var tela := _instanciar_tela()
	await wait_physics_frames(2)

	var melhores := tela.get_node("Centro/Card/Margin/VBoxExterno/Scroll/VBox/Melhores").get_children()
	assert_eq(melhores.size(), 5)
	var texto: String = melhores[0].text
	assert_true(texto.contains("Muito Fácil"))
	assert_true(texto.contains("melhor tempo: 00:30"))
	assert_true(melhores[4].text.contains("Especialista"))
	assert_true(melhores[4].text.contains("9000"))


func test_zerar_limpa_estatisticas() -> void:
	StatisticsSystem.registrar_partida_iniciada()
	StatisticsSystem.registrar_vitoria(DifficultyManager.Dificuldade.FACIL, 60, 3500, 1, 2)

	var tela := _instanciar_tela()
	await wait_physics_frames(2)

	tela._ao_zerar()

	assert_eq(tela.get_node("Centro/Card/Margin/VBoxExterno/Scroll/VBox/LabelIniciadas").text, "Partidas iniciadas: 0")
	assert_eq(tela.get_node("Centro/Card/Margin/VBoxExterno/Scroll/VBox/LabelVencidas").text, "Partidas vencidas: 0")
	assert_eq(StatisticsSystem.partidas_iniciadas, 0)


func test_voltar_navega_para_o_menu() -> void:
	var tela := _instanciar_tela()
	await wait_physics_frames(2)
	var rotas: Array = []
	tela.navegador = func(rota: String) -> void:
		rotas.append(rota)

	tela._ao_voltar()

	assert_eq(rotas, ["res://scenes/main_menu/main_menu.tscn"])
