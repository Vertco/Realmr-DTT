extends Control

@onready var sessionMenu:PopupMenu = %session.get_popup()
var playersWindow:bool = false
var openMenu = PopupMenu.new()

#region functions
func _ready() -> void:
	sessionMenu.connect("id_pressed", _on_sessionItem_pressed)
	#openMenu.connect("id_pressed", _on_openItem_pressed)
	#var dir = DirAccess.open(root.settings.get("sessionsPath") + "/sessions")
	#var sessions = dir.get_directories()
	#for s in sessions:
		#openMenu.add_item(s)
	#sessionMenu.add_submenu_node_item("Open session",openMenu)

func _on_sessionItem_pressed(id) -> void:
	match id:
		0:
			session.save()
		1:
			OS.shell_show_in_file_manager(ProjectSettings.globalize_path(session.assetsRoot))
		2:
			if playersWindow:
				session.emit_signal("togglePlayersView", %displaySelector.selectedDisplay)
				playersWindow = false
			else:
				%playersViewPopup.popup_centered()
		3:
			session.emit_signal("togglePlayersViewVis")
		4:
			session.session = ""
			mainMenu.playersWindowOpen = playersWindow
			get_tree().change_scene_to_file("res://scenes/mainMenu/mainMenu.tscn")
		5:
			root.quit()

func _on_openItem_pressed(id) -> void:
	var s:String = openMenu.get_item_text(id)
	session.session = s
	session.emit_signal("loadSession")
#endregion
