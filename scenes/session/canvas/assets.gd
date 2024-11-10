extends Node

func _ready() -> void:
	session.connect("layerChanged", updateOutliner)

func updateOutliner() -> void:
	var children:Array[Node] = get_children()
	session.emit_signal("updateOutliner", children)
