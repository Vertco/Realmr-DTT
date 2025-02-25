extends Control

@warning_ignore("unused_signal")
signal update_outliner

var path:String
var current_scale:Vector2
var gridsize:int = 1:
	set(value):
		gridsize = value
		if !current_scale:
			current_scale = Vector2(100.0/gridsize, 100.0/gridsize)
		%Image.scale = current_scale
var locked:bool = false:
	set(value):
		locked = value
		if locked:
			%Image.mouse_default_cursor_shape = 0
			%Image.mouse_filter = MOUSE_FILTER_IGNORE
			mouse_filter = MOUSE_FILTER_IGNORE
		else:
			%Image.mouse_default_cursor_shape = CURSOR_POINTING_HAND
			%Image.mouse_filter = MOUSE_FILTER_PASS
			mouse_filter = MOUSE_FILTER_PASS
var pc_vis:bool = true:
	set(value):
		pc_vis = value
		if pc_vis:
			%Image.set_visibility_layer_bit(19,true)
			%Image.material = null
			modulate = Color(1,1,1,1)
		else:
			%Image.set_visibility_layer_bit(19,false)
			var img_material := ShaderMaterial.new()
			img_material.shader = preload("res://media/shaders/highlight.gdshader")
			%Image.material = img_material
			modulate = Color(1,1,1,0.2)


func _on_image_gui_input(event: InputEvent) -> void:
	if event.is_action_pressed("map_multi_select"):
		multi_select()
		accept_event()
	elif event.is_action_pressed("map_select"):
		select()
		accept_event()


func select() -> bool:
	if is_in_group("selected"):
		if get_tree().get_nodes_in_group("selected").size() > 1:
			App.clear_group("selected")
			add_to_group("selected")
		else:
			App.clear_group("selected")
	else:
		App.clear_group("selected")
		add_to_group("selected")
	emit_signal("update_outliner")
	return is_in_group("selected")


func deselect() -> bool:
	if is_in_group("selected"):
		remove_from_group("selected")
	return is_in_group("selected")


func multi_select() -> bool:
	if is_in_group("selected"):
		remove_from_group("selected")
	else:
		add_to_group("selected")
	emit_signal("update_outliner")
	return is_in_group("selected")


func get_full_rect() -> Rect2:
	return %Image.get_rect()


func set_locked(value:bool) -> void:
	locked = value
	emit_signal("update_outliner")


func set_pc_vis(value:bool) -> void:
	pc_vis = value
	emit_signal("update_outliner")


func update(new_path:String = "") -> void:
	if new_path != "":
		path = new_path
	var metadata:Dictionary = {}
	var meta_path := path.get_basename() + ".import"
	
	# Read metadata from import file if it exists
	if FileAccess.file_exists(meta_path):
		var import_file := FileAccess.open(meta_path, FileAccess.READ)
		
		# Parse JSON data from import file
		var json := JSON.new()
		if json.parse(import_file.get_as_text()) == OK:
			metadata = json.get_data()
		call_deferred("set_meta","properties",metadata)
		import_file.close()
	gridsize = metadata.gridsize
	
	# Set %Image texture
	var image := Image.load_from_file(path)
	var image_texture := ImageTexture.create_from_image(image)
	if image && image_texture:
		%Image.texture = image_texture
		%Image.pivot_offset = image.get_size()/2
	emit_signal("update_outliner")


func save() -> Dictionary:
	var saveDict:Dictionary = {
		"filename" : get_scene_file_path(),
		"parent" : get_parent().get_path(),
		"pos_x" : position.x,
		"pos_y" : position.y,
		"scale_x" : current_scale.x,
		"scale_y" : current_scale.y,
		"rotation" : rotation,
		"path" : path,
		"locked" : locked,
		"pc_vis" : pc_vis
	}
	return saveDict
