extends Control

const sessionItemSc:PackedScene = preload("res://scenes/mainMenu/sessionItem.tscn")

var selected:String:
	set(value):
		selected = value
		%open.disabled = false
		%delete.disabled = false

func _ready() -> void:
	%versionLabel.text = "Version: "+ProjectSettings.get_setting("application/config/version")
	loadSessions()
	updateVisibleLayer()

#region functions
func updateVisibleLayer() -> void:
	var window:Window = get_window()
	for layer in range(9):
		window.set_canvas_cull_mask_bit(layer, true)

func loadSessions() -> void:
	for child in %sessionsContainer.get_children():
		child.queue_free()
	var dir = DirAccess.open(root.settings.get("sessionsPath") + "/sessions")
	var sessions = dir.get_directories()
	for s in sessions:
		var sessionItem = sessionItemSc.instantiate()
		sessionItem.ses = s
		sessionItem.connect("_on_session_selected", updateSelection)
		sessionItem.connect("_on_session_opened", openSession)
		sessionItem.connect("_on_sessionFolder_pressed", openSessionFolder)
		%sessionsContainer.add_child(sessionItem)

func openSession(s) -> void:
	session.session = s
	get_tree().change_scene_to_file("res://scenes/session/canvas/canvasV2.tscn")

func openSessionFolder(s) -> void:
	OS.shell_show_in_file_manager(ProjectSettings.globalize_path("user://sessions/"+s+"/assets"))

func createSession(sessionName) -> void:
	var sessions = DirAccess.open(root.settings.get("sessionsPath") + "/sessions")
	if sessions.dir_exists(sessionName):
		openNewSessionDialog("Session already exists!")
	else:
		var result = sessions.make_dir_recursive(sessionName + "/assets/images") & sessions.make_dir_recursive(sessionName + "/assets/audio")
		if result == OK:
			print("Session created successfully!")
			openSession(sessionName)
			session.save()
		else:
			print("Failed to create session!")

func openNewSessionDialog(message:String) -> void:
	var messageLabel = Label.new()
	if message == "":
		messageLabel.queue_free()
		%sessionName.clear()
	else:
		messageLabel.text = message
		%newSessionForm.add_child(messageLabel)
	%menuBlur.visible = true
	%newSessionDialog.popup_centered()

func updateSelection(selectedSession:String) -> void:
	selected = selectedSession
	var sessions:Array[Node] = %sessionsContainer.get_children()
	for s in sessions:
		if s.ses != selectedSession:
			s.selected = false

# TODO Create working delete function
func deleteSession() -> void:
	var path = ProjectSettings.globalize_path(root.settings.get("sessionsPath")+"sessions/"+selected)
	var dir = DirAccess.open(path)
	var files = DirAccess.get_files_at(path)
	for file in files:
		if dir.current_is_dir():
			dir.delete_folder(dir.get_current_dir()+"/"+file)
			print("Deleted folder "+dir)
		else:
			DirAccess.remove_absolute(file)
	dir.remove(path)
	loadSessions()
	%menuBlur.visible = false

func cancelDialog() -> void:
	%confirmDialog.disconnect("confirmed", quit)
	%confirmDialog.disconnect("canceled", cancelDialog)
	%menuBlur.visible = false

func quit() -> void:
	get_tree().quit()
#endregion

#region Signal functions
func _on_open_pressed() -> void:
	openSession(selected)

func _on_delete_pressed() -> void:
	%confirmLabel.text = "Delete session "+selected+"?"
	%confirmDialog.connect("confirmed", deleteSession)
	%confirmDialog.connect("canceled", cancelDialog)
	%menuBlur.visible = true
	%confirmDialog.popup_centered()

func _on_new_pressed() -> void:
	openNewSessionDialog("")

func _on_quit_pressed() -> void:
	%confirmLabel.text = "Quit session manager?"
	%confirmDialog.connect("confirmed", quit)
	%confirmDialog.connect("canceled", cancelDialog)
	%confirmDialog.get_ok_button().mouse_default_cursor_shape = CURSOR_POINTING_HAND
	%confirmDialog.get_cancel_button().mouse_default_cursor_shape = CURSOR_POINTING_HAND
	%menuBlur.visible = true
	%confirmDialog.popup_centered()

func _on_newSessionDialog_confirmed() -> void:
	var newSession:String = %sessionName.text
	createSession(newSession)

func _on_newSessionDialog_canceled() -> void:
	%menuBlur.visible = false
#endregion
