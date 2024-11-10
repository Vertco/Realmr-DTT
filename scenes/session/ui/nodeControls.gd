extends Control

var selectedNodes:Array[Node]:
	get:
		var nodes:Array[Node] = get_tree().get_nodes_in_group("selected")
		return nodes

func _on_visButton_pressed() -> void:
	for node in selectedNodes:
		node.playerVis = !node.playerVis

func _on_lockButton_pressed() -> void:
	for node in selectedNodes:
		node.locked = !node.locked

func _on_delButton_pressed() -> void:
	for node in selectedNodes:
		node.queue_free()
