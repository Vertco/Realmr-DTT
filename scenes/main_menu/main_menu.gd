extends Control

func _ready() -> void:
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	get_window().title = ProjectSettings.get_setting("application/config/name")
	get_tree().set_auto_accept_quit(false)
	%VersionLabel.text = "Version: "+str(ProjectSettings.get_setting("application/config/version"))


func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		App.confirm("Do you want to quit Realmr?", "Quit Realmr?","",false,"","Quit","Cancel")
		var confirm = await App.confirmation
		if confirm[0]:
			get_tree().quit()
		else:
			pass


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
	var path:String = %MapsContainer.current_folder
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
		zip.open(%MapsContainer.current_folder+"/"+map_name+".rmm")
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
		App.map_path = %MapsContainer.current_folder+"/"+map_name+".rmm"
		get_tree().change_scene_to_file("uid://dnsgqouj0cu8w") # map_editor


func _on_new_btn_pressed() -> void:
	open_new_map_popup(true)


func _on_new_map_popup_confirmed() -> void:
	create_map(%NewMapName.text)


func _on_quit_button_pressed() -> void:
	App.confirm("Do you want to quit Realmr?", "Quit Realmr?")
	var confirm = await App.confirmation
	if confirm[0]:
		get_tree().quit()
