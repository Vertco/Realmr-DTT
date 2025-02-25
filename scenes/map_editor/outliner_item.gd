extends Control

var asset:Node
var path:String

func update() -> void:
	path = asset.path
	%Label.text = path.get_file()
	tooltip_text = path.get_file()
	if !asset.is_connected("update_outliner", update):
		asset.connect("update_outliner", update)
	if asset.is_in_group("selected"):
		self_modulate = "#ffffffff"
	elif !asset.is_in_group("selected"):
		self_modulate = "#ffffff00"
	set_icons()


func set_icons() -> void:
	if asset.pc_vis:
		%VisButton.icon = preload("uid://bkb5bvkic3wn5")
	else:
		%VisButton.icon = preload("uid://cwjoo48cxfep7")
	if asset.locked:
		%LockButton.icon = preload("uid://dlspyivnh08k6")
	else:
		%LockButton.icon = preload("uid://bme838l035yws")


func _on_vis_button_pressed() -> void:
	asset.set_pc_vis(!asset.pc_vis)


func _on_lock_button_pressed() -> void:
	asset.set_locked(!asset.locked)


func _on_gui_input(event: InputEvent) -> void:
	if event.is_action_pressed("map_multi_select"):
		asset.multi_select()
	elif event.is_action_pressed("map_select"):
		asset.select()
