extends Control

@warning_ignore("unused_signal")
signal deleteFile(file:String)

@export var filePath:String:
	set(value):
		filePath = value
		file = value.get_file()
		tooltip_text = file
		%fileLabel.text = file
var file:String
var metadata:Dictionary
var preview:ImageTexture

func _ready() -> void:
	update()

func update() -> void:
	set_tooltip_text(file)
	%fileLabel.text = file
	match metadata.type:
		"image":
			%filePreview.texture = _load_image()
		"audio":
			var image:= Image.new()
			image.load("res://media/icons/sound.svg")
			var texture:= ImageTexture.create_from_image(image)
			%filePreview.texture = texture

@warning_ignore("shadowed_variable")
func _load_image() -> ImageTexture:
	var image:= Image.new()
	var texture:ImageTexture
	if metadata.preview:
		var previewPath = filePath.rsplit(".", false, 1)[0] + ".preview"
		var f = FileAccess.open(previewPath, FileAccess.READ)
		var buffer = f.get_buffer(f.get_length())
		image.load_webp_from_buffer(buffer)
		texture = ImageTexture.create_from_image(image)
		preview = texture
	else:
		image.load(filePath)
		texture = ImageTexture.create_from_image(image)
		preview = texture
	return texture

func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		session.newAsset = self

func _on_mouse_entered() -> void:
	modulate = Color(1.5,1.5,1.5)
	%deleteButton.visible = true

func _on_mouse_exited() -> void:
	modulate = Color(1,1,1)
	if %deleteButton:
		%deleteButton.visible = false

func _on_deleteButton_pressed() -> void:
	emit_signal("deleteFile", file)
