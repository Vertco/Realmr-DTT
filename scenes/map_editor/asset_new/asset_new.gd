extends Control

@warning_ignore("unused_signal")
signal pressed

var hover:bool = false

func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				emit_signal("pressed")


func _on_mouse_entered() -> void:
	hover = true
	set_self_modulate(Color(1,1,1,0.5))


func _on_mouse_exited() -> void:
	hover = false
	set_self_modulate(Color(1,1,1,0))
