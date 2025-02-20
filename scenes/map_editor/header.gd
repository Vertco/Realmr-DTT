extends Control

var file_popup:PopupMenu
var pc_popup:PopupMenu

func _ready() -> void:
	# Connect popup menu id_pressed events
	file_popup = %FileMenu.get_popup()
	pc_popup = %PcMenu.get_popup()
	file_popup.id_pressed.connect(_on_file_menu_id_pressed)
	pc_popup.id_pressed.connect(_on_pc_menu_id_pressed)
	
	# Add FileMenu items
	file_popup.add_icon_item(preload("res://media/icons/file_new.svg"),"New",0)
	file_popup.add_icon_item(preload("res://media/icons/folder_open.svg"),"Open...",1)
	
	# Add OpenRecent submenu to FileMenu
	file_popup.add_submenu_node_item("Open recent  ",PopupMenu.new(),2)
	file_popup.set_item_icon(file_popup.get_item_indent(2)-1,preload("res://media/icons/folder_open_recent.svg"))
	
	# Style OpenRecent submenu
	#var theme_override:StyleBox = open_recent.get_theme_stylebox("panel").duplicate()
	#theme_override.corner_radius_top_right = 5
	#if open_recent.item_count < 5:
		#theme_override.corner_radius_bottom_left = 0
	#open_recent.add_theme_stylebox_override("panel", theme_override)
	
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
	var _id := 0
	open_recent.id_pressed.connect(_on_recents_menu_id_pressed)
	for recent in App.recents:
		open_recent.add_item(recent.get_file().get_basename())
		#if recent == App.map_path:
			#open_recent.set_item_disabled(id, true)
		_id =+ 1
	return open_recent


func update_recents_menu() -> void:
	var open_recent:PopupMenu = PopupMenu.new()
	var index := 0
	open_recent.id_pressed.connect(_on_recents_menu_id_pressed)
	for recent in App.recents:
		open_recent.add_item(recent.get_file().get_basename())
		if recent == App.map_path:
			open_recent.set_item_disabled(index, true)
		index =+ 1
	
	# Style OpenRecent submenu
	var theme_override:StyleBox = open_recent.get_theme_stylebox("panel").duplicate()
	theme_override.corner_radius_top_right = 5
	if open_recent.item_count < 5:
		theme_override.corner_radius_bottom_left = 0
	open_recent.add_theme_stylebox_override("panel", theme_override)
	
	var popup := file_popup.get_item_submenu_node(2)
	popup.queue_free()
	
	file_popup.set_item_submenu_node(2,open_recent)


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


func _on_recents_menu_id_pressed(id:int) -> void:
	App.add_recent(App.map_path)
	get_node("/root/MapEditor").load_map(App.recents[id])


func _on_file_menu_id_pressed(id:int) -> void:
	match id:
		0:
			get_node("/root/MapEditor").open_new_map_popup(true)
		1:
			var popup := FileDialog.new()
			popup.file_mode = FileDialog.FILE_MODE_OPEN_FILE
			popup.access = FileDialog.ACCESS_FILESYSTEM
			popup.use_native_dialog = true
			popup.add_filter("*.rmm","Realmr maps")
			popup.ok_button_text = "Import"
			popup.dialog_hide_on_ok = true
			popup.current_path = Preferences.maps_path
			popup.initial_position = Window.WINDOW_INITIAL_POSITION_CENTER_MAIN_WINDOW_SCREEN
			popup.file_selected.connect(get_node("/root/MapEditor").load_map)
			popup.visible = true
		4:
			get_node("/root/MapEditor").save_map()
		6:
			OS.shell_show_in_file_manager(ProjectSettings.globalize_path(App.cache_location))
		8:
			App.confirm("Do you want to quit to main?", "Quit to main?","Save and Confirm",false,"save_and_quit")
			var confirm = await App.confirmation
			if confirm[0]:
				if confirm[1] == "save_and_quit":
					await get_node("/root/MapEditor").save_map(false)
				App.add_recent(App.map_path)
				%PcWindow.size_changed.disconnect(%PcCamControl.update)
				get_window().size_changed.disconnect(%PcCamControl.update)
				%PcCamera.item_rect_changed.disconnect(%PcCamControl.update)
				App.map_path = ""
				get_tree().change_scene_to_file("res://scenes/main_menu/main_menu.tscn")
			else:
				pass
		9:
			App.confirm("Do you want to quit Realmr?", "Quit Realmr?","Save and Quit",false,"save_and_quit","Quit","Cancel")
			var confirm = await App.confirmation
			if confirm[0]:
				if confirm[1] == "save_and_quit":
					get_node("/root/MapEditor").save_map()
				%PcWindow.size_changed.disconnect(%PcCamControl.update)
				get_window().size_changed.disconnect(%PcCamControl.update)
				%PcCamera.item_rect_changed.disconnect(%PcCamControl.update)
				get_tree().quit()
			else:
				pass


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
