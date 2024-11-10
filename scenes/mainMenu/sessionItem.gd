extends Control

@warning_ignore("unused_signal")
signal _on_session_selected(ses:String)
@warning_ignore("unused_signal")
signal _on_session_opened(ses:String)
@warning_ignore("unused_signal")
signal _on_sessionFolder_pressed(ses:String)

@export var ses:String:
	set(value):
		ses = value
		globalPath = ProjectSettings.globalize_path(root.settings.get("sessionsPath") + "sessions/" + ses)
var selected:bool:
	set(value):
		selected = value
		if selected:
			self_modulate = Color(1.75,1.75,1.75)
		else:
			if _hover:
				self_modulate = Color(1.5,1.5,1.5)
			else:
				self_modulate = Color(1,1,1)
var globalPath:String
var _hover:bool = false

func _ready() -> void:
	var modifiedTime:int = FileAccess.get_modified_time(globalPath + "/" + ses + ".rrmap")
	var timeDict:Dictionary = Time.get_datetime_dict_from_unix_time(modifiedTime)
	var timeString:String = "%02d-%02d-%02d %02d:%02d" % [
		timeDict.day, timeDict.month, timeDict.year,
		timeDict.hour, timeDict.minute
	]
	%sessionName.text = ses
	%lastModified.text = "Last modified: " + timeString
	%path.text = globalPath
	tooltip_text = "Select "+ses+" session"

func _on_mouse_entered() -> void:
	_hover = true
	self_modulate = Color(1.5,1.5,1.5)

func _on_mouse_exited() -> void:
	_hover = false
	if !selected:
		self_modulate = Color(1,1,1)

func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.double_click:
				emit_signal("_on_session_opened", ses)
			elif event.pressed:
				selected = true
				emit_signal("_on_session_selected", ses)

func _on_folderButton_pressed() -> void:
	emit_signal("_on_sessionFolder_pressed", ses)
