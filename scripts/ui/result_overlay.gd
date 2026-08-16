extends Control
## Sobreposição de resultado de vitória/derrota (apresentação apenas).
##
## Observa os sinais de fim do controller e apresenta o resultado salvo no
## GameSession. Jogar novamente reinicia na mesma dificuldade.

const CENA_JOGO := "res://scenes/game/game.tscn"
const CENA_MENU := "res://scenes/main_menu/main_menu.tscn"

const COR_TITULO_VITORIA := Color(0.4, 0.9, 0.5, 1)
const COR_TITULO_DERROTA := Color(0.95, 0.4, 0.45, 1)

@export_node_path var controller_path: NodePath

var _controller: GameController
var navegador: Callable = _navegar_padrao


func _ready() -> void:
	_controller = get_node(controller_path)
	_controller.vitoria.connect(_ao_vitoria)
	_controller.derrota.connect(_ao_derrota)
	%BtnJogarNovamente.pressed.connect(_ao_jogar_novamente)
	%BtnMenuResultado.pressed.connect(_ao_menu)
	visible = false


func _ao_vitoria(_pontos: int) -> void:
	%LabelTituloResultado.text = "Vitória!"
	%LabelTituloResultado.add_theme_color_override("font_color", COR_TITULO_VITORIA)
	%LabelDetalhesResultado.text = DifficultyManager.get_nome(GameSession.resultado_dificuldade)
	%LabelPontosResultado.text = str(GameSession.resultado_pontos)
	%LabelTempoResultado.text = _formatar_tempo(GameSession.resultado_tempo_segundos)
	%LabelVidasResultado.text = "♥".repeat(GameSession.resultado_vidas) if GameSettings.vidas_ativadas else "OFF"
	%LabelErrosResultado.text = str(GameSession.resultado_erros)
	%LabelDicasResultado.text = str(GameSession.resultado_dicas)
	%CapPontosResultado.visible = true
	%LabelPontosResultado.visible = true
	%CapVidasResultado.visible = true
	%LabelVidasResultado.visible = true
	visible = true
	%BtnJogarNovamente.grab_focus()


func _ao_derrota() -> void:
	%LabelTituloResultado.text = "Derrota"
	%LabelTituloResultado.add_theme_color_override("font_color", COR_TITULO_DERROTA)
	%LabelDetalhesResultado.text = DifficultyManager.get_nome(GameSession.resultado_dificuldade)
	%LabelTempoResultado.text = _formatar_tempo(GameSession.resultado_tempo_segundos)
	%LabelErrosResultado.text = str(GameSession.resultado_erros)
	%LabelDicasResultado.text = str(GameSession.resultado_dicas)
	%CapPontosResultado.visible = false
	%LabelPontosResultado.visible = false
	%CapVidasResultado.visible = false
	%LabelVidasResultado.visible = false
	visible = true
	%BtnJogarNovamente.grab_focus()


func _ao_jogar_novamente() -> void:
	GameSession.definir_nova_partida(_controller.dificuldade)
	navegador.call(CENA_JOGO)


func _ao_menu() -> void:
	navegador.call(CENA_MENU)


func _formatar_tempo(segundos: int) -> String:
	return "%02d:%02d" % [segundos / 60, segundos % 60]


func _navegar_padrao(rota: String) -> void:
	var erro := get_tree().change_scene_to_file(rota)
	if erro != OK:
		push_error("Falha ao abrir a cena %s (erro %s)." % [rota, erro])
