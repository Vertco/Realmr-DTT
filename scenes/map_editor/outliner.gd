extends Control

func _ready() -> void:
	%Canvas.child_order_changed.connect(update)
	%Canvas.child_entered_tree.connect(update)
	%Canvas.child_exiting_tree.connect(update)


func update(node:Node = null) -> void:
	if node:
		pass
	else:
		for asset in %OutlinerContainer.get_children():
			asset.queue_free()
		for asset in %Canvas.get_children():
			var item := preload("uid://cd4qm1naix887").instantiate()
			item.asset = asset
			%OutlinerContainer.add_child(item)
			item.update()
