extends Control

func _on_mouse_entered() -> void:
	modulate = Color(1.5,1.5,1.5)

func _on_mouse_exited() -> void:
	modulate = Color(1,1,1)
