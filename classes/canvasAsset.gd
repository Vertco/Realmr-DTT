class_name CanvasAsset
extends Control

@warning_ignore("unused_signal")
signal selection_changed(selected:bool)
@warning_ignore("unused_signal")
signal lock_changed(locked:bool)
@warning_ignore("unused_signal")
signal playerVis_changed(playerVis:bool)
@warning_ignore("unused_signal")
signal file_changed(file:String)

@export var selected:bool:
	set(value):
		for node in get_tree().get_nodes_in_group("selected"):
			if node != self:
				node.selected = false
		selected = value
		if selected:
			add_to_group("selected")
		else:
			remove_from_group("selected")
		session.emit_signal("updateOutlinerItem", get_index(true))
		emit_signal("selection_changed", value)
@export var locked:bool:
	set(value):
		locked = value
		if locked:
			selected = false
		emit_signal("lock_changed", locked)
		session.emit_signal("updateOutlinerItem", get_index(true))
@export var playerVis:bool = true:
	set(value):
		playerVis = value
		if playerVis:
			modulate = "#ffffff"
			updateLayer(layer)
		else:
			modulate = "ffffff20"
			updateLayer(9)
		emit_signal("playerVis_changed", playerVis)
@export_range(0, 8) var layer:int:
	set(value):
		layer = value
		updateLayer(value)
@export_file var file:String:
	set(value):
		file = value
		emit_signal("file_changed", file)

func _ready() -> void:
	if playerVis:
		updateLayer(layer)

func updateLayer(l:int) -> void:
	var children:Array[Node] = get_children()
	for i in range(9):
		set_visibility_layer_bit(i, false)
		for child in children:
			child.set_visibility_layer_bit(i, false)
	set_visibility_layer_bit(l, true)
	for child in children:
		child.set_visibility_layer_bit(l, true)
