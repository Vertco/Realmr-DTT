extends Control

const maxOffset = Vector2(40000, 40000)
const minOffset = Vector2(-40000, -40000)

@onready var gmWindow: Window = get_window()

var img := preload("res://scenes/session/canvas/items/imageAsset.tscn")
var note := preload("res://scenes/session/canvas/items/noteAsset.tscn")
var playerVisVisibleIcon := preload("res://media/icons/playersView.svg")
var playerVisHiddenIcon := preload("res://media/icons/playersViewHidden.svg")
var _drag := false
@export var maxGmZoom := 0.05
@export var minGmZoom := 4.0
@export var gmZoomIncrement := 0.05
@export var currentGmZoom := 0.54

func _ready() -> void:
	session.connect("loadSession", loadMap)
	init()

func init() -> void:
	get_window().mode = Window.MODE_MAXIMIZED
	%playersView.world_2d = gmWindow.world_2d
	session.connect("layerChanged", updateOutliner)
	session.connect("togglePlayersView", togglePlayersView)
	session.connect("togglePlayersViewVis", togglePlayersViewVis)
	session.connect("focusGmCam", focusGmCam)
	%playersCam.zoom = Vector2(root.settings.playersView_x, root.settings.playersView_y)
	loadMap()
	%playersCamControl.on_playersCam_changed()

func updateOutliner() -> void:
	if %canvasAssets:
		var children:Array[Node] = %canvasAssets.get_children()
		session.emit_signal("updateOutliner", children)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("canvas_select"):
		if session.newAsset:
			match session.newAsset.metadata.type:
				"image":
					var asset := img.instantiate()
					asset.file = session.newAsset.filePath
					asset.gridsize = session.newAsset.metadata.gridsize
					asset.layer = session.activeLayer
					%canvasAssets.add_child(asset)
					asset.set_position(get_global_mouse_position())
				"note":
					var asset := note.instantiate()
					asset.file = session.newAsset.filePath
					asset.layer = session.activeLayer
					%canvasAssets.add_child(asset)
					asset.set_position(get_global_mouse_position())
		else:
			var nodes = get_tree().get_nodes_in_group("selected")
			for node in nodes:
				node.selected = false
			%playersCamControl.hideControls()
	elif event.is_action_pressed("cam_drag"):
		_drag = true
	elif event.is_action_released("cam_drag"):
		_drag = false
	elif event.is_action_pressed("canvas_deselect"):
		if event.pressed:
			if session.newAsset:
				session.newAsset = null
	elif event.is_action("cam_zoomIn"):
		updateGmZoom(gmZoomIncrement)
	elif event.is_action("cam_zoomOut"):
		updateGmZoom(-gmZoomIncrement)
	elif event is InputEventMouseMotion && _drag:
		var new_offset = %gmCam.get_offset() - event.relative/currentGmZoom
		new_offset.x = clamp(new_offset.x, minOffset.x, maxOffset.x)
		new_offset.y = clamp(new_offset.y, minOffset.y, maxOffset.y)
		%gmCam.set_offset(new_offset)
	elif event is InputEventKey:
		if event.is_action_pressed("canvas_delete"):
			if event.pressed:
				for node in get_tree().get_nodes_in_group("selected"):
					node.queue_free()
		elif event.is_action_pressed("ui_cancel"):
			if event.pressed:
				for node in get_tree().get_nodes_in_group("selected"):
					node.selected = false
				if session.newAsset:
					session.newAsset = null

@warning_ignore("shadowed_variable_base_class")
func focusGmCam(position:Vector2) -> void:
	%gmCam.set_offset(lerp(%gmCam.position,position,1))

func updateGmZoom(incr) -> void:
	var old_zoom = currentGmZoom
	var new_incr = incr * currentGmZoom
	currentGmZoom += new_incr
	session.gmZoom = currentGmZoom
	if currentGmZoom < maxGmZoom:
		currentGmZoom = maxGmZoom
	elif currentGmZoom > minGmZoom:
		currentGmZoom = minGmZoom
	if old_zoom == currentGmZoom:
		return
	var newZoom = Vector2(currentGmZoom, currentGmZoom)
	%playersCamControl.on_playersCam_changed()
	%gmCam.set_zoom(newZoom)

func togglePlayersView(display:int) -> void:
	var windowPosition = DisplayServer.screen_get_size(display)/2
	var globalPosition = windowPosition + DisplayServer.screen_get_position(display)
	%playersView.set_position(globalPosition)
	%playersView.visible = !%playersView.visible

func togglePlayersViewVis() -> void:
	%screensaver.visible = !%screensaver.visible
	if %screensaver.visible:
		%visButton.icon = playerVisHiddenIcon
	else:
		%visButton.icon = playerVisVisibleIcon

func loadMap() -> void:
	# Remove previously loaded nodes
	var saveNodes = get_tree().get_nodes_in_group("saveWithSession")
	var version
	for node in saveNodes:
		node.queue_free()  # Use node.queue_free() to free the node
	%screensaver.visible = true
	# Load saved nodes from save file
	if FileAccess.file_exists(session.filePath):
		var file := FileAccess.open(session.filePath, FileAccess.READ)
		var jsonString = file.get_as_text()  # Read the entire file as a string
		var json = JSON.new()
		var parseResult = json.parse(jsonString)
		if parseResult != OK:
			print("JSON Parse Error: ", json.get_error_message(), " in ", jsonString, " at line ", json.get_error_line())
			return
		var data = json.get_data()  # Get the parsed data
		version = data.get("version", "")
		if data.has("nodes"):
			var nodes = data["nodes"]
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
		else:
			print("No nodes found in the save file.")
		file.close()  # Close the file after reading
		var assets:Array[Node] = %canvasAssets.get_children()
		session.emit_signal("updateOutliner", assets)
		print("Loaded map "+session.session+" created in version "+version)
	else:
		push_warning("Save file not found!")
