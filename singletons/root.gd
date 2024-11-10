extends Node

#region global enums
enum mode {
	Edit,
	Play
}
#endregion

#region global constants
const defaultSettings:Dictionary = {
	sessionsPath= "user://",
	gridColor= "00000080",
	backgroundColor = "333333ff",
	playersView_x = 1,
	playersView_y = 1,
	passepartout = 0.0,
	passepartoutColor = "595959bf"
}
#endregion

#region global variables
@export var settings:Dictionary
#endregion

#region global functions
func _ready() -> void:
	#Set default settings if needed
	var settingsFile:FileAccess
	if FileAccess.file_exists("user://settings.json"):
		settingsFile = FileAccess.open("user://settings.json", FileAccess.READ)
		while not settingsFile.eof_reached():
			var json_string = settingsFile.get_line()

			# Creates the helper class to interact with JSON
			var json = JSON.new()

			# Check if there is any error while parsing the JSON string, skip in case of failure
			var parse_result = json.parse(json_string)
			if not parse_result == OK:
				print("JSON Parse Error: ", json.get_error_message(), " in ", json_string, " at line ", json.get_error_line())
				continue

			# Get the data from the JSON object
			settings = json.get_data()
	else:
		settings = defaultSettings
		settingsFile = FileAccess.open("user://settings.json", FileAccess.WRITE)
		var jsonSettings := JSON.stringify(settings)
		settingsFile.store_line(jsonSettings)
	
	#Create the "sessions" directory 
	var dir := DirAccess.open(settings.get("sessionsPath"))
	dir.make_dir("sessions")

func saveSettings(newSettings:Dictionary) -> void:
	var settingsFile := FileAccess.open("user://settings.json", FileAccess.WRITE)
	for setting in newSettings:
		settings.merge(newSettings, true)
	var jsonSettings := JSON.stringify(settings)
	settingsFile.store_line(jsonSettings)

func quit() -> void:
	get_tree().quit()
#endregion
