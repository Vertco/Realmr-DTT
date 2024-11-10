extends Control

@onready var gmCam:Camera2D = get_tree().get_root().get_camera_2d()

var selectedNodes:Array[Node]:
	get:
		var nodes:Array[Node] = get_tree().get_nodes_in_group("selected")
		print(nodes)
		return nodes

var rotating:bool

func _process(_delta) -> void:
	if selectedNodes:
		visible = true
		%nodeControls.visible = true
		for node in selectedNodes:
			var nodeSize:Vector2 = node.size * node.scale
			set_position(node.get_global_transform_with_canvas().origin)
			set_size(nodeSize * gmCam.zoom)
			rotation = node.rotation
	else:
		visible = false
		%nodeControls.visible = false

func _on_visButton_pressed() -> void:
	for node in selectedNodes:
		node.playerVis = !node.playerVis

func _on_lockButton_pressed() -> void:
	for node in selectedNodes:
		node.locked = !node.locked

func _on_delButton_pressed() -> void:
	for node in selectedNodes:
		node.queue_free()
