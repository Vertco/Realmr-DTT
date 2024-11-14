class_name ImageAsset
extends CanvasAsset

var gridsize:int = 1:
	set(value):
		gridsize = value
		localScale = Vector2(100.0/gridsize, 100.0/gridsize)
		%image.scale = localScale
		%imageOverlay.scale = localScale
var localScale:Vector2
var _dragging:bool = false
var dragAccum:Vector2 = Vector2.ONE

func _ready() -> void:
	loadTexture(file)
	connect("file_changed", loadTexture)
	connect("selection_changed", updateSelectionOverlay)
	connect("lock_changed", updateLocked)

@warning_ignore("shadowed_variable")
func loadTexture(imgFile) -> void:
	if imgFile:
		var img:= Image.new()
		img.load(imgFile)
		%image.pivot_offset = img.get_size()/2
		%imageOverlay.pivot_offset = img.get_size()/2
		%image.texture = ImageTexture.create_from_image(img)
		%imageOverlay.texture = ImageTexture.create_from_image(img)

func rotate_node(degrees):
	rotation_degrees += degrees

func updateSelectionOverlay(select) -> void:
	for l in range(9):
		%imageOverlay.set_visibility_layer_bit(l, false)
	%imageOverlay.set_visibility_layer_bit(10, true)
	%imageOverlay.visible = select

func updateLocked(lock) -> void:
	if lock:
		mouse_filter = MOUSE_FILTER_IGNORE
		%image.mouse_filter = MOUSE_FILTER_IGNORE
		%imageOverlay.mouse_filter = MOUSE_FILTER_IGNORE
	else:
		mouse_filter = MOUSE_FILTER_PASS
		%image.mouse_filter = MOUSE_FILTER_PASS
		%imageOverlay.mouse_filter = MOUSE_FILTER_PASS

func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and _dragging and selected:
		dragAccum += event.relative.rotated(rotation) * localScale
		if Input.is_key_pressed(KEY_CTRL):
			if dragAccum.length() >= 50:
				global_position = snap_to_grid(global_position + dragAccum)
				dragAccum = Vector2.ZERO
		else:
			global_position += event.relative.rotated(rotation) * localScale
			dragAccum = Vector2.ZERO
	elif Input.is_key_pressed(KEY_SHIFT) and !locked:
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_WHEEL_UP:
			rotate_node(5)  # Rotate 5 degrees clockwise
			accept_event()
		elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			rotate_node(-5)  # Rotate 5 degrees counterclockwise
			accept_event()
	elif event is InputEventMouseButton and !locked:
		if event.button_index == MOUSE_BUTTON_LEFT:
			_dragging = event.pressed
			if event.double_click:
				selected = !selected
			accept_event()

func snap_to_grid(pos: Vector2) -> Vector2:
	return Vector2(
		round(pos.x / 50) * 50,
		round(pos.y / 50) * 50
	)

func update() -> void:
	initiated = true

func save() -> Dictionary:
	var saveDict:Dictionary = {
		"filename" : get_scene_file_path(),
		"parent" : get_parent().get_path(),
		"pos_x" : position.x, # Vector2 is not supported by JSON
		"pos_y" : position.y,
		"scale_x" : scale.x,
		"scale_y" : scale.y,
		"rotation" : rotation,
		"locked" : locked,
		"playerVis" : playerVis,
		"layer" : layer,
		"file" : file,
		"gridsize" : gridsize
	}
	return saveDict
