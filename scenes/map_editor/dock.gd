extends Control

const folder_icon := preload("res://media/icons/folder.svg")
const asset_scene := preload("res://scenes/map_editor/asset/asset.tscn")
const new_folder := preload("res://scenes/main_menu/maps_folder_new/maps_folder_new.tscn")

var current_dir:String
var current_asset:String
var folder_creator:Node

func _on_assets_container_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			%AssetsPopupMenu.position = get_global_mouse_position()
			%AssetsPopupMenu.visible = true
			current_asset = ""
			select()
		elif event.button_index == MOUSE_BUTTON_LEFT:
			current_asset = ""
			select()


func _on_assets_popup_menu_id_pressed(id: int) -> void:
	match id:
		0:
			folder_creator = new_folder.instantiate()
			folder_creator.created.connect(create_folder)
			%AssetsContainer.add_child(folder_creator)
		1:
			show_in_file_manager(ProjectSettings.globalize_path(current_dir))


func create_folder(folder_name:String) -> void:
	var dir = DirAccess.open(current_dir)
	print("Creating folder "+current_dir+"/"+folder_name)
	dir.make_dir(folder_name)
	folder_creator = null
	update_tree()


func update() -> void:
	update_tree()


func update_tree() -> void:
	# Clears and resets the session tree, adding a root item
	%AssetsTree.clear()
	var tree_root:TreeItem = %AssetsTree.create_item()
	tree_root.set_text(0, "assets")
	tree_root.set_icon(0, folder_icon)
	tree_root.set_metadata(0,ProjectSettings.localize_path(App.cache_location+"/assets"))

	# Recursively list directories
	list_dirs(App.cache_location+"/assets", tree_root)
	
	# List assets in assets folder
	list_assets(App.cache_location+"/assets")


func list_dirs(path:String, parent:TreeItem) -> void:
	# Lists directories within the specified path
	var dir = DirAccess.open(path)
	if dir == null:
		print("Error opening directory: "+path)
		return
	dir.list_dir_begin()
	var dir_name = dir.get_next()
	while dir_name != "":
		# For each directory, create a tree item and recurse
		if dir.current_is_dir():
			var dir_item:TreeItem = %AssetsTree.create_item(parent)
			dir_item.set_text(0, dir_name)
			dir_item.set_icon(0, folder_icon)
			dir_item.set_metadata(0,path+"/"+dir_name)
			list_dirs(path + "/" + dir_name, dir_item)
		dir_name = dir.get_next()
	dir.list_dir_end()


func list_assets(path:String) -> void:
	# List assets in current_dir
	for asset in %AssetsContainer.get_children():
		if asset.get_name() != "AssetNew":
			asset.queue_free()
	var dir := DirAccess.open(path)
	for file in dir.get_files():
		match file.get_extension():
			"folder","import", "preview":
				pass
			_:
				var asset := asset_scene.instantiate()
				asset.path = path+"/"+file
				asset.pressed.connect(select)
				asset.show_in_file_manager.connect(show_in_file_manager)
				asset.open_in_external_program.connect(open_in_external_program)
				asset.edit_properties.connect(edit_properties)
				asset.delete.connect(delete_asset)
				%AssetsContainer.add_child(asset)
	move_asset_new()


func move_asset_new() -> void:
	%AssetsContainer.move_child(%AssetNew,%AssetsContainer.get_child_count())


func select(selected_asset:String = "") -> void:
	current_asset = selected_asset
	var assets := %AssetsContainer.get_children()
	for asset in assets:
		if asset.get_name() != "AssetNew":
			if asset.path != current_asset:
				asset.selected = false


func show_in_file_manager(path:String) -> void:
	OS.shell_show_in_file_manager(ProjectSettings.globalize_path(path))


func open_in_external_program(path:String) -> void:
	OS.shell_open(ProjectSettings.globalize_path(path))


func edit_properties(asset:Node) -> void:
	if %AssetPropsPopup.confirmed.is_connected(update_properties):
		%AssetPropsPopup.confirmed.disconnect(update_properties)
		%AssetPropsPopup.confirmed.connect(update_properties.bind(asset))
	else:
		%AssetPropsPopup.confirmed.connect(update_properties.bind(asset))
	%AssetPropsPopup.title = asset.path.get_file()
	%GridSize.value = asset.get_meta("properties").gridsize
	%AssetPropsPopup.visible = true


func update_properties(asset:Node) -> void:
	var meta:Dictionary = asset.get_meta("properties")
	meta.gridsize = %GridSize.value
	asset.update_properties(meta)


func delete_asset(path:String) -> void:
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	list_assets(current_dir)


func import_files(files:PackedStringArray) -> void:
	for file in files:
		match file.get_extension():
			# Import images as webp images
			"png", "jpg", "jpeg", "webp":
				var image := Image.new()
				image.load(file)
				var imported_image := Image.new()
				imported_image.copy_from(image)
				var buffer := imported_image.save_webp_to_buffer()
				var filename := current_dir+"/"+file.get_file().get_basename()+".webp"
				var new_file := FileAccess.open(filename, FileAccess.WRITE_READ)
				new_file.store_buffer(buffer)
				new_file.close()
			"md", "txt":
				DirAccess.copy_absolute(file,ProjectSettings.globalize_path(current_dir+"/"+file.get_file()))
			_:
				continue
		list_assets(current_dir)


func _on_assets_tree_item_selected() -> void:
	current_dir = %AssetsTree.get_selected().get_metadata(0)
	list_assets(current_dir)


func _on_asset_new_pressed() -> void:
	var popup := FileDialog.new()
	popup.file_mode = FileDialog.FILE_MODE_OPEN_FILES
	popup.access = FileDialog.ACCESS_FILESYSTEM
	popup.use_native_dialog = true
	popup.add_filter("*.png,*.jpg,*.jpeg,*.webp","Bitmap images")
	popup.add_filter("*.md,*.txt","Notes")
	popup.ok_button_text = "Import"
	popup.dialog_hide_on_ok = true
	popup.title = "Import files"
	popup.initial_position = Window.WINDOW_INITIAL_POSITION_CENTER_MAIN_WINDOW_SCREEN
	popup.files_selected.connect(import_files)
	popup.visible = true
