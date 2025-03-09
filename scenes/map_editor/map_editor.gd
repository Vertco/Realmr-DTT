extends Control

@warning_ignore("unused_signal")
signal pc_overlay_visibility_changed
@warning_ignore("unused_signal")
signal load_complete

const image_asset := preload("uid://d3vfv64vt25vc") # image_asset

@export var max_gm_zoom:float = 0.025
@export var min_gm_zoom:float = 4.0
@export var gm_zoom_incr:float = 0.05
@export var gm_zoom:float = 1.0
var gm_cam_drag:bool = false
var initiated:bool = false

func _ready() -> void:
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_MAXIMIZED)
	get_window().title = ProjectSettings.get_setting("application/config/name")+" | "+App.map_path.get_file().get_basename()
	get_tree().set_auto_accept_quit(false)
	get_window().set_canvas_cull_mask_bit(19, false)
	%GmViewport.world_2d = get_world_2d()
	%PcWindow.world_2d = get_world_2d()
	%PcWindow.size_changed.connect(%PcCamControl.update)
	get_window().size_changed.connect(%PcCamControl.update)
	%PcCamera.item_rect_changed.connect(%PcCamControl.update)
	%GmViewport.size_changed.connect(%PcCamControl.update)
	load_complete.connect(%Dock.update)
	%PcCamControl.update()
	if App.map_path:
		load_map(App.map_path)
	emit_signal("load_complete")
	initiated = true


func update_gizmos() -> void:
	%PcOverlay.visible = true
	%Outliner.update()
	%GmGridRenderer.queue_redraw()
	%PcCamControl.update()


func open_new_map_popup(clear:bool,warning:String="") -> void:
	%NewMapWarning.visible = false
	if clear:
		%NewMapName.clear()
	if warning != "":
		%NewMapWarning.text = warning
		%NewMapWarning.visible = true
	%NewMapPopup.visible = true
	%NewMapName.grab_focus()


func create_map(map_name:String) -> void:
	var path:String = Preferences.maps_path
	var dir = DirAccess.open(path)
	var maps:PackedStringArray = dir.get_files()
	if maps.has(map_name+".rmm"):
		open_new_map_popup(false,"Map already exists!")
	else:
		var map_save:Dictionary = {
			gm_zoom = 1,
			pc_position_x = 0,
			pc_position_y = 0
		}
		var json_string = JSON.stringify(map_save)
		var zip:ZIPPacker = ZIPPacker.new()
		zip.open(Preferences.maps_path+"/"+map_name+".rmm")
		zip.start_file("map.save")
		zip.write_file(json_string.to_utf8_buffer())
		zip.close_file()
		zip.start_file("assets/audio/empty.folder")
		zip.close_file()
		zip.start_file("assets/images/empty.folder")
		zip.close_file()
		zip.start_file("assets/notes/empty.folder")
		zip.close_file()
		zip.close()
		App.add_recent(App.map_path)
		App.map_path = Preferences.maps_path+"\\"+map_name+".rmm"
		load_map(App.map_path)


func _on_new_map_popup_confirmed() -> void:
	create_map(%NewMapName.text)


func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		App.confirm("Do you want to quit Realmr?", "Quit Realmr?","Save and Quit",false,"save_and_quit","Quit","Cancel")
		var confirm = await App.confirmation
		if confirm[0]:
			if confirm[1] == "save_and_quit":
				if !await save_map():
					return
			App.add_recent(App.map_path)
			get_tree().quit()
		else:
			fix_default_folders()
			pass


