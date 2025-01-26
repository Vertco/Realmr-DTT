extends Control

func _ready() -> void:
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	get_tree().set_auto_accept_quit(false)
	%VersionLabel.text = "Version: "+str(ProjectSettings.get_setting("application/config/version"))


func _on_quit_button_pressed() -> void:
	App.confirm("Do you want to quit Realmr?", "Quit Realmr?")
	var confirm = await App.confirmation
	if confirm:
		get_tree().quit()
