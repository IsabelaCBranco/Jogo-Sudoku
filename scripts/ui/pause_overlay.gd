extends Control
## Sobreposição de pausa (apresentação apenas).
##
## Observa o sinal de pausa do controller e se mostra/oculta; os botões
## apenas acionam métodos do controller ou navegam de volta ao menu.

const CENA_MENU := "res://scenes/main_menu/main_menu.tscn"

@export_node_path var controller_path: NodePath

var _controller: GameController
var navegador: Callable = _navegar_padrao


func _ready() -> void:
	_controller = get_node(controller_path)
	_controller.pausa_alterada.connect(_ao_pausa_alterada)
	%BtnRetomar.pressed.connect(_controller.alternar_pausa)
	%BtnReiniciarPausa.pressed.connect(_controller.solicitar_reinicio)
	%BtnMenuPausa.pressed.connect(_ao_menu)
	visible = false


func _ao_pausa_alterada(ativo: bool) -> void:
	visible = ativo
	if ativo:
		%BtnRetomar.grab_focus()
	else:
		get_viewport().gui_release_focus()


func _ao_menu() -> void:
	navegador.call(CENA_MENU)


func _navegar_padrao(rota: String) -> void:
	var erro := get_tree().change_scene_to_file(rota)
	if erro != OK:
		push_error("Falha ao abrir a cena %s (erro %s)." % [rota, erro])
