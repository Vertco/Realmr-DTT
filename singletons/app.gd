extends Node

@warning_ignore("unused_signal")
signal confirmation(result:bool)

var map_path:String
var canvas:CanvasLayer


func confirm(message:String,title:String="Confirm?") -> void:
	canvas = CanvasLayer.new()
	
	# Setup background
	var background:Button = Button.new()
	background.theme_type_variation = "SquareButton"
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	background.pressed.connect(cancel_pressed)
	
	# Setup background shader
	var shader_mat:ShaderMaterial = ShaderMaterial.new()
	var shader:Shader = load("res://media/shaders/menuBlur.gdshader")
	shader_mat.shader = shader
	shader_mat.set_shader_parameter("blur_amount", 2)
	shader_mat.set_shader_parameter("mix_amount", 0.5)
	background.material = shader_mat
	
	# Setup dialog
	var dialog:ConfirmationDialog = ConfirmationDialog.new()
	dialog.dialog_text = message
	dialog.title = title
	dialog.get_label().horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	dialog.get_label().vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	dialog.get_label().autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dialog.initial_position = Window.WINDOW_INITIAL_POSITION_CENTER_PRIMARY_SCREEN
	
	# Setup dialog buttons
	dialog.ok_button_text = "Confirm"
	dialog.confirmed.connect(ok_pressed)
	dialog.canceled.connect(cancel_pressed)
	dialog.get_ok_button().mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	dialog.get_cancel_button().mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	
	# Display the popup
	dialog.visible = true
	background.add_child(dialog)
	canvas.add_child(background)
	if get_viewport().get_camera_2d():
		get_viewport().get_camera_2d().add_child(canvas)
	else:
		get_tree().root.add_child(canvas)


func ok_pressed() -> void:
	canvas.queue_free()
	emit_signal("confirmation",true)


func cancel_pressed() -> void:
	emit_signal("confirmation",false)
	canvas.queue_free()


func is_file(path: String) -> bool:
	# Check if path ends with slash
	if path.ends_with("/") or path.ends_with("\\"):
		return false  # It's a directory, not a file
		
	# Check if path contains "."
	var last_dot_index = path.rfind(".")
	if last_dot_index == -1:
		return false
		
	# Ensure "." is not last character
	if last_dot_index == path.length() - 1:
		return false
	return true
