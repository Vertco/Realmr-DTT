extends Control

const map_folder_scene:PackedScene = preload("res://scenes/main_menu/maps_folder/maps_folder.tscn")
const map_scene:PackedScene = preload("res://scenes/main_menu/map/map.tscn")
const new_folder:PackedScene = preload("res://scenes/main_menu/maps_folder_new/maps_folder_new.tscn")

@onready var current_folder:String = Preferences.maps_path
var selected:String
var folder_creator:Node

func _ready() -> void:
	Preferences.maps_path_changed.connect(update)
	update(current_folder)


func update(path:String) -> void:
	current_folder = path
	if current_folder == Preferences.maps_path:
		%UpLevelBTN.disabled = true
	else:
		%UpLevelBTN.disabled = false
	%PathLabel.text = path.right(path.length()-Preferences.maps_path.length())
	%PathLabel.tooltip_text = path
	for child in get_children():
		child.queue_free()
	var dir = DirAccess.open(path)
	var map_folders:PackedStringArray = dir.get_directories()
	var maps:PackedStringArray = dir.get_files()
	for f in map_folders:
		var folder:Node = map_folder_scene.instantiate()
		folder.path = current_folder+"\\"+f
		folder.pressed.connect(select)
		folder.double_pressed.connect(update)
		folder.show_in_file_manager.connect(show_in_file_manager)
		folder.delete.connect(delete)
		add_child(folder)
	for m in maps:
		if m.get_extension() == "rmm":
			var map:Node = map_scene.instantiate()
			map.path = current_folder+"\\"+m
			map.pressed.connect(select)
			map.double_pressed.connect(open_map)
			map.show_in_file_manager.connect(show_in_file_manager)
			map.delete.connect(delete)
			add_child(map)
	select()


func select(selected_map:String = "") -> void:
	selected = selected_map
	if selected != "":
		%OpenBTN.disabled = false
		%DeleteBTN.disabled = false
	else:
		%OpenBTN.disabled = true
		%DeleteBTN.disabled = true
	var maps:Array[Node] = get_children()
	for map in maps:
		if map.path != selected_map:
			map.selected = false


func open_map(path:String) -> void:
	if App.is_file(path):
		App.map_path = path
		get_tree().change_scene_to_file("res://scenes/map_editor/map_editor.tscn")


func delete(path:String) -> void:
	if App.is_file(path):
		App.confirm("Do you want to delete "+path.get_file()+"?", "Delete map?")
	else:
		App.confirm("Do you want to delete "+path.get_file()+" including its content?", "Delete folder?")
	var confirm = await App.confirmation
	if confirm[0]:
		OS.move_to_trash(path)
		update(current_folder)


func show_in_file_manager(path:String) -> void:
	OS.shell_show_in_file_manager(path)


func create_folder(folder_name:String) -> void:
	var dir = DirAccess.open(current_folder)
	dir.make_dir(folder_name)
	folder_creator = null
	update(current_folder)


func _on_up_level_btn_pressed() -> void:
	update(current_folder.get_base_dir())


func _on_select_map_btn_pressed() -> void:
	Preferences.open_maps_path_popup()


func _on_delete_btn_pressed() -> void:
	delete(selected)


func _on_open_btn_pressed() -> void:
	if App.is_file(selected):
		open_map(selected)
	else:
		update(selected)


func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if folder_creator:
			folder_creator.submit()
		if event.button_index == MOUSE_BUTTON_RIGHT:
			%MapsPopupMenu.position = get_global_mouse_position()
			%MapsPopupMenu.visible = true
		else:
			select()


func _on_maps_popup_menu_id_pressed(id: int) -> void:
	match id:
		0:
			folder_creator = new_folder.instantiate()
			folder_creator.created.connect(create_folder)
			add_child(folder_creator)
		1:
			OS.shell_show_in_file_manager(current_folder)
