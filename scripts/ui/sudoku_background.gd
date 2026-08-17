extends Control
## Fundo decorativo do menu principal (apresentação apenas).
## Desenha uma grade de Sudoku 9x9 sutil atrás do card central.

const COR_LINHA := Color(0.35, 0.42, 0.58, 0.1)
const COR_LINHA_GROSSA := Color(0.45, 0.55, 0.75, 0.2)
const LADO_CELULA := 56.0


func _draw() -> void:
	var lado := LADO_CELULA * 9.0
	var origem := (size - Vector2(lado, lado)) * 0.5
	for i in range(10):
		var grossa := i % 3 == 0
		var cor := COR_LINHA_GROSSA if grossa else COR_LINHA
		var espessura := 3.0 if grossa else 1.0
		var pos: float = i * LADO_CELULA
		draw_line(origem + Vector2(pos, 0), origem + Vector2(pos, lado), cor, espessura)
		draw_line(origem + Vector2(0, pos), origem + Vector2(lado, pos), cor, espessura)
