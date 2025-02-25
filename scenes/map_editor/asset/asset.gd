extends Control

@warning_ignore("unused_signal")
signal pressed(path:String)
@warning_ignore("unused_signal")
signal show_in_file_manager(path:String)
@warning_ignore("unused_signal")
signal open_in_external_program(path:String)
@warning_ignore("unused_signal")
signal edit_properties(asset:Node)
@warning_ignore("unused_signal")
signal delete(path:String)

@onready var path:String
var selected:bool:
	set(value):
		selected = value
		if selected:
			set_self_modulate(Color(1,1,1))
		else:
			if hover:
				set_self_modulate(Color(1,1,1,0.5))
			else:
				set_self_modulate(Color(1,1,1,0))
var hover := false

func _ready() -> void:
	var asset := path.get_file()
	%PopupMenu.id_pressed.connect(_on_popup_menu_pressed)
	%Name.text = asset
	tooltip_text = asset
	load_asset(path)


@warning_ignore("shadowed_variable")
func load_asset(path: String) -> void:
	# Set asset type start load
	match path.get_extension():
		"folder", "import", "preview":
			return
		"png", "jpg", "jpeg", "webp":
			%PreviewImage.texture = preload("uid://bp754bpdffe3y") # image_LARGE
			%PopupMenu.set_item_disabled(2,false)
			%PopupMenu.set_item_icon_modulate(2,Color(1,1,1))
			set_meta("type", "image")
			
			# Add the image loading task to the thread pool
			WorkerThreadPool.add_task(_load_image_in_thread.bind(path))
		"md","txt":
			%PreviewImage.texture = preload("uid://fm5oeakptw53") # note_LARGE
			%PopupMenu.set_item_disabled(2,true)
			%PopupMenu.set_item_icon_modulate(2,Color(0.337,0.337,0.337))
		"mp3", "wav":
			pass


@warning_ignore("shadowed_variable")
func _load_image_in_thread(path: String) -> void:
	var image := Image.new()
	var texture:ImageTexture
	var meta_path := path.get_basename() + ".import"
	var preview_path := path.get_basename() + ".preview"
	var metadata:Dictionary = {}

	# Read metadata from import file if it exists
	if FileAccess.file_exists(meta_path):
		var import_file := FileAccess.open(meta_path, FileAccess.READ)
		
		# Parse JSON data from import file
		var json := JSON.new()
		if json.parse(import_file.get_as_text()) == OK:
			metadata = json.get_data()
		call_deferred("set_meta","properties",metadata)
		import_file.close()
	
	# Load image from file
	if FileAccess.file_exists(preview_path):
		var preview_file := FileAccess.open(preview_path, FileAccess.READ)
		var buffer := preview_file.get_buffer(preview_file.get_length())
		image.load_webp_from_buffer(buffer)
	else:
		var err = image.load(path)
		if err != OK:
			print("Failed to load image: ", path)
			return
	
	# Generate metadata if not found
	if metadata.size() == 0:
		# Set default gridsize
		var gridsize:float = 100.0
		
		# Generate preview file if needed
		if image.get_width() > 128 or image.get_height() > 128:
			var aspect := float(image.get_size().x) / float(image.get_size().y)
			
			# Resize the image
			image.resize(128, int(128 / aspect))
			
			# Save preview file
			var preview_file := FileAccess.open(preview_path, FileAccess.WRITE_READ)
			preview_file.store_buffer(image.save_webp_to_buffer())
			preview_file.close()
		
		# Extract gridsize from asset name if present
		var regex := RegEx.new()
		regex.compile("@\\d{2,3}[,.]?\\d{0,2}pps")
		var PPS := regex.search(path.get_file())
		if PPS:
			gridsize = PPS.get_string().replace("@", "").to_float()
		
		# Store metadata
		metadata["type"] = "image"
		metadata["gridsize"] = gridsize
		set_meta("properties",metadata)
		var json_string := JSON.stringify(metadata)
		var import_file := FileAccess.open(meta_path, FileAccess.WRITE)
		import_file.store_line(json_string)
		import_file.close()
	
	# Create texture from image
	texture = ImageTexture.create_from_image(image)

	# Use a signal to update the texture on the main thread
	call_deferred("_on_image_loaded", texture)


func update_properties(properties:Dictionary) -> void:
	var meta_path := path.get_basename() + ".import"
	var json_string := JSON.stringify(properties)
	var import_file := FileAccess.open(meta_path, FileAccess.WRITE)
	import_file.store_line(json_string)
	import_file.close()
	set_meta("properties", properties)


func _on_popup_menu_pressed(id:int) -> void:
	match id:
		0:
			emit_signal("show_in_file_manager", path)
		1:
			emit_signal("open_in_external_program", path)
		2:
			emit_signal("edit_properties", self)
		4:
			emit_signal("delete", path)


func _on_image_loaded(texture: ImageTexture) -> void:
	%PreviewImage.texture = texture

func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				selected = true
				emit_signal("pressed", path)
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			%PopupMenu.position = get_global_mouse_position()
			%PopupMenu.visible = true


func _on_mouse_entered() -> void:
	hover = true
	self_modulate = Color(1, 1, 1, 0.5)


func _on_mouse_exited() -> void:
	hover = false
	if selected:
		self_modulate = Color(1, 1, 1)
	else:
		set_self_modulate(Color(1, 1, 1, 0))
