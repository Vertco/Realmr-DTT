extends Node

@warning_ignore("unused_signal")
signal confirmation(result:bool,custom:StringName)

var recents:Array
var map_path:String
var canvas:CanvasLayer
var cache_location:String = "user://map_cache"


func _ready() -> void:
	var recets_file: FileAccess
	if FileAccess.file_exists("user://recents.json"):
		recets_file = FileAccess.open("user://recents.json", FileAccess.READ)
		
		# Read the entire file content
		var json_string = recets_file.get_as_text()
		recets_file.close()
		
		# Creates the helper class to interact with JSON
		var json = JSON.new()
		
		# Check if there is any error while parsing the JSON string, skip in case of failure
		var parse_result = json.parse(json_string)
		if parse_result != OK:
			print("JSON Parse Error: ", json.get_error_message(), " in ", json_string, " at line ", json.get_error_line())
			return
		
		# Get the data from the JSON object
		var data = json.get_data()
		
		# Load recents from recents file
		recents = data
	else:
		add_recent()


func add_recent(recent:String="") -> void:
	cleanup_recents()
	if recent != "":
		# Create array
		var id := recents.find(recent)
		
		if id == -1:
			# Remove oldest recent if list too long
			if !recents.size() < 8:
				recents.remove_at(recents.size()-1)
			recents.push_front(recent)
		else:
			recents.remove_at(id)
			recents.push_front(recent)
	
	# Serialize the current recents to JSON
	var json_string = JSON.stringify(recents)
	
	var file: FileAccess = FileAccess.open("user://recents.json", FileAccess.WRITE)
	file.store_line(json_string)
	file.close()


func cleanup_recents() -> void:
	for recent in recents:
		if !FileAccess.file_exists(recent):
			recents.erase(recent)


func confirm(message:String,title:String="Confirm?",custom_button:String="",custom_button_right:bool=false,custom_action:String="",confirm_button:String="Confirm",cancel_button:String="Cancel") -> void:
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
	dialog.ok_button_text = confirm_button
	dialog.cancel_button_text = cancel_button
	if custom_button != "":
		var custom:Button = dialog.add_button(custom_button,custom_button_right,custom_action)
		dialog.custom_action.connect(custom_pressed)
		custom.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
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
	emit_signal("confirmation",true,"")


func cancel_pressed() -> void:
	emit_signal("confirmation",false,"")
	canvas.queue_free()


func custom_pressed(action:StringName) -> void:
	emit_signal("confirmation",true,action)
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


func clear_group(group:String) -> void:
	var nodes = get_tree().get_nodes_in_group(group)
	for node in nodes:
		node.remove_from_group(group)
		node.emit_signal("update_outliner")