func _unhandled_input(event: InputEvent) -> void:
	# Handle camera controls
	if event.is_action_pressed("cam_drag"):
		gm_cam_drag = true
	elif event.is_action_released("cam_drag"):
		gm_cam_drag = false
	elif event.is_action("cam_zoom_in"):
		update_gm_zoom(gm_zoom_incr)
		%GmGridRenderer.queue_redraw()
		%PcCamControl.update()
	elif event.is_action("cam_zoom_out"):
		update_gm_zoom(-gm_zoom_incr)
		%GmGridRenderer.queue_redraw()
		%PcCamControl.update()
	elif event.is_action_pressed("map_save"):
		save_map()
	elif event.is_action_pressed("map_delete"):
		var nodes = get_tree().get_nodes_in_group("selected")
		for node in nodes:
			node.queue_free()
		%Outliner.update()
	elif event.is_action_pressed("ui_cancel"):
		%Dock.select()
		App.clear_group("selected")
	elif event.is_action_released("map_select"):
		if %Dock.current_asset:
			var asset := image_asset.instantiate()
			asset.update(%Dock.current_asset)
			%Canvas.add_child(asset)
			asset.set_position(%Canvas.get_global_mouse_position())
	elif event is InputEventMouseMotion && gm_cam_drag:
		var new_offset = %GmCamera.get_offset() - event.relative/gm_zoom
		new_offset.x = new_offset.x
		new_offset.y = new_offset.y
		%GmCamera.set_offset(new_offset)
		%GmGridRenderer.queue_redraw()
		%PcCamControl.update()
	elif event.is_action_pressed("map_select") || event.is_action_pressed("map_deselect"):
		App.clear_group("selected")


func _exit_tree() -> void:
	var signals:Array[Signal] = [
		%PcWindow.size_changed,
		get_window().size_changed,
		%PcCamera.item_rect_changed,
		%GmViewport.size_changed
	]
	for s in signals:
		if s.is_connected(%PcCamControl.update):
			s.disconnect(%PcCamControl.update)


func load_map(path:String) -> void:
	extract_map(path)
	if FileAccess.file_exists(App.cache_location+"/map.save"):
		var save_file := FileAccess.open(App.cache_location+"/map.save", FileAccess.READ)
		var json = JSON.new()
		var json_string:String = save_file.get_as_text()
		var parse_result = json.parse(json_string)
		if not parse_result == OK:
			print("JSON Parse Error: ", json.get_error_message(), " in ", json_string, " at line ", json.get_error_line())
		var save_nodes := get_tree().get_nodes_in_group("persist")
		for node in save_nodes:
			node.queue_free()
		for save in json.get_data().keys():
			match save:
				"gm_zoom":
					set_gm_zoom(json.get_data()[save])
				"pc_position_x":
					%PcCamera.set_offset(Vector2(json.get_data()[save],%PcCamera.offset.y))
				"pc_position_y":
					%PcCamera.set_offset(Vector2(%PcCamera.offset.x,json.get_data()[save]))
				"version":
					App.map_version = App.get_version_vector(json.get_data()[save])
				"nodes":
					var nodes = json.get_data()[save]
					for nodeData in nodes:
						if not nodeData.has("filename") or not nodeData.has("parent"):
							print("Node data is missing required fields: ", nodeData)
							continue
						var newObject = load(nodeData["filename"]).instantiate()
						get_node(nodeData["parent"]).add_child(newObject)
						newObject.position = Vector2(nodeData["pos_x"], nodeData["pos_y"])
						for key in nodeData.keys():
							if key == "filename" or key == "parent" or key == "pos_x" or key == "pos_y":
								continue
							newObject.set(key, nodeData[key])
						if newObject.has_method("update"):
							newObject.update()
	App.map_path = path
	update_gizmos()
	App.add_recent(path)
	%Header.update_recents_menu()


func save_map(background:bool=true) -> bool:
	var map_save:Dictionary = {
		gm_zoom = %GmCamera.zoom.x,
		pc_position_x = %PcCamera.offset.x,
		pc_position_y = %PcCamera.offset.y,
		version = ProjectSettings.get_setting("application/config/version"),
		nodes = []
	}
	var save_nodes := get_tree().get_nodes_in_group("persist")
	for node in save_nodes:
		if node.scene_file_path.is_empty():
			print("Savable node " + node.name + " is not an instanced scene, skipped")
			continue
		if !node.has_method("save"):
			print("Savable node " + node.name + " is missing a saveData() function, skipped saving")
			continue
		var node_data = node.call("save")
		map_save["nodes"].append(node_data)  # Append node data to the nodes array in saveData
	var json_string = JSON.stringify(map_save)
	if !DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(App.cache_location)):
		DirAccess.make_dir_absolute(App.cache_location)
	var file:FileAccess = FileAccess.open(App.cache_location+"/map.save",FileAccess.WRITE)
	file.store_string(json_string)
	file.close()
	fix_default_folders()
	var task := WorkerThreadPool.add_task(pack_map.bind(App.map_path))
	if !background:
		WorkerThreadPool.wait_for_task_completion(task)
	return true


