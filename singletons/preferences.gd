extends Node

@warning_ignore("unused_signal")
signal maps_path_changed(path:String)

const default_preferences:Dictionary = {
	bg_color = "#333333ff",
	grid_color= "#00000080",
	pc_view_size_x = 0.0,
	pc_view_size_y = 0.0,
	pc_desk_enabled = false,
	pc_desk_size = 0.0,
	pc_desk_color = "#595959bf"
}

var maps_path:String:
	set(value):
		maps_path = value
		emit_signal("maps_path_changed",maps_path)
var bg_color:Color
var grid_color:Color
var pc_view_size_x:float
var pc_view_size_y:float
var pc_desk_enabled:bool
var pc_desk_size:float
var pc_desk_color:Color


func _ready() -> void:
	# Set default settings if needed
	var prefs_file: FileAccess
	if FileAccess.file_exists("user://preferences.json"):
		prefs_file = FileAccess.open("user://preferences.json", FileAccess.READ)
		
		# Read the entire file content
		var json_string = prefs_file.get_as_text()
		prefs_file.close()
		
		# Creates the helper class to interact with JSON
		var json = JSON.new()
		
		# Check if there is any error while parsing the JSON string, skip in case of failure
		var parse_result = json.parse(json_string)
		if parse_result != OK:
			print("JSON Parse Error: ", json.get_error_message(), " in ", json_string, " at line ", json.get_error_line())
			return
		
		# Get the data from the JSON object
		var data = json.get_data()
		for pref in data.keys():
			var value = data[pref]
			# Get the property type dynamically
			var property_info = get_script().get_script_property_list()
			for property in property_info:
				if property.name == pref:
					# Check the type of the property
					match property.type:
						TYPE_COLOR:
							set(pref, Color(value))
						_:
							set(pref, value)
					break
	else:
		# Save default_preferences as preferences
		update_preferences(default_preferences)
	
	# Create popup for maps_path if not set
	if !maps_path:
		open_maps_path_popup()
	elif !DirAccess.dir_exists_absolute(maps_path):
		open_maps_path_popup()


func open_maps_path_popup() -> void:
	var dialog = FileDialog.new()
	dialog.current_dir = maps_path
	dialog.access = FileDialog.ACCESS_FILESYSTEM
	dialog.current_dir = OS.get_user_data_dir()
	add_child(dialog)
	dialog.file_mode = FileDialog.FILE_MODE_OPEN_DIR
	dialog.dir_selected.connect(set_maps_path)
	dialog.use_native_dialog = true
	dialog.dialog_hide_on_ok = true
	dialog.ok_button_text = "Select"
	dialog.title = "Where to store maps?"
	dialog.size = Vector2(600, 400)
	OS.request_permissions()
	dialog.popup_centered()


func set_maps_path(dir:String) -> void:
	update_preferences({maps_path = dir})


func update_preferences(new_preferences: Dictionary) -> void:
	# Update instance variables with new preferences
	for pref in new_preferences.keys():
		var value = new_preferences[pref]
		# Get the property type dynamically
		var property_info = get_script().get_script_property_list()
		for property in property_info:
			if property.name == pref:
				# Check the type of the property
				if property.type == 20:
					set(pref, Color(value))
				else:
					set(pref, value)
				break
	# Update instance variables with new preferences
	for pref in new_preferences:
		if typeof(pref) == TYPE_COLOR:
			set(pref, Color(new_preferences[pref]))
		else:
			set(pref, new_preferences[pref])
	
	# Create a dictionary to save the current preferences using get_script_property_list
	var current_preferences: Dictionary = {}
	for property in get_script().get_script_property_list():
		var property_name = property.name
		var property_type = property.type
		if property_type == 20:
			current_preferences[property_name] = get(property_name).to_html()
		else:
			current_preferences[property_name] = get(property_name)
		
	# Serialize the current preferences to JSON
	var json_string = JSON.stringify(current_preferences)
	
	# Save the JSON string to user://preferences.json
	var file: FileAccess = FileAccess.open("user://preferences.json", FileAccess.WRITE)
	file.store_line(json_string)
	file.close()
