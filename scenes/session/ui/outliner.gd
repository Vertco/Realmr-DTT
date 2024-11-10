extends Control

const lockedIcon:Texture2D = preload("res://media/icons/locked.svg")
const outlinerItem = preload("res://scenes/session/ui/outlinerItem.tscn")

var cache:Array[Node]
@onready var scrollbar = %outlinerContainer.get_v_scroll_bar()

func _ready() -> void:
	session.updateOutliner.connect(updateTree)
	session.updateOutlinerItem.connect(updateItem)
	scrollbar.set_visibility_layer_bit(0, false)
	scrollbar.set_visibility_layer_bit(10, true)

func updateItem(index:int) -> void:
	var itemV2 = %outlinerTree.get_child(index)
	itemV2.update()

func updateTree(nodes:Array) -> void:
	for child in %outlinerTree.get_children():
		child.queue_free()
	for node in nodes:
		if node.layer == session.activeLayer and root:
			var itemV2 = outlinerItem.instantiate()
			itemV2.node = node
			%outlinerTree.add_child(itemV2)

func _on_outlinerTree_multi_selected(item:TreeItem, column:int, selected:bool) -> void:
	item.get_metadata(column).selected = selected