func extract_map(path:String) -> void:
	var zip:ZIPReader = ZIPReader.new()
	var error := zip.open(path)
	if error != OK:
		return PackedByteArray()
	var dir:DirAccess = DirAccess.open(App.cache_location.get_base_dir())
	if dir.dir_exists(App.cache_location.get_file()):
		delete_recursive(App.cache_location)
	for file in zip.get_files():
		if dir.dir_exists(App.cache_location.get_file()+"/"+file.get_base_dir()):
			if !file.ends_with("/"):
				var file_access:FileAccess = FileAccess.open(App.cache_location+"/"+file,FileAccess.WRITE)
				var data:PackedByteArray = zip.read_file(file)
				file_access.store_buffer(data)
		else:
			dir.make_dir_recursive(App.cache_location.get_file()+"/"+file.get_base_dir())
			if !file.ends_with("/"):
				var file_access:FileAccess = FileAccess.open(App.cache_location+"/"+file,FileAccess.WRITE)
				var data:PackedByteArray = zip.read_file(file)
				file_access.store_buffer(data)
	zip.close()
	fix_default_folders()


func pack_map(path:String) -> void:
	var zip: ZIPPacker = ZIPPacker.new()
	zip.open(path)
	pack_recursive(zip,App.cache_location)
	zip.close()


func pack_recursive(zip:ZIPPacker, path:String) -> void:
	var dir:DirAccess = DirAccess.open(path)
	dir.list_dir_begin()
	var current:String = dir.get_next()
	while current != "":
		if dir.current_is_dir():
			await pack_recursive(zip,path+"/"+current)
		else:
			var file:FileAccess = FileAccess.open(path+"/"+current,FileAccess.READ)
			var buffer:PackedByteArray = file.get_buffer(file.get_length())
			zip.start_file((path+"/"+current).trim_prefix(App.cache_location))
			zip.write_file(buffer)
			zip.close_file()
		current = dir.get_next()


func delete_recursive(path:String) -> void:
	var dir:DirAccess = DirAccess.open(path)
	dir.list_dir_begin()
	var current:String = dir.get_next()
	while current != "":
		if dir.current_is_dir():
			delete_recursive(path+"/"+current)
			dir.remove(current)
		else:
			dir.remove(current)
		current = dir.get_next()
	dir.list_dir_end()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


func fix_default_folders() -> void:
	var folders := ["/assets/audio","/assets/images","/assets/notes"]
	for folder in folders:
		if !DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(App.cache_location+folder)):
			DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(App.cache_location+folder))
 

func update_gm_zoom(incr:float) -> void:
	var old_zoom = gm_zoom
	var new_incr = incr * gm_zoom
	gm_zoom += new_incr
	if gm_zoom < max_gm_zoom:
		gm_zoom = max_gm_zoom
	elif gm_zoom > min_gm_zoom:
		gm_zoom = min_gm_zoom
	if old_zoom == gm_zoom:
		return
	var new_zoom = Vector2(gm_zoom, gm_zoom)
	%GmCamera.set_zoom(new_zoom)


func set_gm_zoom(zoom:float) -> void:
	gm_zoom = zoom
	if gm_zoom < max_gm_zoom:
		gm_zoom = max_gm_zoom
	elif gm_zoom > min_gm_zoom:
		gm_zoom = min_gm_zoom
	var new_zoom = Vector2(gm_zoom, gm_zoom)
	%GmCamera.set_zoom(new_zoom)


func _on_pc_overlay_visibility_changed() -> void:
	emit_signal("pc_overlay_visibility_changed")
