extends Control

const imageIcon = preload("res://media/icons/image.svg")
const soundIcon = preload("res://media/icons/sound.svg")
const unlockedIcon = preload("res://media/icons/unlocked.svg")
const lockedIcon = preload("res://media/icons/locked.svg")
const visibleIcon = preload("res://media/icons/visible.svg")
const hiddenIcon = preload("res://media/icons/hidden.svg")

@export var node:Node:
	set(value):
		node = value
		update()

func _ready() -> void:
	update()

func update() -> void:
	match node.get_class():
		ImageAsset:
			%type.texture = imageIcon
		#AudioAsset:
			#%type.texture = soundIcon
	%label.text = node.file.get_file()
	tooltip_text = node.file.get_file()
	if node.playerVis:
		%visibility.icon = visibleIcon
	elif !node.playerVis:
		%visibility.icon = hiddenIcon
	if node.locked:
		%lock.icon = lockedIcon
	elif !node.locked:
		%lock.icon = unlockedIcon
	if node.selected:
		self_modulate = "#ffffffff"
	elif !node.selected:
		self_modulate = "#ffffff00"

func _on_visibility_pressed() -> void:
	node.playerVis = !node.playerVis
	update()

func _on_lock_pressed() -> void:
	node.locked = !node.locked
	update()

func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				node.selected = !node.selected
				update()
		if event.button_index == MOUSE_BUTTON_RIGHT:
			%popupMenu.position = get_global_mouse_position()
			%popupMenu.visible = true
