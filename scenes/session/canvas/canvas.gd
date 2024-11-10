extends Control

@onready var gmWindow: Window = get_window()
@onready var playersWindow: Window = %playersWindow

var img = preload("res://scenes/session/canvas/items/imageAsset.tscn")
var ui = preload("res://scenes/session/ui/userInterface.tscn")

func _ready() -> void:
	loadSession()
	playersWindow.world_2d = gmWindow.world_2d
	session.connect("togglePlayersView", togglePlayersView)
	session.connect("togglePlayersViewVis", togglePlayersViewVis)
	session.connect("layerChanged", updateVisibleLayer)
	session.connect("loadSession", loadSession)
	%playersCam.zoom = Vector2(root.settings.playersView_x, root.settings.playersView_y)
	updateVisibleLayer()
	togglePlayersViewVis()
	var uiInstance:= ui.instantiate()
	uiInstance.playersWindow = mainMenu.playersWindowOpen
	%gmCam.add_child(uiInstance)
	var children:Array[Node] = %assets.get_children()
	session.emit_signal("updateOutliner", children)
	if mainMenu.playersWindowOpen:
		togglePlayersView(mainMenu.playersWindowDisplay)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				if session.newAsset:
					match session.newAsset.metadata.type:
						"image":
							var asset := img.instantiate()
							asset.file = session.newAsset.filePath
							asset.gridsize = session.newAsset.metadata.gridsize
							asset.layer = session.activeLayer
							%assets.add_child(asset)
							asset.set_position(get_global_mouse_position())
				else:
					var nodes = get_tree().get_nodes_in_group("selected")
					for node in nodes:
						node.selected = false
					%playersCamControl.hideControls()
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			if event.pressed:
				if session.newAsset:
					session.newAsset = null
	elif event is InputEventKey:
		if event.keycode == KEY_DELETE:
			if event.pressed:
				for node in get_tree().get_nodes_in_group("selected"):
					node.queue_free()
		elif event.keycode == KEY_ESCAPE:
			if event.pressed:
				for node in get_tree().get_nodes_in_group("selected"):
					node.selected = false
				if session.newAsset:
					session.newAsset = null

func togglePlayersView(display:int) -> void:
	var windowPosition = DisplayServer.screen_get_size(display)/2
	var globalPosition = windowPosition + DisplayServer.screen_get_position(display)
	%playersWindow.set_position(globalPosition)
	%playersWindow.visible = !%playersWindow.visible

func togglePlayersViewVis() -> void:
	var state:bool = playersWindow.get_canvas_cull_mask_bit(session.activeLayer)
	playersWindow.set_canvas_cull_mask_bit(session.activeLayer, !state)
	%screensaver.visible = state

func updateVisibleLayer() -> void:
	for layer in range(9):
		if layer == session.activeLayer:
			gmWindow.set_canvas_cull_mask_bit(layer, true)
			playersWindow.set_canvas_cull_mask_bit(layer, true)
		else:
			gmWindow.set_canvas_cull_mask_bit(layer, false)
			playersWindow.set_canvas_cull_mask_bit(layer, false)

func loadSession() -> void:
	var savePath:String = "user://sessions/"+session.session+"/"+session.session+".rrmap"
	print(savePath)
	var saveNodes = get_tree().get_nodes_in_group("saveWithSession")
	if not FileAccess.file_exists(savePath):
		return # Error! We don't have a save to load.
	for node in saveNodes:
		queue_free()
	# Load the file line by line and process that dictionary to restore
	# the object it represents.
	var save_game = FileAccess.open(savePath, FileAccess.READ)
	while save_game.get_position() < save_game.get_length():
		var json_string = save_game.get_line()

		# Creates the helper class to interact with JSON
		var json = JSON.new()

		# Check if there is any error while parsing the JSON string, skip in case of failure
		var parse_result = json.parse(json_string)
		if not parse_result == OK:
			print("JSON Parse Error: ", json.get_error_message(), " in ", json_string, " at line ", json.get_error_line())
			continue

		# Get the data from the JSON object
		var node_data = json.get_data()

		# Firstly, we need to create the object and add it to the tree and set its position.
		var new_object = load(node_data["filename"]).instantiate()
		get_node(node_data["parent"]).add_child(new_object)
		new_object.position = Vector2(node_data["pos_x"], node_data["pos_y"])

		# Now we set the remaining variables.
		for i in node_data.keys():
			if i == "filename" or i == "parent" or i == "pos_x" or i == "pos_y":
				continue
			new_object.set(i, node_data[i])
		if new_object.has_method("update"):
			new_object.update()

func _on_playersWindow_close_requested() -> void:
	session.emit_signal("togglePlayersView")
