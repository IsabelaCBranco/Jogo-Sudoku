extends Control
## Tela de estatísticas (apresentação apenas).
##
## Observa o StatisticsSystem e apresenta os agregados. O botão Zerar chama
## o reset do sistema; a navegação usa o callable injetável `navegador`.

const CENA_MENU := "res://scenes/main_menu/main_menu.tscn"

const ORDEM_DIFICULDADES := [
	DifficultyManager.Dificuldade.MUITO_FACIL,
	DifficultyManager.Dificuldade.FACIL,
	DifficultyManager.Dificuldade.MEDIO,
	DifficultyManager.Dificuldade.DIFICIL,
	DifficultyManager.Dificuldade.ESPECIALISTA,
]

var navegador: Callable = _navegar_padrao


func _ready() -> void:
	StatisticsSystem.estatisticas_alteradas.connect(_atualizar)
	%BtnZerar.pressed.connect(_ao_zerar)
	%BtnVoltar.pressed.connect(_ao_voltar)
	%BtnVoltar.grab_focus()
	_atualizar()


func _atualizar() -> void:
	%LabelIniciadas.text = "Partidas iniciadas: %d" % StatisticsSystem.partidas_iniciadas
	%LabelConcluidas.text = "Partidas concluídas: %d" % StatisticsSystem.partidas_concluidas
	%LabelVencidas.text = "Partidas vencidas: %d" % StatisticsSystem.partidas_vencidas
	%LabelPerdidas.text = "Partidas perdidas: %d" % StatisticsSystem.partidas_perdidas
	%LabelTempoMedio.text = "Tempo médio: %s" % _formatar_tempo(int(StatisticsSystem.get_tempo_medio()))
	%LabelMediaErros.text = "Média de erros: %.1f" % StatisticsSystem.get_media_erros()
	%LabelDicas.text = "Dicas utilizadas: %d" % StatisticsSystem.get_total_dicas()
	_criar_melhores()


func _criar_melhores() -> void:
	for filho in %Melhores.get_children():
		filho.queue_free()
	for dificuldade in ORDEM_DIFICULDADES:
		var tempo := StatisticsSystem.get_melhor_tempo(dificuldade)
		var pontuacao := StatisticsSystem.get_melhor_pontuacao(dificuldade)
		var label := Label.new()
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		label.autowrap_mode = TextServer.AUTOWRAP_WORD
		label.text = "%s — melhor tempo: %s | melhor pontuação: %d" % [
			DifficultyManager.get_nome(dificuldade),
			_formatar_tempo(tempo) if tempo > 0 else "--:--",
			pontuacao,
		]
		%Melhores.add_child(label)


func _ao_zerar() -> void:
	StatisticsSystem.reset()
	StatisticsSystem.salvar()
	_atualizar()


func _ao_voltar() -> void:
	navegador.call(CENA_MENU)


func _formatar_tempo(segundos: int) -> String:
	return "%02d:%02d" % [segundos / 60, segundos % 60]


func _navegar_padrao(rota: String) -> void:
	var erro := get_tree().change_scene_to_file(rota)
	if erro != OK:
		push_error("Falha ao abrir a cena %s (erro %s)." % [rota, erro])
