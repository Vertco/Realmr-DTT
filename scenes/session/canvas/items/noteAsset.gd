extends CanvasAsset

const type := "NoteAsset"

var _dragging:bool = false
var dragAccum:Vector2 = Vector2.ONE

func _ready() -> void:
	loadNote(file)
	connect("file_changed", loadNote)
	connect("selection_changed", updateSelection)

@warning_ignore("shadowed_variable")
func loadNote(file:String) -> void:
	%popup.display_file(file)

func updateSelection(select) -> void:
	if select and locked:
		%popup.visible = true
		%popup.position = position - %popup.size/2
		session.emit_signal("focusGmCam", %popup.global_position + %popup.size/2 + Vector2(98,128))
	elif !select:
		%popup.visible = false
	for l in range(9):
		set_visibility_layer_bit(l, false)

func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and _dragging and selected and %popup.visible == false:
		dragAccum += event.relative
		if Input.is_key_pressed(KEY_CTRL):
			if dragAccum.length() >= 50:
				global_position = snap_to_grid(global_position + dragAccum)
				dragAccum = Vector2.ZERO
		else:
			global_position += event.relative
			dragAccum = Vector2.ZERO
	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			_dragging = event.pressed
			if event.double_click:
				if locked:
					selected = !selected
				else:
					selected = !selected
			elif event.pressed and locked:
				%popup.visible = true
				selected = !selected
			accept_event()

func snap_to_grid(pos: Vector2) -> Vector2:
	return Vector2(
		round(pos.x / 50) * 50,
		round(pos.y / 50) * 50
	)

func save() -> Dictionary:
	var saveDict:Dictionary = {
		"filename" : get_scene_file_path(),
		"parent" : get_parent().get_path(),
		"pos_x" : position.x, # Vector2 is not supported by JSON
		"pos_y" : position.y,
		"locked" : locked,
		"file" : file,
		"layer" : layer
	}
	return saveDict
