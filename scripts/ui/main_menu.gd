extends Control
## Menu principal: escolha de dificuldade e navegação para as demais telas.
##
## A navegação é feita pelo callable `navegador`, injetável para permitir
## testes sem trocar de cena de verdade. O estado escolhido vai para o
## autoload GameSession; nenhuma regra de negócio vive aqui.

signal dificuldade_escolhida(dificuldade: int)

const CENA_JOGO := "res://scenes/game/game.tscn"
const CENA_CONFIGURACOES := "res://scenes/settings/settings.tscn"
const CENA_ESTATISTICAS := "res://scenes/statistics/statistics.tscn"

var navegador: Callable = _navegar_padrao


func _ready() -> void:
	_ajustar_janela_a_tela()
	_preencher_dificuldades()
	_ajustar_continuar()
	%BtnIniciar.pressed.connect(iniciar_jogo)
	%BtnContinuar.pressed.connect(continuar_partida)
	%BtnConfiguracoes.pressed.connect(abrir_configuracoes)
	%BtnEstatisticas.pressed.connect(abrir_estatisticas)
	%BtnSair.pressed.connect(_ao_sair)
	if %BtnContinuar.visible:
		%BtnContinuar.grab_focus()
	else:
		%BtnIniciar.grab_focus()


## Reduz a janela para caber na área utilizável da tela (ex.: notebooks com
## tela baixa). Com o stretch "canvas_items", todo o conteúdo escala junto.
func _ajustar_janela_a_tela() -> void:
	if DisplayServer.get_name() == "headless":
		return
	if DisplayServer.get_screen_count() <= 0:
		return
	var retangulo := DisplayServer.screen_get_usable_rect(DisplayServer.window_get_current_screen())
	var janela := DisplayServer.window_get_size()
	if janela.x <= 0 or janela.y <= 0 or retangulo.size.x <= 0 or retangulo.size.y <= 0:
		return
	var escala: float = min(1.0, float(retangulo.size.x) / float(janela.x), float(retangulo.size.y) / float(janela.y))
	if escala >= 1.0:
		return
	var novo := Vector2i(Vector2(janela) * escala)
	if novo.x < 100 or novo.y < 100:
		return
	DisplayServer.window_set_size(novo)


func _preencher_dificuldades() -> void:
	var ordem := [
		DifficultyManager.Dificuldade.MUITO_FACIL,
		DifficultyManager.Dificuldade.FACIL,
		DifficultyManager.Dificuldade.MEDIO,
		DifficultyManager.Dificuldade.DIFICIL,
		DifficultyManager.Dificuldade.ESPECIALISTA,
	]
	for dificuldade in ordem:
		%OpcaoDificuldade.add_item(DifficultyManager.get_nome(dificuldade))
	%OpcaoDificuldade.selected = 0


func _ao_selecionar_dificuldade(_indice: int) -> void:
	pass


func iniciar_jogo() -> void:
	var indice: int = %OpcaoDificuldade.selected
	escolher_dificuldade(indice + 1)


func _ajustar_continuar() -> void:
	%BtnContinuar.visible = SaveManager.existe_partida_salva()


func escolher_dificuldade(dificuldade: int) -> void:
	GameSession.definir_nova_partida(dificuldade)
	dificuldade_escolhida.emit(dificuldade)
	navegador.call(CENA_JOGO)


func continuar_partida() -> void:
	GameSession.definir_continuar()
	navegador.call(CENA_JOGO)


func abrir_configuracoes() -> void:
	navegador.call(CENA_CONFIGURACOES)


func abrir_estatisticas() -> void:
	navegador.call(CENA_ESTATISTICAS)


func _ao_sair() -> void:
	get_tree().quit()


func _navegar_padrao(rota: String) -> void:
	var erro := get_tree().change_scene_to_file(rota)
	if erro != OK:
		push_error("Falha ao abrir a cena %s (erro %s)." % [rota, erro])
