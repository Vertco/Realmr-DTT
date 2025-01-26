extends Control

func _ready() -> void:
	# Connect popup menu id_pressed events
	var file_popup:PopupMenu = %FileMenu.get_popup()
	var pc_popup:PopupMenu = %PcMenu.get_popup()
	file_popup.id_pressed.connect(_on_file_menu_id_pressed)
	pc_popup.id_pressed.connect(_on_pc_menu_id_pressed)
	
	# Add FileMenu items
	file_popup.add_icon_item(preload("res://media/icons/file_new.svg"),"New",0)
	file_popup.add_icon_item(preload("res://media/icons/folder_open.svg"),"Open...",1)
	
	# Add OpenRecent submenu to FileMenu
	var open_recent = generate_open_recent()
	file_popup.add_submenu_node_item("Open recent  ",open_recent,2)
	file_popup.set_item_icon(file_popup.get_item_indent(2)-1,preload("res://media/icons/folder_open_recent.svg"))
	
	# Style OpenRecent submenu
	var theme_override:StyleBox = open_recent.get_theme_stylebox("panel").duplicate()
	theme_override.corner_radius_top_right = 5
	if open_recent.item_count < 5:
		theme_override.corner_radius_bottom_left = 0
	open_recent.add_theme_stylebox_override("panel", theme_override)
	
	# Add FileMenu items
	file_popup.add_separator("",3)
	file_popup.add_icon_item(preload("res://media/icons/save.svg"),"Save",4)
	file_popup.add_separator("",5)
	file_popup.add_icon_item(preload("res://media/icons/open_external.svg"),"Show files",6)
	file_popup.add_separator("",7)
	file_popup.add_icon_item(preload("res://media/icons/home.svg"),"Quit to main",8)
	file_popup.add_icon_item(preload("res://media/icons/quit.svg"),"Quit",9)


func generate_open_recent() -> PopupMenu:
	var open_recent:PopupMenu = PopupMenu.new()
	open_recent.add_item("Example")
	return open_recent


func _on_pc_menu_about_to_popup() -> void:
	var popup:PopupMenu = %PcMenu.get_popup()
	if %PcWindow.visible:
		popup.set_item_icon(0,preload("res://media/icons/pc_view_close.svg"))
		popup.set_item_text(0,"Close")
	else:
		popup.set_item_icon(0,preload("res://media/icons/open_external.svg"))
		popup.set_item_text(0,"Open")
	if %PcOverlay.visible:
		popup.set_item_icon(1,preload("res://media/icons/pc_view.svg"))
		popup.set_item_text(1,"Reveal")
	else:
		popup.set_item_icon(1,preload("res://media/icons/pc_view_hidden.svg"))
		popup.set_item_text(1,"Cover")


func _on_file_menu_id_pressed(id:int) -> void:
	match id:
		8:
			App.confirm("Do you want to quit to main?", "Quit to main?")
			var confirm = await App.confirmation
			if confirm:
				get_tree().change_scene_to_file("res://scenes/main_menu/main_menu.tscn")
		9:
			App.confirm("Do you want to quit Realmr?", "Quit Realmr?")
			var confirm = await App.confirmation
			if confirm:
				get_tree().quit()


func _on_pc_menu_id_pressed(id:int) -> void:
	match id:
		0:
			if %PcWindow.visible:
				%PcWindow.visible = false
			else:
				%PcViewPopup.popup_centered()
		1:
			%PcOverlay.visible = !%PcOverlay.visible
		2:
			%PcSettings.popup_centered()
